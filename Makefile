.PHONY: default help install uninstall pull update logo mrproper

PROG 		= islet
CONFIG_DIR 	= /etc/$(PROG)
INSTALL_DIR 	= /opt/$(PROG)
LIB_DIR		= $(INSTALL_DIR)/lib
CRON_DIR 	= $(INSTALL_DIR)/cron
BIN_DIR 	= $(INSTALL_DIR)/bin
CRON 		= /etc/cron.d
FUNCTIONS 	= ./functions.sh
REPO		= $(shell grep url .git/config)
Q 		= @
bold   		= $(shell tput bold)
underline 	= $(shell tput smul)
normal 		= $(shell tput sgr0)
red		= $(shell tput setaf 1)
yellow	 	= $(shell tput setaf 3)

default: help

help:
	$(Q)echo "$(bold)ISLET installation targets:$(normal)"
	$(Q)echo " $(red)install$(normal)                  	- Installs and configures islet"
	$(Q)echo " $(red)uninstall$(normal) 	                - Uninstalls islet ($(yellow)Backup first!$(normal))"
	$(Q)echo " $(red)update$(normal)               		- Update code and reinstall islet"
	$(Q)echo " $(red)mrproper$(normal)                     	- Remove all files not in source distribution"
	$(Q)echo "$(bold)System configuration targets$(bold):$(normal)"
	$(Q)echo " $(red)install-docker$(normal)               	- Install docker ($(normal)$(yellow)Ubuntu only$(normal))"
	$(Q)echo " $(red)user-config$(normal)               	- Configure demo user for islet"
	$(Q)echo " $(red)security-config$(normal)               	- Configure security controls (ulimit, sshd_config)"
	$(Q)echo "$(bold)Miscellaneous targets:$(normal)"
	$(Q)echo " $(red)install-brolive-config$(normal)        	- Install and configure Brolive image"
	$(Q)echo " $(red)logo$(normal)                         	- Print logo to stdout"

install: install-files configuration

install-files:
	$(Q)echo " $(yellow)Installing $(PROG)$(normal)"
	mkdir -m 755 -p $(CONFIG_DIR)
	mkdir -m 755 -p $(LIB_DIR)
	mkdir -m 755 -p $(CRON_DIR)
	mkdir -m 755 -p $(BIN_DIR)
	install -o root -g root -m 644 config/islet.conf $(CONFIG_DIR)/$(PROG).conf
	install -o root -g root -m 644 lib/libislet $(LIB_DIR)/libislet
	install -o root -g root -m 755 bin/islet_shell $(BIN_DIR)/$(PROG)_shell
	install -o root -g root -m 755 bin/islet_login $(BIN_DIR)/$(PROG)_login
	install -o root -g root -m 644 cron/islet.crontab $(CRON)/$(PROG)
	install -o root -g root -m 750 cron/remove_old_containers $(CRON_DIR)/remove_old_containers
	install -o root -g root -m 750 cron/remove_old_users $(CRON_DIR)/remove_old_users
	$(Q)echo " $(bold)--> Configuration directory is$(normal) $(underline)$(CONFIG_DIR)$(normal)"
	$(Q)echo " $(bold)--> Install directory is$(normal) $(underline)$(INSTALL_DIR)$(normal)"

configuration:
	$(Q)echo " $(yellow)Post-install configuration$(normal)"
	sed -i "s|LOCATION|$(CRON_DIR)|g" $(CRON)/$(PROG)
	sed -i "s|LOCATION|$(CONFIG_DIR)/$(PROG).conf|g" $(BIN_DIR)/* $(CRON_DIR)/*

uninstall:
	$(Q)echo " $(yellow)Uninstalling $(PROG)$(normal)"
	rm -rf $(CONFIG_DIR)
	rm -rf $(INSTALL_DIR)
	rm -f $(CRON)/$(PROG)
	rm -f /var/tmp/$(PROG)_db

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

install-brolive-config:
	$(FUNCTIONS) install_sample_configuration
	mkdir -m 755 -p $(CONFIG_DIR)
	install -o root -g root -m 644 extra/brolive.conf $(CONFIG_DIR)/brolive.conf
	$(Q)echo " $(yellow)Try it out: ssh demo@<ip>$(normal)"

install-sample-nsm:
	$(FUNCTIONS) install_nsm_configurations
	mkdir -m 755 -p $(CONFIG_DIR)
	install -o root -g root -m 644 extra/brolive.conf $(CONFIG_DIR)/brolive.conf
	install -o root -g root -m 644 extra/ids.conf $(CONFIG_DIR)/ids.conf
	install -o root -g root -m 644 extra/argus.conf $(CONFIG_DIR)/argus.conf
	install -o root -g root -m 644 extra/tcpdump.conf $(CONFIG_DIR)/tcpdump.conf
	install -o root -g root -m 644 extra/netsniff-ng.conf $(CONFIG_DIR)/netsniff-ng.conf
	install -o root -g root -m 644 extra/sniffer.conf $(CONFIG_DIR)/sniffer.conf
	$(Q)echo " $(yellow)Try it out: ssh demo@<ip>$(normal)"

install-sample-distros:
	$(FUNCTIONS) install_sample_distributions
	mkdir -m 755 -p $(CONFIG_DIR)

install-docker:
	$(FUNCTIONS) install_docker

user-config:
	$(FUNCTIONS) user_configuration

security-config:
	$(FUNCTIONS) security_configuration

logo:
	$(FUNCTIONS) logo
