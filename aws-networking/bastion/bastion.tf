data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user_data.tpl")}"
}

resource "aws_iam_role_policy" "push_logs_policy" {
  name = "push_logs"
  role = "${aws_iam_role.bastion_role.id}"
  policy = "${file("${path.module}/policies/push-logs-policy.json")}"
}

resource "aws_iam_role_policy" "push_cloudwatch_metrics_policy" {
  name = "push_cloudwatch_metrics"
  role = "${aws_iam_role.bastion_role.id}"
  policy = "${file("${path.module}/policies/push-cloudwatch-metrics.json")}"
}

resource "aws_iam_role" "bastion_role" {
  name = "bastion"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "bastion_instance_role" {
  name = "bastion_role"
  path = "/"
  roles = ["bastion"]
  depends_on = ["aws_iam_role.bastion_role"]
}

resource "aws_launch_configuration" "bastion_launch_conf" {
  name_prefix = "bastion-launch-conf-"
  image_id = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.bastion_instance_role.id}"
  key_name = "${var.key_name}"
  security_groups = ["${var.security_group_id}"]
  associate_public_ip_address = true
  user_data = "${data.template_file.user_data.rendered}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion_asg" {
  name = "bastion"
  min_size = 1
  max_size = 2
  desired_capacity = 2
  force_delete = true
  launch_configuration = "${aws_launch_configuration.bastion_launch_conf.name}"
  load_balancers       = ["${aws_elb.bastion_elb.name}"]
  vpc_zone_identifier = [
    "${var.subnet_primary_id}",
    "${var.subnet_secondary_id}"
  ]
  tag {
    key = "Name"
    value = "bastion"
    propagate_at_launch = true
  }
}

//Sync Host Keys with something like the following
// ----------------------------------------------------------------------------------------------
//SRC=52.15.93.155
//DEST=52.15.123.142
//SSH="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
//mkdir ssh
//rsync -e "$SSH" --rsync-path="sudo rsync" $SRC:/etc/ssh/*key* ssh/
//rsync -e "$SSH" --rsync-path="sudo rsync" ssh/* $DEST:/etc/ssh
//$SSH $DEST "sudo find /etc/ssh -name "*key" -exec chown 400 {} \; ; sudo service sshd restart"
//rm -fr ssh/

// Also add something like the following your .ssh/config to prevent ssh timeouts
// Host *
//   ServerAliveInterval 60


resource "aws_elb" "bastion_elb" {
  cross_zone_load_balancing = true
  security_groups = ["${var.security_group_id}"]
  idle_timeout = 75
  subnets = [
    "${var.subnet_primary_id}",
    "${var.subnet_secondary_id}"
  ]
  listener {
    instance_port     = 22
    instance_protocol = "tcp"
    lb_port           = 22
    lb_protocol       = "tcp"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:22"
    interval            = 15
  }
  lifecycle {
    create_before_destroy = true
  }
}