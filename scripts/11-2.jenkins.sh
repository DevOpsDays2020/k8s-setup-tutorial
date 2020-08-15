#!/usr/bin/env sh

# 验证
helm install -f jenkins-values.yaml --dry-run --debug --generate-name stable/jenkins

# 安装
kubectl create namespace kube-ops
helm install -f jenkins-values.yaml jenkins-master stable/jenkins -n kube-ops

# 创建存储
kubectl apply -f jenkins-storage-class.yaml -f jenkins-local-pv.yaml

# 更新
helm upgrade -f jenkins-values.yaml jenkins-master stable/jenkins -n kube-ops


