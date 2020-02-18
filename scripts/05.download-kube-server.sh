#!/usr/bin/env bash

cd /opt/k8s/work

echo '下载kubernetes server'

kubernetes_server_pkg="/opt/k8s/work/kubernetes-server-linux-amd64.tar.gz"
if [[ ! -f "$kubernetes_server_pkg" ]]; then
    # 自行解决翻墙下载问题
    wget https://dl.k8s.io/v1.14.8/kubernetes-server-linux-amd64.tar.gz -P /opt/k8s/work/
fi

tar -xzvf kubernetes-server-linux-amd64.tar.gz
cd kubernetes
tar -xzvf kubernetes-src.tar.gz

echo '将二进制文件拷贝到所有 master 节点'
cd /opt/k8s/work
for node_name in ${NODE_NAMES[@]}
  do
    {
      echo ">>> ${node_name}"
      scp kubernetes/server/bin/{apiextensions-apiserver,cloud-controller-manager,kube-apiserver,kube-controller-manager,kube-proxy,kube-scheduler,kubeadm,kubectl,kubelet,mounter} root@${node_name}:/opt/k8s/bin/
      ssh root@${node_name} "chmod +x /opt/k8s/bin/*"
    }
  done
