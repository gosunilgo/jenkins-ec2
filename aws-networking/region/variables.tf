variable "region" {
  description = "The name of the AWS region to set up a network within"
}

variable "allow_traffic_from" {}

variable "base_cidr_block" {}

variable "key_name" {
  description = "SSH key name in your AWS account for AWS instances."
}

provider "aws" {
  region = "${var.region}"
}
