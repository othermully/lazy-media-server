# DEBIAN ONLY
# Stop all containers
sudo docker stop $(docker ps -aq)

# Remove all containers
sudo docker rm $(docker ps -aq)

# Stop Docker and Containerd
sudo systemctl stop docker
sudo systemctl stop docker.socket
sudo systemctl stop containerd

# Remove Docker Engine, CLI, containerd, and plugins
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

# Remove unused dependencies
sudo apt-get autoremove -y --purge

# Remove all Docker data (images, containers, volumes, build cache)
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# Remove Docker configuration
sudo rm -rf /etc/docker
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/keyrings/docker.asc

# Remove Docker socket
sudo rm -f /var/run/docker.sock

# Remove the docker group
sudo groupdel docker

# Remove Docker-related systemd files
sudo rm -rf /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload

# Remove Docker CLI configuration for your user
rm -rf ~/.docker

# Remove appdata config directory
sudo rm -rf /docker

rm ./docker-compose.yaml

# Remove created data directory
sudo rm -rf /data

sudo rm -rf /etc/apt/sources.list.d/docker.list

