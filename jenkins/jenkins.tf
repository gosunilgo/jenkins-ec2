
data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user_data.tpl")}"
}

resource "aws_iam_role" "jenkins_ec2_role" {
  name = "jenkins_ec2_role"
  assume_role_policy = "${file("${path.module}/policies/ec2-role.json")}"
}

resource "aws_iam_role_policy" "jenkins_master_role" {
  name = "jenkins_master_role"
  role = "${aws_iam_role.jenkins_ec2_role.id}"
  policy = "${file("${path.module}/policies/jenkins-master.json")}"
}

resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name = "jenkins_instance_profile"
  path = "/"
  roles = ["jenkins_ec2_role"]
  depends_on = ["aws_iam_role.jenkins_ec2_role"]
}

resource "aws_instance" "jenkins" {
  ami = "${var.ec2_linux_ami_id}"
  instance_type = "${var.instance_type}"
  subnet_id = "${var.subnet_id}"
  vpc_security_group_ids = ["${var.security_group_id}"]
  key_name = "${var.key_name}"
  user_data = "${data.template_file.user_data.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.jenkins_instance_profile.id}"
  tags {
    Name = "jenkins"
  }
  # JENKINS_HOME /var/lib/jenkins will be mounted on this data disk
  ebs_block_device {
    device_name = "/dev/xvdj"
    delete_on_termination = "${var.data_delete_on_termination}"
    volume_size = "${var.data_disk_size_in_gb}"
    volume_type = "gp2"
  }
  depends_on = ["aws_iam_instance_profile.jenkins_instance_profile"]
}
