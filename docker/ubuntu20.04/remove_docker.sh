# please run via sudor (sudo -i)


apt-get -y purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras && \
rm -rf /var/lib/docker && \
rm -rf /var/lib/containerd