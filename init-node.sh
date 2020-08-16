#!/usr/bin/env bash

echo 'set host name resolution'
cat /vagrant/hosts >> /etc/hosts
cat /etc/hosts

echo '/sbin/iptables -P FORWARD ACCEPT' >> /etc/rc.local

cat /vagrant/ipvs.modules > /etc/sysconfig/modules/ipvs.modules
chmod 755 /etc/sysconfig/modules/ipvs.modules && \
  bash /etc/sysconfig/modules/ipvs.modules && \
    lsmod | grep -e ip_vs -e nf_conntrack_ipv4

# for master node
if [[ $1 -eq 1 ]]
then
  echo '### config master node'

  echo '### pull core images'
  kubeadm config images pull --config /vagrant/kubeadm-init.yaml
  docker images

  echo '### kubeadm init'
  kubeadm init --config /vagrant/kubeadm-init.yaml

  echo '### copy kube config'
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  echo '### apply flannel'
  kubectl apply -f /vagrant/kube-flannel.yml

  echo 'master untainted'
  kubectl taint nodes --all node-role.kubernetes.io/master-
fi

if [[ $1 -gt 1 ]]
then
  echo 'Please join to master'
  echo 'script: kubeadm token create --print-join-command'
fi