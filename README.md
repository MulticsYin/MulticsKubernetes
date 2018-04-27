# MulticsKubernetes

该教程记录我安装及使用Kubernetes的历程，主要偏向实战，基础知识请查看参考文档，文档共分为三个部分:  
* Kubernetes 二进制部署 & 插件配置
* 官方实例、社区实例 & 自己开发部署实例
* Kubernetes 架构 & 源码剖析  

Kubernetes 几乎所有的安装组件和 Docker 镜像都放在 goolge 自己的网站上，这对国内的同学可能是个不小的障碍。  
建议是：网络障碍都必须想办法克服，不然连 Kubernetes 的门都进不了。
## 集群详情
* OS: Ubuntu 16.04.4 LTS xenial(查看命令：lsb_release  -a)
* Kubernetes:[kubernetes1.9.3](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.9.md#server-binaries-1)
* Docker: [docker-ce_17.12.1_ce-0_ubuntu_amd64.deb](https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/)
* Etcd: [etcd-v3.3.1-linux-amd64.tar.gz](https://github.com/coreos/etcd/releases/)
* Flannel: [flannel-v0.10.0-linux-amd64.tar.gz](https://github.com/coreos/flannel/releases)
* TLS 认证通信 (所有组件，如 etcd、kubernetes master 和 node)
* RBAC 授权
* kubelet TLS BootStrapping
* kubedns、dashboard、heapster(influxdb、grafana)、EFK(Elasticsearch、fluentd、kibana) 集群插件


## 环境说明
在未来的教程中，我将在本地计算机安装VMware虚拟机，模拟三台物理设备  
角色分配如下(部署了两个集群，IP可能会有差异，后期一起改过来)：
* Master：192.168.177.132
* Node：192.168.177.132、192.168.177.133、192.168.177.134  

注意：192.168.177.132这台主机master和node复用。所有生成证书、执行kubectl命令的操作都在这台节点上执行。一旦node加入到kubernetes集群之后就不需要再登陆node节点了。


## Kubernetes 二进制部署
* [系统初始化配置](https://github.com/MulticsYin/MulticsKubernetes/blob/master/artcle/001-init-setup-ubuntu.md#%E7%B3%BB%E7%BB%9F%E5%88%9D%E5%A7%8B%E5%8C%96%E9%85%8D%E7%BD%AE)
* [创建TLS证书和秘钥](https://github.com/MulticsYin/MulticsKubernetes/blob/master/artcle/002-create-tls-and-secret-key.md#%E5%88%9B%E5%BB%BAtls%E8%AF%81%E4%B9%A6%E5%92%8C%E7%A7%98%E9%92%A5)
* [安装kubectl命令行工具](https://github.com/MulticsYin/MulticsKubernetes/blob/master/artcle/003-kubectl-installation.md#%E5%AE%89%E8%A3%85kubectl%E5%91%BD%E4%BB%A4%E8%A1%8C%E5%B7%A5%E5%85%B7)
* [创建 kubeconfig 文件](https://github.com/MulticsYin/MulticsKubernetes/blob/master/artcle/004-create-kubeconfig.md#%E5%88%9B%E5%BB%BA-kubeconfig-%E6%96%87%E4%BB%B6)
* [创建高可用 etcd 集群](https://github.com/MulticsYin/MulticsKubernetes/blob/master/artcle/005-etcd-cluster-installation.md#%E5%88%9B%E5%BB%BA%E9%AB%98%E5%8F%AF%E7%94%A8-etcd-%E9%9B%86%E7%BE%A4)
* [部署master节点](https://github.com/MulticsYin/MulticsKubernetes/blob/master/artcle/006-master-installation.md#%E9%83%A8%E7%BD%B2master%E8%8A%82%E7%82%B9)
* [安装flannel网络插件](https://github.com/MulticsYin/MulticsKubernetes/blob/master/artcle/007-flannel-installation.md#%E5%AE%89%E8%A3%85flannel%E7%BD%91%E7%BB%9C%E6%8F%92%E4%BB%B6)
* [部署node节点](https://github.com/MulticsYin/MulticsKubernetes/blob/master/artcle/008-node-installation.md#%E9%83%A8%E7%BD%B2node%E8%8A%82%E7%82%B9)
* [安装kubedns插件](https://github.com/MulticsYin/MulticsKubernetes/blob/master/artcle/009-kubedns-addon-installation.md#%E5%AE%89%E8%A3%85kubedns%E6%8F%92%E4%BB%B6)
* [安装dashboard插件](https://github.com/MulticsYin/MulticsKubernetes/blob/master/artcle/010-dashboard-addon-installation.md#%E5%AE%89%E8%A3%85dashboard%E6%8F%92%E4%BB%B6)
* [安装heapster插件](https://github.com/MulticsYin/MulticsKubernetes/blob/master/artcle/011-heapster-addon-installation.md#%E5%AE%89%E8%A3%85heapster%E6%8F%92%E4%BB%B6)
* [安装EFK插件](https://github.com/MulticsYin/MulticsKubernetes/blob/master/artcle/012-efk-addon-installation.md#%E5%AE%89%E8%A3%85efk%E6%8F%92%E4%BB%B6)

## 官方实例 & 社区实例 & 自己开发部署实例
* [Kubernetes 官方实例](https://github.com/kubernetes/examples)

## Kubernetes 架构 & 源码剖析
* [Kubernetes Deconstructed: Understanding Kubernetes by Breaking It Down - Carson Anderson, DOMO](https://vimeo.com/245778144/4d1d597c5e)(**视频**)  
需自备梯子观看，能对Kubernetes有一个大体的认知。[在线PPT演示](http://kube-decon.carson-anderson.com/Layers/0-Intro.sozi.html)

## 参考文档
* [Kubernetes Handbook](https://jimmysong.io/kubernetes-handbook/)  原书基于CentOS部署，与Ubuntu部署有部分差异，文档第一部分主要参考该书。
* [Kubernetes1.9 官方文档(中文)](https://k8smeetup.github.io/)
* [每天5分钟玩转Kubernetes&Docker](http://www.cnblogs.com/CloudMan6/tag/Docker/default.html)  入门首选
* [kubernetes 从入门到实践](https://www.kancloud.cn/huyipow/kubernetes/531982)  51cto kubernetes 培训，具体可看视频[【Kubernetes精品培训】Kubernetes实战培训](http://edu.51cto.com/course/11386.html)
* [以优雅的姿势监控kubernetes 集群服务(Prometheus)](https://www.kancloud.cn/huyipow/prometheus/527093)
* [从零开始写一个运行在Kubernetes上的服务程序(中文)](https://mp.weixin.qq.com/s?__biz=MzA5OTAyNzQ2OA==&mid=2649696211&idx=1&sn=4357517ee2f85109d1ba5850dbc2566d&chksm=889318b0bfe491a6be37fc14d21b17b84bc2ea66abc20ef895e2529f5b74e7bec5260ff64422&mpshare=1&scene=1&srcid=1222tsbWehxtACFF3vdXe43p&pass_ticket=Ve1GjgUuO3ZbG6Q%2FlsmHJjFSBovqz9HQDqm9H0EuXcr12yI7f7h0eN%2B%2Fj90iafRi#rd) -- [英文原地址](https://blog.gopheracademy.com/advent-2017/kubernetes-ready-service/) -- [GitHub](https://github.com/rumyantseva/advent-2017/tree/all-steps)
