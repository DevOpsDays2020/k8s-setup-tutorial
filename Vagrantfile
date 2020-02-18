# -*- mode: ruby -*-
# vi: set ft=ruby :

$num_instances = 3
$vm_gui = false
$vm_memory = 4096
$vm_cpus = 1

Vagrant.configure("2") do |config|
  config.vm.box_check_update = false

  config.vm.synced_folder "./scripts", "/vagrant", type: "rsync"

  (1..$num_instances).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.box = "myCentos7"
      node.vm.hostname = "node#{i}"
      
      ip = "192.168.56.#{i+100}"
      node.vm.network "private_network", ip: ip
      
      node.vm.provider "virtualbox" do |vb|        
        vb.gui = $vm_gui
        vb.memory = $vm_memory
        vb.cpus = $vm_cpus
        vb.name = "node#{i}"
      end

      node.vm.provision "shell", path: "init-node.sh"
    end
  end
end
