zookeeper
=========

A container system for teaching Linux based software with minimal participation effort. <br>
Students only need an SSH client.

## Installation

Installation of Zookeeper is very simple.

```shell
make install
```

Target:         |    Description:
----------------|----------------
install         | Install Zookeeper: install-files + configuration
update		| Updates and install new code: pull + install
uninstall       | Uninstall Zookeeper (Recommended to backup your stuff first)
mrproper 	| Removes files that did not come with the source
install-files   | Copies the zookeeper config and scripts files
configuration   | Configures the newly copied config and script files. Sets CONFIG variable for operation
pull  	        | Checkout master branch and run git pull
install-docker  | Installs latest Docker from Docker repo (Ubuntu only)
user-config     | Configures a user account called demo
security-config | Configures sshd with security in mind

### Dependencies

* Linux, Bash, OpenSSH, and Docker

The included installation scripts are designed to work with Ubuntu.

#### Ubuntu

The following make targets will install docker and configure the system with security in mind for the Docker process.
It is designed to be a quick way to get a working system with a good configuration.

```shell
make install-docker	# Installs latest Docker
make user-config	# Configures demo user account, sudo access, and SSH security controls
make system-config 	# Configure ulimit security settings for the system
```

#### Manual

Manually install and configure all dependencies to your liking.

* Install Docker:
```shell
apt-get install docker
yum install docker
```

* Configure user account for training (this is given to students to login):
```shell
useradd --create-home --shell /opt/zookeeper/bin/sandbox_shell training
echo "training:training | chpasswd
groupadd docker
gpasswd -a training docker
```

* Other recommendations:

SSH: _/etc/ssh/sshd_config_

```shell
LoginGraceTime 30s
ClientAliveInterval 15
ClientAliveCountMax 10

#Subsystem       sftp    /usr/libexec/openssh/sftp-server

Match User training
        ForceCommand /opt/zookeeper/bin/zookeeper_shell
        X11Forwarding no
        AllowTcpForwarding no
	PermitTunnel no
	PermitOpen none
	MaxAuthTries 3
	MaxSessions 2
	AllowAgentForwarding no
	PermitEmptyPasswords no
```

Separate storage for containers:

```
service docker stop
rm -rf /var/lib/docker/*
mkfs.ext2 /dev/sdb1
mount -o defaults,noatime,nodiratime /dev/sdb1 /var/lib/docker
echo -e "/dev/sdb1\t/var/lib/docker\text2}\tdefaults,noatime,nodiratime,nobootwait\t0\t1" >> /etc/fstab
service docker start
```

# Demo

I used Zookeeper to teach the Bro platform at BroCon14.

Steps:
* Install Zookeeper and dependencies
* Build Docker image containing Bro
* Write a Zookeeper config file for the Bro image
* Edit the zookeeper_shell script to do some light branding (logo)
* Hand out the demo account credentials to your students so they can SSH in
* Instruct them on the software

Here's a brief demonstration:

```
        $ ssh demo@live.bro.org

        Welcome to Bro Live!
        ====================

            -----------
          /             \
         |  (   (0)   )  |
         |            // |
          \     <====// /
            -----------

        A place to try out Bro.

        Are you a new or existing user? [new/existing]: new

        A temporary account will be created so that you can resume your session. Account is valid for the length of the event.

        Choose a username [a-zA-Z0-9]: jon
        Your username is jon
        Choose a password:
        Verify your password:
        Your account will expire on Fri 29 Aug 2014 07:40:11 PM UTC

        Enjoy yourself!
        Training materials are located in /exercises.
        e.g. $ bro -r /exercises/beginner/http.pcap

        demo@bro:~$ pwd
        /home/demo
        demo@bro:~$ which bro
        /usr/local/bro/bin/bro
```


