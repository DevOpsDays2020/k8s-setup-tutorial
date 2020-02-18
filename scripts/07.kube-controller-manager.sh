#!/usr/bin/env bash

cd /opt/k8s/work

echo '创建 kube-controller-manager 证书和私钥'

cat > kube-controller-manager-csr.json <<EOF
{
    "CN": "system:kube-controller-manager",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "hosts": [
      "127.0.0.1",
      "192.168.56.101",
      "192.168.56.102",
      "192.168.56.103"
    ],
    "names": [
      {
        "C": "CN",
        "ST": "SC",
        "L": "CD",
        "O": "system:kube-controller-manager",
        "OU": "system"
      }
    ]
}
EOF


echo '生成证书和私钥：'

cfssl gencert -ca=/opt/k8s/work/ca.pem \
  -ca-key=/opt/k8s/work/ca-key.pem \
  -config=/opt/k8s/work/ca-config.json \
  -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
ls kube-controller-manager*pem

echo '将生成的证书和私钥分发到所有 master 节点：'

for node_name in ${NODE_NAMES[@]}
  do
    echo ">>> ${node_name}"
    scp kube-controller-manager*.pem root@${node_name}:/etc/kubernetes/cert/
  done


echo '创建和分发 kubeconfig 文件'

kubectl config set-cluster kubernetes \
  --certificate-authority=/opt/k8s/work/ca.pem \
  --embed-certs=true \
  --server="https://##NODE_IP##:6443" \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=kube-controller-manager.pem \
  --client-key=kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context system:kube-controller-manager \
  --cluster=kubernetes \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig


echo '分发 kubeconfig 到所有 master 节点：'

for (( i=0; i < ${CLUSTER_INSTANCES}; i++ ))
  do
    echo ">>> ${NODE_NAMES[i]}"
    sed -e "s/##NODE_IP##/${NODE_IPS[i]}/" kube-controller-manager.kubeconfig > kube-controller-manager-${NODE_NAMES[i]}.kubeconfig
    scp kube-controller-manager-${NODE_NAMES[i]}.kubeconfig root@${NODE_NAMES[i]}:/etc/kubernetes/kube-controller-manager.kubeconfig
  done


echo '创建 kube-controller-manager systemd unit 模板文件'

cat > kube-controller-manager.service.template <<EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
WorkingDirectory=${K8S_DIR}/kube-controller-manager
ExecStart=/opt/k8s/bin/kube-controller-manager \\
  --profiling \\
  --cluster-name=kubernetes \\
  --controllers=*,bootstrapsigner,tokencleaner \\
  --kube-api-qps=1000 \\
  --kube-api-burst=2000 \\
  --leader-elect \\
  --use-service-account-credentials\\
  --concurrent-service-syncs=2 \\
  --bind-address=##NODE_IP## \\
  --secure-port=10252 \\
  --tls-cert-file=/etc/kubernetes/cert/kube-controller-manager.pem \\
  --tls-private-key-file=/etc/kubernetes/cert/kube-controller-manager-key.pem \\
  --port=0 \\
  --authentication-kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \\
  --client-ca-file=/etc/kubernetes/cert/ca.pem \\
  --requestheader-allowed-names="aggregator" \\
  --requestheader-client-ca-file=/etc/kubernetes/cert/ca.pem \\
  --requestheader-extra-headers-prefix="X-Remote-Extra-" \\
  --requestheader-group-headers=X-Remote-Group \\
  --requestheader-username-headers=X-Remote-User \\
  --authorization-kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \\
  --cluster-signing-cert-file=/etc/kubernetes/cert/ca.pem \\
  --cluster-signing-key-file=/etc/kubernetes/cert/ca-key.pem \\
  --experimental-cluster-signing-duration=876000h \\
  --horizontal-pod-autoscaler-sync-period=10s \\
  --concurrent-deployment-syncs=10 \\
  --concurrent-gc-syncs=30 \\
  --node-cidr-mask-size=24 \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --pod-eviction-timeout=6m \\
  --terminated-pod-gc-threshold=10000 \\
  --root-ca-file=/etc/kubernetes/cert/ca.pem \\
  --service-account-private-key-file=/etc/kubernetes/cert/ca-key.pem \\
  --kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \\
  --logtostderr=true \\
  --v=2
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF


echo '为各节点创建和分发 kube-controller-mananger systemd unit 文件'

for (( i=0; i < ${CLUSTER_INSTANCES}; i++ ))
  do
    sed -e "s/##NODE_NAME##/${NODE_NAMES[i]}/" -e "s/##NODE_IP##/${NODE_IPS[i]}/" kube-controller-manager.service.template > kube-controller-manager-${NODE_NAMES[i]}.service
  done
ls kube-controller-manager*.service

echo '分发到所有 master 节点：'

for node_name in ${NODE_NAMES[@]}
  do
    echo ">>> ${node_name}"
    scp kube-controller-manager-${node_name}.service root@${node_name}:/etc/systemd/system/kube-controller-manager.service
  done

echo '启动 kube-controller-manager 服务'

for node_name in ${NODE_NAMES[@]}
  do
    echo ">>> ${node_name}"
    ssh root@${node_name} "mkdir -p ${K8S_DIR}/kube-controller-manager"
    ssh root@${node_name} "systemctl daemon-reload && systemctl enable kube-controller-manager && systemctl restart kube-controller-manager"
  done


echo '检查服务运行状态'

for node_name in ${NODE_NAMES[@]}
  do
    echo ">>> ${node_name}"
    ssh root@${node_name} "systemctl status kube-controller-manager|grep Active"
  done

sudo netstat -lnpt | grep kube-cont

echo '查看输出的 metrics'

curl -s --cacert /opt/k8s/work/ca.pem --cert /opt/k8s/work/admin.pem --key /opt/k8s/work/admin-key.pem https://${NODE_IPS[0]}:10252/metrics |head

echo '查看当前的 leader'

kubectl get endpoints kube-controller-manager --namespace=kube-system  -o yaml
