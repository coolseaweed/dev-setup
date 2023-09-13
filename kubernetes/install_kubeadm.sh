#!/bin/bash

# -----------------------------------
# run as root (sudo -i)
# Script is compatibled with:
# [v] Ubuntu 20.04 LTS
# [ ] Ubuntu 21.04 LTS
# -----------------------------------

# apt-transport-https may be a dummy package; if so, you can skip that package
apt-get update && \
apt-get install -y apt-transport-https ca-certificates curl && \
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list && \
apt-get update && apt-get install -y kubelet kubeadm kubectl && \
apt-mark hold kubelet kubeadm kubectl