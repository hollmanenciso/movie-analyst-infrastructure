variable "name" {
  type    = string
  default = ""
}
variable "subnet_ids" {
  type    = list(string)
  default = []
}
variable "ami" {
  type    = string
  default = ""
}
variable "instance_type" {
  type    = string
  default = ""
}
variable "associate_public_ip_address" {
  type    = bool
  default = false
}
variable "user_data" {
  type    = string
  default = null
}
variable "user_data_base64" {
  type    = string
  default = null
}
variable "vpc_security_group_ids" {
  type    = list(string)
  default = []
}
variable "key_name" {
  type    = string
  default = ""
}
variable "tags" {
  type    = map(string)
  default = {}
}
