#!/usr/bin/env bash

cd /opt/k8s/work

echo '创建 kube-scheduler 证书和私钥'

cat > kube-scheduler-csr.json <<EOF
{
    "CN": "system:kube-scheduler",
    "hosts": [
      "127.0.0.1",
      "192.168.56.101",
      "192.168.56.102",
      "192.168.56.103"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "ST": "SC",
        "L": "CD",
        "O": "system:kube-scheduler",
        "OU": "system"
      }
    ]
}
EOF

echo '生成证书和私钥：'

cfssl gencert -ca=/opt/k8s/work/ca.pem \
  -ca-key=/opt/k8s/work/ca-key.pem \
  -config=/opt/k8s/work/ca-config.json \
  -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kube-scheduler
ls kube-scheduler*pem

echo '将生成的证书和私钥分发到所有 master 节点：'

for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    scp kube-scheduler*.pem root@${node_ip}:/etc/kubernetes/cert/
  done


echo '创建和分发 kubeconfig 文件'

kubectl config set-cluster kubernetes \
  --certificate-authority=/opt/k8s/work/ca.pem \
  --embed-certs=true \
  --server="https://##NODE_IP##:6443" \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=kube-scheduler.pem \
  --client-key=kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context system:kube-scheduler \
  --cluster=kubernetes \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig


echo '分发 kubeconfig 到所有 master 节点：'

for (( i=0; i < ${CLUSTER_INSTANCES}; i++ ))
  do
    echo ">>> ${NODE_NAMES[i]}"
    sed -e "s/##NODE_IP##/${NODE_IPS[i]}/" kube-scheduler.kubeconfig > kube-scheduler-${NODE_NAMES[i]}.kubeconfig
    scp kube-scheduler-${NODE_NAMES[i]}.kubeconfig root@${NODE_NAMES[i]}:/etc/kubernetes/kube-scheduler.kubeconfig
  done

echo '创建 kube-scheduler 配置文件'

cat >kube-scheduler.yaml.template <<EOF
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
bindTimeoutSeconds: 600
clientConnection:
  burst: 200
  kubeconfig: "/etc/kubernetes/kube-scheduler.kubeconfig"
  qps: 100
enableContentionProfiling: false
enableProfiling: true
hardPodAffinitySymmetricWeight: 1
healthzBindAddress: ##NODE_IP##:10251
leaderElection:
  leaderElect: true
metricsBindAddress: ##NODE_IP##:10251
EOF

echo '替换模板文件中的变量'

for (( i=0; i < ${CLUSTER_INSTANCES}; i++ ))
  do
    sed -e "s/##NODE_NAME##/${NODE_NAMES[i]}/" -e "s/##NODE_IP##/${NODE_IPS[i]}/" kube-scheduler.yaml.template > kube-scheduler-${NODE_NAMES[i]}.yaml
  done
ls kube-scheduler*.yaml

echo '分发 kube-scheduler 配置文件到所有 master 节点：'

for node_name in ${NODE_NAMES[@]}
  do
    echo ">>> ${node_name}"
    scp kube-scheduler-${node_name}.yaml root@${node_name}:/etc/kubernetes/kube-scheduler.yaml
  done


echo '创建 kube-scheduler systemd unit 模板文件'

cat > kube-scheduler.service.template <<EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
WorkingDirectory=${K8S_DIR}/kube-scheduler
ExecStart=/opt/k8s/bin/kube-scheduler \\
  --config=/etc/kubernetes/kube-scheduler.yaml \\
  --bind-address=##NODE_IP## \\
  --secure-port=10259 \\
  --port=0 \\
  --tls-cert-file=/etc/kubernetes/cert/kube-scheduler.pem \\
  --tls-private-key-file=/etc/kubernetes/cert/kube-scheduler-key.pem \\
  --authentication-kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig \\
  --client-ca-file=/etc/kubernetes/cert/ca.pem \\
  --requestheader-allowed-names="" \\
  --requestheader-client-ca-file=/etc/kubernetes/cert/ca.pem \\
  --requestheader-extra-headers-prefix="X-Remote-Extra-" \\
  --requestheader-group-headers=X-Remote-Group \\
  --requestheader-username-headers=X-Remote-User \\
  --authorization-kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig \\
  --logtostderr=true \\
  --v=2
Restart=always
RestartSec=10
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF

echo '为各节点创建和分发 kube-scheduler systemd unit 文件'

for (( i=0; i < ${CLUSTER_INSTANCES}; i++ ))
  do
    echo ">>> ${NODE_NAMES[i]}"
    sed -e "s/##NODE_NAME##/${NODE_NAMES[i]}/" -e "s/##NODE_IP##/${NODE_IPS[i]}/" kube-scheduler.service.template > kube-scheduler-${NODE_NAMES[i]}.service
    scp kube-scheduler-${NODE_NAMES[i]}.service root@${NODE_NAMES[i]}:/etc/systemd/system/kube-scheduler.service
  done

ls kube-scheduler*.service

echo '启动 kube-scheduler 服务'

for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ssh root@${node_ip} "mkdir -p ${K8S_DIR}/kube-scheduler"
    ssh root@${node_ip} "systemctl daemon-reload && systemctl enable kube-scheduler && systemctl restart kube-scheduler"
  done

echo '检查服务运行状态'

for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ssh root@${node_ip} "systemctl status kube-scheduler|grep Active"
  done

echo '查看输出的 metrics'

sudo netstat -lnpt |grep kube-sch

curl -s http://${NODE_IPS[0]}:10251/metrics |head

curl -s --cacert /opt/k8s/work/ca.pem --cert /opt/k8s/work/admin.pem --key /opt/k8s/work/admin-key.pem https://${NODE_IPS[0]}:10259/metrics |head

echo '查看当前的 leader'

kubectl get endpoints kube-scheduler --namespace=kube-system  -o yaml
