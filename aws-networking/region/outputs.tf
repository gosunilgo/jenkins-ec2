output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "public_primary_subnet_id" {
  value = "${module.public_primary_subnet.subnet_id}"
}

output "public_secondary_subnet_id" {
  value = "${module.public_primary_subnet.subnet_id}"
}

output "private_primary_subnet_id" {
  value = "${module.private_primary_subnet.subnet_id}"
}

output "private_secondary_subnet_id" {
  value = "${module.private_primary_subnet.subnet_id}"
}
