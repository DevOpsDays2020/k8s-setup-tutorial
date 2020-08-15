#!/usr/bin/env sh

git clone https://github.com/kubernetes-incubator/metrics-server

cd metrics-server/deploy/kubernetes

# 无法科学上网的话修改metrics-server-deployment.yaml的镜像仓库地址

# k8s.gcr.io/metrics-server:v0.3.6 ==> registry.cn-hangzhou.aliyuncs.com/google_containers/metrics-server-amd64:v0.3.6


# 修改启动参数: metrics-server-deployment.yaml
#args:
#- --cert-dir=/tmp
#- --secure-port=4443
#- --kubelet-insecure-tls # 解决ip请求没有证书问题，跳过
#- --kubelet-preferred-address-types=InternalIP # 解决pod内部node的hostname问题

# 安装
kubectl apply -f .

# 验证
kubectl get apiservice | grep metrics
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes"

kubectl top nodes
kubectl top pods
