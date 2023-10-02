#!/bin/bash
# run as root (sudo -i)


# POSITIONAL_ARGS=()
# CIDR_IP_ADDRESS="10.244.0.0/16"
# APISERVER_ADVERTISE_ADDRESS=$(hostname -I | awk '{print $1}')
# master=false

# . ../utils/parse_options.sh 



# ------------------------
# Pre requests
# ------------------------
swapoff -a  && sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Forward IPv4 and let iptables see bridged traffic
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
sudo sysctl --system -q

# verify `br_netfilter` & `overlay`modules are loaded by running 
for module in br_netfilter overlay; do
    check=$(lsmod | grep $module -o| uniq)
    if [ $check != $module ]; then
        echo "ERROR: $module is not loaded check: ${check}"
        exit 1
    fi
done

# verify `net.bridge.bridge-nf-call-iptables` & `net.bridge.bridge-nf-call-ip6tables` are set to 1
check=$(sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward | awk -F '=' '{sum+=$2;} END {print sum;}' )
if [ $check != 3 ]; then
    echo "sysctl params are not set" && exit 1
fi

# ------------------------
# install container runtime
# ------------------------
# uninstall all conflicting packages
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    apt-get remove $pkg; 
done

# install containerd
apt-get update && apt-get install -y ca-certificates curl gnupg && \
install -m 0755 -d /etc/apt/keyrings && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg  --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg && \
chmod a+r /etc/apt/keyrings/docker.gpg && \
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
apt-get update && apt-get -y install containerd.io

# configure containerd the `systemd` cgroup driver
mkdir -p /etc/containerd && cat <<EOF | tee /etc/containerd/config.toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
EOF
systemctl restart containerd


# ------------------------
# install kubeadm & kubelet & kubectl
# ------------------------

apt-get update && apt-get install -y apt-transport-https ca-certificates curl && \
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list && \
apt-get update && apt-get install -y kubelet kubeadm kubectl && \
apt-mark hold kubelet kubeadm kubectl


# # ------------------------
# # setup kubernetes cluster (only master node)
# # ------------------------
# if [[ $master == true ]]; then
#     EXTRA_ARGS="--pod-network-cidr=$CIDR_IP_ADDRESS --apiserver-advertise-address=$APISERVER_ADVERTISE_ADDRESS"

#     echo $EXTRA_ARGS
#     kubeadm init $EXTRA_ARGS && \

#     mkdir -p $HOME/.kube && \
#     cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && \
#     chown $(id -u):$(id -g) $HOME/.kube/config
# fi