module "bastion_primary" {
  source            = "../bastion"
  ami_id            = "${var.ec2_linux_ami_id}"
  instance_type     = "${var.bastion_instance_type}"
  subnet_id         = "${module.public_primary_subnet.subnet_id}"
  security_group_id = "${aws_security_group.ssh.id}"
  key_name          = "${var.key_name}"
  tag_name          = "bastion ${data.aws_availability_zones.all.names[0]}"
}

module "bastion_secondary" {
  source            = "../bastion"
  ami_id            = "${var.ec2_linux_ami_id}"
  instance_type     = "${var.bastion_instance_type}"
  subnet_id         = "${module.public_secondary_subnet.subnet_id}"
  security_group_id = "${aws_security_group.ssh.id}"
  key_name          = "${var.key_name}"
  tag_name          = "bastion ${data.aws_availability_zones.all.names[1]}"
}
