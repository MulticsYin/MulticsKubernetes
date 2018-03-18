# 系统初始化配置

## 安装基本工具
```bash
sudo apt-get install -y openssh-server vim git
```

## 系统配置

* 修改主机名`/etc/hostname`，分别为: master, node01, node02。
* 修改`/etc/hosts`文件对应主机名和IP。
* 设置`root`密码，设置`root`登录(节省时间，生产环境推荐严格按照要求来)。  
```bash
sudo passwd root
```
设置`root`远程登录，修改`/etc/ssh/sshd_config`文件，找到`PermitRootLogin prohibit-password`一行，改为`PermitRootLogin yes`。
重启 `openssh server`: `sudo systemctl restart ssh.service`
