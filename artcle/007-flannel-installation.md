## 安装flannel网络插件

所有的node节点都需要安装网络插件才能让所有的Pod加入到同一个局域网中，本文是安装flannel网络插件的参考文档。

直接使用二进制安装flanneld，在此安装的是0.10.0版本的flannel。

下载flannel二进制版本：
```bash
$ wget https://github.com/coreos/flannel/releases/download/v0.10.0/flannel-v0.10.0-linux-amd64.tar.gz
$ tar -zxvf flannel-v0.10.0-linux-amd64.tar.gz
$ cd flannel-v0.10.0-linux-amd64
$ mv flanneld  mk-docker-opts.sh /usr/local/bin
```

service配置文件`/usr/lib/systemd/system/flanneld.service`。

```ini
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/flanneld
EnvironmentFile=-/etc/sysconfig/docker-network
ExecStart=/usr/bin/flanneld-start \
  -etcd-endpoints=${FLANNEL_ETCD_ENDPOINTS} \
  -etcd-prefix=${FLANNEL_ETCD_PREFIX} \
  $FLANNEL_OPTIONS
ExecStartPost=/usr/libexec/flannel/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker
Restart=on-failure

[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
```

`/etc/sysconfig/flanneld`配置文件：

```ini
# Flanneld configuration options  

# etcd url location.  Point this to the server where etcd runs
FLANNEL_ETCD_ENDPOINTS="https://192.168.177.132:2379,https://192.168.177.133:2379,https://192.168.177.134:2379"

# etcd config key.  This is the configuration key that flannel queries
# For address range assignment
FLANNEL_ETCD_PREFIX="/kube-centos/network"

# Any additional options that you want to pass
FLANNEL_OPTIONS="-etcd-cafile=/etc/kubernetes/ssl/ca.pem -etcd-certfile=/etc/kubernetes/ssl/kubernetes.pem -etcd-keyfile=/etc/kubernetes/ssl/kubernetes-key.pem"
```

如果是多网卡（例如vagrant环境），则需要在FLANNEL_OPTIONS中增加指定的外网出口的网卡，例如-iface=eth2

**在etcd中创建网络配置**

执行下面的命令为docker分配IP地址段。

```bash
etcdctl --endpoints=https://192.168.177.132:2379,https://192.168.177.133:2379,https://192.168.177.134:2379 \
  --ca-file=/etc/kubernetes/ssl/ca.pem \
  --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
  --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
  mkdir /kube-centos/network
  
etcdctl --endpoints=https://192.168.177.132:2379,https://192.168.177.133:2379,https://192.168.177.134:2379 \
  --ca-file=/etc/kubernetes/ssl/ca.pem \
  --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
  --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
  mk /kube-centos/network/config '{"Network":"172.30.0.0/16","SubnetLen":24,"Backend":{"Type":"vxlan"}}'
```

如果你要使用`host-gw`模式，可以直接将vxlan改成`host-gw`即可。

**启动flannel**再次

```bash
systemctl daemon-reload
systemctl enable flanneld
systemctl start flanneld
systemctl status flanneld
```

现在查询etcd中的内容可以看到：

```bash
root@master:~# etcdctl --endpoints=${ETCD_ENDPOINTS} \
   --ca-file=/etc/kubernetes/ssl/ca.pem \
   --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
   --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
   ls /kube-centos/network/subnets
/kube-centos/network/subnets/172.30.27.0-24
/kube-centos/network/subnets/172.30.94.0-24
/kube-centos/network/subnets/172.30.90.0-24

root@master:~# etcdctl --endpoints=${ETCD_ENDPOINTS} \
   --ca-file=/etc/kubernetes/ssl/ca.pem \
   --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
   --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
   get /kube-centos/network/config
{"Network":"172.30.0.0/16","SubnetLen":24,"Backend":{"Type":"vxlan"}}

root@master:~# etcdctl --endpoints=${ETCD_ENDPOINTS} \
   --ca-file=/etc/kubernetes/ssl/ca.pem \
   --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
   --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
   get /kube-centos/network/subnets/172.30.27.0-24
{"PublicIP":"192.168.177.130","BackendType":"vxlan","BackendData":{"VtepMAC":"42:66:0d:7a:73:e6"}}

$ etcdctl --endpoints=${ETCD_ENDPOINTS} \
  --ca-file=/etc/kubernetes/ssl/ca.pem \
  --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
  --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
  get /kube-centos/network/subnets/172.30.94.0-24
{"PublicIP":"192.168.177.128","BackendType":"vxlan","BackendData":{"VtepMAC":"2a:bf:cb:54:c3:42"}}

$ etcdctl --endpoints=${ETCD_ENDPOINTS} \
  --ca-file=/etc/kubernetes/ssl/ca.pem \
  --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
  --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
  /kube-centos/network/subnets/172.30.90.0-24
{"PublicIP":"192.168.177.129","BackendType":"vxlan","BackendData":{"VtepMAC":"7e:47:e0:27:01:c7"}}
```

推荐在“.bashrc” 文件中写入如下设置，以后操作`etcd`就不用输入那么长的一串字符了：
```bash
alias etcdctl='etcdctl --endpoints=${ETCD_ENDPOINTS} --ca-file=/etc/kubernetes/ssl/ca.pem  --cert-file=/etc/kubernetes/ssl/kubernetes.pem --key-file=/etc/kubernetes/ssl/kubernetes-key.pem'
```


**[返回目录](https://github.com/MulticsYin/MulticsKubernetes#kubernetes-%E4%BA%8C%E8%BF%9B%E5%88%B6%E9%83%A8%E7%BD%B2)**  
**[下一章 - 部署node节点](https://github.com/MulticsYin/MulticsKubernetes/blob/master/artcle/008-node-installation.md#%E9%83%A8%E7%BD%B2node%E8%8A%82%E7%82%B9)**
