#!/bin/bash

clear
cat motd

# Globals
kernel_version=$(uname -r)
network_interface=""
ip_addr=""
hostname=""

# Functions:
function read_line(){
	read -p "> " "$1"
}


function get_network_info(){
	echo ""
	echo "<-------------------- SYSTEM INFORMATION -------------------->"
	echo "-- Hostname:		$hostname"
	echo "-- Network interface:	$network_interface"
	echo "-- Local IPv4:		$ip_addr"
	echo "-- Kernel version:	$kernel_version"
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
}

#function check_if_ufw_installed(){}

#function check_if_docker_installed(){}
#function check_if_folder_exists(){}
#
#function print_main_menu(){}
#
#function add_sonarr(){}
#function add_radarr(){}
#function add_jackett(){}
#function add_transmission(){}
#function add_qbitorrrent(){}
#function add_plex(){}
#function add_jellyfin(){}
#
#function create_manual_paths(){}
#function create_automatic_paths(){}
#function setup_permissions(){}
#function create_ufw_rules(){}
#
#function install_docker(){}
#function install_ufw(){}
#
#function build_containers(){}
#

select_network_interface
get_network_info

