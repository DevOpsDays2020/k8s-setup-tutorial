#!/usr/bin/env bash

cd /opt/k8s/work

echo '检查节点状态'
kubectl get nodes

echo '创建测试文件'

cat > nginx-ds.yml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: nginx-ds
  labels:
    app: nginx-ds
spec:
  type: NodePort
  selector:
    app: nginx-ds
  ports:
  - name: http
    port: 80
    targetPort: 80
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nginx-ds
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  selector:
    matchLabels:
      app: nginx-ds
  template:
    metadata:
      labels:
        app: nginx-ds
    spec:
      containers:
      - name: my-nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
EOF

echo '执行测试'
kubectl create -f nginx-ds.yml

echo '检查各节点的 Pod IP 连通性'
kubectl get pods  -o wide -l app=nginx-ds

# 使用上面每个pod的ip地址
#for node_ip in ${NODE_IPS[@]}
#  do
#    echo ">>> ${node_ip}"
#    ssh ${node_ip} "ping -c 1 172.30.166.134"
#    ssh ${node_ip} "ping -c 1 172.30.104.4"
#    ssh ${node_ip} "ping -c 1 172.30.135.3"
#  done

echo '检查服务 IP 和端口可达性'
kubectl get svc -l app=nginx-ds

# 使用CLUSTER-IP
#for node_ip in ${NODE_IPS[@]}
#  do
#    echo ">>> ${node_ip}"
#    ssh ${node_ip} "curl -s 10.254.102.126"
#  done


echo '检查服务的 NodePort 可达性'

# 32300是nginx映射到node的端口
#for node_ip in ${NODE_IPS[@]}
#  do
#    echo ">>> ${node_ip}"
#    ssh ${node_ip} "curl -s ${node_ip}:32300"
#  done