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
```bash
swapoff -a
```
