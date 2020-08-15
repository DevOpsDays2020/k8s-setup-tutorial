#!/usr/bin/env sh

# 使用自定义yaml文件安装EFK（elasticsearch + fluentd + kibana）
# 文件目录scripts/addons/efk

# 参考：https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/fluentd-elasticsearch

# 1. 新建命名空间
kubectl apply -f logging-namespace.yaml

# 2. 创建Elasticsearch集群
kubectl apply -f es-service.yaml es-statefulset.yaml

## pod运行完毕过后，验证
kubectl port-forward es-cluster-0 9200:9200 --namespace=logging
curl http://localhost:9200/_cluster/state?pretty


# 3. 创建Kibana
kubectl apply -f kibana.yaml

## 或者
helm install kibana stable/kibana \
    --set env.ELASTICSEARCH_HOSTS=http://elasticsearch:9200 \
    --namespace logging

# 4. 创建Fluentd
kubectl apply -f fluentd-cm.yaml -f fluentd-daemonset.yaml

## 设置node selector
kubectl label nodes k8s-master beta.kubernetes.io/fluentd-ds-ready="true"




