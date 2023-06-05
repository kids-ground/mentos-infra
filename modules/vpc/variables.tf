variable "name" {
  type = string
}

variable "cidr" {
  type = string
}

variable "az_names" {}

variable "public_subnets" {}

variable "private_subnets" {}

variable "tags" {
  type = map(string)
}