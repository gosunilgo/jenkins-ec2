## jenkins-ec2

An example deployment of Jenkins using Terraform

__Note:__ This uses syntax introduced in the [0.7.6 version](https://github.com/hashicorp/terraform/blob/v0.7.6/CHANGELOG.md) of Terraform

### Features

* Deploys a highly available VPC with two public and private subnets each with their own NAT Gateway and Bastion
* Deploys a Jenkins instance with JENKINS_HOME mounted to a separate EBS volume in a private subnet
* Jenkins instance is launched with an IAM role allowing it to use the EC2 Plugin to provision worker nodes dynamically
* Builds are done on dynamically provisioned instances using Docker containers so dev have control of their build environment and the infrastructure team doesn't have to worry about configuring Jenkins worker nodes

### Deployment Steps

* Ensure you have Terraform v0.7.6+ installed locally
* Make a copy of variables.example, update the settings as desired and source the file
* Run `make apply` to provision the VPC and Jenkins instance
* SSH through the bastion and forward back port 8080 of the internal jenkins instance to connect via your local web browser
* Install and configure the Git and EC2 Jenkins plugins
* Create a job that builds using Docker

[Detailed Deployment Steps](https://github.com/spohnan/jenkins-ec2/deployment/)

### Diagram

![diagram](https://github.com/spohnan/jenkins-ec2/blob/master/deployment/jenkins-ec2.png)
