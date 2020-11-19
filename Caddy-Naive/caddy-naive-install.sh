#!/bin/bash
export LC_ALL=C
export LANG=en_US
export LANGUAGE=en_US.UTF-8

##Be adapted from https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/vless/src/v2gun.sh

if [[ $(uname -m 2> /dev/null) != x86_64 ]]; then
    echo Please run this script on x86_64 machine.
    exit 1
fi

uninstall() {
  $(which rm) -rf $1
  printf "Removed: %s\n" $1
}

set_caddy_systemd() {
  cat > "/etc/systemd/system/caddy.service" <<-EOF
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
#User=caddy
#Group=caddy
User=root
Group=root
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5s
#LimitNOFILE=1048576
#LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
#AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
}

get_caddy() {
  if [ ! -d "/usr/bin/caddy" ]; then
    echo "Caddy 2 is not installed. start installation"

    local caddy_link="https://raw.githubusercontent.com/proxysu/Resources/master/Caddy2/caddy2.zip"

    $(which mkdir) -p "/etc/caddy"
    printf "Cretated: %s\n" "/etc/caddy"
    echo "OK" > /etc/caddy/naive

    wget "${caddy_link}" -O /tmp/caddy.zip && unzip /tmp/caddy.zip -d /usr/bin/ && $(which chmod) +x /usr/bin/caddy
    printf "Installed: %s\n" "/usr/bin/caddy"


    echo "Building caddy.service"
    set_caddy_systemd

    systemctl daemon-reload
    #systemctl enable caddy

    echo "Caddy 2 is installed."
  fi
}

install_caddy(){
    get_caddy
}

uninstall_caddy(){
  if [ -f "/usr/bin/caddy" ]; then
  echo "Shutting down caddy service."
  systemctl stop caddy
  systemctl disable caddy
  uninstall /etc/systemd/system/caddy.service
  echo  "Removing caddy binaries & files."
  uninstall /usr/bin/caddy
  uninstall /etc/caddy
  echo  "Removed caddy successfully."
fi
}

action=$1
[ -z "$1" ] && action=install
case "$action" in
    install|uninstall)
        ${action}_caddy
        ;;
    *)
        echo "Arguments error! [${action}]"
        echo "Usage: $(basename "$0") [install|uninstall]"
        ;;
esac
