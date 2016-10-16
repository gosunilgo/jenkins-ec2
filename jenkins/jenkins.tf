
data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user_data.tpl")}"
}

resource "aws_iam_role" "jenkins_iam_role" {
  name = "jenkins_iam_role"
  assume_role_policy = "${file("${path.module}/policies/ec2-role.json")}"
}

resource "aws_iam_role_policy" "iam_role_jenkins_policy" {
  name = "iam_role_jenkins_policy"
  role = "${aws_iam_role.jenkins_iam_role.id}"
  policy = "${file("${path.module}/policies/jenkins-role.json")}"
}

resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name = "jenkins_instance_profile"
  path = "/"
  roles = ["jenkins_iam_role"]
}

resource "aws_instance" "jenkins" {
  ami = "${var.ec2_linux_ami_id}"
  instance_type = "${var.jenkins_instance_type}"
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
    device_name = "/dev/xvdf"
    delete_on_termination = false
    volume_size = 512
    volume_type = "gp2"
  }
}
