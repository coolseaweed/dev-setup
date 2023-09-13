#!/bin/bash

kubeadm reset -f && rm -rf $HOME/.kube/ && \
apt-get purge --allow-change-held-packages -y kubeadm kubectl kubelet kubernetes-cni  && \
apt-get -y autoremove  && \
rm -rf ~/.kube