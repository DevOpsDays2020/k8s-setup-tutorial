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


ssh root@node2 "mkdir -p /etc/kubernetes/pki/etcd"
scp /etc/kubernetes/pki/ca.* root@node2:/etc/kubernetes/pki/
scp /etc/kubernetes/pki/sa.* root@node2:/etc/kubernetes/pki/
scp /etc/kubernetes/pki/front-proxy-ca.* root@node2:/etc/kubernetes/pki/
scp /etc/kubernetes/pki/etcd/ca.* root@node2:/etc/kubernetes/pki/etcd/
scp /etc/kubernetes/admin.conf root@node2:/etc/kubernetes/

# node2 加入到master节点
kubeadm join 192.168.56.101:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:4ca68042acf53047772dc21e036c130692c3b140262d751adbe438aefd85fc3a \
    --control-plane

# node3 加入到worker节点
kubeadm join 192.168.56.101:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:4ca68042acf53047772dc21e036c130692c3b140262d751adbe438aefd85fc3a

# token有效期是有限的，如果旧的token过期，可以使用 kubeadm token create --print-join-command重新创建一条token

# 下载flannel
wget https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml

kubectl apply -f kube-flannel.yml

kubectl get pods -n kube-system

# master节点污点问题
kubectl taint nodes --all node-role.kubernetes.io/master-