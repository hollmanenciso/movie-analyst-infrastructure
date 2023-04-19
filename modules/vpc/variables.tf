variable "create_vpc" {
  type    = bool
  default = true
}
variable "create_igw" {
  type    = bool
  default = true
}
variable "create_nat" {
  type    = bool
  default = true
}
variable "create_rt" {
  description = "Create a route table."
  type        = bool
  default     = true
}
variable "create_sg" {
  description = "Create a security group."
  type        = bool
  default     = true
}
variable "name" {
  type    = string
  default = ""
}
variable "cidr_block" {
  type    = string
  default = "0.0.0.0/0"
}
variable "instance_tenancy" {
  default = "default"
}
variable "cidr_block_public_subnets" {
  type    = list(string)
  default = []
}
variable "availability_zone_public_susbnets" {
  type    = list(string)
  default = []
}
variable "cidr_block_private_subnets" {
  type    = list(string)
  default = []
}
variable "availability_zone_private_susbnets" {
  type    = list(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}
