variable "name" {
  type    = string
  default = ""
}
variable "internal" {
  type    = bool
  default = false
}
variable "load_balancer_type" {
  type    = string
  default = ""
}
variable "subnets" {
  type    = list(string)
  default = []
}
variable "security_groups" {
  type    = list(string)
  default = []
}
variable "vpc_id" {
  type    = string
  default = ""
}
variable "target_type" {
  type    = string
  default = ""
}
variable "target_protocol" {
  type    = string
  default = ""
}
variable "target_port" {
  type    = number
  default = 80
}
variable "listener_protocol" {
  type    = string
  default = ""
}
variable "listener_port" {
  type    = number
  default = 80
}
variable "target_ids" {
  type    = list(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}
