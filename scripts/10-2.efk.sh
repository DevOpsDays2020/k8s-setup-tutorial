#!/usr/bin/env sh

# 安装EFK（elasticsearch + fluent-bit + kibana）
# elasticsearch和kibana不变，将fluentd替换成fluent-bit

# 替换之前需要清空es的数据，不然会出现final mapping would have more than 1 type: [flb_type, fluentd]"}}}


# 1. 下载fluent-bit yaml文件
cd scripts/addons/fluent-bit

wget https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/fluent-bit-service-account.yaml
wget https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/fluent-bit-role.yaml
wget https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/fluent-bit-role-binding.yaml

wget https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/output/elasticsearch/fluent-bit-configmap.yaml

# 按照自己的机器，修改FLUENT_ELASTICSEARCH_HOST和FLUENT_ELASTICSEARCH_PORT
wget https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/output/elasticsearch/fluent-bit-ds.yaml

# 2. 安装
kubectl apply -f .