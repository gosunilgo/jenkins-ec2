#!/usr/bin/env bash

poll_for_response() {
    echo "polling for response from $1"
    until $(curl --output /dev/null --silent --head --fail "$1"); do
        echo -n "." && sleep 2
    done
}

# Wait for NAT and Internet Gateway so we can get to all our network resources
poll_for_response http://pkg.jenkins-ci.org/redhat/jenkins.repo
poll_for_response http://repo.us-east-2.amazonaws.com/latest/main/mirror.list

# Get updates and ensure we stay updated
yum -y update
yum -y install yum-cron
service yum-cron start
chkconfig yum-cron on

# Configure data disk
parted -s /dev/xvdj mklabel gpt
parted -s -- /dev/xvdj mkpart primary ext4 2048s 100%
mkfs -t ext4 /dev/xvdj1
tune2fs -m 0 /dev/xvdj1

# Install Jenkins
curl http://pkg.jenkins-ci.org/redhat/jenkins.repo > /etc/yum.repos.d/jenkins.repo
rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key
yum -y install jenkins xmlstarlet

# Mount data disk to JENKINS_HOME
echo "/dev/xvdj1    /var/lib/jenkins    ext4    defaults,nofail 0 2" >> /etc/fstab
mount -a
chown jenkins:jenkins /var/lib/jenkins

# Adjust settings
sed -i 's/JENKINS_JAVA_OPTIONS=.*/JENKINS_JAVA_OPTIONS="-Xmx1g -Djava.awt.headless=true"/' /etc/sysconfig/jenkins

# Start up Jenkins
service jenkins start
chkconfig jenkins on

# Wait for Jenkins to come back up
until $(curl --output /dev/null --silent --head --fail -u "admin:$(cat /var/lib/jenkins/secrets/initialAdminPassword)" http://localhost:8080/cli/); do
    sleep 1
done

# Pre-install these plugins
plugins=(ec2 git)
for plugin in "$${plugins[@]}"; do
    java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar -s "http://localhost:8080/" -noKeyAuth install-plugin "$plugin" --username admin --password "$(cat /var/lib/jenkins/secrets/initialAdminPassword)"
done

service jenkins stop
echo "Waiting for Jenkins to stop"
until ! $(pgrep -u jenkins java); do sleep 1 && echo -n "."; done

# Update the config file and restart
xmlstarlet ed -u "/hudson/numExecutors" -v 0 /var/lib/jenkins/config.xml
service jenkins start

# Wait for Jenkins to come back up
until $(curl --output /dev/null --silent --head --fail -u "admin:$(cat /var/lib/jenkins/secrets/initialAdminPassword)" http://localhost:8080/cli/); do
    sleep 1
done

# Reset admin password
echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("admin", "${admin_password}")' | java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar -s "http://localhost:8080/" -noKeyAuth groovy = --username admin --password "$(cat /var/lib/jenkins/secrets/initialAdminPassword)"
