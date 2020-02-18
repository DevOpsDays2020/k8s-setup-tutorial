#!/usr/bin/env bash

cd /opt/k8s/work

# echo '下载和配置 coredns'

# git clone https://github.com/coredns/deployment.git
# mv deployment coredns-deployment

# echo '部署'
# cd /opt/k8s/work/coredns-deployment/kubernetes
# ./deploy.sh -i ${CLUSTER_DNS_SVC_IP} -d ${CLUSTER_DNS_DOMAIN} | kubectl apply -f -

cd /opt/k8s/work/kubernetes/cluster/addons/dns/coredns
cp coredns.yaml.base coredns.yaml
source /opt/k8s/bin/environment.sh
sed -i -e "s/__PILLAR__DNS__DOMAIN__/${CLUSTER_DNS_DOMAIN}/" -e "s/__PILLAR__DNS__SERVER__/${CLUSTER_DNS_SVC_IP}/" coredns.yaml

kubectl create -f coredns.yaml


cd /opt/k8s/work
echo '检查 coredns 功能'

kubectl get all -n kube-system -l k8s-app=kube-dns

echo '新建一个 Deployment：'

cat > my-nginx.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      run: my-nginx
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
EOF
kubectl create -f my-nginx.yaml

echo 'export 该 Deployment, 生成 my-nginx 服务'

kubectl expose deploy my-nginx

kubectl get services my-nginx -o wide

echo '创建另一个 Pod'

cat > dnsutils-ds.yml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: dnsutils-ds
  labels:
    app: dnsutils-ds
spec:
  type: NodePort
  selector:
    app: dnsutils-ds
  ports:
  - name: http
    port: 80
    targetPort: 80
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: dnsutils-ds
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  selector:
    matchLabels:
      app: dnsutils-ds
  template:
    metadata:
      labels:
        app: dnsutils-ds
    spec:
      containers:
      - name: my-dnsutils
        image: tutum/dnsutils:latest
        command:
          - sleep
          - "3600"
        ports:
        - containerPort: 80
EOF
kubectl create -f dnsutils-ds.yml

kubectl get pods -lapp=dnsutils-ds -o wide

# 注意下面的pod名称需要替换成自己集群里面的
#kubectl -it exec dnsutils-ds-7h9np  cat /etc/resolv.conf
#
#kubectl -it exec dnsutils-ds-7h9np nslookup kubernetes
#
#kubectl -it exec dnsutils-ds-7h9np nslookup www.baidu.com
#
#kubectl -it exec dnsutils-ds-7h9np nslookup www.baidu.com.
#
#kubectl -it exec dnsutils-ds-7h9np nslookup my-nginx


