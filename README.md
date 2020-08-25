# shellscript  
* naive-quickstart.sh 是从[Trojan-quickstart.sh](https://github.com/trojan-gfw/trojan-quickstart)的基础上改写-------已弃用。  
* trojan-go.sh 是从V2Ray的[install-release.sh](https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)的安装程序基础上改写。  

trojan-go.sh安装位置  
 /usr/local/bin/trojan-go  
 /usr/local/etc/trojan-go/config.json  
 /etc/systemd/system/trojan-go.service  
 /etc/systemd/system/trojan-go@.service  
 /var/log/trojan-go  

systemctl start trojan-go  
systemctl stop trojan-go  
systemctl restart trojan-go  

remove  
trojan-go.sh --remove  
