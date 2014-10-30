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

# Other Declarations
RESTART_SSH=0
RESTART_DOCKER=1
LIMITS=/etc/security/limits.d
DEFAULT=/etc/default/docker
UPSTART=/etc/init/docker.conf

# Logging
#exec > >(tee -a "$LOGFILE") 2>&1
#printf "\n --> Logging stdout & stderr to ${LOGFILE}\n"

die(){
    if [ -f ${COWSAY:-none} ]; then
        $COWSAY -d "$*"
    else
        printf "$(tput setaf 1)$*$(tput sgr0)\n"
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
        printf "$(tput setaf 3)$*$(tput sgr0)\n"
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
	printf "\n==> Ubuntu Linux is required for installation! <==\n"
	exit 1
fi
}

install_docker(){
is_ubuntu
hi "  Installing Docker!\n"

# Check that HTTPS transport is available to APT
if [ ! -e /usr/lib/apt/methods/https ]; then
	apt-get update -qq
	apt-get install -qy apt-transport-https
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
	apt-get update -qq
	apt-get install -qy lxc-docker
	echo
fi
}

user_configuration(){
local USER="${1:-$USER}"
local SHELL="${2:-$SHELL}"
hi "  Configuring the $USER user account!\n"

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
local USER="${1:-$USER}"
local SHELL="${2:-$SHELL}"
hi "  Configuring the system with security in mind!\n"

if [ ! -e $LIMITS/islet.conf ]; then
	echo "demo             hard    maxlogins       500" 	>  $LIMITS/islet.conf
	echo "demo             hard    cpu             180" 	>> $LIMITS/islet.conf
	echo "@docker          hard    fsize           1000000" >> $LIMITS/islet.conf
	echo "@docker          hard    nproc           10000" 	>> $LIMITS/islet.conf
fi


grep -q ISLET $UPSTART && RESTART_DOCKER=0 || sed -i '/limit/a \
# BEGIN ISLET Additions \
limit nofile 1000 2000 \
limit nproc  1000 2000 \
limit fsize  100000000 200000000 \
limit cpu    500  500 \
# END' $UPSTART

if ! grep -q "ClientAliveInterval 15" $SSH_CONFIG
then
       printf "\nClientAliveInterval 15\nClientAliveCountMax 10\n" >> $SSH_CONFIG
       RESTART_SSH=1
fi

if ! grep -q "Match User $USER" $SSH_CONFIG; then
cat <<EOF >> $SSH_CONFIG
Match User $USER
	ForceCommand $SHELL
	PasswordAuthentication yes
	X11Forwarding no
	AllowTcpForwarding no
	GatewayPorts no
	PermitOpen none
	PermitTunnel no
	MaxAuthTries 3
	MaxSessions 1
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
	if sshd -t 2>/dev/null
	then
		service sshd restart 2>/dev/null
		service ssh restart 2>/dev/null
	else
		echo "Syntax error in ${SSH_CONFIG}."
	fi
	echo
fi

if [ $RESTART_DOCKER -eq 1 ]
then
	stop docker
	sleep 1
	start docker
	echo
	cat /proc/$(pgrep -f "docker -d")/limits
	echo
fi

}

install_sample_configuration(){
hi "  Installing sample training image for Bro!\n"
if ! docker images | grep -q brolive
then
	docker pull broplatform/brolive
fi
}

install_nsm_configurations(){

install_sample_configuration

for file in $(git ls-files extra/*.conf | grep -v brolive.conf)
do
	F=$(basename $file .conf)
	if ! docker images | grep -q $F
	then
		hi "  Installing sample training image for ${F}\n"
		docker pull jonschipp/islet-${F}
	fi
done
}

install_sample_distributions(){
DISTRO="ubuntu debian fedora centos"
for image in $DISTRO
do
	if ! docker images | grep -q $image
	then
		hi "  Installing distribution image for ${image}\n"
		docker pull $image
	fi
done
}

"$@"
