#!/bin/bash

# TODO: Add a active interface check, grab the IP of that interface, populate host IP
# TODO: Input validation
# TODO: Error handling
# TODO: Move docker compose creation into its own function
# TODO: Fix the manual path creation logic so it sets abs_downloads properly
# TODO: Adjust overly permissive chmod in permission_setup() function
# TODO: UID and GUID should be constatns at top of file
# TODO: Main logic should only take place at bottom of file, all functions at top

set -euo pipefail # Prevent silent failures i think?

# Manual folder creation doesn't set abs_downloads
# Manual input with spaces will sometimes fail
# Very aggressive permission stance
# hardcoded UID:GUID lol
# Package checking will break if package name is different

abs_download_complete_path=""
abs_download_incomplete_path=""
abs_movie_path=""
abs_tv_path=""
abs_media_path=""
root_media_path=""
abs_downloads=""

function read_line() {
	read -p "> " "$1"
}

function permission_setup(){
	echo "-- Setting up permission on $@"
	sudo chown -R 1000:1000 "$@"
	sudo chmod -R a=,a+rX,u+w,g+w "$@"
	echo "-- Permission set."
}

function create_folders(){
	echo "-- Creating folder structure..."
	mkdir -p /data/media/downloads
	mkdir -p /data/media/downloads/complete
	mkdir -p /data/media/downloads/incomplete
	mkdir -p /data/media/movies
	mkdir -p /data/media/tv
	echo "-- All folders created under: /data/media"

	root_media_path="/data"
	abs_downloads="/data/media/downloads"
	abs_download_complete_path="/data/media/downloads/complete"
	abs_download_incomplete_path="/data/media/downloads/incomplete"
	abs_movie_path="/data/media/movies"
	abs_tv_path="/data/media/tv"

	return 0
}

function check_if_folder_exists(){
	# Check if the folder exists, if not, create it.
	if [[ -d "$1" ]]; then
		echo "-- "$1" exists. Nothing left to do."
	else
		echo "-- $1 does not exists. Creating it..."
		mkdir -p "$1"
		echo "-- $1 created."
	fi
}

function setup_docker_apt_repo(){
	# Add Docker's official GPG key:
	sudo apt update
	sudo apt install ca-certificates curl
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc

	# Add the repository to Apt sources:
	sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
	Types: deb
	URIs: https://download.docker.com/linux/ubuntu
	Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
	Components: stable
	Signed-By: /etc/apt/keyrings/docker.asc
EOF

	echo "-- Docker GPG key and APT sources added."
	sudo apt update

}

function install_docker(){
	echo "-- Starting docker installation."

	REQUIRED_PKG="docker-ce"
	PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
	echo Checking for $REQUIRED_PKG: $PKG_OK
	if [ "" = "$PKG_OK" ]; then
	  echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
	  
	  sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	fi

	echo "Docker + docker components have been installed."
}

clear
cat motd
echo "Do you want this script to automatically create the folder structure for you? (Y/N)"
read_line create_folder_bool

if [[ "$create_folder_bool" != "N" ]]; then
	create_folders
else

	echo "Root media path (e.g /data)"
	read_line root_media_path
	check_if_folder_exists $root_media_path

	echo "Absolute path of the completed download folder (e.g /data/media/downloads/complete)"
	read_line abs_download_complete_path
	check_if_folder_exists $abs_download_complete_path

	echo "Absolute path of the incomplete download folder (e.g. /data/media/downloads/incomplete)"
	read_line abs_download_incomplete_path
	check_if_folder_exists $abs_download_incomplete_path

	echo "Will you be downloading both movies and tv? (Y/N)"
	read_line movies_and_tv_bool

	if [[ "$movies_and_tv_bool" == "Y" ]]; then
		echo "Enter the absolute path of the movies directory: (e.g. /data/media/movies)"
		read_line abs_movie_path
		check_if_folder_exists $abs_movie_path

		echo "Enter the absolute path of the tv directory: (e.g. /data/media/tv)"
		read_line abs_tv_path
		check_if_folder_exists $abs_tv_path

	else
		echo "Enter your main media directory path: (e.g. /data/media/)"
		read_line abs_media_path
		check_if_folder_exists $abs_media_path
	fi
fi

permission_setup "$root_media_path"

echo ""
echo "---------- Your current directory structure ----------"
echo "Complete downloads	   -> $abs_download_complete_path"
echo "Incomplete downloads	   -> $abs_download_incomplete_path"

if [[ -z $abs_media_path ]]; then
	echo "Movies directory	   -> $abs_movie_path"
	echo "TV directory		   -> $abs_tv_path"
else
	echo "Main media directory -> $abs_media_path"
fi
echo "------------------------------------------------------"

# Check if user wants to create the ufw rules
function create_ufw_rules(){
	echo "Do you want to create the UFW rules for all services? (Y/N)"
	read_line create_ufw_bool 
	if [[ "$create_ufw_bool" == "Y" ]]; then
		sudo ufw allow 7878/tcp comment "Radarr"
		sudo ufw allow 8989/tcp comment "Sonarr"
		sudo ufw allow 32400/tcp comment "Plex web"
		sudo ufw allow 9091/tcp comment "Transmission"
		sudo ufw allow 51413 comment "Transmission" 
		sudo ufw allow 9117/tcp comment "Jackett"

		echo "-- All firewall rules created."
		sudo ufw status
	else
		echo "-- No firewall rules created, please complete that once the containers are live."
	fi

}

create_ufw_rules()

# Start docker install here
echo "-- Creating docker config directories."
mkdir -p /docker/appdata/config/radarr
mkdir -p /docker/appdata/config/sonarr
mkdir -p /docker/appdata/config/plex
mkdir -p /docker/appdata/config/jackett
mkdir -p /docker/appdata/config/transmission

permission_setup /docker
echo "-- /docker/appdata/config/{all service directories} created."
echo "-- permissions setup on /docker."
echo ""

function create_docker_compose() {
	echo "Creating docker-compose.yaml..."
	cat > docker-compose.yaml << EOF
	version: "3.2"
	services:
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
	      - $root_media_path:/data
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
	      - $root_media_path:/data
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
	      - $abs_tv_path:/tv
	      - $abs_movie_path:/movies
	    restart: unless-stopped
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
	      - $abs_download_complete_path:/downloads/complete #optional
	      - $abs_download_incomplete_path:/downloads/incomplete#optional
	    ports:
	      - 9091:9091
	      - 51413:51413
	      - 51413:51413/udp
	    restart: unless-stopped
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
	      - $abs_downloads:/downloads
	    ports:
	      - 9117:9117
	    restart: unless-stopped
EOF
}

function start_containers(){
	echo "-- Building containers..."
	sudo docker compose -f docker-compose.yaml up -d
	sudo docker ps -a 
}

echo ""
echo "docker-compose.yaml created!"
echo "Starting docker installation."

setup_docker_apt_repo
install_docker
create_docker_compose



echo ""
start_containers
echo ""
echo "Process completed."
echo ""
echo "------------------------- WEB INTERFACES -------------------------------"
echo "Plex:		http://{host-ip}:32400"
echo "Sonarr:		http://{host-ip}:8989"
echo "Radarr:		http://{host-ip}:7878"
echo "Jackett:		http://{host-ip}:9117"
echo "Transmission:	http://{host-ip}:9091"
echo "-------------------------------------------------------------------------"




