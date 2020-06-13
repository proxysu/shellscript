# shellscript  
* naive-quickstart.sh 是从[Trojan-quickstart.sh](https://github.com/trojan-gfw/trojan-quickstart)的基础上改写。  
* trojan-go.sh 是从V2Ray的[install-release.sh](https://github.com/v2ray/v2ray-core/blob/master/release/install-release.sh)的安装程序基础上改写。  

trojan-go.sh安装位置  
/usr/bin/trojan-go/trojan-go  
/etc/trojan-go/config.json  
/etc/systemd/system/trojan-go.service  
/var/log/trojan-go  

systemctl start trojan-go  
systemctl stop trojan-go  
systemctl restart trojan-go  

remove  
trojan-go.sh --remove  
