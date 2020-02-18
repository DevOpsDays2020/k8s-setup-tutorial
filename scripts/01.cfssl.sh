#!/usr/bin/env bash

sudo mkdir -p /opt/k8s/cert /vagrant/tools && cd /opt/k8s/work

echo '安装 cfssl 工具集合'

cfssl="/opt/k8s/work/cfssl_1.4.1_linux_amd64"
if [[ ! -f "$cfssl" ]]; then
    wget https://github.com/cloudflare/cfssl/releases/download/v1.4.1/cfssl_1.4.1_linux_amd64 -P /opt/k8s/work/
fi

cfssljson="/opt/k8s/work/cfssljson_1.4.1_linux_amd64"
if [[ ! -f "$cfssljson" ]]; then
    wget https://github.com/cloudflare/cfssl/releases/download/v1.4.1/cfssljson_1.4.1_linux_amd64 -P /opt/k8s/work/
fi

cfsslcert="/opt/k8s/work/cfssl-certinfo_1.4.1_linux_amd64"
if [[ ! -f "$cfsslcert" ]]; then
    wget https://github.com/cloudflare/cfssl/releases/download/v1.4.1/cfssl-certinfo_1.4.1_linux_amd64 -P /opt/k8s/work/
fi

mv cfssl_1.4.1_linux_amd64 /opt/k8s/bin/cfssl
mv cfssljson_1.4.1_linux_amd64 /opt/k8s/bin/cfssljson
mv cfssl-certinfo_1.4.1_linux_amd64 /opt/k8s/bin/cfssl-certinfo
chmod +x /opt/k8s/bin/*

echo '创建配置文件'
cd /opt/k8s/work
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "876000h"
      }
    }
  }
}
EOF

echo '创建证书签名请求文件'
cd /opt/k8s/work
cat > ca-csr.json <<EOF
{
  "CN": "kubernetes-ca",
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
  ],
  "ca": {
    "expiry": "876000h"
 }
}
EOF

echo '生成 CA 证书和私钥'
cd /opt/k8s/work
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
ls ca*

echo '分发证书文件'
cd /opt/k8s/work
for node_name in ${NODE_NAMES[@]}
  do
    echo ">>> ${node_name}"
    ssh root@${node_name} "mkdir -p /etc/kubernetes/cert"
    scp ca*.pem ca-config.json root@${node_name}:/etc/kubernetes/cert
  done

