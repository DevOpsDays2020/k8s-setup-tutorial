#!/usr/bin/env bash

cd /opt/k8s/work

echo '下载和分发 flanneld 二进制文件'

flanneld_pkg="/opt/k8s/work/kubernetes-server-linux-amd64.tar.gz"
if [[ ! -f "$flanneld_pkg" ]]; then
    wget https://github.com/coreos/flannel/releases/download/v0.11.0/flannel-v0.11.0-linux-amd64.tar.gz -P /opt/k8s/work/
fi

mkdir flannel
tar -xzvf flannel-v0.11.0-linux-amd64.tar.gz -C flannel

echo '分发二进制文件到集群所有节点：'

cd /opt/k8s/work
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    scp flannel/{flanneld,mk-docker-opts.sh} root@${node_ip}:/opt/k8s/bin/
    ssh root@${node_ip} "chmod +x /opt/k8s/bin/*"
  done

echo '创建 flannel 证书和私钥'

cat > flanneld-csr.json <<EOF
{
  "CN": "flanneld",
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
      "O": "k8s",
      "OU": "system"
    }
  ]
}
EOF

echo '生成证书和私钥：'

cfssl gencert -ca=/opt/k8s/work/ca.pem \
  -ca-key=/opt/k8s/work/ca-key.pem \
  -config=/opt/k8s/work/ca-config.json \
  -profile=kubernetes flanneld-csr.json | cfssljson -bare flanneld
ls flanneld*pem

echo '将生成的证书和私钥分发到所有节点（master 和 worker）：'

for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ssh root@${node_ip} "mkdir -p /etc/flanneld/cert"
    scp flanneld*.pem root@${node_ip}:/etc/flanneld/cert
  done


echo '向 etcd 写入集群 Pod 网段信息(注意：本步骤只需执行一次)'
/opt/k8s/bin/etcdctl \
  --endpoints=${ETCD_ENDPOINTS} \
  --ca-file=/opt/k8s/work/ca.pem \
  --cert-file=/opt/k8s/work/flanneld.pem \
  --key-file=/opt/k8s/work/flanneld-key.pem \
  mk ${FLANNEL_ETCD_PREFIX}/config '{"Network":"'${CLUSTER_CIDR}'", "SubnetLen": 24, "Backend": {"Type": "vxlan"}}'


echo '创建 flanneld 的 systemd unit 文件'

cat > flanneld.service << EOF
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service

[Service]
Type=notify
ExecStart=/opt/k8s/bin/flanneld \\
  -etcd-cafile=/etc/kubernetes/cert/ca.pem \\
  -etcd-certfile=/etc/flanneld/cert/flanneld.pem \\
  -etcd-keyfile=/etc/flanneld/cert/flanneld-key.pem \\
  -etcd-endpoints=${ETCD_ENDPOINTS} \\
  -etcd-prefix=${FLANNEL_ETCD_PREFIX} \\
  -iface=${IFACE} \\
  -ip-masq
ExecStartPost=/opt/k8s/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker
Restart=always
RestartSec=5
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
EOF


echo '分发 flanneld systemd unit 文件到所有节点'
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    scp flanneld.service root@${node_ip}:/etc/systemd/system/
  done


echo '启动 flanneld 服务'
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ssh root@${node_ip} "systemctl daemon-reload && systemctl enable flanneld && systemctl restart flanneld"
  done  


echo '检查分配给各 flanneld 的 Pod 网段信息'
/opt/k8s/bin/etcdctl \
  --endpoints=${ETCD_ENDPOINTS} \
  --ca-file=/etc/kubernetes/cert/ca.pem \
  --cert-file=/etc/flanneld/cert/flanneld.pem \
  --key-file=/etc/flanneld/cert/flanneld-key.pem \
  get ${FLANNEL_ETCD_PREFIX}/config


echo '查看已分配的 Pod 子网段列表(/24):'
/opt/k8s/bin/etcdctl \
  --endpoints=${ETCD_ENDPOINTS} \
  --ca-file=/etc/kubernetes/cert/ca.pem \
  --cert-file=/etc/flanneld/cert/flanneld.pem \
  --key-file=/etc/flanneld/cert/flanneld-key.pem \
  ls ${FLANNEL_ETCD_PREFIX}/subnets


echo '检查节点 flannel 网络信息'
ip addr show  

ip route show |grep flannel.1


echo '验证各节点能通过 Pod 网段互通'
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ssh ${node_ip} "/usr/sbin/ip addr show flannel.1|grep -w inet"
  done


echo '在各节点上 ping 所有 flannel 接口 IP，确保能通：(上面输出的ip地址)'

# for node_ip in ${NODE_IPS[@]}
#   do
#     echo ">>> ${node_ip}"
#     ssh ${node_ip} "ping -c 1 172.30.47.0"
#     ssh ${node_ip} "ping -c 1 172.30.98.0"
#     ssh ${node_ip} "ping -c 1 172.30.57.0"
#   done  
