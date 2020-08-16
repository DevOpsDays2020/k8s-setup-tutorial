#!/usr/bin/env sh

# 1. 克隆代码
git clone https://github.com/amuguelove/kubernetes-yamls.git

# 2. 执行代码
cd kubernetes-yamls/jenkins

kubectl apply -f .

