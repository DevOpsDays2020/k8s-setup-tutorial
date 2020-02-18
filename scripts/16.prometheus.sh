#!/usr/bin/env bash

cd /opt/k8s/work

echo '下载kube prometheus源码'
git clone https://github.com/coreos/kube-prometheus.git
cd kube-prometheus/
sed -i -e 's_quay.io_quay.azk8s.cn_' manifests/*.yaml manifests/setup/*.yaml # 使用微软的 Registry

echo 'setup'
kubectl apply -f manifests/setup # 安装 prometheus-operator
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
kubectl apply -f manifests/ # 安装 promethes metric adapter

# 删除kubectl资源
#kubectl delete --ignore-not-found=true -f /opt/k8s/work/kube-prometheus/manifests/ -f /opt/k8s/work/kube-prometheus/manifests/setup

echo 'check results'
kubectl get pods -n monitoring

echo '访问访问 Prometheus UI'
echo '启动代理'

#kubectl port-forward --address 0.0.0.0 pod/prometheus-k8s-0 -n monitoring 9090:9090

nohup kubectl port-forward --address 0.0.0.0 pod/prometheus-k8s-0 -n monitoring 9090:9090 > /opt/k8s/work/prometheus.log 2>&1 &
#浏览器访问：http://192.168.56.101:9090/new/graph?g0.expr=&g0.tab=1&g0.stacked=0&g0.range_input=1h


echo '访问 Grafana UI'
echo '启动代理'
#kubectl port-forward --address 0.0.0.0 svc/grafana -n monitoring 3000:3000

nohup kubectl port-forward --address 0.0.0.0 svc/grafana -n monitoring 3000:3000 > /opt/k8s/work/grafana.log 2>&1 &

#浏览器访问：http://192.168.56.101:3000/
#用 admin/admin 登录