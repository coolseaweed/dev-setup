# Kubeadm Install Guide

Script is compatibled with:
- [x] Ubuntu 20.04 LTS
- [ ] Ubuntu 21.04 LTS

## Step 1. install container runtime
```bash
./install_containerd.sh
``` 

## Step 2. install kubeadm + kubelet + kubectl
```bash
./install_kubeadm.sh
```

## Step 3. setup cluster (only master node)
```bash
CIDR_IP_ADDRESS=${CIDR_IP_ADDRESS} ./setup_cluster.sh
```

## Step 4. Install CNI (weave-net)
```bash
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

k edit ds weave-net -n kube-system
----------------------------------
      containers:
        - name: weave
          env:
            - name: IPALLOC_RANGE
              value: {CIDR-ADDR}
----------------------------------
```



## Remove kubeadm
```
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
    ufw disable
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

- **Problem: node Not Ready**
  ```bash
  k describe node <node1>로 보았을때
  ------------------------------------------
  Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  MemoryPressure   False   Wed, 13 Sep 2023 17:33:58 +0000   Wed, 13 Sep 2023 17:25:34 +0000   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Wed, 13 Sep 2023 17:33:58 +0000   Wed, 13 Sep 2023 17:25:34 +0000   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Wed, 13 Sep 2023 17:33:58 +0000   Wed, 13 Sep 2023 17:25:34 +0000   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            False   Wed, 13 Sep 2023 17:33:58 +0000   Wed, 13 Sep 2023 17:25:34 +0000   KubeletNotReady              container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized
  ```
  **Solution: CNI를 설치해주자**
  ```bash
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

  ```



## Cross check
쿠버네티스 컴포넌트끼리 통신하기위해 특정 포트가 반드시 열려 있어야한다.
```bash
telent 127.0.0.1 6443
----------------
Trying 127.0.0.1...
Connected to 127.0.0.1.
Escape character is '^]'.
----------------
```


## Reference
- [라즈베리파이로 쿠버네티스 클러스터 만들기](https://www.binaryflavor.com/raspberry-pi-kubernetes-1/)
- [ubuntu20.04 kubeadm 설치하기](https://velog.io/@simgyuhwan/kubeadm-ubuntu-20.04-%EC%84%A4%EC%B9%98)