
variable "cluster_name" {}
variable "cluster_version" {}
variable "aws_region" {}
variable "s3_bucket_name" {}
variable "vpc_name" {}
variable "vpc_cidr" {}
variable "vpc_network_azs" { type = list(any) }
variable "private_subnet_cidr" { type = list(any) }
variable "public_subnet_cidr" { type = list(any) }
variable "node_type" { type = string }