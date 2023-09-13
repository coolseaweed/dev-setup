#!/bin/bash

# run as root (sudo -i)

CIDR_IP_ADDRESS="10.244.0.0/16"
APISERVER_ADVERTISE_ADDRESS=$(hostname -I | awk '{print $1}')
EXTRA_ARGS="--pod-network-cidr=$CIDR_IP_ADDRESS --apiserver-advertise-address=$APISERVER_ADVERTISE_ADDRESS"

# only master node
kubeadm init $EXTRA_ARGS && \
mkdir -p $HOME/.kube && \
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && \
chown $(id -u):$(id -g) $HOME/.kube/config