.PHONY: default install uninstall update logo

PROG = zookeeper
CONFIGS_DIR = /etc/$(PROG)
SCRIPTS_DIR = /opt/$(PROG)
CRON = /etc/cron.d
CRON_DIR = $(SCRIPTS_DIR)/cron
BIN_DIR = $(SCRIPTS_DIR)/bin
FUNCTIONS = ./functions.sh
AUTOINSTALL = ./auto-install.sh

default: install

install:
	$(info Installing $(PROG))
	mkdir -m 755 -p $(CONFIGS_DIR)
	mkdir -m 755 -p $(SCRIPTS_DIR)
	install -o root -g root -m 644 config/sandbox.conf $(CONFIGS_DIR)/$(PROG).conf
	install -o root -g root -m 644 scripts/sandbox.cron $(CRON)/$(PROG)
	sed -i "s|LOCATION|$(CRON_DIR)|g" $(CRON)/$(PROG)
	install -o root -g root -m 755 scripts/sandbox_shell $(BIN_DIR)/$(PROG)_shell
	install -o root -g root -m 755 scripts/sandbox_login $(BIN_DIR)/$(PROG)_login
	install -o root -g root -m 750 cron/remove_old_containers $(CRON_DIR)/remove_old_containers.sh
	install -o root -g root -m 750 cron/remove_old_user $(CRON_DIR)/remove_old_users.sh
	$(info Configuration directory is $(CONFIGS_DIR))
	$(info Scripts directory is $(SCRIPTS__DIR))

uninstall:
	rm -rf $(CONFIGS_DIR)
	rm -rf $(SCRIPTS_DIR)
	rm -f $(CRON)/$(PROG)

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
