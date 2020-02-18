#!/usr/bin/env bash

cd /opt/k8s/work

# 备注：占用内存太大了，虚拟机一直跑不起来

echo '修改配置文件'
cd /opt/k8s/work/kubernetes/cluster/addons/fluentd-elasticsearch
cp fluentd-es-ds.yaml  fluentd-es-ds.yaml.orig

# diff fluentd-es-ds.yaml.orig fluentd-es-ds.yaml
# 105c105
# <           path: /var/lib/docker/containers
# ---
# >           path: /data/k8s/docker/data/containers/


# sed -i -e 's_quay.io_quay.azk8s.cn_' es-statefulset.yaml # 使用微软的 Registry
# sed -i -e 's_quay.io_quay.azk8s.cn_' fluentd-es-ds.yaml # 使用微软的 Registry

# gcr.azk8s.cn 替换 gcr.io

echo '执行'

kubectl apply -f /opt/k8s/work/kubernetes/cluster/addons/fluentd-elasticsearch

# 删除资源
# kubectl delete --ignore-not-found=true -f /opt/k8s/work/kubernetes/cluster/addons/fluentd-elasticsearch

echo '检查执行结果'
kubectl get all -n kube-system |grep -E 'elasticsearch|fluentd|kibana'


kubectl get pod -o wide -n kube-system |grep -E 'elasticsearch|fluentd|kibana'


echo '通过 kubectl proxy 访问 kibana'

echo '创建代理：'
kubectl proxy --address='192.168.56.101' --port=8086 --accept-hosts='^*$'

