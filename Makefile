.PHONY: default help install uninstall pull update logo

PROG 		= zookeeper
CONFIG_DIR 	= /etc/$(PROG)
INSTALL_DIR 	= /opt/$(PROG)
CRON 		= /etc/cron.d
CRON_DIR 	= $(INSTALL_DIR)/cron
BIN_DIR 	= $(INSTALL_DIR)/bin
FUNCTIONS 	= ./functions.sh
AUTOINSTALL 	= ./auto-install.sh
Q 		= @
bold   		= $(shell tput bold)
normal 		= $(shell tput sgr0)

default: help

help:
	$(Q)echo "$(bold)Zookeeper installation targets:$(normal)"
	$(Q)echo " install                  	- Installs zookeeper"
	$(Q)echo " uninstall 	                - Uninstalls zookeeper (custom files too)"
	$(Q)echo " update               	- Update code and reinstall zookeeper"
	$(Q)echo " mrproper                     - Remove all files not in source distribution"
	$(Q)echo "$(bold)System installation targets (Ubuntu only):$(normal)"
	$(Q)echo " install-docker               - Install docker"
	$(Q)echo " user-config               	- Configure demo user for zookeeper"
	$(Q)echo " system-config               	- Configure system controls for zookeeper"
	$(Q)echo "$(bold)Miscellaneous targets:$(normal)"
	$(Q)echo " install-sample-config        - Install sample default config file"
	$(Q)echo " logo                         - Print logo to stdout"

install:
	$(info Installing $(PROG))
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
	$(info Uninstalling $(PROG))
	rm -rf $(CONFIG_DIR)
	rm -rf $(INSTALL_DIR)
	rm -f $(CRON)/$(PROG)

pull:
	$(info 1. Getting latest code)
	git checkout master
	git pull

update: pull
	$(info 2. Installing latest code)
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
