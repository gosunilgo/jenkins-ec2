#!/bin/bash

# Configure data disk
parted -s /dev/xvdf mklabel gpt
parted -s -- /dev/xvdf mkpart primary ext4 2048s 100%
mkfs -t ext4 /dev/xvdf1
tune2fs -m 0 /dev/xvdf1

# Install Jenkins
curl http://pkg.jenkins-ci.org/redhat/jenkins.repo > /etc/yum.repos.d/jenkins.repo
rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key
yum -y install jenkins

# Mount data disk to JENKINS_HOME
echo "/dev/xvdf1    /var/lib/jenkins    ext4    defaults,nofail 0 2" >> /etc/fstab
mount -a
chown jenkins:jenkins /var/lib/jenkins

# Had trouble with escaping so this is a base64 copy of jenkins/config/config.xml
echo "PD94bWwgdmVyc2lvbj0nMS4wJyBlbmNvZGluZz0nVVRGLTgnPz4KPGh1ZHNvbj4KICAgIDxkaXNhYmxlZEFkbWluaXN0cmF0aXZlTW9uaXRvcnMvPgogICAgPHZlcnNpb24+MS4wPC92ZXJzaW9uPgogICAgPG51bUV4ZWN1dG9ycz4wPC9udW1FeGVjdXRvcnM+CiAgICA8bW9kZT5OT1JNQUw8L21vZGU+CiAgICA8dXNlU2VjdXJpdHk+ZmFsc2U8L3VzZVNlY3VyaXR5PgogICAgPGRpc2FibGVSZW1lbWJlck1lPmZhbHNlPC9kaXNhYmxlUmVtZW1iZXJNZT4KICAgIDxwcm9qZWN0TmFtaW5nU3RyYXRlZ3kgY2xhc3M9ImplbmtpbnMubW9kZWwuUHJvamVjdE5hbWluZ1N0cmF0ZWd5JERlZmF1bHRQcm9qZWN0TmFtaW5nU3RyYXRlZ3kiLz4KICAgIDx3b3Jrc3BhY2VEaXI+JHtKRU5LSU5TX0hPTUV9L3dvcmtzcGFjZS8ke0lURU1fRlVMTE5BTUV9PC93b3Jrc3BhY2VEaXI+CiAgICA8YnVpbGRzRGlyPiR7SVRFTV9ST09URElSfS9idWlsZHM8L2J1aWxkc0Rpcj4KICAgIDxqZGtzLz4KICAgIDx2aWV3c1RhYkJhciBjbGFzcz0iaHVkc29uLnZpZXdzLkRlZmF1bHRWaWV3c1RhYkJhciIvPgogICAgPG15Vmlld3NUYWJCYXIgY2xhc3M9Imh1ZHNvbi52aWV3cy5EZWZhdWx0TXlWaWV3c1RhYkJhciIvPgogICAgPGNsb3Vkcy8+CiAgICA8c2NtQ2hlY2tvdXRSZXRyeUNvdW50PjA8L3NjbUNoZWNrb3V0UmV0cnlDb3VudD4KICAgIDx2aWV3cz4KICAgICAgICA8aHVkc29uLm1vZGVsLkFsbFZpZXc+CiAgICAgICAgICAgIDxvd25lciBjbGFzcz0iaHVkc29uIiByZWZlcmVuY2U9Ii4uLy4uLy4uIi8+CiAgICAgICAgICAgIDxuYW1lPkFsbDwvbmFtZT4KICAgICAgICAgICAgPGZpbHRlckV4ZWN1dG9ycz5mYWxzZTwvZmlsdGVyRXhlY3V0b3JzPgogICAgICAgICAgICA8ZmlsdGVyUXVldWU+ZmFsc2U8L2ZpbHRlclF1ZXVlPgogICAgICAgICAgICA8cHJvcGVydGllcyBjbGFzcz0iaHVkc29uLm1vZGVsLlZpZXckUHJvcGVydHlMaXN0Ii8+CiAgICAgICAgPC9odWRzb24ubW9kZWwuQWxsVmlldz4KICAgIDwvdmlld3M+CiAgICA8cHJpbWFyeVZpZXc+QWxsPC9wcmltYXJ5Vmlldz4KICAgIDxzbGF2ZUFnZW50UG9ydD4tMTwvc2xhdmVBZ2VudFBvcnQ+CiAgICA8bGFiZWw+PC9sYWJlbD4KICAgIDxjcnVtYklzc3VlciBjbGFzcz0iaHVkc29uLnNlY3VyaXR5LmNzcmYuRGVmYXVsdENydW1iSXNzdWVyIj4KICAgICAgICA8ZXhjbHVkZUNsaWVudElQRnJvbUNydW1iPmZhbHNlPC9leGNsdWRlQ2xpZW50SVBGcm9tQ3J1bWI+CiAgICA8L2NydW1iSXNzdWVyPgogICAgPG5vZGVQcm9wZXJ0aWVzLz4KICAgIDxnbG9iYWxOb2RlUHJvcGVydGllcy8+CjwvaHVkc29uPg==" > /tmp/config.xml
base64 -d /tmp/config.xml > /var/lib/jenkins/config.xml

# Adjust settings
sed -i 's/JENKINS_JAVA_OPTIONS=.*/JENKINS_JAVA_OPTIONS="-Xmx1g -Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"/' /etc/sysconfig/jenkins

# Start the service
service jenkins start
chkconfig --add jenkins