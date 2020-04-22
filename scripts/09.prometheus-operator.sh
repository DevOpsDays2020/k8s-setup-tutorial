#!/usr/bin/env sh

# clone code
git clone https://github.com/coreos/kube-prometheus.git

cd kube-prometheus/manifests

# 安装setup目录下的CRD和Operator资源对象
kubectl apply -f setup/
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done

# 安装node-exporter、kube-state-metrics、grafana、prometheus-adapter 以及 prometheus 和 alertmanager 组件
kubectl apply -f .


# 如果是单机，修改replicas=1
# 文件有：alertmanager-alertmanager.yaml、prometheus-prometheus.yaml


# 验证
kubectl get pods -n monitoring
kubectl get svc -n monitoring

# 将 type: ClusterIP 更改为 type: NodePort
kubectl edit svc grafana -n monitoring
kubectl edit svc alertmanager-main -n monitoring
kubectl edit svc prometheus-k8s -n monitoring
kubectl get svc -n monitoring

# 或者直接修改文件，alertmanager-service.yaml、grafana-service.yaml、prometheus-service.yaml


# 添加kube-scheduler和kube-controller的service monitor，见addons文件夹
# 添加etcd的monitor，参考addons文件夹

# 访问grafana，第一次登陆admin:admin
# import 8919、3070

# kubectl exec -it prometheus-k8s-0 /bin/sh -n monitoring
# /etc/prometheus/rules/prometheus-k8s-rulefiles-0/  报警规则文件
# monitoring-prometheus-k8s-rules.yaml

# 自定义报警，参考addons文件夹


# 自动发现k8s service, 需要我们在 Service 的 annotation 区域添加 prometheus.io/scrape=true 的声明，并执行

kubectl create secret generic additional-configs --from-file=prometheus-additional.yaml -n monitoring

# 修改 prometheus-prometheus.yaml 文件中的 additionalScrapeConfigs 属性
additionalScrapeConfigs:
  name: additional-configs
  key: prometheus-additional.yaml

# 修改prometheus-clusterRole.yaml, 见addons
kubectl apply -f prometheus-clusterRole.yaml

# 删除资源
kubectl delete --ignore-not-found=true -f . -f setup/