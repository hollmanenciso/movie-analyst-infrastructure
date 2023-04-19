variable "access_key" {}
variable "secret_key" {}
variable "tags" {
  type = map(string)
  default = {
    created_by    = "Hollman Arroyo"
    creation_date = "22/02/2021"
    project_name  = "Ramp-Up"
    stop          = "stop"
  }
}
variable "user_data_bastion" {
  default = <<EOF
#!/bin/bash
sudo apt update
curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install -y terraform
#wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
#sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
#sudo apt update
#sudo apt install -y default-jdk
#sudo apt install -y jenkins
#sudo systemctl start jenkins
EOF
}
variable "user_data_frontend" {
  default = <<EOF
#!/bin/bash
sudo apt update
curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
EOF
}
variable "user_data_backend" {
  default = <<EOF
#!/bin/bash
sudo apt update
curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo apt install -y mysql-server
sudo service mysql start
sudo mysql <<MYSQL_SCRIPT
CREATE USER 'applicationuser'@'localhost' IDENTIFIED BY 'applicationuser'; GRANT ALL PRIVILEGES ON * . * TO 'applicationuser'@'localhost';
FLUSH PRIVILEGES;
ALTER USER 'applicationuser'@'localhost' IDENTIFIED WITH mysql_native_password BY 'applicationuser';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
mysql -u applicationuser -papplicationuser <<DB_SCRIPT
CREATE DATABASE IF NOT EXISTS movie_db;
USE movie_db;
#DROP TABLE IF EXISTS movies;
#DROP TABLE IF EXISTS reviewers;
#DROP TABLE IF EXISTS publications;
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
}
