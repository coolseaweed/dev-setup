#!/bin/bash

# run as root

cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sysctl --system


# # Add Docker's official GPG key:
# apt-get update && \
# apt-get install ca-certificates curl gnupg && \
# install -m 0755 -d /etc/apt/keyrings && \
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
# chmod a+r /etc/apt/keyrings/docker.gpg

# # Add the repository to Apt sources:
# echo \
#   "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
#   "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
#   tee /etc/apt/sources.list.d/docker.list > /dev/null && \
# apt-get update