#!/usr/bin/bash

cd /opt/k8s/work

etcd_release_pkg="/opt/k8s/work/etcd-v3.3.13-linux-amd64.tar.gz"
if [[ ! -f "$etcd_release_pkg" ]]; then
    # 自行解决翻墙下载问题
    wget https://github.com/coreos/etcd/releases/download/v3.3.13/etcd-v3.3.13-linux-amd64.tar.gz -P /opt/k8s/work/
fi
tar -xvf etcd-v3.3.13-linux-amd64.tar.gz

echo '分发 etcd 二进制文件'
for node_name in ${NODE_NAMES[@]}
  do
    echo ">>> ${node_name}"
    scp etcd-v3.3.13-linux-amd64/etcd* root@${node_name}:/opt/k8s/bin
    ssh root@${node_name} "chmod +x /opt/k8s/bin/*"
  done


echo '创建 etcd 证书和私钥'
cat > etcd-csr.json <<EOF
{
  "CN": "etcd",
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
      "O": "k8s",
      "OU": "system"
    }
  ]
}
EOF

echo '生成证书和私钥'
cfssl gencert -ca=/opt/k8s/work/ca.pem \
    -ca-key=/opt/k8s/work/ca-key.pem \
    -config=/opt/k8s/work/ca-config.json \
    -profile=kubernetes etcd-csr.json | cfssljson -bare etcd
ls etcd*pem

echo '分发生成的证书和私钥到各 etcd 节点'
for node_name in ${NODE_NAMES[@]}
  do
    echo ">>> ${node_name}"
    ssh root@${node_name} "mkdir -p /etc/etcd/cert"
    scp etcd*.pem root@${node_name}:/etc/etcd/cert/
  done

echo '创建 etcd 的 systemd unit 模板文件'

cat > etcd.service.template <<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
WorkingDirectory=${ETCD_DATA_DIR}
ExecStart=/opt/k8s/bin/etcd \\
  --data-dir=${ETCD_DATA_DIR} \\
  --wal-dir=${ETCD_WAL_DIR} \\
  --name=##NODE_NAME## \\
  --cert-file=/etc/etcd/cert/etcd.pem \\
  --key-file=/etc/etcd/cert/etcd-key.pem \\
  --trusted-ca-file=/etc/kubernetes/cert/ca.pem \\
  --peer-cert-file=/etc/etcd/cert/etcd.pem \\
  --peer-key-file=/etc/etcd/cert/etcd-key.pem \\
  --peer-trusted-ca-file=/etc/kubernetes/cert/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --listen-peer-urls=https://##NODE_IP##:2380 \\
  --initial-advertise-peer-urls=https://##NODE_IP##:2380 \\
  --listen-client-urls=https://##NODE_IP##:2379,http://127.0.0.1:2379 \\
  --advertise-client-urls=https://##NODE_IP##:2379 \\
  --initial-cluster-token=etcd-cluster-0 \\
  --initial-cluster=${ETCD_NODES} \\
  --initial-cluster-state=new \\
  --auto-compaction-mode=periodic \\
  --auto-compaction-retention=1 \\
  --max-request-bytes=33554432 \\
  --quota-backend-bytes=6442450944 \\
  --heartbeat-interval=250 \\
  --election-timeout=2000
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF


echo '为各节点创建和分发 etcd systemd unit 文件'
for (( i=0; i < ${CLUSTER_INSTANCES}; i++ ))
  do
    echo ">>> ${NODE_NAMES[i]}"
    sed -e "s/##NODE_NAME##/${NODE_NAMES[i]}/" -e "s/##NODE_IP##/${NODE_IPS[i]}/" etcd.service.template > etcd-${NODE_NAMES[i]}.service
    scp etcd-${NODE_NAMES[i]}.service root@${NODE_NAMES[i]}:/etc/systemd/system/etcd.service
  done

echo '启动 etcd 服务'

for node_name in ${NODE_NAMES[@]}
  do
    echo ">>> ${node_name}"
    ssh root@${node_name} "mkdir -p ${ETCD_DATA_DIR} ${ETCD_WAL_DIR}"
    ssh root@${node_name} "systemctl daemon-reload && systemctl enable etcd && systemctl restart etcd " &
  done

echo '检查启动结果'
for node_name in ${NODE_NAMES[@]}
  do
    echo ">>> ${node_name}"
    ssh root@${node_name} "systemctl status etcd|grep Active"
  done

echo '验证服务状态'
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ETCDCTL_API=3 /opt/k8s/bin/etcdctl \
    --endpoints=https://${node_ip}:2379 \
    --cacert=/etc/kubernetes/cert/ca.pem \
    --cert=/etc/etcd/cert/etcd.pem \
    --key=/etc/etcd/cert/etcd-key.pem endpoint health
  done

echo '查看当前的 leader';
ETCDCTL_API=3 /opt/k8s/bin/etcdctl \
  -w table --cacert=/etc/kubernetes/cert/ca.pem \
  --cert=/etc/etcd/cert/etcd.pem \
  --key=/etc/etcd/cert/etcd-key.pem \
  --endpoints=${ETCD_ENDPOINTS} endpoint status

#echo '清空数据, 重新安装etcd'

#systemctl stop etcd
#rm -rf /data/k8s/etcd/data/
#rm -rf /data/k8s/etcd/wal/
#rm -rf /opt/k8s/work/etcd**
#rm -rf /opt/k8s/bin/etcd**
#rm -rf /etc/etcd/cert/etcd**
#rm -rf /etc/systemd/system/etcd.service

