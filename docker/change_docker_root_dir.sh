# please run via sudor (sudo -i)

target_dir="/mnt/hdd0/opt/docker_images"
docker_daemon_path="/etc/docker/daemon.json"
data_root="data-root" # "graph" (Docker VERSION <= 17.05) 

mkdir -p $target_dir && \
systemctl stop docker.service && systemctl stop docker.socket && \
rsync -aP /var/lib/docker ${target_dir} && \
[ ! -f $docker_daemon_path ] && echo "{ \"${data_root}\": \"${target_dir}\" }" > $docker_daemon_path && \
systemctl start docker

# check
docker info | grep "Docker Root Dir"