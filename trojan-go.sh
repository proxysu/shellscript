#!/bin/bash

# Trojan-go install script Forked from https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh

# The files installed by the script conform to the Filesystem Hierarchy Standard:
# https://wiki.linuxfoundation.org/lsb/fhs

# The URL of the script project is:
# https://github.com/proxysu/shellscript

# The URL of the script is:
# https://github.com/proxysu/shellscript/master/install-release.sh

# If the script executes incorrectly, go to:
# https://github.com/proxysu/shellscript/issues

# trojan-go.sh installed:
# /usr/local/bin/trojan-go
# /usr/local/etc/trojan-go/config.json
# /etc/systemd/system/trojan-go.service
# /etc/systemd/system/trojan-go@.service
# /usr/share/trojan-go/geoip.dat
# /usr/share/trojan-go/geosite.dat
# /var/log/trojan-go

# systemctl start trojan-go
# systemctl stop trojan-go
# systemctl restart trojan-go

# remove
# trojan-go.sh --remove


DAT_PATH='/usr/share/trojan-go/'
JSON_PATH='/usr/local/etc/trojan-go/'

check_if_running_as_root() {
    # If you want to run as another user, please modify $UID to be owned by this user
    if [[ "$UID" -ne '0' ]]; then
        echo "error: You must run this script as root!"
        exit 1
    fi
}

identify_the_operating_system_and_architecture() {
    if [[ "$(uname)" == 'Linux' ]]; then
        case "$(uname -m)" in
            'i386' | 'i686')
                MACHINE='386'
                ;;
            'amd64' | 'x86_64')
                MACHINE='amd64'
                ;;
            'armv5tel')
                MACHINE='armv5'
                ;;
            'armv6l')
                MACHINE='armv6'
                ;;
            'armv7' | 'armv7l' )
                MACHINE='armv7'
                ;;
            'armv8' | 'aarch64')
                MACHINE='armv8'
                ;;
            'mips')
                MACHINE='mips-hardfloat'
                ;;
            'mipsle')
                MACHINE='mipsle-hardfloat'
                ;;
            'mips64')
                MACHINE='mips64'
                ;;
            'mips64le')
                MACHINE='mips64le'
                ;;
          #  'ppc64')
          #      MACHINE='ppc64'
          #      ;;
          #  'ppc64le')
          #      MACHINE='ppc64le'
          #      ;;
          #  'riscv64')
          #      MACHINE='riscv64'
          #      ;;
          #  's390x')
          #      MACHINE='s390x'
          #      ;;
            *)
                echo "error: The architecture is not supported."
                exit 1
                ;;
        esac
        if [[ ! -f '/etc/os-release' ]]; then
            echo "error: Don't use outdated Linux distributions."
            exit 1
        fi
        if [[ -z "$(ls -l /sbin/init | grep systemd)" ]]; then
            echo "error: Only Linux distributions using systemd are supported."
            exit 1
        fi
        if [[ "$(command -v apt)" ]]; then
            PACKAGE_MANAGEMENT_INSTALL='apt install'
            PACKAGE_MANAGEMENT_REMOVE='apt remove'
        elif [[ "$(command -v yum)" ]]; then
            PACKAGE_MANAGEMENT_INSTALL='yum install'
            PACKAGE_MANAGEMENT_REMOVE='yum remove'
            if [[ "$(command -v dnf)" ]]; then
                PACKAGE_MANAGEMENT_INSTALL='dnf install'
                PACKAGE_MANAGEMENT_REMOVE='dnf remove'
            fi
        elif [[ "$(command -v zypper)" ]]; then
            PACKAGE_MANAGEMENT_INSTALL='zypper install'
            PACKAGE_MANAGEMENT_REMOVE='zypper remove'
        else
            echo "error: The script does not support the package manager in this operating system."
            exit 1
        fi
    else
        echo "error: This operating system is not supported."
        exit 1
    fi
}

judgment_parameters() {
    if [[ "$#" -gt '0' ]]; then
        case "$1" in
            '--remove')
                if [[ "$#" -gt '1' ]]; then
                    echo 'error: Please enter the correct parameters.'
                    exit 1
                fi
                REMOVE='1'
                ;;
            '--version')
                if [[ "$#" -gt '2' ]] || [[ -z "$2" ]]; then
                    echo 'error: Please specify the correct version.'
                    exit 1
                fi
                VERSION="$2"
                ;;
            '-c' | '--check')
                if [[ "$#" -gt '1' ]]; then
                    echo 'error: Please enter the correct parameters.'
                    exit 1
                fi
                CHECK='1'
                ;;
            '-f' | '--force')
                if [[ "$#" -gt '1' ]]; then
                    echo 'error: Please enter the correct parameters.'
                    exit 1
                fi
                FORCE='1'
                ;;
            '-h' | '--help')
                if [[ "$#" -gt '1' ]]; then
                    echo 'error: Please enter the correct parameters.'
                    exit 1
                fi
                HELP='1'
                ;;
            '-l' | '--local')
                if [[ "$#" -gt '2' ]] || [[ -z "$2" ]]; then
                    echo 'error: Please specify the correct local file.'
                    exit 1
                fi
                LOCAL_FILE="$2"
                LOCAL_INSTALL='1'
                ;;
            '-p' | '--proxy')
                case "$2" in
                    'http://'*)
                        ;;
                    'https://'*)
                        ;;
                    'socks4://'*)
                        ;;
                    'socks4a://'*)
                        ;;
                    'socks5://'*)
                        ;;
                    'socks5h://'*)
                        ;;
                    *)
                        echo 'error: Please specify the correct proxy server address.'
                        exit 1
                        ;;
                esac
                PROXY="-x$2"
                # Parameters available through a proxy server
                if [[ "$#" -gt '2' ]]; then
                    case "$3" in
                        '--version')
                            if [[ "$#" -gt '4' ]] || [[ -z "$4" ]]; then
                                echo 'error: Please specify the correct version.'
                                exit 1
                            fi
                            VERSION="$2"
                            ;;
                        '-c' | '--check')
                            if [[ "$#" -gt '3' ]]; then
                                echo 'error: Please enter the correct parameters.'
                                exit 1
                            fi
                            CHECK='1'
                            ;;
                        '-f' | '--force')
                            if [[ "$#" -gt '3' ]]; then
                                echo 'error: Please enter the correct parameters.'
                                exit 1
                            fi
                            FORCE='1'
                            ;;
                        *)
                            echo "$0: unknown option -- -"
                            exit 1
                            ;;
                    esac
                fi
                ;;
            *)
                echo "$0: unknown option -- -"
                exit 1
                ;;
        esac
    fi
}

install_software() {
    COMPONENT="$1"
    if [[ -n "$(command -v "$COMPONENT")" ]]; then
        return
    fi
    ${PACKAGE_MANAGEMENT_INSTALL} "$COMPONENT"
    if [[ "$?" -ne '0' ]]; then
        echo "error: Installation of $COMPONENT failed, please check your network."
        exit 1
    fi
    echo "info: $COMPONENT is installed."
}

version_number() {
    case "$1" in
        'v'*)
            echo "$1"
            ;;
        *)
            echo "v$1"
            ;;
    esac
}

get_version() {
    # 0: Install or update Trojan-go.
    # 1: Installed or no new version of Trojan-go.
    # 2: Install the specified version of Trojan-go.
    if [[ -z "$VERSION" ]]; then
        # Determine the version number for Trojan-go installed from a local file
        if [[ -f '/usr/local/bin/trojan-go' ]]; then
            VERSION="$(/usr/local/bin/trojan-go -version)"
            CURRENT_VERSION="$(version_number $(echo "$VERSION" | head -n 1 | awk -F ' ' '{print $2}'))"
            if [[ "$LOCAL_INSTALL" -eq '1' ]]; then
                RELEASE_VERSION="$CURRENT_VERSION"
                return
            fi
        fi
        # Get Trojan-go release version number
        TMP_FILE="$(mktemp)"
        install_software curl
        # DO NOT QUOTE THESE `${PROXY}` VARIABLES!
        if ! curl ${PROXY} -s -o "$TMP_FILE" 'https://api.github.com/repos/p4gefau1t/trojan-go/tags'; then
            rm "$TMP_FILE"
            echo 'error: Failed to get release list, please check your network.'
            exit 1
        fi
        RELEASE_LATEST="$(sed 'y/,/\n/' "$TMP_FILE" | grep 'name' | head -n 1 | awk -F '"' '{print $4}')"
        rm "$TMP_FILE"
        RELEASE_VERSION="$(version_number "$RELEASE_LATEST")"
        # Compare Trojan-go version numbers
        if [[ "$RELEASE_VERSION" != "$CURRENT_VERSION" ]]; then
            RELEASE_VERSIONSION_NUMBER="${RELEASE_VERSION#v}"
            RELEASE_MAJOR_VERSION_NUMBER="${RELEASE_VERSIONSION_NUMBER%%.*}"
            RELEASE_MINOR_VERSION_NUMBER="$(echo "$RELEASE_VERSIONSION_NUMBER" | awk -F '.' '{print $2}')"
            RELEASE_MINIMUM_VERSION_NUMBER="${RELEASE_VERSIONSION_NUMBER##*.}"
            CURRENT_VERSIONSION_NUMBER="$(echo "${CURRENT_VERSION#v}" | sed 's/-.*//')"
            CURRENT_MAJOR_VERSION_NUMBER="${CURRENT_VERSIONSION_NUMBER%%.*}"
            CURRENT_MINOR_VERSION_NUMBER="$(echo "$CURRENT_VERSIONSION_NUMBER" | awk -F '.' '{print $2}')"
            CURRENT_MINIMUM_VERSION_NUMBER="${CURRENT_VERSIONSION_NUMBER##*.}"
            if [[ "$RELEASE_MAJOR_VERSION_NUMBER" -gt "$CURRENT_MAJOR_VERSION_NUMBER" ]]; then
                return 0
            elif [[ "$RELEASE_MAJOR_VERSION_NUMBER" -eq "$CURRENT_MAJOR_VERSION_NUMBER" ]]; then
                if [[ "$RELEASE_MINOR_VERSION_NUMBER" -gt "$CURRENT_MINOR_VERSION_NUMBER" ]]; then
                    return 0
                elif [[ "$RELEASE_MINOR_VERSION_NUMBER" -eq "$CURRENT_MINOR_VERSION_NUMBER" ]]; then
                    if [[ "$RELEASE_MINIMUM_VERSION_NUMBER" -gt "$CURRENT_MINIMUM_VERSION_NUMBER" ]]; then
                        return 0
                    else
                        return 1
                    fi
                else
                    return 1
                fi
            else
                return 1
            fi
        elif [[ "$RELEASE_VERSION" == "$CURRENT_VERSION" ]]; then
            return 1
        fi
    else
        RELEASE_VERSION="$(version_number "$VERSION")"
        return 2
    fi
}

download_trojan-go() {
    mkdir "$TMP_DIRECTORY"
    DOWNLOAD_LINK="https://github.com/p4gefau1t/trojan-go/releases/download/$RELEASE_VERSION/trojan-go-linux-$MACHINE.zip"
    echo "Downloading Trojan-go archive: $DOWNLOAD_LINK"
    if ! curl ${PROXY} -L -H 'Cache-Control: no-cache' -o "$ZIP_FILE" "$DOWNLOAD_LINK"; then
        echo 'error: Download failed! Please check your network or try again.'
        return 1
    fi
 #   echo "Downloading verification file for Trojan-go archive: $DOWNLOAD_LINK.dgst"
 #   if ! curl ${PROXY} -L -H 'Cache-Control: no-cache' -o "$ZIP_FILE.dgst" "$DOWNLOAD_LINK.dgst"; then
 #       echo 'error: Download failed! Please check your network or try again.'
 #       return 1
 #   fi
 #   if [[ "$(cat "$ZIP_FILE".dgst)" == 'Not Found' ]]; then
 #       echo 'error: This version does not support verification. Please replace with another version.'
 #       return 1
 #   fi

    # Verification of Trojan-go archive
 #   for LISTSUM in 'md5' 'sha1' 'sha256' 'sha512'; do
 #       SUM="$(${LISTSUM}sum "$ZIP_FILE" | sed 's/ .*//')"
 #       CHECKSUM="$(grep ${LISTSUM^^} "$ZIP_FILE".dgst | grep "$SUM" -o -a | uniq)"
 #       if [[ "$SUM" != "$CHECKSUM" ]]; then
 #           echo 'error: Check failed! Please check your network or try again.'
 #           return 1
 #       fi
 #   done
}

decompression() {
    if ! unzip -q "$1" -d "$TMP_DIRECTORY"; then
        echo 'error: Trojan-go decompression failed.'
        rm -r "$TMP_DIRECTORY"
        echo "removed: $TMP_DIRECTORY"
        exit 1
    fi
    echo "info: Extract the Trojan-go package to $TMP_DIRECTORY and prepare it for installation."
}

install_file() {
    NAME="$1"
    if [[ "$NAME" == 'trojan-go' ]]; then
        install -m 755 "${TMP_DIRECTORY}$NAME" "/usr/local/bin/$NAME"
    elif [[ "$NAME" == 'geoip.dat' ]] || [[ "$NAME" == 'geosite.dat' ]]; then
        install -m 644 "${TMP_DIRECTORY}$NAME" "${DAT_PATH}$NAME"
    elif [[ "$NAME" == 'server.json' ]]; then
        install -m 644 "${TMP_DIRECTORY}example/$NAME" "${JSON_PATH}config.json"
    fi
}

install_trojan-go() {
    # Install trojan-go binary to /usr/local/bin/ and $DAT_PATH
    install_file trojan-go
    # install_file v2ctl
    install -d "$DAT_PATH"
    # If the file exists, geoip.dat and geosite.dat will not be installed or updated
    if [[ ! -f "${DAT_PATH}.undat" ]]; then
        install_file geoip.dat
        install_file geosite.dat
    fi

    # Install trojan-go configuration file to $JSON_PATH
    if [[ ! -d "$JSON_PATH" ]]; then
        install -d "$JSON_PATH"
        if [[ ! -f "${JSON_PATH}.unjson" ]]; then
            install_file server.json
        fi
        CONFDIR='1'
    fi

    # Used to store Trojan-go log files
    #if [[ ! -d '/var/log/trojan-go/' ]]; then
    #    if [[ -n "$(id nobody | grep nogroup)" ]]; then
    #        install -d -m 700 -o nobody -g nogroup /var/log/trojan-go/
    #    else
    #        install -d -m 700 -o nobody -g nobody /var/log/trojan-go/
    #    fi
    #    LOG='1'
    #fi
}

install_startup_service_file() {
    if [[ ! -f '/etc/systemd/system/trojan-go.service' ]]; then
        mkdir -p "${TMP_DIRECTORY}systemd/system/"
        #install_software curl
        cat > "${TMP_DIRECTORY}systemd/system/trojan-go.service" <<-EOF
[Unit]
Description=Trojan-go Service
After=network.target nss-lookup.target
[Service]
#User=nobody
User=root
#CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
#AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
#Environment=V2RAY_LOCATION_ASSET=/usr/local/share/v2ray/
ExecStart=/usr/local/bin/trojan-go -config /usr/local/etc/trojan-go/config.json
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
        cat > "${TMP_DIRECTORY}systemd/system/trojan-go@.service" <<-EOF
[Unit]
Description=Trojan-go Service
After=network.target nss-lookup.target
[Service]
#User=nobody
User=root
#CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
#AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
#Environment=V2RAY_LOCATION_ASSET=/usr/local/share/v2ray/
ExecStart=/usr/local/bin/trojan-go -config /usr/local/etc/trojan-go/%i.json
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
        install -m 644 "${TMP_DIRECTORY}systemd/system/trojan-go.service" /etc/systemd/system/trojan-go.service
        install -m 644 "${TMP_DIRECTORY}systemd/system/trojan-go@.service" /etc/systemd/system/trojan-go@.service
        
       # if ! curl ${PROXY} -s -o "${TMP_DIRECTORY}systemd/system/v2ray.service" 'https://raw.githubusercontent.workers.dev/v2fly/fhs-install-v2ray/master/systemd/system/v2ray.service'; then
            # echo 'error: Failed to start service file download! Please check your network or try again.'
            # exit 1
        # fi
        # if ! curl ${PROXY} -s -o "${TMP_DIRECTORY}systemd/system/v2ray@.service" 'https://raw.githubusercontent.workers.dev/v2fly/fhs-install-v2ray/master/systemd/system/v2ray@.service'; then
            # echo 'error: Failed to start service file download! Please check your network or try again.'
            # exit 1
        # fi
        #install -m 644 "${TMP_DIRECTORY}example/trojan-go.service" /etc/systemd/system/trojan-go.service
        #sed -i 's/usr\/bin\/trojan-go/usr\/local\/bin\/trojan-go/' /etc/systemd/system/trojan-go.service
        #sed -i 's/etc\/trojan-go/usr\/local\/etc\/trojan-go/' /etc/systemd/system/trojan-go.service
       # sed -i 's/User=nobody/#User=nobody/' /etc/systemd/system/trojan-go.service

        
        #install -m 644 "${TMP_DIRECTORY}example/trojan-go@.service" /etc/systemd/system/trojan-go@.service
        #sed -i 's/usr\/bin\/trojan-go/usr\/local\/bin\/trojan-go/' /etc/systemd/system/trojan-go@.service
        #sed -i 's/etc\/trojan-go/usr\/local\/etc\/trojan-go/' /etc/systemd/system/trojan-go@.service
       # sed -i 's/User=nobody/#User=nobody/' /etc/systemd/system/trojan-go@.service
        
        SYSTEMD='1'
    fi
}

start_trojan-go() {
    if [[ -f '/etc/systemd/system/trojan-go.service' ]]; then
        if [[ -z "$TROJAN_GO_CUSTOMIZE" ]]; then
            systemctl start trojan-go
        else
            systemctl start "$TROJAN_GO_CUSTOMIZE"
        fi
    fi
    if [[ "$?" -ne 0 ]]; then
        echo 'error: Failed to start Trojan-go service.'
        exit 1
    fi
    echo 'info: Start the Trojan-go service.'
}

stop_trojan-go() {
    TROJAN_GO_CUSTOMIZE="$(systemctl list-units | grep 'trojan-go' | awk -F ' ' '{print $1}')"
    if [[ -z "$TROJAN_GO_CUSTOMIZE" ]]; then
        systemctl stop trojan-go
    else
        systemctl stop "$TROJAN_GO_CUSTOMIZE"
    fi
    if [[ "$?" -ne '0' ]]; then
        echo 'error: Stopping the Trojan-go service failed.'
        exit 1
    fi
    echo 'info: Stop the Trojan-go service.'
}

check_update() {
    if [[ -f '/etc/systemd/system/trojan-go.service' ]]; then
        get_version
        if [[ "$?" -eq '0' ]]; then
            echo "info: Found the latest release of Trojan-go $RELEASE_VERSION . (Current release: $CURRENT_VERSION)"
        elif [[ "$?" -eq '1' ]]; then
            echo "info: No new version. The current version of Trojan-go is $CURRENT_VERSION ."
        fi
        exit 0
    else
        echo 'error: Trojan-go is not installed.'
        exit 1
    fi
}

remove_trojan-go() {
    if [[ -n "$(systemctl list-unit-files | grep 'trojan-go')" ]]; then
        if [[ -n "$(pidof trojan-go)" ]]; then
            stop_trojan-go
        fi
        NAME="$1"
        rm /usr/local/bin/trojan-go
        #rm /usr/local/bin/v2ctl
        rm -r "$DAT_PATH"
        rm /etc/systemd/system/trojan-go.service
        rm /etc/systemd/system/trojan-go@.service
        if [[ "$?" -ne '0' ]]; then
            echo 'error: Failed to remove Trojan-go.'
            exit 1
        else
            echo 'removed: /usr/local/bin/trojan-go'
            #echo 'removed: /usr/local/bin/v2ctl'
            echo "removed: $DAT_PATH"
            echo 'removed: /etc/systemd/system/trojan-go.service'
            echo 'removed: /etc/systemd/system/trojan-go@.service'
            echo 'Please execute the command: systemctl disable trojan-go'
            echo "You may need to execute a command to remove dependent software: $PACKAGE_MANAGEMENT_REMOVE curl unzip"
            echo 'info: Trojan-go has been removed.'
            echo 'info: If necessary, manually delete the configuration and log files.'
            echo "info: e.g., $JSON_PATH and /var/log/trojan-go/ ..."
            exit 0
        fi
    else
        echo 'error: Trojan-go is not installed.'
        exit 1
    fi
}

# Explanation of parameters in the script
show_help() {
    echo "usage: $0 [--remove | --version number | -c | -f | -h | -l | -p]"
    echo '  [-p address] [--version number | -c | -f]'
    echo '  --remove        Remove Trojan-go'
    echo '  --version       Install the specified version of Trojan-go, e.g., --version v0.18.0'
    echo '  -c, --check     Check if Trojan-go can be updated'
    echo '  -f, --force     Force installation of the latest version of Trojan-go'
    echo '  -h, --help      Show help'
    echo '  -l, --local     Install Trojan-go from a local file'
    echo '  -p, --proxy     Download through a proxy server, e.g., -p http://127.0.0.1:8118 or -p socks5://127.0.0.1:1080'
    exit 0
}

main() {
    check_if_running_as_root
    identify_the_operating_system_and_architecture
    judgment_parameters "$@"

    # Parameter information
    [[ "$HELP" -eq '1' ]] && show_help
    [[ "$CHECK" -eq '1' ]] && check_update
    [[ "$REMOVE" -eq '1' ]] && remove_trojan-go

    # Two very important variables
    TMP_DIRECTORY="$(mktemp -du)/"
    ZIP_FILE="${TMP_DIRECTORY}trojan-go-linux-$MACHINE.zip"

    # Install Trojan-go from a local file, but still need to make sure the network is available
    if [[ "$LOCAL_INSTALL" -eq '1' ]]; then
        echo 'warn: Install Trojan-go from a local file, but still need to make sure the network is available.'
        echo -n 'warn: Please make sure the file is valid because we cannot confirm it. (Press any key) ...'
        read
        install_software unzip
        mkdir "$TMP_DIRECTORY"
        decompression "$LOCAL_FILE"
    else
        # Normal way
        get_version
        NUMBER="$?"
        if [[ "$NUMBER" -eq '0' ]] || [[ "$FORCE" -eq '1' ]] || [[ "$NUMBER" -eq 2 ]]; then
            echo "info: Installing Trojan-go $RELEASE_VERSION for $(uname -m)"
            download_trojan-go
            if [[ "$?" -eq '1' ]]; then
                rm -r "$TMP_DIRECTORY"
                echo "removed: $TMP_DIRECTORY"
                exit 0
            fi
            install_software unzip
            decompression "$ZIP_FILE"
        elif [[ "$NUMBER" -eq '1' ]]; then
            echo "info: No new version. The current version of Trojan-go is $CURRENT_VERSION ."
            exit 0
        fi
    fi

    # Determine if Trojan-go is running
    if [[ -n "$(systemctl list-unit-files | grep 'trojan-go')" ]]; then
        if [[ -n "$(pidof trojan-go)" ]]; then
            stop_trojan-go
            TROJAN_GO_RUNNING='1'
        fi
    fi
    install_trojan-go
    install_startup_service_file
    echo 'installed: /usr/local/bin/trojan-go'
    #echo 'installed: /usr/local/bin/v2ctl'
    # If the file exists, the content output of installing or updating geoip.dat and geosite.dat will not be displayed
    if [[ ! -f "${DAT_PATH}.undat" ]]; then
        echo "installed: ${DAT_PATH}geoip.dat"
        echo "installed: ${DAT_PATH}geosite.dat"
    fi
    if [[ "$CONFDIR" -eq '1' ]]; then
        echo "installed: ${JSON_PATH}config.json"
        # echo "installed: ${JSON_PATH}00_log.json"
        # echo "installed: ${JSON_PATH}01_api.json"
        # echo "installed: ${JSON_PATH}02_dns.json"
        # echo "installed: ${JSON_PATH}03_routing.json"
        # echo "installed: ${JSON_PATH}04_policy.json"
        # echo "installed: ${JSON_PATH}05_inbounds.json"
        # echo "installed: ${JSON_PATH}06_outbounds.json"
        # echo "installed: ${JSON_PATH}07_transport.json"
        # echo "installed: ${JSON_PATH}08_stats.json"
        # echo "installed: ${JSON_PATH}09_reverse.json"
    fi
    # if [[ "$LOG" -eq '1' ]]; then
        # echo 'installed: /var/log/trojan-go/'
    # fi
    if [[ "$SYSTEMD" -eq '1' ]]; then
        echo 'installed: /etc/systemd/system/trojan-go.service'
        echo 'installed: /etc/systemd/system/trojan-go@.service'
    fi
    rm -r "$TMP_DIRECTORY"
    echo "removed: $TMP_DIRECTORY"
    if [[ "$LOCAL_INSTALL" -eq '1' ]]; then
        get_version
    fi
    echo "info: Trojan-go $RELEASE_VERSION is installed."
    echo "You may need to execute a command to remove dependent software: $PACKAGE_MANAGEMENT_REMOVE curl unzip"
    if [[ "$TROJAN_GO_RUNNING" -eq '1' ]]; then
        start_trojan-go
    else
        echo 'Please execute the command: systemctl enable trojan-go; systemctl start trojan-go'
    fi
}

main "$@"
