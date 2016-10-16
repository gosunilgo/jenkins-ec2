resource "aws_eip" "main" {
  vpc = true
}

resource "aws_instance" "main" {
  ami = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  subnet_id = "${var.subnet_id}"
  vpc_security_group_ids = ["${var.security_group_id}"]
  key_name = "${var.key_name}"
  tags {
    Name = "${var.tag_name}"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id = "${aws_instance.main.id}"
  allocation_id = "${aws_eip.main.id}"
}
