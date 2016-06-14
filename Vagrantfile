# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "trusty"
  config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
  config.vm.synced_folder ".", "/islet"

  config.vm.provider "virtualbox" do |vb|
     vb.gui = false
     vb.name = "islet-dev"
     vb.customize ["modifyvm", :id, "--memory", "1024"]
     vb.customize ["modifyvm", :id, "--cpus", 1]
  end

  config.vm.provision "shell", inline: <<-SHELL
    apt-get update -qq
    apt-get install -yq cowsay git make sqlite pv

    if test -d /islet; then
      cd /islet
      make install-docker && ./configure && make logo &&
      make user-config && make install && make security-config && make iptables-config || { printf "ISLET install failed\!\n" && exit 1; }
      make install-sample-nsm-configs
      printf "\nTry it out: ssh -p 2222 demo@127.0.0.1 -o UserKnownHostsFile=/dev/null\n"
    fi
  SHELL

end
