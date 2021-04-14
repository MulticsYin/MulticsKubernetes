# 系统初始化配置

安装VMware在这块不做详细描述,详情可以参考[官网](https://www.vmware.com/products/workstation-pro.html)

## 初始化系统 & 安装基础工具
成功安装VMware虚拟机后，在本教程中使用 Ubuntu16.04 server版本新建三台主机,如下:  
```
172.16.111.100	k8s-00
172.16.111.101	k8s-01
172.16.111.102	k8s-02
```
系统配置文件设置: 提供k8s-00主要部分,其他两台机大同小异,此处配置需要与VMware相配合(VMware使用的静态IP)
* 修改主机名(对应的节点类似配置): /etc/hostname
```text
k8s-00
```  

* 设置主机间通过主机名相互通讯: /etc/hosts  
```text
127.0.0.1	localhost
172.16.111.100	k8s-00
172.16.111.101	k8s-01
172.16.111.102	k8s-02
```

* /etc/network/interfaces
```text
# The loopback network interface
auto lo
iface lo inet loopback
# The primary network interface
auto ens33
iface ens33 inet static
address 172.16.111.100
netmask 255.255.255.0
gateway 172.16.111.2
```

* 设置DNS解析(配置相同): /etc/resolv.conf, /etc/resolvconf/resolv.conf.d/base
```text
nameserver 8.8.8.8
```
* 注释无用的apt配置,避免安装软件报错: /etc/apt/sources.list
```text
# deb cdrom:[Ubuntu-Server 16.04 LTS _Xenial Xerus_ - Release amd64 (20160420.3)]/ xenial main restricted
```

* 设置 root 密码
```shell script
sudo passwd root
```

* 设置 root 登录: /etc/ssh/sshd_config  
找到`PermitRootLogin prohibit-password`一行，改为`PermitRootLogin yes`  
重启 `openssh server`，运行命令: `sudo systemctl restart ssh.service`

* 关闭 swap: /etc/fstab  
注释关于 `swap` 部分，否则后期启动`kubelet`时会报错，运行以下命令暂时生效，不用重启电脑。  
`sudo swapoff -a`

* 安装完成以后运行以下命令安装基本工具和软件：
```bash
sudo apt-get install -y openssh-server vim git htop
```

**[返回目录](https://github.com/MulticsYin/MulticsKubernetes#kubernetes-%E4%BA%8C%E8%BF%9B%E5%88%B6%E9%83%A8%E7%BD%B2)**  
**[下一章 - 创建TLS证书和秘钥](https://github.com/MulticsYin/MulticsKubernetes/blob/master/artcle/002-create-tls-and-secret-key.md#%E5%88%9B%E5%BB%BAtls%E8%AF%81%E4%B9%A6%E5%92%8C%E7%A7%98%E9%92%A5)**
