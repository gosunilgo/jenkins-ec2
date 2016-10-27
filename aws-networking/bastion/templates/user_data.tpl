#!/bin/bash

poll_for_response() {
    echo "polling for response from $1"
    until $(curl --output /dev/null --silent --head --fail "$1"); do
        echo -n "." && sleep 2
    done
}

# Wait for NAT and Internet Gateway so we can get to all our network resources
poll_for_response http://repo.us-east-2.amazonaws.com/latest/main/mirror.list

yum -y install awslogs curl jq yum-cron
pip install awscli --upgrade

# Sync SSH host keys
keys_not_present() {
    return $(aws s3 ls s3://${s3_bucket}/${s3_bucket_prefix}/ssh/ssh_host_rsa_key --region ${region} | wc -l)
}
download_keys() {
    rm -f /etc/ssh/ssh_host*
    aws s3api wait object-exists --bucket ${s3_bucket} --key ${s3_bucket_prefix}/ssh/ssh_host_rsa_key --region ${region}
    aws s3 sync s3://${s3_bucket}/${s3_bucket_prefix}/ssh/ /etc/ssh/ --region ${region} --include 'ssh_host*'
    find /etc/ssh -name "*key" -exec chmod 600 {} \;
    service sshd restart
}

if keys_not_present ; then
    INSTANCE_ID=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id)
    LEAD_BASTION=$(aws autoscaling describe-auto-scaling-instances --region ${region} | jq --raw-output --sort-keys '.AutoScalingInstances[].InstanceId' | head -1)
    if [ "$INSTANCE_ID" = "$LEAD_BASTION" ] ; then
        aws s3 cp /etc/ssh/ s3://${s3_bucket}/${s3_bucket_prefix}/ssh/ --recursive --exclude '*' --include '*key*' --region ${region}
    else
        download_keys
    fi
else
    download_keys
fi

echo "* * * * * aws cloudwatch put-metric-data --region ${region} --metric-name ssh-sessions --namespace "bastion" --timestamp \$(date -Ih) --value \$(w -h | wc -l)" >> /var/spool/cron/root

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
region = ${region}" > /etc/awslogs/awscli.conf

service awslogs start
chkconfig awslogs on
service yum-cron start
chkconfig yum-cron on

yum -y update
