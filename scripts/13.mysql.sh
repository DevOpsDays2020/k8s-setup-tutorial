#!/usr/bin/env sh

# 查看参数
helm inspect values stable/mysql

# 修改参数
cat > mysql-values.yaml <<EOF
mysqlRootPassword: password
mysqlUser: root
mysqlPassword: abcd!234
mysqlDatabase: example_db
configurationFiles:
  mysql.cnf: |-
    [mysqld]
    default-time-zone = '+8:00'
EOF

# 安装
helm install -f mysql-values.yaml mysql stable/mysql -n dev

# 添加mysql-pv.yaml

cat > mysql-pv.yaml <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  capacity:
    storage: 8Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/mysql"
EOF

# 升级
# helm upgrade -f mysql-values.yaml mysql stable/mysql -n dev