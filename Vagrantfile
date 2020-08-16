# -*- mode: ruby -*-
# vi: set ft=ruby :

$num_instances = 2
$vm_memory = 2048
$vm_cpus = 2

Vagrant.configure("2") do |config|

  config.vm.box_check_update = false
  config.vm.synced_folder "./node-config", "/vagrant", type: "rsync"

  (1..$num_instances).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.box = "k8s-centos/7"
      node.vm.hostname = "node#{i}"
      
      ip = "192.168.56.#{i+100}"
      node.vm.network "private_network", ip: ip
      
      node.vm.provider "virtualbox" do |vb|        
        vb.gui = false
        vb.memory = $vm_memory
        vb.cpus = $vm_cpus
        vb.name = "node#{i}"
      end

      node.vm.provision "shell", path: "init-node.sh", args: [i, ip]
    end
  end
end
