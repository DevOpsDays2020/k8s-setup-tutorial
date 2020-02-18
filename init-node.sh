#!/usr/bin/env bash

# add docker user
useradd -m docker

echo 'set host name resolution'
cat >> /etc/hosts <<EOF
192.168.56.101 node1
192.168.56.102 node2
192.168.56.103 node3
EOF
cat /etc/hosts

echo 'create k8s directory'
mkdir -p /opt/k8s/{bin,work} /etc/{kubernetes,etcd}/cert

cp /vagrant/environment.sh /opt/k8s/bin
chmod +x /opt/k8s/bin/*

echo 'update root bashrc'
echo 'source /opt/k8s/bin/environment.sh' >> /root/.bashrc
source /root/.bashrc

echo '/sbin/iptables -P FORWARD ACCEPT' >> /etc/rc.local