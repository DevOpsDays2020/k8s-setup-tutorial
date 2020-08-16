#!/usr/bin/env bash

# add docker user
useradd -m docker

echo 'set host name resolution'
cat >> /etc/hosts <<EOF
192.168.50.100 k8s-master
EOF
cat /etc/hosts

echo '/sbin/iptables -P FORWARD ACCEPT' >> /etc/rc.local

wget http://mirrors.aliyun.com/repo/Centos-7.repo -O /etc/yum.repos.d/CentOS-Base.repo
wget http://mirrors.aliyun.com/repo/epel-7.repo -O /etc/yum.repos.d/epel.repo
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo

cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4

# check
lsmod | grep -e ip_vs -e nf_conntrack_ipv4