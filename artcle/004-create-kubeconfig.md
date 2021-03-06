# 创建 kubeconfig 文件

`kubelet`、`kube-proxy` 等 Node 机器上的进程与 Master 机器的 `kube-apiserver` 进程通信时需要认证和授权；

kubernetes 1.4 开始支持由 `kube-apiserver` 为客户端生成 TLS 证书的 [TLS Bootstrapping](https://kubernetes.io/docs/admin/kubelet-tls-bootstrapping/) 功能，这样就不需要为每个客户端生成证书了；该功能**当前仅支持为 `kubelet`** 生成证书；

在此部署文档中, master节点和node节点复用，上一步已安装了kubectl。

以下操作只需要在master节点上执行，生成的`*.kubeconfig`文件可以直接拷贝到node节点的`/etc/kubernetes`目录下。

## 创建 TLS Bootstrapping Token

**Token auth file**

Token可以是任意的包含128 bit的字符串，可以使用安全的随机数发生器生成。

```shell script
mkdir -p /apps/server/k8s/k8s_config
export BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
cat > /apps/server/k8s/k8s_config/token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF
```

> 后三行是一句，直接复制上面的脚本运行即可。

**注意：在进行后续操作前请检查 `token.csv` 文件，确认其中的 `${BOOTSTRAP_TOKEN}` 环境变量已经被真实的值替换。**

**BOOTSTRAP_TOKEN** 将被写入到 kube-apiserver 使用的 token.csv 文件和 kubelet 使用的 `bootstrap.kubeconfig` 文件，如果后续重新生成了 BOOTSTRAP_TOKEN，则需要：

1. 更新 token.csv 文件，分发到所有机器 (master 和 node）的 /etc/kubernetes/ 目录下，分发到node节点上非必需；
2. 重新生成 bootstrap.kubeconfig 文件，分发到所有 node 机器的 /etc/kubernetes/ 目录下；
3. 重启 kube-apiserver 和 kubelet 进程；
4. 重新 approve kubelet 的 csr 请求；

## 创建 kubelet bootstrapping kubeconfig 文件

执行下面的命令时需要先安装kubectl命令。

```shell script
export KUBE_APISERVER="https://172.16.111.100:6443"
cd /apps/server/k8s/k8s_config

# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/apps/server/k8s/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=bootstrap.kubeconfig
  
# 设置客户端认证参数
kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=bootstrap.kubeconfig
  
# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=bootstrap.kubeconfig
  
# 设置默认上下文
kubectl config use-context default --kubeconfig=bootstrap.kubeconfig
```

+ `--embed-certs` 为 `true` 时表示将 `certificate-authority` 证书写入到生成的 `bootstrap.kubeconfig` 文件中；
+ 设置客户端认证参数时**没有**指定秘钥和证书，后续由 `kube-apiserver` 自动生成；


## 创建 kube-proxy kubeconfig 文件

```shell script
export KUBE_APISERVER="https://172.16.111.100:6443"

# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/apps/server/k8s/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials kube-proxy \
  --client-certificate=/apps/server/k8s/ssl/kube-proxy.pem \
  --client-key=/apps/server/k8s/ssl/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig
# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig
# 设置默认上下文
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
```

+ 设置集群参数和客户端认证参数时 `--embed-certs` 都为 `true`，这会将 `certificate-authority`、`client-certificate` 和 `client-key` 指向的证书文件内容写入到生成的 `kube-proxy.kubeconfig` 文件中；
+ `kube-proxy.pem` 证书中 CN 为 `system:kube-proxy`，`kube-apiserver` 预定义的 RoleBinding `cluster-admin` 将User `system:kube-proxy` 与 Role `system:node-proxier` 绑定，该 Role 授予了调用 `kube-apiserver` Proxy 相关 API 的权限；


## 分发 kubeconfig 文件

将两个 kubeconfig 文件分发到所有 Node 机器的 `/etc/kubernetes/` 目录

```shell script
scp -r /apps/server/k8s/k8s_config/ multics@172.16.111.101:/apps/server/k8s/
scp -r /apps/server/k8s/k8s_config/ multics@172.16.111.102:/apps/server/k8s/
```


**[返回目录](https://github.com/MulticsYin/MulticsKubernetes#kubernetes-%E4%BA%8C%E8%BF%9B%E5%88%B6%E9%83%A8%E7%BD%B2)**  
**[下一章 - 创建高可用 etcd 集群](https://github.com/MulticsYin/MulticsKubernetes/blob/master/artcle/005-etcd-cluster-installation.md#%E5%88%9B%E5%BB%BA%E9%AB%98%E5%8F%AF%E7%94%A8-etcd-%E9%9B%86%E7%BE%A4)**
