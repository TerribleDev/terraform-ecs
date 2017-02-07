variable "SubnetPublic1a" {
  type    = "string"
}
variable "SubnetPublic1b" {
  type    = "string"
}
variable "SubnetPublic1c" {
  type    = "string"
}
variable "SubnetPrivate1a" {
  type    = "string"
}
variable "SubnetPrivate1b" {
  type    = "string"
}
variable "SubnetPrivate1c" {
  type    = "string"
}

variable "VpcId"{
    type = "string"
    default = ""
}

variable "account_id"{
    type = "string"
    default = ""
}
variable "region"{
    type = "string"
    default = "eu-west-1"
}

variable "container_name"{
    type = "string"
}
variable "container_port"{
    type = "string"
}
variable "lb_port"{
    type = "string"
}