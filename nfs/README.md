## NFS setup guide


### Install dependency
```bash
sudo apt install -y nfs-kernel-server
```

### Edit `/etc/fstab` file

```bash
# add following line
# nfs
<nfs server ip>:<source path> <target path> nfs defaults 0 0

```