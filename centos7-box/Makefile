default: build

build:
	mkdir -p ~/Documents/vagrant
	vagrant up
	vagrant halt
	vagrant package --base MyCentos7 --output ~/Documents/vagrant/k8s-centos7.box
	vagrant box add k8s-centos/7 ~/Documents/vagrant/k8s-centos7.box
	vagrant box list

clean-vagrant:
	vagrant halt && vagrant destroy -f

clean-box:
	rm -f ~/Documents/vagrant/k8s-centos7.box
	vagrant box remove k8s-centos/7

clean: clean-vagrant clean-box