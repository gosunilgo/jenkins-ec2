module "bastions" {
  source              = "../bastion"
  ami_id              = "${var.ec2_linux_ami_id}"
  instance_type       = "${var.bastion_instance_type}"
  region              = "${var.region}"
  subnet_primary_id   = "${module.public_primary_subnet.subnet_id}"
  subnet_secondary_id = "${module.public_secondary_subnet.subnet_id}"
  security_group_id   = "${aws_security_group.ssh.id}"
  s3_bucket           = "${var.s3_bucket}"
  s3_bucket_prefix    = "${var.s3_bucket_prefix}"
  key_name            = "${var.key_name}"
}
