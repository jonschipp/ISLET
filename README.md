Isolated, Scalable, & Lightweight Environment for Training
=========

[![Join the chat at https://gitter.im/jonschipp/ISLET](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/jonschipp/ISLET?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Make IT training a smoother process... <br>

A container based system for teaching Linux based software with minimal participation and configuration effort. ISLET supports running many different training environments concurrently and has a plugin system for extending functionality. The participation barrier is set very low, students only need an SSH client to connect to ISLET.

![ISLET Screenshot](http://jonschipp.com/islet/islet.png)

#### Uses

* Event and staff training
* Capture the flag competitions
* Development environments

#### Who Uses ISLET?
ISLET has been used for official training of two leading open source network security projects.  These and other notable examples are listed below.

* [Bro](https://bro.org) Team
* [Suricata](http://suricata-ids.org/) Team
* [CriticalStack](https://criticalstack.com)
* University of Illinois at Urbana-Champaign Digital Forensics 2 Course
* [OpenNSM](http://open-nsm.net)
* ACM [GNU/LUG](http://www.gnulug.org/) at UIUC

If you would like commercial support for ISLET including creating and deploying custom training environments contact me through my company [Draconyx](http://www.draconyx.net/).

## Design

These images a little old but they mostly represent the design.

####Simplified Diagram
![ISLET Diagram](http://jonschipp.com/islet/islet_diagram.jpg)

####Detailed Flowchart
![ISLET Flowchart](http://jonschipp.com/islet/islet_flowchart.png)

## Installation

Installation of ISLET is very simple, first grab the dependencies and then
install ISLET.

### Dependencies

* Linux, Bash, Cron, OpenSSH, Make, SQLite, and Docker Engine

The configure script will check for dependencies (except docker)
```shell
./configure
```

![ISLET Configure Screenshot](http://jonschipp.com/islet/islet_configure.png)

Typically all you need is make, sqlite, and docker engine (for Debian/Ubuntu):
```shell
apt-get install make sqlite
```
See Docker's documentation for installation instructions.

### Install

After installing the dependencies, run
```shell
make user-config && make install && make security-config
```

See the menu for more options, `make` 
![ISLET Make Screenshot](http://jonschipp.com/islet/islet_make.png)

Target:         |    Description:
----------------|----------------
install         | Install ISLET: install-files + configuration
update		| Downloads and install new code (custom changes to default files will be overwritten)
uninstall       | Uninstall ISLET (Recommended to backup your stuff first)
mrproper 	| Removes files that did not come with the source
user-config     | Configures a user account called demo w/ password demo
security-config | Configures sshd with islet relevant security in mind
iptables-config | Installs iptables ruleset

GNU make accepts arguments if you want a customized installation (*not supported*):
```shell
make user-config INSTALL_DIR=/usr/local/islet USER=training PASS=training
make install INSTALL_DIR=/usr/local/islet USER=training
make security-config INSTALL_DIR=/usr/local/islet USER=training
make uninstall INSTALL_DIR=/usr/local/islet USER=training
```

Variable:       |    Description:
----------------|----------------
CONFIG_DIR      | ISLET configuration directory (def: /etc/islet)
INSTALL_DIR     | ISLET installation directory (def: /opt/islet)
USER		| User account created with user-config target (def: demo)
PASS		| User account password created with user-config target (def: demo)
IPTABLES	| Iptables ruleset (def: /etc/network/if-pre-up.d/iptables-rules)

## Updating

Updating an existing ISLET installation is very simple:

```shell
tar zcf islet_config.tgz /etc/islet # Backup configs
make update
tar zxf islet_config.tgz -C /       # Restore configs
```

# Adding Training Environments


See Docker's [image documentation](http://docs.docker.com/userguide/dockerimages)

 1. Build or pull in a new Docker image

 2. Create an ISLET config file for that image (training environment). You can use `make template` for an example.

 3. Place it in /etc/islet/environments with a `.conf` extension.

 It should now be available from the selection menu upon login.

![ISLET Configs Screenshot](http://jonschipp.com/islet/islet_configs.png)

More info:
See the SECURITY file for more information on manually securing the system.
See the ADMIN file for more information on administering the system.
[Mailing List] (https://groups.google.com/d/forum/islet)
