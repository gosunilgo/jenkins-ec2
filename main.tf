provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

module "jenkins-vpc" {
  source             = "./aws-networking/region"
  region             = "${var.region}"
  allow_traffic_from = "${var.allow_traffic_from}"
  base_cidr_block    = "${var.base_cidr_block}"
  key_name           = "${var.key_name}"
}
