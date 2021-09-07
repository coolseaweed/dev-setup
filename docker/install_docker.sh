#!/bin/bash

# Please run this script using sudo ( sudo -i )

DOCKER_VERSION=$(cat VERSION)


apt-get update && \
apt-get install -y - apt-transport-https ca-certificates curl gnupg-agent software-properties-common 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - 
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
VERSION_STRING=$(apt-cache madison docker-ce | grep $DOCKER_VERSION | cut -d "|" -f2 | sed 's: ::') 
if [ -z $VERSION_STRING ];then
    echo "[ERROR] cannot search VERSION of docker. exit 1"
    exit 1
else
    echo "Install docker VERSION: $VERSION_STRING"
fi
apt-get install -y docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io 

echo "[INFO] Docker is installed! Try run 'docker run hello-world'"

exit 0





