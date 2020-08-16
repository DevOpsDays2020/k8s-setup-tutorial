#!/usr/bin/env sh

# 查看参数
helm inspect values stable/redis

# 验证
helm install --generate-name --dry-run -f redis-values.yaml stable/redis -n dev

# 安装
helm install -f redis-values.yaml redis stable/redis -n dev

# 安装本地pv
kubectl apply -f redis-storage-class.yaml -f redis-local-pv.yaml

# 升级
helm upgrade -f redis-values.yaml redis stable/redis -n dev