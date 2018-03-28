# 创建高可用 etcd 集群

kuberntes 系统使用 etcd 存储所有数据，本文档介绍部署一个三节点高可用 etcd 集群的步骤，这三个节点复用 kubernetes master 机器，分别命名为`master`、`node01`、`node02`：

+ master：192.168.177.132
+ node01：192.168.177.133
+ node02：192.168.177.134

## TLS 认证文件

需要为 etcd 集群创建加密通信的 TLS 证书，这里复用以前创建的 kubernetes 证书，在前面已拷贝证书的话可忽略该步骤。

``` bash
cp ca.pem kubernetes-key.pem kubernetes.pem /etc/kubernetes/ssl
```

+ kubernetes 证书的 `hosts` 字段列表中包含上面三台机器的 IP，否则后续证书校验会失败；

## 下载二进制文件

到 `https://github.com/coreos/etcd/releases` 页面下载最新版本的二进制文件

``` bash
wget https://github.com/coreos/etcd/releases/download/v3.3.2/etcd-v3.3.2-linux-amd64.tar.gz
tar -xvf etcd-v3.3.2-linux-amd64.tar.gz
mv etcd-v3.3.2-linux-amd64/etcd* /usr/local/bin
```

或者直接使用`apt-get`命令安装(推荐使用二进制)：

```bash
yum install etcd
```

若使用`apt-get`安装，默认etcd命令将在`/usr/bin`目录下，注意修改下面`的etcd.service`文件中的启动命令地址为`/usr/bin/etcd`。

## 创建 etcd 的 systemd unit 文件

在/usr/lib/systemd/system/目录下创建文件etcd.service，内容如下。注意替换IP地址为你自己的etcd集群的主机IP。

``` bash
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
ExecStart=/usr/local/bin/etcd \
  --name ${ETCD_NAME} \
  --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
  --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
  --peer-cert-file=/etc/kubernetes/ssl/kubernetes.pem \
  --peer-key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
  --trusted-ca-file=/etc/kubernetes/ssl/ca.pem \
  --peer-trusted-ca-file=/etc/kubernetes/ssl/ca.pem \
  --initial-advertise-peer-urls ${ETCD_INITIAL_ADVERTISE_PEER_URLS} \
  --listen-peer-urls ${ETCD_LISTEN_PEER_URLS} \
  --listen-client-urls ${ETCD_LISTEN_CLIENT_URLS},http://127.0.0.1:2379 \
  --advertise-client-urls ${ETCD_ADVERTISE_CLIENT_URLS} \
  --initial-cluster-token ${ETCD_INITIAL_CLUSTER_TOKEN} \
  --initial-cluster infra1=https://192.168.177.132:2380,infra2=https://192.168.177.133:2380,infra3=https://192.168.177.134:2380 \
  --initial-cluster-state new \
  --data-dir=${ETCD_DATA_DIR}
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

+ 指定 `etcd` 的工作目录为 `/var/lib/etcd`，数据目录为 `/var/lib/etcd`，需在启动服务前创建这个目录，否则启动服务的时候会报错“Failed at step CHDIR spawning /usr/bin/etcd: No such file or directory”；
+ 为了保证通信安全，需要指定 etcd 的公私钥(cert-file和key-file)、Peers 通信的公私钥和 CA 证书(peer-cert-file、peer-key-file、peer-trusted-ca-file)、客户端的CA证书（trusted-ca-file）；
+ 创建 `kubernetes.pem` 证书时使用的 `kubernetes-csr.json` 文件的 `hosts` 字段**包含所有 etcd 节点的IP**，否则证书校验会出错；
+ `--initial-cluster-state` 值为 `new` 时，`--name` 的参数值必须位于 `--initial-cluster` 列表中；

环境变量配置文件`/etc/etcd/etcd.conf`。

```ini
# [member]
ETCD_NAME=infra1
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.177.132:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.177.132:2379"

#[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.177.132:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.177.132:2379"
```

这是`192.168.177.132`节点的配置，其他两个etcd节点只要将上面的IP地址改成相应节点的IP地址即可。ETCD_NAME换成对应节点的infra1/2/3。

## 启动 etcd 服务

``` bash
mv etcd.service /usr/lib/systemd/system/
systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
systemctl status etcd
```

在所有的 kubernetes master 节点重复上面的步骤，直到所有机器的 etcd 服务都已启动。

## 验证服务

在任一 kubernetes master 机器上执行如下命令：

``` bash
root@master:~# etcdctl \
>   --ca-file=/etc/kubernetes/ssl/ca.pem \
>   --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
>   --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
>   cluster-health
member 510a8054e4811df5 is healthy: got healthy result from https://192.168.177.128:2379
member 6ab85ff965367723 is healthy: got healthy result from https://192.168.177.129:2379
member ca4271d155867b44 is healthy: got healthy result from https://192.168.177.130:2379
cluster is healthy

```

结果最后一行为 `cluster is healthy` 时表示集群服务正常(我有我部署了两套集群，有的时候测试输出IP可能会有一点差异)。


**[返回目录](https://github.com/MulticsYin/MulticsKubernetes#kubernetes-%E4%BA%8C%E8%BF%9B%E5%88%B6%E9%83%A8%E7%BD%B2)**  
**[下一章 - 部署master节点](https://github.com/MulticsYin/MulticsKubernetes/blob/master/artcle/006-master-installation.md#%E9%83%A8%E7%BD%B2master%E8%8A%82%E7%82%B9)**
