#!/bin/bash
##Adapted from Trojan-quickstart.sh
set -euo pipefail

function prompt() {
    while true; do
        read -p "$1 [y/N] " yn
        case $yn in
            [Yy] ) return 0;;
            [Nn]|"" ) return 1;;
        esac
    done
}

if [[ $(id -u) != 0 ]]; then
    echo Please run this script as root.
    exit 1
fi

if [[ $(uname -m 2> /dev/null) != x86_64 ]]; then
    echo Please run this script on x86_64 machine.
    exit 1
fi
getPMT(){
    if [[ -n `command -v apt-get` ]];then
        apt-get -qq update
        apt-get -y -qq install curl xz-utils libnss3

    elif [[ -n `command -v yum` ]]; then
        yum -q makecache
        yum -y -q install curl xz nss
    else
        return 1
    fi
    return 0
}

getPMT
NAME=naive
#NAMESIM=naive
VERSION=$(curl -fsSL https://api.github.com/repos/klzgrad/naiveproxy/releases/latest | grep tag_name | sed -E 's/.*"v(.*)".*/\1/')
TARBALL="naiveproxy-v${VERSION}-linux-x64.tar.xz"
PATHNAME="naiveproxy-v$VERSION-linux-x64"
DOWNLOADURL="https://github.com/klzgrad/naiveproxy/releases/download/v${VERSION}/${TARBALL}"
TMPDIR="$(mktemp -d)"
INSTALLPREFIX=/usr/local
SYSTEMDPREFIX=/etc/systemd/system

BINARYPATH="$INSTALLPREFIX/bin/naive"
CONFIGPATH="$INSTALLPREFIX/etc/naive/config.json"
SYSTEMDPATH="$SYSTEMDPREFIX/naive.service"

echo Entering temp directory $TMPDIR...
cd "$TMPDIR"

echo Downloading $NAME $VERSION...
curl -LO --progress-bar "$DOWNLOADURL" || wget -q --show-progress "$DOWNLOADURL"

echo Unpacking $NAME $VERSION...
tar -xf "$TARBALL"
cd "$PATHNAME"

echo Installing $NAME $VERSION to $BINARYPATH...
install -Dm755 "$NAME" "$BINARYPATH"

echo Installing $NAME server config to $CONFIGPATH...
if ! [[ -f "$CONFIGPATH" ]] || prompt "The server config already exists in $CONFIGPATH, overwrite?"; then
   install -Dm755 "config.json" "$CONFIGPATH"
   cat <<EOF > "$CONFIGPATH"
{
"listen": "http://127.0.0.1:8383",
"padding": true
}
EOF
else
    echo Skipping installing $NAME server config...
fi

if [[ -d "$SYSTEMDPREFIX" ]]; then
    echo Installing $NAME systemd service to $SYSTEMDPATH...
    if ! [[ -f "$SYSTEMDPATH" ]] || prompt "The systemd service already exists in $SYSTEMDPATH, overwrite?"; then
        cat > "$SYSTEMDPATH" << EOF
[Unit]
Description=$NAME
After=network.target network-online.target nss-lookup.target mysql.service mariadb.service mysqld.service

[Service]
Type=simple
StandardError=journal
ExecStart="$BINARYPATH" "$CONFIGPATH"
ExecReload=/bin/kill -HUP \$MAINPID
LimitNOFILE=51200
Restart=on-failure
RestartSec=1s

[Install]
WantedBy=multi-user.target
EOF

        echo Reloading systemd daemon...
        systemctl daemon-reload
    else
        echo Skipping installing $NAME systemd service...
    fi
fi

echo Deleting temp directory $TMPDIR...
rm -rf "$TMPDIR"

echo Done!
