# MulticsKubernetes

该教程记录我安装及使用Kubernetes的历程，主要偏向实战，基础知识请查看参考文档，文档共分为三个部分:  
* Kubernetes 安装 & 插件配置
* 官方实例、社区实例及自己开发部署实例
* Kubernetes 架构 & 源码剖析

## 集群详情
* OS: Ubuntu16.04 4.4.0-87-generic
* kubernetes1.9.3
* Docker: docker-ce_17.12.1_ce-0_ubuntu_amd64.deb
* Etcd: etcd-v3.3.1-linux-amd64.tar.gz
* Flannel: flannel-v0.10.0-linux-amd64.tar.gz
* TLS 认证通信 (所有组件，如 etcd、kubernetes master 和 node)
* RBAC 授权
* kubelet TLS BootStrapping
* kubedns、dashboard、heapster(influxdb、grafana)、EFK(elasticsearch、fluentd、kibana) 集群插件


## 环境说明
在未来的教程中，我将在本地计算机安装VMware虚拟机，模拟三台物理设备  
角色分配如下：  
* Master：192.168.177.132
* Node：192.168.177.132、192.168.177.133、192.168.177.134  

注意：192.168.177.132这台主机master和node复用。所有生成证书、执行kubectl命令的操作都在这台节点上执行。一旦node加入到kubernetes集群之后就不需要再登陆node节点了。



## 参考文档
* [《Kubernetes Handbook》](https://jimmysong.io/kubernetes-handbook/)  
原书基于CentOS部署，与Ubuntu部署有部分差异，文档第一部分主要参考该书。
* [kubernetes 从入门到实践](https://www.kancloud.cn/huyipow/kubernetes/531982)  
51cto kubernetes 培训，具体可看视频[【Kubernetes精品培训】Kubernetes实战培训](http://edu.51cto.com/course/11386.html)
* [以优雅的姿势监控kubernetes 集群服务](https://www.kancloud.cn/huyipow/prometheus/527093)
* [从零开始写一个运行在Kubernetes上的服务程序(中文)](https://mp.weixin.qq.com/s?__biz=MzA5OTAyNzQ2OA==&mid=2649696211&idx=1&sn=4357517ee2f85109d1ba5850dbc2566d&chksm=889318b0bfe491a6be37fc14d21b17b84bc2ea66abc20ef895e2529f5b74e7bec5260ff64422&mpshare=1&scene=1&srcid=1222tsbWehxtACFF3vdXe43p&pass_ticket=Ve1GjgUuO3ZbG6Q%2FlsmHJjFSBovqz9HQDqm9H0EuXcr12yI7f7h0eN%2B%2Fj90iafRi#rd) -- [英文原地址](https://blog.gopheracademy.com/advent-2017/kubernetes-ready-service/) -- [GitHub](https://github.com/rumyantseva/advent-2017/tree/all-steps)
* [docker 实践](https://www.kancloud.cn/huyipow/docker/502959)
