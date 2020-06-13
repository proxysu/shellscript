* 都是从V2Ray的[install-release.sh](https://github.com/v2ray/v2ray-core/blob/master/release/install-release.sh)的安装程序基础上改写。分别安装客户端和服务端。
* install-kcptun-server.sh安装位置
/usr/bin/kcptun-server/kcptun-server
/etc/kcptun-server/config-server.json
/etc/systemd/system/kcptun-server.service
/var/log/kcptun-server

 systemctl start kcptun-server
 systemctl stop kcptun-server
 systemctl restart kcptun-server

* remove
 install-kcptun-server.sh --remove
 
 * install-kcptun-client.sh安装位置
/usr/bin/kcptun-client/kcptun-client
/etc/kcptun-client/config-client.json
/etc/systemd/system/kcptun-client.service
/var/log/kcptun-client

 systemctl start kcptun-client
 systemctl stop kcptun-clientclient
 systemctl restart kcptun-client

* remove
 install-kcptun-client.sh --remove
