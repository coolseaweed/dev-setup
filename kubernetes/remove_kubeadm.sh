#!/bin/bash

# -----------------------------------
# run as root (sudo -i)
# Script is compatibled with:
# [v] Ubuntu 20.04 LTS
# [ ] Ubuntu 21.04 LTS
# -----------------------------------

kubeadm reset -f && rm -rf $HOME/.kube/ && \
apt-get purge --allow-change-held-packages -y kubeadm kubectl kubelet kubernetes-cni  && \
apt-get -y autoremove  && \
rm -rf ~/.kube