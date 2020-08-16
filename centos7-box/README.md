## 定制Centos7

```
mkdir -p ~/Documents/vagrant

vagrant up
vagrant halt
vagrant package --base MyCentos7 --output ~/Documents/vagrant/k8s-centos7.box
vagrant box add k8s-centos/7 ~/Documents/vagrant/k8s-centos7.box
vagrant box list

```

## SSH

```
rm -f .vagrant/machines/default/virtualbox/private_key
vagrant ssh
```

## 清理数据

```
vagrant halt && vagrant destroy -f

rm -f ~/Documents/vagrant/k8s-centos7.box
vagrant box remove k8s-centos/7

```