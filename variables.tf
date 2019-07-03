variable "aws_region" {
  description = "Région AWS à utiliser"
  default = "eu-west-3"
}

variable "base_cidr_block" {
  description = "Adressage CIDR /16 , tel que 10.1.0.0/16, utilisé par le VPC"
  default = "10.1.0.0/16"
}

# Declare the data source
data "aws_availability_zones" "available" {
  state = "available"
}





provider "aws" {
  profile    = "default"
  region     = var.aws_region
}