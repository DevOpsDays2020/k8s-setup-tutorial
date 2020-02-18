#!/usr/bin/env bash

cd /opt/k8s/work

echo 'download kubectl'
kubernetes_client="/opt/k8s/work/kubernetes-client-linux-amd64.tar.gz"
if [[ ! -f "$kubernetes_client" ]]; then
    # 自行解决翻墙下载问题
    wget https://dl.k8s.io/v1.14.8/kubernetes-client-linux-amd64.tar.gz -P /opt/k8s/work/
fi
tar -xzvf kubernetes-client-linux-amd64.tar.gz

echo '分发到所有使用 kubectl 工具的节点'
for node_name in ${NODE_NAMES[@]}
  do
    echo ">>> ${node_name}"
    scp kubernetes/client/bin/kubectl root@${node_name}:/opt/k8s/bin/
    ssh root@${node_name} "chmod +x /opt/k8s/bin/*"
  done

echo '创建 admin 证书和私钥'
cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "SC",
      "L": "CD",
      "O": "system:masters",
      "OU": "system"
    }
  ]
}
EOF

echo '生成证书和私钥'
cfssl gencert -ca=/opt/k8s/work/ca.pem \
  -ca-key=/opt/k8s/work/ca-key.pem \
  -config=/opt/k8s/work/ca-config.json \
  -profile=kubernetes admin-csr.json | cfssljson -bare admin
ls admin*

echo '创建 kubeconfig 文件'
# 设置集群参数(--server：指定 kube-apiserver 的地址，这里指向第一个节点上的服务)
kubectl config set-cluster kubernetes \
  --certificate-authority=/opt/k8s/work/ca.pem \
  --embed-certs=true \
  --server=https://${NODE_IPS[0]}:6443 \
  --kubeconfig=kubectl.kubeconfig

# 设置客户端认证参数
kubectl config set-credentials admin \
  --client-certificate=/opt/k8s/work/admin.pem \
  --client-key=/opt/k8s/work/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=kubectl.kubeconfig

# 设置上下文参数
kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=admin \
  --kubeconfig=kubectl.kubeconfig

# 设置默认上下文
kubectl config use-context kubernetes --kubeconfig=kubectl.kubeconfig


echo '分发 kubeconfig 文件'

for node_name in ${NODE_NAMES[@]}
  do
    echo ">>> ${node_name}"
    ssh root@${node_name} "mkdir -p ~/.kube"
    scp kubectl.kubeconfig root@${node_name}:~/.kube/config
  done

echo "Configure Kubectl to autocomplete"
source <(kubectl completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.  