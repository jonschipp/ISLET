#!/usr/bin/env bash
# Author: Jon Schipp <jonschipp@gmail.com>
# Written for Ubuntu Saucy and Trusty, should be adaptable to other distros.

# Installation notification (not implemented yet)
MAIL=$(which mail 2>/dev/null)
COWSAY=/usr/games/cowsay
IRCSAY=/usr/local/bin/ircsay
IRC_CHAN="#replace_me"
HOST=$(hostname -s)
LOGFILE=install.log
EMAIL=user@company.com

# System Configuration
USER="demo" 					# User account to create for that people will ssh into to enter container
PASS="demo" 					# Password for the account that users will ssh into
SSH_CONFIG=/etc/ssh/sshd_config
CONTAINER_DESTINATION= 				# Put containers on another volume e.g. /dev/sdb1 (optional). You must mkfs.$FS first!
FS="ext4"					# Filesystem type for CONTAINER_DESTINATION, used for mounting
INSTALL_DIR=/opt/islet	 			# ISLET component directory
BIN_DIR="$INSTALL_DIR/bin" 			# Directory to install islet scripts
SHELL="$BIN_DIR/islet_shell"			# $USER's shell: displays login banner then launches islet_login

# Logging
#exec > >(tee -a "$LOGFILE") 2>&1
#echo -e "\n --> Logging stdout & stderr to $LOGFILE"

die(){
    if [ -f ${COWSAY:-none} ]; then
        $COWSAY -d "$*"
    else
        echo -e "$(tput setaf 1)$*$(tput sgr0)"
    fi
    if [ -f $IRCSAY ]; then
        ( set +e; $IRCSAY "$IRC_CHAN" "$*" 2>/dev/null || true )
    fi
    if [ -f ${MAIL:-none} ]; then
    	echo "$*" | mail -s "[vagrant] Bro Sandbox install information on $HOST" $EMAIL
    fi

    exit 1
}

hi(){
    if [ -f ${COWSAY:-none} ]; then
        $COWSAY "$*"
    else
        echo -e "$(tput setaf 3)$*$(tput sgr0)"
    fi
    if [ -f $IRCSAY ]; then
        ( set +e; $IRCSAY "$IRC_CHAN" "$*" 2>/dev/null || true )
    fi
    if [ -f ${MAIL:-none} ]; then
    	echo "$*" | mail -s "[vagrant] Bro Sandbox install information on $HOST" $EMAIL
    fi
}

logo(){
cat <<"EOF"
===============================================================

   ISLET: A Linux-based Software Training System

(I)solated,
	  (S)calable,
		     & (L)ightweight (E)nvironment
						 for (T)raining

   Web: https://github.com/jonschipp/islet

===============================================================
EOF
}

is_ubuntu(){
if ! lsb_release -s -d 2>/dev/null | grep -q Ubuntu
then
	echo -e "\n==> Ubuntu Linux is required for installation! <==\n"
	exit 1
fi
}

install_docker(){
is_ubuntu
local ORDER=$1
hi "$ORDER Installing Docker!\n"

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

user_configuration(){
local ORDER=$1
local RESTART_SSH=0
hi "$ORDER Configuring the $USER user account!\n"

if ! getent passwd $USER 1>/dev/null
then
	useradd --create-home --shell $SHELL $USER
	echo "$USER:$PASS" | chpasswd
fi

if ! getent group docker | grep -q $USER 1>/dev/null
then
	groupadd docker 2>/dev/null
	gpasswd -a $USER docker 2>/dev/null
fi
}

security_configuration(){
local ORDER=$1
local LIMITS=/etc/security/limits.d
hi "$ORDER Configuring the system with security in mind!\n"

if [ ! -e $LIMITS/islet.conf ]; then
	echo "demo             hard    maxlogins       500" 	>  $LIMITS/islet.conf
	echo "demo             hard    cpu             180" 	>> $LIMITS/islet.conf
	echo "@docker          hard    fsize           1000000" >> $LIMITS/islet.conf
	echo "@docker          hard    nproc           10000" 	>> $LIMITS/islet.conf
fi

if ! grep -q "ClientAliveInterval 15" $SSH_CONFIG
then
       echo -e "\nClientAliveInterval 15\nClientAliveCountMax 10\n" >> $SSH_CONFIG
       RESTART_SSH=1
fi

if ! grep -q "Match User $USER" $SSH_CONFIG; then
cat <<EOF >> $SSH_CONFIG
Match User $USER
	ForceCommand $SHELL
	PasswordAuthentication yes
	X11Forwarding no
	AllowTcpForwarding no
	PermitOpen none
	PermitTunnel no
	MaxAuthTries 3
	MaxSessions 2
	AllowAgentForwarding no
	PermitEmptyPasswords no
EOF
RESTART_SSH=1
fi

if grep -q '^Subsystem sftp' $SSH_CONFIG
then
	sed -i '/Subsystem.*sftp/s/^/#/' $SSH_CONFIG
	RESTART_SSH=1
fi

if [ $RESTART_SSH -eq 1 ]
then

	service sshd restart 2>/dev/null
	service ssh restart 2>/dev/null

	echo
fi
}

docker_configuration(){
is_ubuntu
local ORDER=$1
local DEFAULT=/etc/default/docker
local UPSTART=/etc/init/docker.conf

hi "$ORDER Installing the Bro Sandbox Docker image!\n"


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
		service docker restart 2>/dev/null
		sleep 5
	fi
fi
}

install_sample_configuration(){
hi "$ORDER Installing sample training image for Bro!\n"
if ! docker images | grep -q brolive
then
	docker pull broplatform/brolive
	docker tag broplatform/brolive brolive
fi
}

install_nsm_configurations(){

install_sample_configuration

for file in $(git ls-files extra/*.conf)
do
	F=$(basename $file .conf)
	if ! docker images | grep -q $F
	then
		hi "$ORDER Installing sample training image for ${F}\n"
		docker pull jonschipp/${F}-sandbox
		docker tag jonschipp/${F}-sandbox $F
	fi
done
}

install_sample_distributions(){
DISTRO="ubuntu debian fedora centos"
for image in $DISTRO
do
	if ! docker images | grep -q $image
	then
		hi "$ORDER Installing distribution image for ${image}\n"
		docker pull $image
	fi
done
}

"$@"
