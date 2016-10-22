#!/bin/bash

yum -y update
yum -y install awslogs curl jq yum-cron
REGION=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
echo "* * * * * aws cloudwatch put-metric-data --region $REGION --metric-name ssh-sessions --namespace "bastion" --timestamp \$(date -Ih) --value \$(w -h | wc -l)" >> /var/spool/cron/root

echo "[general]
state_file = /var/lib/awslogs/agent-state
[/var/log/messages]
datetime_format = %b %d %H:%M:%S
file = /var/log/messages
log_stream_name = {instance_id}/var/log/messages
log_group_name = bastion
[/var/log/secure]
datetime_format = %b %d %H:%M:%S
file = /var/log/secure
log_stream_name = {instance_id}/var/log/secure
log_group_name = bastion" > /etc/awslogs/awslogs.conf

echo "[plugins]
cwlogs = cwlogs
[default]
region = $REGION" > /etc/awslogs/awscli.conf

service awslogs start
chkconfig awslogs on
service yum-cron start
chkconfig yum-cron on
