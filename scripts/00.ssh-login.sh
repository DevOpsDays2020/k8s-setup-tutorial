#!/usr/bin/bash

# 需要人工先登陆所有的虚拟机修改如下参数
# vi /etc/ssh/sshd_config
# PermitRootLogin yes
# PasswordAuthentication yes
# PubkeyAuthentication yes
# service sshd restart

ssh-keygen -t rsa
ssh-copy-id root@node1
ssh-copy-id root@node2
ssh-copy-id root@node3

# 在每个node执行ssh-keygen -t rsa以及ssh-copy-id root@node1之后在node1上执行

cat /root/.ssh/authorized_keys | ssh root@node2 'cat >> /root/.ssh/authorized_keys'
