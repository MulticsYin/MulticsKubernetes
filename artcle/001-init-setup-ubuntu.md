# 系统初始化配置

## 安装基本工具
```bash
sudo apt-get install -y openssh-server vim git htop
```

## 系统配置

* 修改主机名`/etc/hostname`，分别为: master, node01, node02。
* 修改`/etc/hosts`文件对应主机名和IP。
* 设置`root`密码:  
`sudo passwd root`。
* 设置`root`登录(节省时间，生产环境推荐严格按照要求来)  
修改`/etc/ssh/sshd_config`文件，找到`PermitRootLogin prohibit-password`一行，改为`PermitRootLogin yes`。  
重启 `openssh server`: `sudo systemctl restart ssh.service`
* 关闭`swap`  
注释`/etc/fstab` `swap` 部分，运行以下命令暂时生效，不用重启电脑。  
`sudo swapoff -a`

**[返回目录](https://github.com/MulticsYin/MulticsKubernetes#kubernetes-%E4%BA%8C%E8%BF%9B%E5%88%B6%E9%83%A8%E7%BD%B2)**
**[下一章 - 创建TLS证书和秘钥](https://github.com/MulticsYin/MulticsKubernetes/blob/master/artcle/002-create-tls-and-secret-key.md#%E5%88%9B%E5%BB%BAtls%E8%AF%81%E4%B9%A6%E5%92%8C%E7%A7%98%E9%92%A5)**
