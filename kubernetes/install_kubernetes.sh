#!/bin/bash


# run as root (sudo -i)

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

apt-get -y install containerd && \
cp ./config.toml /etc/containerd/config.toml && \
systemctl restart containerd 

# swap disable
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab && \
swapoff -a

# Install kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add && \
apt-add-repository -y "deb http://apt.kubernetes.io/ kubernetes-xenial main" && \
apt-get -y install kubeadm kubelet kubectl