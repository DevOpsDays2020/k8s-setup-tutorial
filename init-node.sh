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

echo '/sbin/iptables -P FORWARD ACCEPT' >> /etc/rc.local

wget http://mirrors.aliyun.com/repo/Centos-7.repo -O /etc/yum.repos.d/CentOS-Base.repo
wget http://mirrors.aliyun.com/repo/epel-7.repo -O /etc/yum.repos.d/epel.repo
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo