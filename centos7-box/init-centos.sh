#!/usr/bin/env bash

echo '### update yum repos'
rm /etc/yum.repos.d/CentOS-Base.repo
rm -f /etc/yum.repos.d/epel*.repo
cp /vagrant/yum/*.* /etc/yum.repos.d/
yum clean all
yum makecache fast

echo '### install common libs'
yum install -y git wget curl vim htop \
  epel-release conntrack-tools net-tools telnet tcpdump bind-utils socat \
  ntp chrony kmod ceph-common dos2unix ipvsadm ipset jq iptables bridge-utils libseccomp

echo '### update locale'
cat <<EOF | sudo tee -a /etc/environment
LANG=en_US.utf8
LC_CTYPE=en_US.utf8
EOF

echo '### disable selinux'
setenforce 0
sed -i 's/=enforcing/=disabled/g' /etc/selinux/config

echo '### disable firewalld'
systemctl stop firewalld
systemctl disable firewalld
iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat
iptables -P FORWARD ACCEPT

echo '### disable swap'
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

echo '### optimize linux kernel parameters'
cp /vagrant/sysctl/kubernetes.conf  /etc/sysctl.d/kubernetes.conf
sysctl -p /etc/sysctl.d/kubernetes.conf

echo '### change timezone'
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
timedatectl set-timezone Asia/Shanghai

echo '### sync time'
systemctl enable chronyd
systemctl start chronyd
timedatectl status
timedatectl set-local-rtc 0
systemctl restart rsyslog
systemctl restart crond

echo '### disable useless system server'
systemctl stop postfix && systemctl disable postfix

echo '### install docker'
yum install -y yum-utils device-mapper-persistent-data lvm2
yum -y install docker-ce-18.09.9

mkdir -p /etc/docker
cat /vagrant/docker/daemon.json > /etc/docker/daemon.json
cat /vagrant/systemd/docker.service > /usr/lib/systemd/system/docker.service

echo '### enable docker service'
systemctl daemon-reload
systemctl enable docker
systemctl start docker

echo '### install and enable kubeadm'
yum install -y kubelet-1.16.8 kubeadm-1.16.8 kubectl-1.16.8 --disableexcludes=kubernetes
systemctl enable --now kubelet

echo '### for custom vagrant box'
sudo -u vagrant wget https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -O  /home/vagrant/.ssh/authorized_keys
chmod go-w /home/vagrant/.ssh/authorized_keys
cat /home/vagrant/.ssh/authorized_keys

echo "### permit root login"
/bin/cp -rf /vagrant/ssh/sshd_config /etc/ssh/sshd_config
service sshd restart

echo '### info output'
docker --version
docker info
kubelet --version
kubeadm version
kubectl version




