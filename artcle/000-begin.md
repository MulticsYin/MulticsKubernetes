# Kubernetes安装教程(暂基于1.9.3，后期会不断更新)

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

注意：172.20.0.113这台主机master和node复用。所有生成证书、执行kubectl命令的操作都在这台节点上执行。一旦node加入到kubernetes集群之后就不需要再登陆node节点了。


