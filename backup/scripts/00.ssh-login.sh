#!/usr/bin/bash

# 需要人工先登陆所有的虚拟机修改如下参数
# vi /etc/ssh/sshd_config

# PermitRootLogin yes
# PasswordAuthentication yes
# PubkeyAuthentication yes

# service sshd restart

# 在每个node执行
# ssh-keygen -t rsa
# ssh-copy-id root@node1

# 之后将node1中的authorized_keys拷贝到其他节点
# cat /root/.ssh/authorized_keys | ssh root@node2 'cat > /root/.ssh/authorized_keys'
# cat /root/.ssh/authorized_keys | ssh root@node3 'cat > /root/.ssh/authorized_keys'

kubeadm join 192.168.56.101:6443 --token abcdef.0123456789abcdef \
  --discovery-token-ca-cert-hash sha256:07e894f408e08a7a767fdbd9153642e29d4c960dfaa0ff9939393b181d4571f7