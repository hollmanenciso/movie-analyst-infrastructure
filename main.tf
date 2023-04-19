provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

module "vpc" {
  source = "./modules/vpc/"

  #Resources
  create_nat = true

  #VPC
  name       = "Hollman-movie-analyst"
  cidr_block = "10.0.0.0/16"

  #Subnet
  cidr_block_public_subnets          = ["10.0.1.0/24", "10.0.2.0/24"]
  availability_zone_public_susbnets  = ["us-east-1a", "us-east-1b"]
  cidr_block_private_subnets         = ["10.0.3.0/24"]
  availability_zone_private_susbnets = ["us-east-1a"]

  tags = var.tags
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

module "security_group_bastion" {
  source = "./modules/security/"

  name                 = "Hollman-bastion-sg"
  description          = "This security group is used for the bastion host and allows access to jenkins by port 8080"
  vpc_id               = module.vpc.vpc_id
  from_port_cidr_block = [22, 8080]
  to_port_cidr_block   = [22, 8080]
  protocol_cidr_block  = ["tcp", "tcp"]
  cidr_block           = [format("%s/%s", chomp(data.http.myip.body), "32"), format("%s/%s", chomp(data.http.myip.body), "32")]
  tags                 = var.tags
}
module "security_group_frontend_lb" {
  source = "./modules/security/"

  name                 = "Hollman-frontend-lb-sg"
  description          = "This security group is used for the fronted load balancer and allows access by 0.0.0.0/80"
  vpc_id               = module.vpc.vpc_id
  from_port_cidr_block = [80]
  to_port_cidr_block   = [80]
  protocol_cidr_block  = ["tcp"]
  cidr_block           = ["0.0.0.0/0"]
  tags                 = var.tags
}

module "security_group_frontend" {
  source = "./modules/security/"

  name                     = "Hollman-frontend-sg"
  description              = "This security group is used for the fronted and allows access by frontend-lb and bastion-sg"
  vpc_id                   = module.vpc.vpc_id
  from_port_sg_id          = [22, 3030]
  to_port_sg_id            = [22, 3030]
  protocol_sg_id           = ["tcp", "tcp"]
  source_security_group_id = [module.security_group_bastion.sg_id, module.security_group_frontend_lb.sg_id]
  tags                     = var.tags
}

module "security_group_backend" {
  source = "./modules/security/"

  name                     = "Hollman-backend-sg"
  description              = "This security group is used for the backend and allows access by frontend-sg and bastion-sg"
  vpc_id                   = module.vpc.vpc_id
  from_port_sg_id          = [22, 3000]
  to_port_sg_id            = [22, 3000]
  protocol_sg_id           = ["tcp", "tcp"]
  source_security_group_id = [module.security_group_bastion.sg_id, module.security_group_frontend.sg_id]
  tags                     = var.tags
}

module "security_group_rds" {
  source = "./modules/security/"

  name                     = "Hollman-rds-sg"
  description              = "This security group is used for the rds and allows access by backend-sg and bastion-sg"
  vpc_id                   = module.vpc.vpc_id
  from_port_sg_id          = [3306, 3306]
  to_port_sg_id            = [3306, 3306]
  protocol_sg_id           = ["tcp", "tcp"]
  source_security_group_id = [module.security_group_bastion.sg_id, module.security_group_backend.sg_id]
  tags                     = var.tags
}

locals {
  db_subnet_group      = aws_db_subnet_group.this.id
  db_instance_endpoint = aws_db_instance.mysql.address
}

resource "aws_db_subnet_group" "this" {
  name_prefix = "Hollman-movie-analyst-rds"
  subnet_ids  = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)

  tags = merge(
    {
      "Name" = format("%s", "Hollman-movie-analyst-rds")
    },
    var.tags,
  )
}

resource "aws_db_instance" "mysql" {

  engine         = "mysql"
  engine_version = "8.0.32"

  identifier = "Hollman-movie-analyst-rds"
  username   = "applicationuser"
  password   = "applicationuser"

  instance_class = "db.t2.micro"

  storage_type      = "gp2"
  allocated_storage = "20"

  multi_az = "false"

  db_subnet_group_name   = local.db_subnet_group
  publicly_accessible    = false
  vpc_security_group_ids = [module.security_group_rds.sg_id]
  availability_zone      = "us-east-1a"
  port                   = 3306

  tags = merge(
    {
      "Name" = format("%s", "Hollman-movie-analyst-rds")
    },
    var.tags,
  )
}

module "ec2_bastion" {
  source = "./modules/ec2/"

  name = "Hollman-bastion-ec2"

  ami           = "ami-06e46074ae430fba6"
  instance_type = "t2.micro"

  subnet_ids                  = slice(module.vpc.public_subnet_ids, 0, 1)
  associate_public_ip_address = true
  user_data                   = var.user_data_bastion

  vpc_security_group_ids = [module.security_group_bastion.sg_id]

  key_name = "ramp-up"

  tags = var.tags
}
module "ec2_public" {
  source = "./modules/ec2/"

  name = "Hollman-frontend-ec2"

  ami           = "ami-06e46074ae430fba6" 
  instance_type = "t2.micro"

  subnet_ids                  = module.vpc.public_subnet_ids
  associate_public_ip_address = true
  user_data                   = var.user_data_frontend

  vpc_security_group_ids = [module.security_group_frontend.sg_id]

  key_name = "ramp-up"

  tags = var.tags
}
module "ec2_backend" {
  source = "./modules/ec2/"

  name = "Hollman-backend-ec2"

  ami           = "ami-06e46074ae430fba6"
  instance_type = "t2.micro"

  subnet_ids = module.vpc.private_subnet_ids
  user_data  = <<EOF
#!/bin/bash
sudo apt update
curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo apt install -y mysql-server
sudo service mysql start
mysql -u applicationuser -h ${local.db_instance_endpoint} -papplicationuser <<DB_SCRIPT
CREATE DATABASE IF NOT EXISTS movie_db;
USE movie_db;
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS reviewers;
DROP TABLE IF EXISTS publications;
CREATE TABLE IF NOT EXISTS publications (
name VARCHAR(250),
avatar VARCHAR(250),
PRIMARY KEY (name)
);
CREATE TABLE IF NOT EXISTS reviewers (
name VARCHAR(250),
publication VARCHAR(250),
avatar VARCHAR(250),
PRIMARY KEY (name),
FOREIGN KEY (publication) REFERENCES publications(name)
);
CREATE TABLE IF NOT EXISTS movies (
title VARCHAR(250),
release_year VARCHAR(250),
score INT(11),
reviewer VARCHAR(250),
publication VARCHAR(250),
PRIMARY KEY (title),
FOREIGN KEY (reviewer) REFERENCES reviewers(name)
);
DB_SCRIPT
EOF

  vpc_security_group_ids = [module.security_group_backend.sg_id]

  key_name = "ramp-up"

  tags = var.tags
}
module "load_balancer" {
  source = "./modules/load_balancer/"

  name = "Hollman-frontend"

  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnet_ids
  security_groups    = [module.security_group_frontend_lb.sg_id]

  vpc_id          = module.vpc.vpc_id
  target_type     = "instance"
  target_protocol = "HTTP"
  target_port     = 3030

  listener_protocol = "HTTP"
  listener_port     = 80

  target_ids = module.ec2_public.ec2_id

  tags = var.tags
}
