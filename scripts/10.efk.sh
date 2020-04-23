#!/usr/bin/env sh

# 使用自定义Yamls启动EFK（Elasticsearch + Fluentd + Kibana），文件目录scripts/addons/efk

# 新建命名空间
kubectl apply -f logging-namespace.yaml

# 创建Elasticsearch集群

kubectl apply -f es-service.yaml es-statefulset.yaml

## pod运行完毕过后，验证
kubectl port-forward es-cluster-0 9200:9200 --namespace=logging
curl http://localhost:9200/_cluster/state?pretty


# 创建Kibana
kubectl apply -f kibana.yaml

# 创建Fluentd
kubectl apply -f fluentd-cm.yaml fluentd-daemonset.yaml




