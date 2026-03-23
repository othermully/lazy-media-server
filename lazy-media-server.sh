#!/bin/bash

set -euo pipefail
clear
cat motd

# Globals
kernel_version=$(uname -r)
distro=$(lsb_release -i | cut -f2)
network_interface=""
ip_addr=""
ip_addr_trimmed=""
hostname=${HOSTNAME}

pkgman=""
package_install_command=""

ufw_installed=""
docker_installed=""

# Clear existing docker compose file
> docker-compose.yaml

declare -A selected_services=()

# Directory structure (Can remove most of these, most of them are just to keep track of the paths):
# Torrents
abs_dir_root="/data"
abs_dir_torrents="/data/torrents"
abs_dir_torrents_incomplete="/data/torrents/incomplete"
abs_dir_torrent_books="/data/torrents/books"
abs_dir_torrent_movies="/data/torrents/movies"
abs_dir_torrent_tv="/data/torrents/tv"

# Media
abs_dir_media="/data/media"
abs_dir_media_books="/data/media/books"
abs_dir_media_movies="/data/media/movies"
abs_dir_media_tv="/data/media/tv"
abs_dir_media_music="/data/media/music"

# Usenet
abs_dir_usenet="/data/usenet"
abs_dir_usenet_incomplete="/data/usenet/incomplete"
abs_dir_usenet_complete="/data/usenet/complete"
abs_dir_usenet_books="/data/usenet/complete/books"
abs_dir_usenet_movies="/data/usenet/complete/movies"
abs_dir_usenet_music="/data/usenet/complete/music"
abs_dir_usenet_tv="/data/usenet/complete/tv"


# Functions:
function read_line(){
	read -p "> " "$1"
}

function get_system_info(){
	echo ""
	echo "<-------------------- SYSTEM INFORMATION -------------------->"
	echo "-- Distro:		$distro"
	echo "-- Hostname:		$hostname"
	echo "-- Package Manager:	$pkgman"
	echo "-- UFW Installed:	$ufw_installed"
	echo "-- Docker Installed:	$docker_installed"
	echo "-- Kernel version:	$kernel_version"
	echo "-- Network interface:	$network_interface"
	echo "-- Local IPv4:		$ip_addr"
	echo ""
}

function select_network_interface(){
	echo ""
	echo "<-------------------- GET NET STUFF -------------------->"
	ip a | grep "UP"
	echo "Type the name of your active network interface (e.g. eth1)"
	echo ""
	read_line input 

	network_interface=${input}
	ip_addr=$(ip addr show "$network_interface" | awk '/inet / {print $2}')
	ip_addr_trimmed=${ip_addr%%/*}
}

function get_package_manager(){
	if command -v apt > /dev/null 2>&1; then
		pkgman="apt"
		package_install_command="apt install"
	elif command -v dnf > /dev/null 2>&1; then
		pkgman="dnf"
		package_install_command="dnf install"
	elif command -v yum > /dev/null 2>&1; then
		pkgman="yum"
		package_install_command="yum -S"
	elif command -v pacman > /dev/null 2>&1; then
		pkgman="pacman"
		package_install_command="pacman -S"
	fi
}
function check_if_ufw_installed(){
	if command -v ufw > /dev/null 2>&1; then
		ufw_installed="true"
	else
		ufw_installed="false"
	fi
}

function check_if_docker_installed(){
	if command -v docker > /dev/null 2>&1; then
		docker_installed="true"
	else
		docker_installed="false"
	fi

}

function add_lidarr(){
	sudo mkdir -p /docker/appdata/config/lidarr
	cat >> docker-compose.yaml << EOF
  lidarr:
    image: lscr.io/linuxserver/lidarr:latest
    container_name: lidarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Halifax
    volumes:
      - /docker/appdata/config/lidarr:/config
      - $abs_dir_root:/data #optional
    ports:
      - 8686:8686
    restart: unless-stopped
EOF

}

function add_bazarr(){
	sudo mkdir -p /docker/appdata/config/bazarr
	cat >> docker-compose.yaml << EOF
  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Halifax
    volumes:
      - /docker/appdata/config/bazarr:/config
      - $abs_dir_root:/data #optional
    ports:
      - 6767:6767
    restart: unless-stopped
EOF
}

function add_sabnzbd(){
	sudo mkdir -p /docker/appdata/config/sabnzbd
	cat >> docker-compose.yaml << EOF
  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd:latest
    container_name: sabnzbd
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Halifax
    volumes:
      - /docker/appdata/config/sabnzbd:/config
      - $abs_dir_usenet:/data/usenet #optional
    ports:
      - 8080:8080
    restart: unless-stopped
EOF

}

function add_radarr(){
	sudo mkdir -p /docker/appdata/config/radarr
	cat >> docker-compose.yaml << EOF
  radarr:
    container_name: radarr
    hostname: radarr.internal
    image: ghcr.io/hotio/radarr:latest
    restart: unless-stopped
    logging:
      driver: json-file
    ports:
      - 7878:7878
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Halifax
    volumes:
      - /docker/appdata/config/radarr:/config
      - $abs_dir_root:/data
EOF
}

function add_sonarr(){
	sudo mkdir -p /docker/appdata/config/sonarr
	cat >> docker-compose.yaml << EOF
  sonarr:
    container_name: sonarr
    hostname: sonarr.internal
    image: ghcr.io/hotio/sonarr:latest
    restart: unless-stopped
    logging:
      driver: json-file
    ports:
      - 8989:8989
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Halifax
    volumes:
      - /docker/appdata/config/sonarr:/config
      - $abs_dir_root:/data
EOF

}

function add_jackett(){
	sudo mkdir -p /docker/appdata/config/jackett
	cat >> docker-compose.yaml << EOF
  jackett:
    image: lscr.io/linuxserver/jackett:latest
    container_name: jackett
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Halifax
      - AUTO_UPDATE=true #optional
      - RUN_OPTS= #optional
    volumes:
      - /docker/appdata/config/jackett:/config
      - $abs_dir_torrents:/data/torrents
    ports:
      - 9117:9117
    restart: unless-stopped
EOF
}

function add_transmission(){
	sudo mkdir -p /docker/appdata/config/transmission/
	cat >> docker-compose.yaml << EOF
  transmission:
    image: lscr.io/linuxserver/transmission:latest
    container_name: transmission
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Halifax
      - TRANSMISSION_WEB_HOME= #optional
      - USER= #optional
      - PASS= #optional
      - WHITELIST= #optional
      - PEERPORT= #optional
      - HOST_WHITELIST= #optional
    volumes:
      - /docker/appdata/config/transmission:/config
      - $abs_dir_torrents:/data/torrents #optional
    ports:
      - 9091:9091
      - 51413:51413
      - 51413:51413/udp
    restart: unless-stopped
EOF

}

function add_qbittorrent(){
	sudo mkdir -p /docker/appdata/config/qbittorrent
	cat >> docker-compose.yaml << EOF
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Halifax
      - WEBUI_PORT=8081
      - TORRENTING_PORT=6881
    volumes:
      - /docker/appdata/config/qbittorrent:/config
      - $abs_dir_torrents:/data/torrents #optional
    ports:
      - 8081:8081
      - 6881:6881
      - 6881:6881/udp
    restart: unless-stopped
EOF
}

function add_plex(){
	sudo mkdir -p /docker/appdata/config/plex
	cat >> docker-compose.yaml << EOF
  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: plex
    network_mode: host
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Halifax
      - VERSION=docker
      - PLEX_CLAIM= #optional
    volumes:
      - /docker/appdata/config/plex:/config
      - $abs_dir_media_tv:/tv
      - $abs_dir_media_movies:/movies
    restart: unless-stopped
EOF
}

function add_seer(){
	sudo mkdir -p /docker/appdata/config/seer
	cat >> docker-compose.yaml << EOF
  seerr:
    image: ghcr.io/seerr-team/seerr:latest
    init: true
    container_name: seerr
    environment:
      - LOG_LEVEL=debug
      - TZ=America/Halifax
    ports:
      - 5055:5055
    volumes:
      - /docker/appdata/config/seer:/app/config
    healthcheck:
      test: wget --no-verbose --tries=1 --spider http://localhost:5055/api/v1/status || exit 1
      start_period: 20s
      timeout: 3s
      interval: 15s
      retries: 3
    restart: unless-stopped
EOF
}

function add_flaresolver(){
    sudo mkdir -p /docker/appdata/config/flaresolver
    cat >> docker-compose.yaml << EOF
  flaresolverr:
    image: ghcr.io/flaresolverr/flaresolverr:latest
    container_name: flaresolverr
    environment:
      - LOG_LEVEL=${LOG_LEVEL:-info}
      - LOG_HTML=${LOG_HTML:-false}
      - CAPTCHA_SOLVER=${CAPTCHA_SOLVER:-none}
      - TZ=America/Halifax
    ports:
      - "${PORT:-8191}:8191"
    restart: unless-stopped 
EOF
}

function select_docker_containers(){
	echo ""
	echo "<-------------------- SERVICE SELECTION -------------------->"
	echo "Please select which services you want installed, separated by spaces (e.g. 1 3 4)"
	echo "1. Sonarr	2. Radarr	3. Plex"
	echo "4. Jellyfin	5. Jackett	6. Transmission"
	echo "7. qBittorrent	8. SABnzbd	9. Bazarr"
	echo "10. Lidarr	11: Prowlarr	12. Seer"
	read_line input

	for service_number in $input; do
		if [[ $service_number == '1' ]]; then
			add_sonarr
			sudo ufw allow 8989/tcp comment "Sonarr"
			selected_services[SONARR]=http://$ip_addr_trimmed:8989
		fi
		if [[ $service_number == '2' ]]; then
			add_radarr
			sudo ufw allow 7878/tcp comment "Radarr"
			selected_services[RADARR]=http://$ip_addr_trimmed:7878
		fi
		if [[ $service_number == '3' ]]; then
			add_plex
			sudo ufw allow 32400/tcp comment "Plex web"
			selected_services[PLEX]=http://$ip_addr_trimmed:32400/web
		fi
		if [[ $service_number == '4' ]]; then
			echo "Jellyfin, not added yet."
		fi
		if [[ $service_number == '5' ]]; then
			add_jackett
			add_flaresolver
			sudo ufw allow 8191/tcp comment "FlareSolver"
			sudo ufw allow 9117/tcp comment  "Jackett"
			selected_services[JACKETT]=http://$ip_addr_trimmed:9117
			selected_services[FLARESOLVER]=http://$ip_addr_trimmed:8191
		fi
		if [[ $service_number == '6' ]]; then
			add_transmission
			sudo ufw allow 9091/tcp comment "Transmission"
			sudo ufw allow 51413 comment "Transmission"
			selected_services[TRANSMISSION]=http://$ip_addr_trimmed:9091
		fi
		if [[ $service_number == '7' ]]; then
			add_qbittorrent
			sudo ufw allow 8081 comment "qBittorrent"
			sudo ufw allow 6881 comment "qBittorrent"
			selected_services[qBITTORRENT]=http://$ip_addr_trimmed:8081
		fi
		if [[ $service_number == '8' ]]; then
			add_sabnzbd
			sudo ufw allow 8080 comment "SABnzbd"
			selected_services[SABNZBD]=http://$ip_addr_trimmed:8080
		fi
		if [[ $service_number == '9' ]]; then
			add_bazarr
			sudo ufw allow 6767 comment "Bazarr"
			selected_services[BAZARR]=http://$ip_addr_trimmed:6767
		fi
		if [[ $service_number == '10' ]]; then
			add_lidarr
			sudo ufw allow 8686 comment "Lidarr"
			selected_services[LIDARR]=http://$ip_addr_trimmed:8686
		fi
		if [[ $service_number == '11' ]]; then
			echo "Prowlarr, not added yet"
		fi
		if [[ $service_number == '12' ]]; then
			add_seer
			sudo ufw allow 5055 comment "Seer"
			selected_services[SEER]=http://$ip_addr_trimmed:5055
		fi
	done

}

function create_automatic_paths(){
	echo ""
	echo "Simple or complex(preferred) structure? (S/C)"
	read_line input
	if [[ $input == 'S' ]]; then
		sudo mkdir -p /data/torrents/incomplete
		sudo mkdir -p /data/torrents/complete
		sudo mkdir -p /data/media/movies
		sudo mkdir -p /data/media/tv
		abs_dir_usenet="/dev/null"

	elif [[ $input == 'C' ]]; then
		sudo mkdir -p /data/{usenet/{incomplete,complete}/{tv,movies,music},media/{tv,movies,music}}
		sudo mkdir -p /data/{torrents/{tv,movies,music},media/{tv,movies,music}}
	else
		echo "-- Invalid option."
	fi

	echo ""
	echo "<-------------------- CURRENT DIRECTORY STRUCTURE -------------------->"
	echo "-- Root dir: $abs_dir_root"
	echo "-- Torrent folder: $abs_dir_torrents"
	ls -la $abs_dir_torrents
	echo ""
	echo "-- Media folder: $abs_dir_media"
	ls -la $abs_dir_media
	echo ""
	echo "-- Usenet folder: $abs_dir_usenet"
	ls -la $abs_dir_usenet
	echo ""
	echo "<--------------------------------------------------------------------->" 
}

function setup_permissions(){
	sudo chown -R 1000:1000 $abs_dir_root
	sudo chmod -R a=,a+rX,u+w,g+w $abs_dir_root
	echo "-- Completed permission setup."
}

function install_docker(){

	if [[ $distro == *"Debian"* ]] || [[ $distro == *"Ubuntu"* ]]; then
		echo "-- Installing Docker for Debian/Ubuntu..."

		sudo apt update
		sudo apt install -y ca-certificates curl gnupg

		sudo install -m 0755 -d /etc/apt/keyrings

		curl -fsSL https://download.docker.com/linux/$([[ $distro == *"Ubuntu"* ]] && echo ubuntu || echo debian)/gpg \
			| sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

		sudo chmod a+r /etc/apt/keyrings/docker.gpg

		echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
		https://download.docker.com/linux/$([[ $distro == *"Ubuntu"* ]] && echo ubuntu || echo debian) \
		$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
		| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

		sudo apt update

		sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	fi

	if [[ $distro == "Arch" ]]; then
		$package_install_command docker
	fi

	docker_installed="true"
}

function build_containers(){
	sudo docker compose -f docker-compose.yaml up -d
	sudo docker ps -a
	echo "-- Containers built."
}


function main(){
	# Getting system information
	get_package_manager
	select_network_interface
	check_if_ufw_installed
	check_if_docker_installed
	get_system_info

	# Handle package installs
	if [[ $ufw_installed == 'false' ]]; then
		echo "UFW is not installed, would you like to install it? (Y/N)"
		read_line input
		if [[ $input == 'Y' ]]; then
			$package_install_command 'ufw'
			sudo ufw enable
			echo "-- UFW Installed."
		fi
	else
		echo "-- UFW Installed, skipping installation."
	fi

	if [[ $docker_installed == 'false' ]]; then
		echo "Docker is not installed, would you like to install it? (Y/N)"
		read_line input
		if [[ $input == 'Y' ]]; then
			install_docker
		fi
	else
		echo "-- Docker installed, skipping installation."
	fi

	# Creating directory structure
	echo ""
	echo "Do you want this script to automatically create the folder structure? (Y/N)"
	read_line input
	if [[ $input == 'Y' ]]; then
		create_automatic_paths
	else
		echo "I didn't finish this part, create automatic paths instead"
	fi

	echo ""
	echo "-- Setting up folder permissions..."
	setup_permissions

	# Setting up docker-compose file and building containers
	cat >> docker-compose.yaml <<EOF
---
services:
EOF
	select_docker_containers
	echo ""
	if [[ $docker_installed == 'false' ]]; then
		echo ""
		echo "-- Docker not installed. Skipping container build."
		echo ""
	else
		build_containers
		echo "-- Docker images have been pulled, and built."
	fi

	# List web interfaces
	echo "<-------------------- WEB INTERFACES -------------------->"
	for value in "${!selected_services[@]}";
	do 
		echo "${value}:${selected_services[$value]}"
	done
	echo "<-------------------------------------------------------->"
}

main


