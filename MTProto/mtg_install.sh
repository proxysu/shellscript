#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===================================================================#
#   System Required:  CentOS 7,8/Debian 8,9,10/Ubuntu16.04+         #
#   Description: Install mtg server                                 #
#   Edit Author: ProxySU <https://github.com/proxysu>               #
#   Original Author: Teddysun <i@teddysun.com>                      #
#   Thanks: @madeye <https://github.com/madeye>                     #
#===================================================================#

# journalctl --boot -u mtg
# bash mtg_install.sh 443 azure.microsoft.com adtag
#$1=443
#$2=azure.microsoft.com
#$3=adtag

listen_port="$1"
listen_port=${listen_port:-443}
fake_domain="$2"
fake_domain=${fake_domain:-azure.microsoft.com}
adtag="$3"
adtag=${adtag-""}


# Current folder
cur_dir=$(pwd)


# Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'


get_latest_version(){

    ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/9seconds/mtg/releases/latest | grep 'tag_name' | cut -d\" -f4)
    [ -z "${ver}" ] && echo "Error: Get mtg latest version failed" && exit 1

    mtg_ver="mtg-linux-amd64"
    #https://github.com/9seconds/mtg/releases/download/v1.0.7/mtg-linux-amd64
    download_link="https://github.com/9seconds/mtg/releases/download/${ver}/${mtg_ver}"
    
}


check_installed(){
    if [ "$(command -v "$1")" ]; then
        return 0
    else
        return 1
    fi
}

check_version(){
    check_installed "mtg"
    if [ $? -eq 0 ]; then
        # installed_ver=$(cloak-plugin-server -v | grep cloak-plugin-server | cut -d' ' -f2)
        installed_ver=$(mtg --version 2>&1 | cut -d' ' -f1)
        get_latest_version
        #latest_ver=$(echo "${ver}" | sed -e 's/^[a-zA-Z]//g')
        latest_ver="${ver}"
        if [ "${latest_ver}" == "${installed_ver}" ]; then
            return 0
        else
            return 1
        fi
    else
        return 2
    fi
}

# print_info(){
    # clear
    # echo "#############################################################"
    # echo "# Install Shadowsocks-libev server for Debian or Ubuntu     #"
    # echo "# Intro:  https://teddysun.com/358.html                     #"
    # echo "# Author: Teddysun <i@teddysun.com>                         #"
    # echo "# Github: https://github.com/shadowsocks/shadowsocks-libev  #"
    # echo "#############################################################"
    # echo
# }


# Pre-installation settings
pre_install(){
    check_version
    status=$?
    if [ ${status} -eq 0 ]; then
        echo -e "[${green}Info${plain}] Latest version ${green}${mtg_ver}${plain} has already been installed, nothing to do..."
        exit 0
    elif [ ${status} -eq 1 ]; then
        echo -e "Installed version: ${red}${installed_ver}${plain}"
        echo -e "Latest version: ${red}${latest_ver}${plain}"
        echo -e "[${green}Info${plain}] Upgrade mtg to latest version..."

    elif [ ${status} -eq 2 ]; then
        #print_info
        get_latest_version
        echo -e "[${green}Info${plain}] Latest version: ${green}${mtg_ver}${ver}${plain}"
        echo
    fi

 
}

download() {
    local filename=${1}
    local cur_dir=$(pwd)
    if [ -s "${filename}" ]; then
        echo -e "[${green}Info${plain}] ${filename} [found]"
    else
        echo -e "[${green}Info${plain}] ${filename} not found, download now..."
        wget --no-check-certificate -cq -t3 -T60 -O "${1}" "${2}"
        if [ $? -eq 0 ]; then
            echo -e "[${green}Info${plain}] ${filename} download completed..."
        else
            echo -e "[${red}Error${plain}] Failed to download ${filename}, please download it to ${cur_dir} directory manually and try again."
            exit 1
        fi
    fi
}


download_files(){
    cd "${cur_dir}" || exit

    download "${mtg_ver}" "${download_link}"

}


install_mtg(){

    #ldconfig
    cd "${cur_dir}" || exit
    if [ -f /usr/local/bin/mtg ]; then
        rm -f /usr/local/bin/mtg
    fi
    cp "${mtg_ver}" /usr/local/bin/mtg

    if [ -f /usr/local/bin/mtg ]; then
        chmod +x /usr/local/bin/mtg
        secret=$(/usr/local/bin/mtg generate-secret -c ${fake_domain} tls)
        #ipv4=$(curl -s https://api.ip.sb/ip --ipv4)
        #ipv6=$(curl -s https://api.ip.sb/ip --ipv6)
        # if [[ -z "${ipv6}" ]]; then
            # PUBLIC_IPV4="${ipv4}:${listen_port}"
            # public_ip="--public-ipv4=${PUBLIC_IPV4}"
        # else
            # PUBLIC_IPV4="${ipv4}:${listen_port}"
            # PUBLIC_IPV6="${ipv6}:${listen_port}"
            # public_ip="--public-ipv4=${PUBLIC_IPV4} --public-ipv6=${PUBLIC_IPV6}"
        # fi
        public_ip="--bind=0.0.0.0:${listen_port}"
        #adtag=""
        
        cat > "/etc/systemd/system/mtg.service" <<-EOF
[Unit]
Description=MTProxy
After=network.target network-online.target nss-lookup.target mysql.service mariadb.service mysqld.service

[Service]
Type=simple
StandardError=journal
StandardOutput=file:/usr/local/etc/mtg_info.json
ExecStart=/usr/local/bin/mtg run ${public_ip} ${secret} ${adtag}
ExecReload=/bin/kill -HUP \$MAINPID
LimitNOFILE=51200
Restart=on-failure
RestartSec=1s

[Install]
WantedBy=multi-user.target
EOF

cat > "/usr/local/etc/mtg.sh" <<-EOF
/usr/local/bin/mtg run ${public_ip} ${secret} ${adtag} > /usr/local/etc/mtg_info.json
EOF
        echo
        echo "mtg server installed successfully! "
        echo 'Please execute the command: systemctl enable mtg; systemctl start mtg'
        echo "Enjoy it!"
        echo

    else
        echo
        echo -e "[${red}Error${plain}] mtg install failed. please visit https://github.com/proxysu/windows and contact."
        exit 1
    fi

    cd "${cur_dir}" || exit
    rm -rf "${mtg_ver}"
 
}


install_mtg_go(){

    pre_install
    download_files

    install_mtg
}


# uninstall_mtg_go(){
  
        # rm -f /usr/local/bin/mtg
        # echo "mtg uninstall success!"

# }

# Initialization step
install_mtg_go
# action=$1
# listen_port="$1"
# fake_domain="$2"
# adtag="$3"
# [ -z "$1" ] && action=install
# case "$action" in
    # install|uninstall)
        # ${action}_mtg_go
        # ;;
    # *)
        # echo "Arguments error! [${action}]"
        # echo "Usage: $(basename "$0") [install|uninstall]"
        # ;;
# esac
