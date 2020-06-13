# shellscript  
* naive-quickstart.sh 是从[Trojan-quickstart.sh](https://github.com/trojan-gfw/trojan-quickstart)的基础上改写。  
* trojan-go.sh 是从V2Ray的[install-release.sh](https://github.com/v2ray/v2ray-core/blob/master/release/install-release.sh)的安装程序基础上改写。  

install-kcptun-client.sh安装位置  
/usr/bin/kcptun-client/kcptun-client  
/etc/kcptun-client/config-client.json  
/etc/systemd/system/kcptun-client.service  
/var/log/kcptun-client  

systemctl start kcptun-client  
systemctl stop kcptun-clientclient  
systemctl restart kcptun-client  

remove  
install-kcptun-client.sh --remove  
