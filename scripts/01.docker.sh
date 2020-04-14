#!/usr/bin/bash

yum install -y yum-utils device-mapper-persistent-data lvm2

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# yum list docker-ce --showduplicates | sort -r

yum install docker-ce-18.09.9

mkdir -p /etc/docker

cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors" : [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
EOF

systemctl start docker
systemctl enable docker


docker info | grep Cgroup

vi /usr/lib/systemd/system/docker.service

# 修改如下参数：
# ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --exec-opt native.cgroupdriver=systemd

systemctl daemon-reload
systemctl restart docker
