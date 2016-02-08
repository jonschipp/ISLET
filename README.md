Isolated, Scalable, & Lightweight Environment for Training
=========

[![Join the chat at https://gitter.im/jonschipp/ISLET](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/jonschipp/ISLET?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Make IT training a smoother process... <br>

A container based system for teaching Linux based software with minimal participation and configuration effort.
ISLET supports running many different training environments concurrently and has a plugin system for extending functionality.
The participation barrier is set very low, students only need an SSH client to connect to ISLET.

![ISLET Screenshot](http://jonschipp.com/islet/islet.png)

#### Uses

* Event and staff training
* Capture the flag competitions
* Development environments

## Demo
You can quickly try out ISLET on some of my dev systems. Password is demo
```shell
ssh demo@islet1.jonschipp.com
ssh demo@islet2.jonschipp.com
```

## Design

####Simplified Diagram
![ISLET Diagram](http://jonschipp.com/islet/islet_diagram.jpg)

####Detailed Flowchart
![ISLET Flowchart](http://jonschipp.com/islet/islet_flowchart.png)

## Installation

Installation of ISLET is very simple and it can be done in two ways:

On the host operation system
```shell
make install
```
Or as a Docker container which requires little to no modification to the host
```shell
make install-contained
```

![ISLET Make Screenshot](http://jonschipp.com/islet/islet_make.png)

Target:         |    Description:
----------------|----------------
install         | Install ISLET: install-files + configuration
install-contained | Install ISLET as a container, no modification to host system
update		| Downloads and install new code (custom changes to default files will be overwritten)
uninstall       | Uninstall ISLET (Recommended to backup your stuff first)
mrproper 	| Removes files that did not come with the source
install-docker  | Installs latest Docker from Docker repo (Debian/Ubuntu only)
docker-config   | Reconfigures Docker storage backend to limit container and image sizes
user-config     | Configures a user account called demo w/ password dem
security-config | Configures sshd with islet relevant security in mind
iptables-config | Installs iptables ruleset

GNU make accepts arguments if you want a customized installation (*not supported*):
```shell
make install INSTALL_DIR=/usr/local/islet USER=training
make user-config INSTALL_DIR=/usr/local/islet USER=training PASS=training
make security-config INSTALL_DIR=/usr/local/islet USER=training
make uninstall INSTALL_DIR=/usr/local/islet USER=training
```

Variable:       |    Description:
----------------|----------------
CONFIG_DIR      | ISLET config files directory (def: /etc/islet)
INSTALL_DIR     | ISLET installation directory (def: /opt/islet)
CRON		| Directory to place islet crontab file (def: /etc/cron.d)
USER		| User account created with user-config target (def: demo)
PASS		| User account password created with user-config target (def: demo)
SIZE		| Maximum container and image size with configure-docker target (def: 2G)
IPTABLES	| Iptables ruleset (def: /etc/network/if-pre-up.d/iptables-rules)
NAGIOS      | Location of nagios plugins (def: /usr/local/nagios/libexec)
PORT        | The SSH port on the host when installing ISLET as a container (def: 2222)
PACKAGE     | Type of package to build for `make package` (def: deb)

## Updating

Updating an existing ISLET installation is very simple:

For an existing host installation (`make install`):
```shell
make update
```
For an existing container installation (`make install-contained`):
```shell
docker pull jonschipp/islet
```
### Dependencies

* Linux, Bash, Cron, OpenSSH, Make, SQLite, and Docker

The configure script will check for dependencies
```shell
./configure
```

![ISLET Configure Screenshot](http://jonschipp.com/islet/islet_configure.png)

Typically all you need is make, sqlite, and docker (for Debian/Ubuntu):
```shell
apt-get install make sqlite
make install-docker
```

The included installation scripts are designed to work with Debian/Ubuntu systems.

**Note:** Installing ISLET as container (`make install-contained`) only requires Docker

#### Debian/Ubuntu

The following make targets will install ISLET and configure the system with security in mind for ISLET.
It is designed to be a quick way to get a working system with a good configuration.

Install ISLET on the host:
```shell
make install
make user-config
make security-config    # Configure islet relevant security with sshd
```

Install ISLET as a container on the host:
```shell
make install-contained	# Installs ISLET as a container
```

See the SECURITY file for more information on manually securing the system.
See the ADMIN file for more information on administering the system.

# Adding Training Environments

See Docker's [image documentation](http://docs.docker.com/userguide/dockerimages)

 1. Build or pull in a new Docker image

 2. Create an ISLET config file for that image. You can use `make template` for an example.

 3. Place it in /etc/islet with a .conf extension.

 It should now be available from the selection menu upon login.

![ISLET Configs Screenshot](http://jonschipp.com/islet/islet_configs.png)

More info:
[Mailing List] (https://groups.google.com/d/forum/islet)
