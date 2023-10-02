# Kubeadm Install Guide

Script is compatibled with:
- [x] Ubuntu 20.04 LTS
- [ ] Ubuntu 22.04 LTS

## Install kubernetes (kubeadm)
```bash
./install_kubernetes.sh
``` 

## Setup kubeadm (master only)
```bash
kubeadm init --pod-network-cidr="10.244.0.0/16" --apiserver-advertise-address=$(hostname -I | awk '{print $1}')

mkdir -p $HOME/.kube && \
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && \
chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

## Remove kubeadm
```bash
./remove_kubeadm.sh
```

## Trouble Shootings

- **Problem: kubelet 이 설치해도 동작하지 않는 경우**
    ```bash
    E0913 14:22:37.537210  178504 run.go:74] "command failed" err="failed to run Kubelet: running with swap on is not supported, please disable swap! or set --fail-swap-on flag to false. /proc/swaps contained: [Filename\t\t\t\tType\t\tSize\tUsed\tPriority /swap.img file\t\t4194300\t0\t-2]"
    ```
    **Solution: swap을 꺼야한다.**
    ```bash
    # to enable kubelet turn off swap
    swapoff -a && sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    ``` 

- **Problem: worknode 에서 kubectl 이 동작하지 않을 경우**
  ```bash
  E0913 17:28:24.904776    5148 memcache.go:265] couldn't get current server API group list: Get "http://localhost:8080/api?timeout=32s": dial tcp [::1]:8080: connect: connection refused
  ```
  **Solution: master node의 `/etc/kubernetes/admin.conf` 파일을 node에 복사해온다**
  ```bash
  # /etc/kubernetes/admin.conf에 복사후 아래 커맨드 적용
  mkdir -p $HOME/.kube && \
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && \
  chown $(id -u):$(id -g) $HOME/.kube/config
  ```

  **Problem: Raspiberry4 flannel.1 ip interface가 없을때**
  **Solution**
  ```bash
  sudo apt-get install -y linux-modules-extra-raspi
  ```


## Cross check (will be moved to Wiki section)
쿠버네티스 컴포넌트끼리 통신하기위해 특정 포트가 반드시 열려 있어야한다.
```bash
telnet 127.0.0.1 6443
----------------
Trying 127.0.0.1...
Connected to 127.0.0.1.
Escape character is '^]'.
----------------
```


## Reference
- [라즈베리파이로 쿠버네티스 클러스터 만들기](https://www.binaryflavor.com/raspberry-pi-kubernetes-1/)
- [ubuntu20.04 kubeadm 설치하기](https://velog.io/@simgyuhwan/kubeadm-ubuntu-20.04-%EC%84%A4%EC%B9%98)
### commands
**view services**
  ```
  cat /etc/systemd/system/kube-apiserver.service
  ```
- service logs
  ```bash
  # system log
  journalctl -u <service name> -l

  # kubeadm log
  k logs <target>

  # container

  ```
**Security**
- Certificate Autority (CA) Generation
  ```bash
  # Generate Keys
  openssl genrsa -out ca.key 2048

  # Certificate Signing Request
  openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA" -out ca.csr

  # Sign Certificates (self sign)
  openssl x509 -req -in ca.csr -signkey ca.key -out ca.crt 
  ```

- admin user
  ```bash
  
  # Generate keys
  openssl genrsa -out admin.key 2048

  # Generate CSR
  openssl req -new -key admin.key -subj \
    "/CN=kube-admin/O=system:masters" -out admin.csr
  
  # Get Sign from CA
  openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -out admin.crt 

  ```
- inspect cert file
  ```bash
  openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
  ```
