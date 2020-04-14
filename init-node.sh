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