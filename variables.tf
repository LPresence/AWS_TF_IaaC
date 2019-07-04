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

output "EFS-mount-target-dns" {
  description = "DNS name of the mount target provisioned."
  value       = "${aws_efs_mount_target.efs-mt-ecs.dns_name}"
}

output "EIP-access-address" {
  description = "IP address of the Elastic IP."
  value       = "${aws_eip.CDS-tools-EIP.public_ip}"
}

output "ECS-ip" {
  description = "IP address of the ECS instance."
  value       = "${aws_instance.CDS-tools-frontend.private_ip}"
}
