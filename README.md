# lazy-media-server

A simple Bash script for automating the setup of a self-hosted media stack, including Plex/Jellyfin and related *arr services.

This project is a work in progress and is not intended for production use.

## Overview

`lazy-media-server` streamlines the installation and volume configuration of a typical media server stack using Docker-based services. It is designed for quick setup in controlled environments. App configuration required once installed.

Volume paths and general structure are inspired by: https://trash-guides.info/

## Included Services

The script can install the following services:

### Media Servers
- **Plex**  
  Documentation: https://docs.linuxserver.io/images/docker-plex/

### Media Management (*arr Stack)
- **Sonarr** – TV show management  
  https://hub.docker.com/r/linuxserver/sonarr/

- **Radarr** – Movie management  
  https://hub.docker.com/r/linuxserver/radarr/

- **Lidarr** – Music management  
  https://hub.docker.com/r/linuxserver/lidarr/

- **Bazarr** – Subtitle management  
  https://hub.docker.com/r/linuxserver/bazarr/

### Download Clients
- **Transmission** – BitTorrent client  
  https://hub.docker.com/r/linuxserver/transmission/

- **qBittorrent** – BitTorrent client  
  https://hub.docker.com/r/linuxserver/qbittorrent/

- **SABnzbd** – Usenet client  
  https://hub.docker.com/r/linuxserver/sabnzbd/

### Indexing / Integration
- **Jackett** – Indexer proxy for *arr applications  
  https://hub.docker.com/r/linuxserver/jackett/

## Requirements

- Linux-based system
- Docker and Docker Compose installed (This can be done via the script as well)
- Uncomplicted firewall (UFW) installed (This can also be done via the script)
- Basic familiarity with shell scripts and containerized environments
- All app configuration must be handled by the user (Visit https://trash-guides.info for configuration info)

## Usage

Clone the repository and run the script:

    git clone https://github.com/othermully/lazy-media-server.git
    cd lazy-media-server
    chmod +x ./lazy-media-server.sh
    ./lazy-media-server.sh

Review the script before executing to ensure it matches your environment and expectations.

## Limitations

This project currently has several limitations:

- Minimal error handling
- Limited input validation
- Sensitive to incorrect or unexpected input
- Not tested against edge cases
- Assumes a specific filesystem layout and environment

Failures may occur without clear or helpful error messages.

## Disclaimer

This script is provided as-is with no guarantees.

- Use at your own risk
- Not suitable for production environments
- Always review the code before running it on your system

## Contributing

Contributions are welcome, particularly in the following areas:

- Error handling improvements
- Input validation
- General robustness and portability
- Documentation updates

Please open an issue or submit a pull request to discuss changes.
