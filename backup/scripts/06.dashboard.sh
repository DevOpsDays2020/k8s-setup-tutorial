#!/usr/bin/bash

wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta5/aio/deploy/recommended.yaml


kubectl apply -f recommended.yaml


kubectl get pods -n kubernetes-dashboard


kubectl get svc -n kubernetes-dashboard


nohup kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard 4443:443 --address 0.0.0.0 > /opt/k8s/work/dashboard.log 2>&1 &


# 权限
kubectl apply -f dashboard-admin.yaml

kubectl get secret -n kubernetes-dashboard|grep dashboard-admin-token

ADMIN_SECRET=$(kubectl get secrets -n kubernetes-dashboard | grep dashboard-admin-token | awk '{print $1}')
DASHBOARD_LOGIN_TOKEN=$(kubectl get secret ${ADMIN_SECRET} -n kubernetes-dashboard -o jsonpath={.data.token} | base64 -d)
echo ${DASHBOARD_LOGIN_TOKEN}