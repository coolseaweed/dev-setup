## Docker setup


### default docker data directory change
```bash
docker info | grep -i "docker root dir"
---
 Docker Root Dir: /var/lib/docker
---

# stop docker service
sudo systemctl stop docker.service
sudo systemctl stop docker.socket

# cp legacy data to new directory
sudo rsync -rapv /var/lib/docker <new docker dir>

# change config
sudo vi /etc/docker/daemon.json
---
{
    "data-root": <new docker dir>
}
---

# service restart
sudo systemctl start docker
```