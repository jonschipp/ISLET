.PHONY: default install uninstall update logo

PROG = zookeeper
CONFIGS_DIR = /etc/$(PROG)
SCRIPTS_DIR = /opt/$(PROG)
FUNCTIONS = ./functions.sh
AUTOINSTALL = ./auto-install.sh

default: install

install:
	$(info Installing $(PROG))
	mkdir -m 755 -p $(CONFIGS_DIR)
	mkdir -m 755 -p $(SCRIPTS_DIR)
	install -o root -g root -m 644 config/sandbox.conf $(CONFIGS_DIR)/$(PROG).conf
	install -o root -g root -m 644 scripts/sandbox.cron /etc/cron.d/$(PROG)
	install -o root -g root -m 755 scripts/sandbox_shell $(SCRIPTS_DIR)/bin/$(PROG)_shell
	install -o root -g root -m 755 scripts/sandbox_login $(SCRIPTS_DIR)/bin/$(PROG)_login
	install -o root -g root -m 750 cron/remove_old_containers $(SCRIPTS_DIR)/cron/$(PROG)_${FILE}
	install -o root -g root -m 750 cron/remove_old_user $(SCRIPTS_DIR)/cron/$(PROG)_${FILE}
	$(info Configuration directory is $(CONFIGS_DIR))
	$(info Scripts directory is $(SCRIPTS__DIR))

uninstall:
	rm -rf $(CONFIGS_DIR)
	rm -rf $(SCRIPTS_DIR)
	rm -f /etc/cron.d/$(PROG)

update:
	$(info 1. Getting latest code)
	git checkout master
	git pull
	$(info 2. Installing latest code)
	install 
   
#function docker_configuration() {
 
install-config:
	$(FUNCTIONS) install_configuration_file

install-docker:
	$(FUNCTIONS) install_docker

user-config:
	$(FUNCTIONS) user_configuration

system-config:
	$(FUNCTIONS) system_configuration

logo:
	$(FUNCTIONS) logo
