# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    config.vm.box = "centos/7"
    config.vm.box_version = "2004.01"
    config.vm.provider "virtualbox" do |vb|
       vb.name = "MyCentos7"
       vb.gui = false
    end
    config.vm.provision "shell", path: "init-centos.sh"
end
