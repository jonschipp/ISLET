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
useradd --create-home --shell /opt/zookeeper/bin/zookeeper_shell training
echo "training:training | chpasswd
groupadd docker
gpasswd -a training docker
```

### Security Recommendations

* SSH: _/etc/ssh/sshd_config_

The following command will configure sshd_config to match the example after with the exception of modifying LoginGraceTime.

```shell
make security-config
```

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

* Separate storage for containers:

```
service docker stop
rm -rf /var/lib/docker/*
mkfs.ext2 /dev/sdb1
mount -o defaults,noatime,nodiratime /dev/sdb1 /var/lib/docker
tail -1 /etc/fstab
	/dev/sdb1	/var/lib/docker	    ext2     defaults,noatime,nodiratime,nobootwait 0 1
service docker start
```

* Limit container storage size to prevent DoS or resource abuse

Switching storage backends to devicemapper allows for disk quotas.
Set dm.basesize to the maximum size the container can grow to, 10G is the default.

```
service docker stop
rm -rf /var/lib/docker/*
tail -1 /etc/default/docker
	DOCKER_OPTS="--storage-driver=devicemapper --storage-opt dm.basesize=3G"
mkdir -p /var/lib/docker/devicemapper/devicemapper
restart docker
sleep 5
```

**Note:** There's currently a bug in devicemapper that may cause docker to fail run containers after a reboot (my experience anyway).
Not recommended for production at the moment, [more info](https://github.com/docker/docker/issues/4036).

# Administration

* Global configuration file: */etc/zookeeper/zookeeper.conf*
* Per-image configuration file: */etc/zookeeper/$IMAGE.conf*

Per-image configs overwrite the global variables specified in the global config file.
For each Docker image you want available for use by zookeeper, create an image file with a .conf extension and place it in the /etc/zookeeper/ directory.
These images will be selectable from the zookeeper menu after a student authenticates via SSH as the demo user (default).

Common Tasks:

* Change the password of the demo user to help prevent unauthorized access

```
        $ passwd demo
```

* Change the password of a container user (Not a system account). Place an SHA-1 hash of the password of choice in the second field of desired user in /var/tmp/zookeeper_db.

```
        $ PASS=$(echo "newpassword" | sha1sum | sed 's/ .*//)
        $ USER=testuser
        $ sed -i "/^$USER:/ s/:[^:]*/:$PASS/" /var/tmp/zookeeper_db
        $ grep testuser /var/tmp/zookeeper_db
        testuser:dd76770fc59bcb08cfe7951e5839ac2cb007b9e5:1410247448

```

* Configure container and user lifetime (e.g. conference duration)

  1. Specify the number of days for user account and container lifetime in:

```
        $ grep ^DAYS /etc/zookeeper/brolive.conf
        DAYS=3 # Length of the event in days
```

  Removal scripts are cron jobs that are scheduled in /etc/cron.d/zookeeper

* Allocate more or less resources for containers, and control other container settings.
  These changes will take effect for each newly created container.
  - System and use case dependent

```
        $ grep -A 5 "Container config /etc/zookeeper/brolive.conf
	# Container Configuration
	VIRTUSER="demo"                                         # Account used when container is entered (Must exist in container!)
	CPU="1"                                                 # Number of CPU's allocated to each container
	RAM="256m"                                              # Amount of memory allocated to each container
	HOSTNAME="bro"	                                      	# Set hostname in container. PS1 will end up as $VIRTUSER@$HOSTNAME:~$ in shell
	NETWORK="none"                                          # Disable networking by default: none; Enable networking: bridge
	DNS="127.0.0.1"                                         # Use loopback when networking is disabled to prevent error messages from resolver
	MOUNT="-v /exercises:/exercises:ro"			# Mount point(s), sep. by -v: /src:/dst:attributes, ro = readonly (avoid rw)
	OPTIONS="--cap-add=NET_RAW --cap-add=NET_ADMIN"		# Apply any other options you want passed to Docker run here
	MOTD="Training materials are in /exercises"             # Message of the day is displayed before container launch and reattachment
```

* Adding, removing, or modifying exercises

  1. Make changes in /exercises on the host's filesystem

  *  Changes are immediately available for new and existing containers

# Branding

* Custom greeting upon initial system login

  1. Edit /opt/zookeeper/bin/zookeeper_shell with the text of your liking

```
	...

	# Zookeeper Banner
        echo "Welcome to Bro Live!"
        echo "===================="
        cat <<"EOF"
          -----------
          /             \
         |  (   (0)   )  |
         |            // |
          \     <====// /
            -----------
        EOF
        echo
        echo "A place to try out Bro."
        echo

	....
```

* Custom login message for each user

  1. Edit the MOTD variable in /etc/zookeeper/brolive.conf with the text of your liking.
     'echo -e' escape sequences work here.

```
        $ grep -A 2 MOTD /etc/zookeeper/brolive.conf 
        MOTD="
        Training materials are located in /exercises
        \te.g. $ bro -r /exercises/BroCon14/beginner/http.pcap\n"

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


