#!/usr/bin/env sh

# 使用yaml文件安装

# 1. 克隆代码
git clone https://github.com/coreos/kube-prometheus.git

cd kube-prometheus/manifests

# 2. 安装setup目录下的CRD和Operator资源对象

# 如果是单机，修改replicas=1
# 文件有：alertmanager-alertmanager.yaml、prometheus-prometheus.yaml

kubectl apply -f setup/
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done

## 安装node-exporter、kube-state-metrics、grafana、prometheus-adapter 以及 prometheus 和 alertmanager 组件
kubectl apply -f .

## 验证
kubectl get pods -n monitoring
kubectl get svc -n monitoring

## 将 type: ClusterIP 更改为 type: NodePort
## 或者直接修改文件，alertmanager-service.yaml、grafana-service.yaml、prometheus-service.yaml
kubectl edit svc grafana -n monitoring
kubectl edit svc alertmanager-main -n monitoring
kubectl edit svc prometheus-k8s -n monitoring
kubectl get svc -n monitoring

# 添加kube-scheduler、kube-controller、etcd的service monitor，见scripts/addons/prometheus文件夹

# 自定义报警功能，见scripts/addons/prometheus，默认报警规则文件，在pod中的/etc/prometheus/rules/prometheus-k8s-rulefiles-0/monitoring-prometheus-k8s-rules.yaml

# 自动发现k8s service, 需要我们在 Service 的 annotation 区域添加 prometheus.io/scrape=true 的声明，并执行
kubectl create secret generic additional-scrape-configs --from-file=prometheus-additional.yaml -n monitoring

# 修改 prometheus-prometheus.yaml 文件中的 additionalScrapeConfigs 属性
#additionalScrapeConfigs:
#  name: additional-scrape-configs
#  key: prometheus-additional.yaml

# 修改prometheus-clusterRole.yaml, 见addons
kubectl apply -f prometheus-clusterRole.yaml


# 访问grafana，第一次登陆admin:admin
# import 8919、3070


# 删除资源
kubectl delete --ignore-not-found=true -f . -f setup/