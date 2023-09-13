# Kubeadm Install Guide

Script is compatibled with:

[x] Ubuntu 20.04 LTS

## Step 1. install container runtime
```bash
./install_containerd.sh
``` 



## trouble shootings

**Problem: kubelet 이 설치해도 동작하지 않는 경우**
```bash
E0913 14:22:37.537210  178504 run.go:74] "command failed" err="failed to run Kubelet: running with swap on is not supported, please disable swap! or set --fail-swap-on flag to false. /proc/swaps contained: [Filename\t\t\t\tType\t\tSize\tUsed\tPriority /swap.img file\t\t4194300\t0\t-2]"
```
**Solution: swap을 꺼야한다.**
```bash
# to enable kubelet turn off swap
swapoff -a && sed -i '/swap/s/&/#/' /etc/fstab
ufw disable
``` 


```bash
# 쿠버네티스 컴포넌트끼리 통신하기위해 특정 포트가 반드시 열려 있어야한다.
telent 127.0.0.1 6443
----------------
Trying 127.0.0.1...
Connected to 127.0.0.1.
Escape character is '^]'.
----------------
```