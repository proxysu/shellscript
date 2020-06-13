#!/bin/bash

# Kcptun-server install script Forked from https://install.direct/go.sh
# This file is accessible as https://install.direct/go.sh
# Original source is located at github.com/v2ray/v2ray-core/release/install-release.sh

# If not specify, default meaning of return value:
# 0: Success
# 1: System error
# 2: Application error
# 3: Network error

# CLI arguments
PROXY=''
HELP=''
FORCE=''
CHECK=''
REMOVE=''
VERSION=''
VSRC_ROOT='/tmp/kcptun'
EXTRACT_ONLY=''
LOCAL=''
LOCAL_INSTALL=''
DIST_SRC='github'
ERROR_IF_UPTODATE=''

CUR_VER=""
NEW_VER=""
NEW_VER_NO_V=""
VDIS=''
ZIPFILE="/tmp/kcptun/kcptun.tar.gz"
V2RAY_RUNNING=0

CMD_INSTALL=""
CMD_UPDATE=""
SOFTWARE_UPDATED=0

SYSTEMCTL_CMD=$(command -v systemctl 2>/dev/null)
SERVICE_CMD=$(command -v service 2>/dev/null)

#######color code########
RED="31m"      # Error message
GREEN="32m"    # Success message
YELLOW="33m"   # Warning message
BLUE="36m"     # Info message


#########################
while [[ $# > 0 ]]; do
    case "$1" in
        -p|--proxy)
        PROXY="-x ${2}"
        shift # past argument
        ;;
        -h|--help)
        HELP="1"
        ;;
        -f|--force)
        FORCE="1"
        ;;
        -c|--check)
        CHECK="1"
        ;;
        --remove)
        REMOVE="1"
        ;;
        --version)
        VERSION="$2"
        shift
        ;;
        --extract)
        VSRC_ROOT="$2"
        shift
        ;;
        --extractonly)
        EXTRACT_ONLY="1"
        ;;
        -l|--local)
        LOCAL="$2"
        LOCAL_INSTALL="1"
        shift
        ;;
        --source)
        DIST_SRC="$2"
        shift
        ;;
        --errifuptodate)
        ERROR_IF_UPTODATE="1"
        ;;
        *)
                # unknown option
        ;;
    esac
    shift # past argument or value
done

###############################
colorEcho(){
    echo -e "\033[${1}${@:2}\033[0m" 1>& 2
}

archAffix(){
    case "${1:-"$(uname -m)"}" in
        i686|i386)
            echo '386'
        ;;
        x86_64|amd64)
            echo 'amd64'
        ;;
          *armv5*)
            echo 'arm5'
        ;;
          *armv6l)
            echo 'arm6'
        ;;
        *armv7*)
            echo 'arm7'
        ;;
        *armv8*|aarch64)
            echo 'arm64'
        ;;
        *mipsle*)
            echo 'mipsle'
        ;;
        *mips*)
            echo 'mips'
        ;;
        *)
            return 1
        ;;
    esac

	return 0
}


downloadKcptun(){
    rm -rf /tmp/kcptun
    mkdir -p /tmp/kcptun

    DOWNLOAD_LINK="https://github.com/xtaci/kcptun/releases/download/${NEW_VER}/kcptun-linux-${VDIS}-${NEW_VER_NO_V}.tar.gz"

    colorEcho ${BLUE} "Downloading Kcptun-server: ${DOWNLOAD_LINK}"
    curl ${PROXY} -L -H "Cache-Control: no-cache" -o ${ZIPFILE} ${DOWNLOAD_LINK}
    if [ $? != 0 ];then
        colorEcho ${RED} "Failed to download! Please check your network or try again."
        return 3
    fi
    return 0
}

installSoftware(){
    COMPONENT=$1
    if [[ -n `command -v $COMPONENT` ]]; then
        return 0
    fi

    getPMT
    if [[ $? -eq 1 ]]; then
        colorEcho ${RED} "The system package manager tool isn't APT or YUM, please install ${COMPONENT} manually."
        return 1
    fi
    if [[ $SOFTWARE_UPDATED -eq 0 ]]; then
        colorEcho ${BLUE} "Updating software repo"
        $CMD_UPDATE
        SOFTWARE_UPDATED=1
    fi

    colorEcho ${BLUE} "Installing ${COMPONENT}"
    $CMD_INSTALL $COMPONENT
    if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "Failed to install ${COMPONENT}. Please install it manually."
        return 1
    fi
    return 0
}

# return 1: not apt, yum, or zypper
getPMT(){
    if [[ -n `command -v apt-get` ]];then
        CMD_INSTALL="apt-get -y -qq install"
        CMD_UPDATE="apt-get -qq update"
    elif [[ -n `command -v yum` ]]; then
        CMD_INSTALL="yum -y -q install"
        CMD_UPDATE="yum -q makecache"
    elif [[ -n `command -v zypper` ]]; then
        CMD_INSTALL="zypper -y install"
        CMD_UPDATE="zypper ref"
    else
        return 1
    fi
    return 0
}

normalizeVersion() {
    if [ -n "$1" ]; then
        case "$1" in
            v*)
                echo "$1"
            ;;
            *)
                echo "v$1"
            ;;
        esac
    else
        echo ""
    fi
}

# 1: new Kcptun-server. 0: no. 2: not installed. 3: check failed. 4: don't check.
getVersion(){
    if [[ -n "$VERSION" ]]; then
        NEW_VER="$(normalizeVersion "$VERSION")"
        return 4
    else
        VER="$(/usr/bin/kcptun-server/kcptun-server -v)"
        RETVAL=$?
        CUR_VER="$(normalizeVersion "$(echo "$VER" | head -n 1 | cut -d " " -f3)")"
        TAG_URL="https://api.github.com/repos/xtaci/kcptun/tags"
        NEW_VER="$(normalizeVersion "$(curl ${PROXY} -H "Accept: application/json" -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:74.0) Gecko/20100101 Firefox/74.0" -s "${TAG_URL}" --connect-timeout 10| grep 'name' | cut -d\" -f4 | head -n 1)")"
        NEW_VER_NO_V="$(echo "${NEW_VER#*v}")"
        
        if [[ $? -ne 0 ]] || [[ $NEW_VER == "" ]]; then
            colorEcho ${RED} "Failed to fetch release information. Please check your network or try again."
            return 3
        elif [[ $RETVAL -ne 0 ]];then
            return 2
        elif [[ $NEW_VER != $CUR_VER ]];then
            return 1
        fi
        return 0
    fi
}

stopKcptun(){
    colorEcho ${BLUE} "Shutting down Kcptun-server service."
    if [[ -n "${SYSTEMCTL_CMD}" ]] || [[ -f "/lib/systemd/system/kcptun-server.service" ]] || [[ -f "/etc/systemd/system/kcptun-server.service" ]]; then
        ${SYSTEMCTL_CMD} stop kcptun-server

    fi
    if [[ $? -ne 0 ]]; then
        colorEcho ${YELLOW} "Failed to shutdown Kcptun-server service."
        return 2
    fi
    return 0
}

startKcptun(){
    if [ -n "${SYSTEMCTL_CMD}" ] && [[ -f "/lib/systemd/system/kcptun-server.service" || -f "/etc/systemd/system/kcptun-server.service" ]]; then
        ${SYSTEMCTL_CMD} start kcptun-server

    fi
    if [[ $? -ne 0 ]]; then
        colorEcho ${YELLOW} "Failed to start Kcptun-server service."
        return 2
    fi
    return 0
}

installKcptun(){
    # Install Kcptun-server binary to /usr/bin/kcptun-server
    mkdir -p '/usr/bin/kcptun-server' '/etc/kcptun-server' '/var/log/kcptun-server' && \
    tar -zxf "${ZIPFILE}" -C '/tmp/kcptun' && \
    cp "/tmp/kcptun/server_linux_amd64" "/usr/bin/kcptun-server/kcptun-server" && \
    chmod +x '/usr/bin/kcptun-server/kcptun-server' || {
        colorEcho ${RED} "Failed to copy Kcptun-server binary and resources."
        return 1
    }

    # Install Kcptun-server server config to /etc/kcptun-server
    if [ ! -f '/etc/kcptun-server/config-server.json' ]; then
        local PORT="$(($RANDOM + 10000))"
        local UUID="$(cat '/proc/sys/kernel/random/uuid')"

        curl ${PROXY} -L -s -H "Cache-Control: no-cache" -o '/etc/kcptun-server/config-server.json' 'https://raw.githubusercontent.com/xtaci/kcptun/master/examples/server.json' && \
        sed -i "s/2000/${PORT}/g; s/PASSWORD/${UUID}/g;" '/etc/kcptun-server/config-server.json' || {
            colorEcho ${YELLOW} "Failed to create Kcptun-server configuration file. Please create it manually."
            return 1
        }

        colorEcho ${BLUE} "PORT:${PORT}"
        colorEcho ${BLUE} "Your Password:${UUID}"
    fi
}


installInitScript(){
    if [[ -n "${SYSTEMCTL_CMD}" ]]; then
        if [[ ! -f "/etc/systemd/system/kcptun-server.service" && ! -f "/lib/systemd/system/kcptun-server.service" ]]; then
            curl ${PROXY} -L -s -H "Cache-Control: no-cache" -o '/etc/systemd/system/kcptun-server.service' 'https://raw.githubusercontent.com/xtaci/kcptun/master/examples/kcptun.service' && \
            sed -i "s/\/home\/user\/client_linux_amd64 -c \/home\/user\/local.json/\/usr\/bin\/kcptun-server\/kcptun-server -c \/etc\/kcptun-server\/config-server.json/g;" '/etc/systemd/system/kcptun-server.service' && \
            systemctl enable kcptun-server.service
        fi

    fi
}

Help(){
  cat - 1>& 2 << EOF
./install-release.sh [-h] [-c] [--remove] [-p proxy] [-f] [--version vx.y.z] [-l file]
  -h, --help            Show help
  -p, --proxy           To download through a proxy server, use -p socks5://127.0.0.1:1080 or -p http://127.0.0.1:3128 etc
  -f, --force           Force install
      --version         Install a particular version, use --version v3.15
  -l, --local           Install from a local file
      --remove          Remove installed Kcptun-server
  -c, --check           Check for update
EOF
}

remove(){
    if [[ -n "${SYSTEMCTL_CMD}" ]] && [[ -f "/etc/systemd/system/kcptun-server.service" ]];then
        if pgrep "kcptun-server" > /dev/null ; then
            stopKcptun
        fi
        systemctl disable kcptun-server.service
        rm -rf "/usr/bin/kcptun-server" "/etc/systemd/system/kcptun-server.service"
        if [[ $? -ne 0 ]]; then
            colorEcho ${RED} "Failed to remove Kcptun-server."
            return 0
        else
            colorEcho ${GREEN} "Removed Kcptun-server successfully."
            colorEcho ${BLUE} "If necessary, please remove configuration file and log file manually."
            return 0
        fi
    elif [[ -n "${SYSTEMCTL_CMD}" ]] && [[ -f "/lib/systemd/system/kcptun-server.service" ]];then
        if pgrep "kcptun-server" > /dev/null ; then
            stopKcptun
        fi
        systemctl disable kcptun-server.service
        rm -rf "/usr/bin/kcptun-server" "/lib/systemd/system/kcptun-server.service"
        if [[ $? -ne 0 ]]; then
            colorEcho ${RED} "Failed to remove Kcptun-server."
            return 0
        else
            colorEcho ${GREEN} "Removed Kcptun-server successfully."
            colorEcho ${BLUE} "If necessary, please remove configuration file and log file manually."
            return 0
        fi
    else
        colorEcho ${YELLOW} "Kcptun-server not found."
        return 0
    fi
}

checkUpdate(){
    echo "Checking for update."
    VERSION=""
    getVersion
    RETVAL="$?"
    if [[ $RETVAL -eq 1 ]]; then
        colorEcho ${BLUE} "Found new version ${NEW_VER} for Kcptun-server.(Current version:$CUR_VER)"
    elif [[ $RETVAL -eq 0 ]]; then
        colorEcho ${BLUE} "No new version. Current version is ${NEW_VER}."
    elif [[ $RETVAL -eq 2 ]]; then
        colorEcho ${YELLOW} "No Kcptun-server installed."
        colorEcho ${BLUE} "The newest version for Kcptun-server is ${NEW_VER}."
    fi
    return 0
}

main(){
    #helping information
    [[ "$HELP" == "1" ]] && Help && return
    [[ "$CHECK" == "1" ]] && checkUpdate && return
    [[ "$REMOVE" == "1" ]] && remove && return

    local ARCH=$(uname -m)
    VDIS="$(archAffix)"

    # extract local file
    if [[ $LOCAL_INSTALL -eq 1 ]]; then
        colorEcho ${YELLOW} "Installing Kcptun-server via local file. Please make sure the file is a valid Kcptun-server package, as we are not able to determine that."
        NEW_VER=local
        rm -rf /tmp/kcptun
        ZIPFILE="$LOCAL"

    else
        # download via network and extract
        installSoftware "curl" || return $?
        getVersion
        RETVAL="$?"
        if [[ $RETVAL == 0 ]] && [[ "$FORCE" != "1" ]]; then
            colorEcho ${BLUE} "Latest version ${CUR_VER} is already installed."
            if [ -n "${ERROR_IF_UPTODATE}" ]; then
              return 10
            fi
            return
        elif [[ $RETVAL == 3 ]]; then
            return 3
        else
            colorEcho ${BLUE} "Installing Kcptun-server ${NEW_VER} on ${ARCH}"
            downloadKcptun || return $?
        fi
    fi


    installSoftware tar || return $?

    if [ -n "${EXTRACT_ONLY}" ]; then
        colorEcho ${BLUE} "Extracting Kcptun-server package to ${VSRC_ROOT}."

        if tar -zxpvf "${ZIPFILE}" -C ${VSRC_ROOT}; then
            colorEcho ${GREEN} "Kcptun-server extracted to ${VSRC_ROOT%/}${ZIPROOT:+/${ZIPROOT%/}}, and exiting..."
            return 0
        else
            colorEcho ${RED} "Failed to extract Kcptun-server."
            return 2
        fi
    fi

    if pgrep "kcptun-server" > /dev/null ; then
        V2RAY_RUNNING=1
        stopKcptun
    fi
    installKcptun "${ZIPFILE}" || return $?
    installInitScript "${ZIPFILE}" "${ZIPROOT}" || return $?
    if [[ ${V2RAY_RUNNING} -eq 1 ]];then
        colorEcho ${BLUE} "Restarting Kcptun-server service."
        startKcptun
    fi
    colorEcho ${GREEN} "Kcptun-server ${NEW_VER} is installed."
    rm -rf /tmp/kcptun
    return 0
}

main
