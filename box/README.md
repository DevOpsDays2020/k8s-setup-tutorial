## 自定义 Centos Vagrant Box

### 1. 手动添加centos/7 box

```
wget http://mirrors.ustc.edu.cn/centos-cloud/centos/7/vagrant/x86_64/images/CentOS-7-x86_64-Vagrant-1801_02.VirtualBox.box

vagrant box add CentOS-7-x86_64-Vagrant-1801_02.VirtualBox.box --name centos/7
```

### 2. 编辑Vagrantfile，并启动
```
vagrant up
```

### 3. 还原认证信息(不然打包出来的box无法下次使用)

```

sudo -u vagrant wget https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -O  /home/vagrant/.ssh/authorized_keys

chmod go-w /home/vagrant/.ssh/authorized_keys
```


```
pub key:
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
```

### 4. 本地宿主机上打包vagrant box（主要是用来做分布式基础包，免得每个环境都需要下载依赖）

```
vagrant halt

mkdir -p ~/Documents/vagrant/
vagrant package --base myCentos7 --output ~/Documents/vagrant/myCentos7.box

vagrant box add myCentos7 ~/Documents/vagrant/myCentos7.box
```