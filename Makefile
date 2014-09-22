.PHONY: default help install uninstall pull update logo mrproper

PROG 		= zookeeper
CONFIG_DIR 	= /etc/$(PROG)
INSTALL_DIR 	= /opt/$(PROG)
CRON 		= /etc/cron.d
CRON_DIR 	= $(INSTALL_DIR)/cron
BIN_DIR 	= $(INSTALL_DIR)/bin
FUNCTIONS 	= ./functions.sh
AUTOINSTALL 	= ./auto-install.sh
REPO		= http://github.com/jonschipp/zookeeper
Q 		= @
bold   		= $(shell tput bold)
underline 	= $(shell tput smul)
normal 		= $(shell tput sgr0)
red		= $(shell tput setaf 1)
yellow	 	= $(shell tput setaf 3)

default: help

help:
	$(Q)echo "$(bold)Zookeeper installation targets:$(normal)"
	$(Q)echo " $(red)install$(normal)                  	- Installs zookeeper"
	$(Q)echo " $(red)uninstall$(normal) 	                - Uninstalls zookeeper (custom files too)"
	$(Q)echo " $(red)update$(normal)               		- Update code and reinstall zookeeper"
	$(Q)echo " $(red)mrproper$(normal)                     	- Remove all files not in source distribution"
	$(Q)echo "$(bold)System installation targets ($(normal)$(yellow)Ubuntu only$(normal))$(bold):$(normal)"
	$(Q)echo " $(red)install-docker$(normal)               	- Install docker"
	$(Q)echo " $(red)user-config$(normal)               	- Configure demo user for zookeeper"
	$(Q)echo " $(red)system-config$(normal)               	- Configure system controls for zookeeper"
	$(Q)echo "$(bold)Miscellaneous targets:$(normal)"
	$(Q)echo " $(red)install-sample-config$(normal)        	- Install sample default config file"
	$(Q)echo " $(red)logo$(normal)                         	- Print logo to stdout"

install:
	$(Q)echo " $(yellow)Installing $(PROG)$(normal)"
	mkdir -m 755 -p $(CONFIG_DIR)
	mkdir -m 755 -p $(CRON_DIR)
	mkdir -m 755 -p $(BIN_DIR)
	install -o root -g root -m 644 config/zookeeper.conf $(CONFIG_DIR)/$(PROG).conf
	install -o root -g root -m 755 bin/zookeeper_shell $(BIN_DIR)/$(PROG)_shell
	install -o root -g root -m 755 bin/zookeeper_login $(BIN_DIR)/$(PROG)_login
	install -o root -g root -m 644 cron/zookeeper.crontab $(CRON)/$(PROG)
	install -o root -g root -m 750 cron/remove_old_containers $(CRON_DIR)/remove_old_containers
	install -o root -g root -m 750 cron/remove_old_users $(CRON_DIR)/remove_old_users
	$(info Configuration directory is $(CONFIG_DIR))
	$(info Scripts directory is $(INSTALL_DIR))

uninstall:
	$(Q)echo " $(yellow)Uninstalling $(PROG)$(normal)"
	rm -rf $(CONFIG_DIR)
	rm -rf $(INSTALL_DIR)
	rm -f $(CRON)/$(PROG)

mrproper:
	$(Q)echo " $(yellow)Removing files not in source$(normal)"
	$(Q)git ls-files -o | xargs rm -rf

pull:
	$(Q)echo " $(yellow)Pulling latest code from:$(normal) $(underline)$(REPO)$(normal)"
	$(Q)git checkout master 1>/dev/null 2>/dev/null
	$(Q)git pull

update: pull
	$(Q)echo " $(yellow)Installing latest code$(normal)"
	make install
   
#function docker_configuration() {
 
install-sample-config:
	$(FUNCTIONS) install_configuration_file

install-docker:
	$(FUNCTIONS) install_docker

user-config:
	$(FUNCTIONS) user_configuration

system-config:
	$(FUNCTIONS) system_configuration

logo:
	$(FUNCTIONS) logo
