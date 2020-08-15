#!/usr/bin/env sh

# 使用Helm安装

# 验证
# prometheus-operator-config.yaml 文件参考scripts/addons/prometheus2
helm install -f prometheus-operator-values.yaml --dry-run --debug --generate-name stable/prometheus-operator

# 安装
kubectl create namespace monitoring
helm install -f prometheus-operator-values.yaml prometheus-operator stable/prometheus-operator -n monitoring

# 添加 prometheus-pv.yaml
cat > prometheus-pv.yaml <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: prometheus-pv
  labels:
    app: prometheus-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce # required
  hostPath:
    path: /data/prometheus
EOF

# 更新
helm upgrade -f prometheus-operator-config.yaml prometheus-operator stable/prometheus-operator -n monitoring

# 修改grafana service
kubectl edit svc prometheus-operator-grafana -n monitoring
# spec.type: NodePort
# spec.ports[0].nodePort: 30000

# 删除
helm delete prometheus-operator --purge
kubectl delete customresourcedefinitions prometheuses.monitoring.coreos.com prometheusrules.monitoring.coreos.com servicemonitors.monitoring.coreos.com alertmanagers.monitoring.coreos.com