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
user-config     | Configures a demo user account, sudoer file, and sshd with security in mind
system-config   | Configures ulimit for the system

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


