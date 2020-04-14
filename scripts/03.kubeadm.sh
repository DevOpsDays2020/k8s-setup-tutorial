#!/usr/bin/bash

kubeadm config print init-defaults > kubeadm-init.yaml

## 修改部分参数，参考本目录下的kubeadm.yaml

# 预下载镜像
kubeadm config images pull --config kubeadm-init.yaml

kubeadm init --config kubeadm-init.yaml

# 拷贝 kubeconfig 文件
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 拷贝到其他节点
scp ~/.kube/config root@node2:/root/.kube/config
scp ~/.kube/config root@node3:/root/.kube/config

# worker节点执行join方法
kubeadm join 192.168.56.101:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:0d7aa4c7d406eca5d9a66a3ebb9b213280649093242a386e8b37cc25f4834970


# 下载flannel
wget https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml

kubectl apply -f kube-flannel.yml

kubectl get pods -n kube-system