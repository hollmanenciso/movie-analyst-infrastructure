variable "name" {
  type    = string
  default = ""
}
variable "description" {
  type    = string
  default = ""
}
variable "vpc_id" {
  type    = string
  default = ""
}
variable "from_port_cidr_block" {
  type    = list(string)
  default = []
}
variable "to_port_cidr_block" {
  type    = list(string)
  default = []
}
variable "protocol_cidr_block" {
  type    = list(string)
  default = []
}
variable "cidr_block" {
  type    = list(string)
  default = []
}
variable "from_port_sg_id" {
  type    = list(string)
  default = []
}
variable "to_port_sg_id" {
  type    = list(string)
  default = []
}
variable "protocol_sg_id" {
  type    = list(string)
  default = []
}
variable "source_security_group_id" {
  type    = list(string)
  default = []
}
variable "allow_all" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
