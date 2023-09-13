#!/bin/bash

# run as root (sudo -i)

CIDR_IP_ADDRESS="10.244.0.0/16"
APISERVER_ADVERTISE_ADDRESS=$(hostname -I | awk '{print $1}')



# only master node
kubeadm init --pod-network-cidr=$CIDR_IP_ADDRESS --apiserver-advertise-address=$APISERVER_ADVERTISE_ADDRESS && \
mkdir -p $HOME/.kube && \
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && \
chown $(id -u):$(id -g) $HOME/.kube/config