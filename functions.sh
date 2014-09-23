#!/bin/bash
# Author: Jon Schipp <jonschipp@gmail.com>
# Written for Ubuntu Saucy and Trusty, should be adaptable to other distros.

# Installation notification (not implemented yet)
COWSAY=/usr/games/cowsay
IRCSAY=/usr/local/bin/ircsay
IRC_CHAN="#replace_me"
HOST=$(hostname -s)
LOGFILE=install.log
EMAIL=user@company.com

# System Configuration
SSH_CONFIG=/etc/ssh/sshd_config
DOCKER_FILE="Dockerfile" 			# Build image from specific Dockerfile. Defaults to latest stable release.
CUSTOM_IMAGE="no"				# no to pull image from Docker hub, yes to build image from $DOCKER_FILE if it exists
CONTAINER_DESTINATION= 				# Put containers on another volume e.g. /dev/sdb1 (optional). You must mkfs.$FS first!
FS="ext4"					# Filesystem type for CONTAINER_DESTINATION, used for mounting
IMAGE="ubuntu"			 		# Assign a different name to the image (optional)
USER="demo" 					# User account to create for that people will ssh into to enter container
PASS="demo" 					# Password for the account that users will ssh into
DB=/var/tmp/zookeeper_db 			# Credentials database, must be readable by $USER
INSTALL_DIR=/opt/zookeeper	 		# Zookeeper component directory
BIN_DIR="$INSTALL_DIR/bin" 			# Directory to install zookeeper scripts
CRON_DIR="$INSTALL_DIR/cron" 			# Directory to install cron scripts
CONFIG_DIR=/etc/zookeeper 			# Directory to install configuration files
CONFIG="$CONFIG_DIR/zookeeper.conf" 		# Global configuration file
SHELL="$BIN_DIR/zookeeper_shell"		# $USER's shell: displays login banner then launches zookeeper_login
LAUNCH_CONTAINER="$BIN_DIR/zookeeper_login"	# User management script and container launcher
BASENAME="zk"					# Container prefix as $BASENAME.$USERNAME, used for re-attachment.
MOTD="Training materials are in /exercises"	# Message of the day is displayed before container launch and reattachment

## Container configuration (applies to each container)
DAYS=3	       # Container lifetime specified in days, removed after x days
VIRTUSER=demo  # Account used when container is entered (Must exist in container!)
CPU=1          # Number of CPU's allocated to each container
RAM=256m       # Amount of memory allocated to each container
HOSTNAME=zk    # Cosmetic: Will end up as $USER@$HOSTNAME:~$ in shell
NETWORK=none   # Disable networking by default: none; Enable networking: bridge
DNS=127.0.0.1  # Use loopback when networking is disabled to prevent error messages
MOUNT="-v /exercises:/exercises:ro" # Mount directory in container, src:dst:attributes

# Logging
#exec > >(tee -a "$LOGFILE") 2>&1
#echo -e "\n --> Logging stdout & stderr to $LOGFILE"

function die {
    if [ -f ${COWSAY:-none} ]; then
        $COWSAY -d "$*"
    else
        echo "$*"
    fi
    if [ -f $IRCSAY ]; then
        ( set +e; $IRCSAY "$IRC_CHAN" "$*" 2>/dev/null || true )
    fi
    echo "$*" | mail -s "[vagrant] Bro Sandbox install information on $HOST" $EMAIL
    exit 1
}

function hi {
    if [ -f ${COWSAY:-none} ]; then
        $COWSAY "$*"
    else
        echo "$*"
    fi
    if [ -f $IRCSAY ]; then
        ( set +e; $IRCSAY "$IRC_CHAN" "$*" 2>/dev/null || true )
    fi
    echo "$*" | mail -s "[vagrant] Bro Sandbox install information on $HOST" $EMAIL
}

function logo {
cat <<"EOF"
==============================================

   Zoo Keeper: A Linux-based Training System

   Web: https://github.com/jonschipp/zookeeper

==============================================

EOF
}

function is_ubuntu(){
if ! lsb_release -s -d 2>/dev/null | grep -q Ubuntu
then
	echo -e "\n==> Ubuntu Linux is required for installation! <==\n"
	exit 1
fi
}

function install_docker() {
is_ubuntu
local ORDER=$1
echo -e "$ORDER Installing Docker!\n"

# Check that HTTPS transport is available to APT
if [ ! -e /usr/lib/apt/methods/https ]; then
	apt-get update
	apt-get install -y apt-transport-https
	echo
fi

# Add the repository to your APT sources
# Then import the repository key
if [ ! -e /etc/apt/sources.list.d/docker.list ]
then
	echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
	echo
fi

# Install docker
if ! command -v docker >/dev/null 2>&1
then
	apt-get update
	apt-get install -y lxc-docker
	echo
fi
}

function user_configuration() {
local ORDER=$1
local RESTART_SSH=0
echo -e "$ORDER Configuring the $USER user account!\n"

if [ ! -e /etc/sudoers.d/zookeeper ]; then
cat > /etc/sudoers.d/zookeeper <<EOF
Cmnd_Alias SANDBOX = /usr/bin/docker
$USER ALL=(root) NOPASSWD: SANDBOX
EOF
chmod 0440 /etc/sudoers.d/zookeeper && chown root:root /etc/sudoers.d/zookeeper
fi

if ! getent passwd $USER 1>/dev/null
then
	adduser --disabled-login --gecos "" --shell $SHELL $USER
	echo "$USER:$PASS" | chpasswd
fi

if ! grep -q "ClientAliveInterval 15" $SSH_CONFIG
then
	echo -e "\nClientAliveInterval 15\nClientAliveCountMax 10\n" >> $SSH_CONFIG
	RESTART_SSH=1
fi

if grep -q "PasswordAuthentication no" $SSH_CONFIG
then
	if ! grep -q "Match User $USER" $SSH_CONFIG
	then
		echo -e "\nMatch User $USER\n\tPasswordAuthentication yes\n" >> $SSH_CONFIG
		RESTART_SSH=1
	fi
fi

if ! grep -q '^#Subsystem sftp' $SSH_CONFIG
then
	sed -i '/^Subsystem sftp/s/^/#/' $SSH_CONFIG
	RESTART_SSH=1
fi

if [ $RESTART_SSH -eq 1 ]
then
	restart ssh
	echo
fi
}

function system_configuration() {
local ORDER=$1
local LIMITS=/etc/security/limits.d
echo -e "$ORDER Configuring the system for use!\n"

if [ ! -e $LIMITS/zookeeper.conf ]; then
	echo "*                hard    fsize           1000000" > $LIMITS/fsize.conf
	echo "*                hard    nproc           10000" >> $LIMITS/nproc.conf
fi
}

function docker_configuration() {
is_ubuntu
local ORDER=$1
local DEFAULT=/etc/default/docker
local UPSTART=/etc/init/docker.conf

echo -e "$ORDER Installing the Bro Sandbox Docker image!\n"


if ! grep -q "limit fsize" $UPSTART
then
	sed -i '/limit nproc/a limit fsize 500000000 500000000' $UPSTART
fi

if ! grep -q "limit nproc 524288 524288" $UPSTART
then
	sed -i '/limit nproc/s/[0-9]\{1,8\}/524288/g' $UPSTART
fi

if [[ "$DISTRIB_CODENAME" == "saucy" || "$DISTRIB_CODENAME" == "trusty" ]]
then
	# Devicemapper allows us to limit container sizes for security
	# https://github.com/docker/docker/tree/master/daemon/graphdriver/devmapper
	if ! grep -q devicemapper $DEFAULT
	then
		echo -e " --> Using devicemapper as storage backend\n"
		install -o root -g root -m 644 $HOME/etc.default.docker $DEFAULT

		if [ -d /var/lib/docker ]; then
			rm -rf /var/lib/docker/*
		fi

		if [ ! -z $CONTAINER_DESTINATION ]; then

			if ! mount | grep -q $CONTAINER_DESTINATION ; then
				mount -o defaults,noatime,nodiratime $CONTAINER_DESTINATION /var/lib/docker
			fi

			if ! grep -q $CONTAINER_DESTINATION /etc/fstab 2>/dev/null; then
				echo -e "${CONTAINER_DESTINATION}\t/var/lib/docker\t${FS}\tdefaults,noatime,nodiratime,nobootwait\t0\t1" >> /etc/fstab
			fi
                fi

		mkdir -p /var/lib/docker/devicemapper/devicemapper
		restart docker
		sleep 5
	fi
fi
}

function install_sample_configuration(){
echo -e "$ORDER Installing sample training image for Bro!\n"
if ! docker images | grep -q brolive
then
	docker pull broplatform/brolive
	docker tag broplatform/brolive brolive
fi
}

$@
