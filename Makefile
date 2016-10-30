.PHONY: default help install uninstall pull update logo mrproper package

PROG 		= islet
VERSION		= 1.0.0
CONFIG_DIR 	= /etc/$(PROG)
INSTALL_DIR 	= /opt/$(PROG)
LIB_DIR		= $(INSTALL_DIR)/lib
BIN_DIR 	= $(INSTALL_DIR)/bin
PLUGIN_DIR 	= $(INSTALL_DIR)/plugins
MODULE_DIR	= $(INSTALL_DIR)/modules
MAN_DIR 	= /usr/share/man
FUNCTIONS 	= ./functions.sh
USER		= demo
PASS		= demo
GROUP		= islet
IPTABLES	= /etc/network/if-pre-up.d/iptables-rules
UPSTART  	= /etc/init
REPO		= $(shell grep url .git/config)
PACKAGE		= deb
Q 		= @
bold   		= $(shell tput bold)
underline 	= $(shell tput smul)
normal 		= $(shell tput sgr0)
red		= $(shell tput setaf 1)
yellow	 	= $(shell tput setaf 3)

default: help

help:
	$(Q)echo "$(bold)ISLET (v$(VERSION)) installation targets:$(normal)"
	$(Q)echo " $(red)install$(normal)                  	- Install and configure islet on the host"
	$(Q)echo " $(red)install-contained$(normal)    		- Install islet as container, with little modification to host"
	$(Q)echo " $(red)uninstall$(normal) 	                - Uninstalls islet ($(yellow)Backup first!$(normal))"
	$(Q)echo " $(red)update$(normal)               		- Update code and reinstall islet"
	$(Q)echo " $(red)mrproper$(normal)                     	- Remove all files not in source distribution"
	$(Q)echo "$(bold)System configuration targets$(bold):$(normal)"
	$(Q)echo " $(red)user-config$(normal)               	- Configure demo user for islet"
	$(Q)echo " $(red)security-config$(normal)               	- Configure security controls (sshd_config)"
	$(Q)echo " $(red)iptables-config$(normal)               	- Install iptables rules (def: /etc/network/if-pre-up.d/)"
	$(Q)echo "$(bold)Miscellaneous targets:$(normal)"
	$(Q)echo " $(red)install-brolive-config$(normal)        	- Install and configure Brolive image"
	$(Q)echo " $(red)template$(normal)                       - Print ISLET config template to stdout"
	$(Q)echo " $(red)package$(normal)                        - Create package from an ISLET installation (def: deb)"
	$(Q)echo " $(red)logo$(normal)                         	- Print logo to stdout"

install: install-files configuration

install-contained:
	$(Q)echo " $(yellow)Installing $(PROG)$(normal)"
	mkdir -m 755 -p $(CONFIG_DIR)
	install -o 0 -g 0 -m 644 config/islet.conf $(CONFIG_DIR)/$(PROG).conf
	sed -i.bu "s|ISLETVERS|$(VERSION)|" $(CONFIG_DIR)/islet.conf
	sed -i.bu "s|USERACCOUNT|$(USER)|g" $(CONFIG_DIR)/islet.conf
	rm -f *.bu
	docker run -d --name="islet" \
								-v /usr/bin/docker:/usr/bin/docker:ro \
								-v /var/lib/docker/:/var/lib/docker:rw \
								-v /sbin/iptables:/sbin/iptables:ro \
								-v /sbin/sysctl:/sbin/sysctl:ro \
								-v /exercises:/exercises:ro \
								-v /etc/islet:/etc/islet:ro \
								-v /var/run/docker.sock:/var/run/docker.sock \
								--cap-add=NET_ADMIN \
								-p $(PORT):22 jonschipp/islet
	install -o 0 -g 0 -m 644 config/islet.upstart $(UPSTART)/islet.conf
	$(Q)echo " $(bold)--> Connect to ISLET on $(normal)$(underline)SSH port $(PORT)$(normal)"

install-files:
	$(Q)echo " $(yellow)Installing $(PROG)$(normal)"
	mkdir -m 755 -p $(CONFIG_DIR)/modules $(CONFIG_DIR)/environments $(CONFIG_DIR)/plugins
	mkdir -m 755 -p $(LIB_DIR) $(BIN_DIR) $(PLUGIN_DIR) $(MODULE_DIR)
	install -o 0 -g 0 -m 644 config/islet.conf $(CONFIG_DIR)/
	install -o 0 -g 0 -m 644 config/plugins/*.conf $(CONFIG_DIR)/plugins/
	install -o 0 -g 0 -m 644 config/modules/*.conf $(CONFIG_DIR)/modules/
	install -o 0 -g 0 -m 644 lib/libislet $(LIB_DIR)/libislet
	install -o 0 -g 0 -m 755 bin/islet_shell $(BIN_DIR)/$(PROG)_shell
	install -o 0 -g 0 -m 755 bin/isletd $(BIN_DIR)/$(PROG)d
	install -o 0 -g 0 -m 755 plugins/* $(PLUGIN_DIR)/
	install -o 0 -g 0 -m 755 modules/* $(MODULE_DIR)/
	install -o 0 -g 0 -m 644 docs/islet.5 $(MAN_DIR)/man5/islet.5
	$(Q)echo " $(bold)--> Configuration directory is$(normal) $(underline)$(CONFIG_DIR)$(normal)"
	$(Q)echo " $(bold)--> Install directory is$(normal) $(underline)$(INSTALL_DIR)$(normal)"

configuration:
	$(Q)echo " $(yellow)Post-install configuration$(normal)"
	sed -i.bu "s|ISLETVERS|$(VERSION)|" $(CONFIG_DIR)/islet.conf
	sed -i.bu "s|USERACCOUNT|$(USER)|g" $(CONFIG_DIR)/islet.conf
	sed -i.bu "s|LOCATION|$(CONFIG_DIR)/$(PROG).conf|g" $(BIN_DIR)/*
	rm -f $(CONFIG_DIR)/*.bu $(BIN_DIR)/*.bu

uninstall:
	$(Q)echo " $(yellow)Uninstalling $(PROG)$(normal)"
	rm -rf $(CONFIG_DIR)
	rm -rf $(INSTALL_DIR)
	rm -f /var/tmp/$(PROG)_db
	rm -f /etc/security/limits.d/islet.conf
	rm -f $(MAN_DIR)/man5/islet.5
	fgrep -q $(USER) /etc/passwd && userdel -r $(USER) || true
	fgrep -q $(GROUP) /etc/group && groupdel $(GROUP)  || true

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
	mkdir -m 755 -p $(CONFIG_DIR)/environments
	install -o 0 -g 0 -m 644 extra/brolive.conf $(CONFIG_DIR)/environments/brolive.conf
	$(Q)echo " $(yellow)Try it out: ssh demo@<ip>$(normal)"

install-sample-nsm: install-sample-nsm-configs
	$(FUNCTIONS) install_nsm_configurations
	$(Q)echo " $(yellow)Try it out: ssh demo@<ip>$(normal)"

install-sample-nsm-configs:
	mkdir -m 755 -p $(CONFIG_DIR)
	install -o 0 -g 0 -m 644 extra/brolive.conf $(CONFIG_DIR)/environments/brolive.conf
	install -o 0 -g 0 -m 644 extra/ids.conf $(CONFIG_DIR)/environments/ids.conf
	install -o 0 -g 0 -m 644 extra/argus.conf $(CONFIG_DIR)/environments/argus.conf
	install -o 0 -g 0 -m 644 extra/tcpdump.conf $(CONFIG_DIR)/environments/tcpdump.conf
	install -o 0 -g 0 -m 644 extra/netsniff-ng.conf $(CONFIG_DIR)/environments/netsniff-ng.conf
	install -o 0 -g 0 -m 644 extra/volatility.conf $(CONFIG_DIR)/environments/volatility.conf
	install -o 0 -g 0 -m 644 extra/sagan.conf $(CONFIG_DIR)/environments/sagan.conf

install-sample-distros:
	$(FUNCTIONS) install_sample_distributions
	mkdir -m 755 -p $(CONFIG_DIR)/environments

install-sample-cadvisor:
	docker run -d -v /var/run:/var/run:rw -v /sys:/sys:ro -v /var/lib/docker/:/var/lib/docker:ro -p 8080:8080 --name="cadvisor" google/cadvisor:latest
	install -o 0 -g 0 -m 644 extra/cadvisor.upstart $(UPSTART)/cadvisor.conf

install-docker:
	$(FUNCTIONS) install_docker

user-config:
	$(FUNCTIONS) user_configuration $(USER) $(PASS) $(GROUP) $(BIN_DIR)/$(PROG)_shell

security-config:
	$(FUNCTIONS) security_configuration $(USER) $(BIN_DIR)/$(PROG)_shell

bro-training: install user-config security-config install-docker install-brolive-config

iptables-config:
	install -o 0 -g 0 -m 750 extra/iptables-rules $(IPTABLES)
	$(IPTABLES)

package:
	$(Q)! command -v fpm 1>/dev/null && echo "$(yellow)fpm is not installed or in PATH, try \`\`gem install fpm''.$(normal)" \
	|| fpm -s dir -t $(PACKAGE) -n "islet" -v $(VERSION) /etc/islet /opt/islet \

logo:
	$(FUNCTIONS) logo

template:
	$(Q) $(FUNCTIONS) template
