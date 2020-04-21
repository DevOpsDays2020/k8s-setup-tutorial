#!/usr/bin/env sh

# clone code
git clone https://github.com/coreos/kube-prometheus.git

cd kube-prometheus/manifests

# 安装setup目录下的CRD和Operator资源对象
kubectl apply -f setup/



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


# 添加kube-scheduler和kube-controller的service monitor，见addons文件夹

# 访问grafana，第一次登陆admin:admin

