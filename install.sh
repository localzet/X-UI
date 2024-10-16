#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

function LOGD() {
    echo -e "${yellow}[DEG] $* ${plain}"
}

function LOGE() {
    echo -e "${red}[ERR] $* ${plain}"
}

function LOGI() {
    echo -e "${green}[INF] $* ${plain}"
}

cur_dir=$(pwd)

# Проверка прав
[[ $EUID -ne 0 ]] && LOGE "Ошибка: Пожалуйста, запустите скрипт с root-правами! \n " && exit 1

# Проверка ОС
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "Не удалось проверить ОС системы, свяжитесь с автором!" >&2
    exit 1
fi

echo "Ваша OS: $release"

arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    s390x) echo 's390x' ;;
    *) echo -e "${green}Неподдерживаемая архитектура CPU! ${plain}" && rm -f install.sh && exit 1 ;;
    esac
}

echo "Архитектура: $(arch)"

os_version=""
os_version=$(grep "^VERSION_ID" /etc/os-release | cut -d '=' -f2 | tr -d '"' | tr -d '.')

if [[ "${release}" == "arch" ]]; then
    echo "Ваша OS - Arch Linux"
elif [[ "${release}" == "parch" ]]; then
    echo "Ваша OS - Parch linux"
elif [[ "${release}" == "manjaro" ]]; then
    echo "Ваша OS - Manjaro"
elif [[ "${release}" == "armbian" ]]; then
    echo "Ваша OS - Armbian"
elif [[ "${release}" == "opensuse-tumbleweed" ]]; then
    echo "Ваша OS - OpenSUSE Tumbleweed"
elif [[ "${release}" == "openEuler" ]]; then
    if [[ ${os_version} -lt 2203 ]]; then
        echo -e "${red} Пожалуйста используйте OpenEuler 22.03 или выше ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "centos" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} Пожалуйста используйте CentOS 8 или выше ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ubuntu" ]]; then
    if [[ ${os_version} -lt 2004 ]]; then
        echo -e "${red} Пожалуйста используйте Ubuntu 20 или выше ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "fedora" ]]; then
    if [[ ${os_version} -lt 36 ]]; then
        echo -e "${red} Пожалуйста используйте Fedora 36 или выше ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "amzn" ]]; then
    if [[ ${os_version} != "2023" ]]; then
        echo -e "${red} Пожалуйста используйте Amazon Linux 2023!${plain}\n" && exit 1
    fi
elif [[ "${release}" == "debian" ]]; then
    if [[ ${os_version} -lt 11 ]]; then
        echo -e "${red} Пожалуйста используйте Debian 11 или выше ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "almalinux" ]]; then
    if [[ ${os_version} -lt 80 ]]; then
        echo -e "${red} Пожалуйста используйте AlmaLinux 8.0 или выше ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "rocky" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} Пожалуйста используйте Rocky Linux 8 или выше ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ol" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} Пожалуйста используйте Oracle Linux 8 или выше ${plain}\n" && exit 1
    fi
else
    echo -e "${red}Ваша операционная система не поддерживается данным скриптом.${plain}\n"
    echo "Убедитесь, что вы используете одну из поддерживаемых операционных систем:"
    echo "- Ubuntu 20.04+"
    echo "- Debian 11+"
    echo "- CentOS 8+"
    echo "- OpenEuler 22.03+"
    echo "- Fedora 36+"
    echo "- Arch Linux"
    echo "- Parch Linux"
    echo "- Manjaro"
    echo "- Armbian"
    echo "- AlmaLinux 8.0+"
    echo "- Rocky Linux 8+"
    echo "- Oracle Linux 8+"
    echo "- OpenSUSE Tumbleweed"
    echo "- Amazon Linux 2023"
    exit 1
fi

install_base() {
    case "${release}" in
    ubuntu | debian | armbian)
        apt-get update && apt-get install -y -q wget curl tar tzdata cron
        ;;
    centos | almalinux | rocky | ol)
        yum -y update && yum install -y -q wget curl tar tzdata
        ;;
    fedora | amzn)
        dnf -y update && dnf install -y -q wget curl tar tzdata
        ;;
    arch | manjaro | parch)
        pacman -Syu && pacman -Syu --noconfirm wget curl tar tzdata
        ;;
    opensuse-tumbleweed)
        zypper refresh && zypper -q install -y wget curl tar timezone
        ;;
    *)
        apt-get update && apt install -y -q wget curl tar tzdata
        ;;
    esac
}

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
    echo "$random_string"
}

# Установка зоны безопасности
config_after_install() {

#    local existing_username=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'username: .+' | awk '{print $2}')
#    local existing_password=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'password: .+' | awk '{print $2}')
#    local existing_webBasePath=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}')
#
#    if [[ -n "$existing_username" && -n "$existing_password" ]]; then
#        if [[ ${#existing_webBasePath} -lt 4 ]]; then
#            local config_webBasePath=$(gen_random_string 15)
#            echo -e "${yellow}Путь диспетчерской отсутствует или слишком короткий. Генерация новго...${plain}"
#            /usr/local/x-ui/x-ui setting -webBasePath "${config_webBasePath}"
#            echo -e "${green}Новый путь диспетчерской: ${config_webBasePath}${plain}"
#        else
#            echo -e "${green}Имя пользователя, пароль и путь диспетчерской уже заданы. Завершение...${plain}"
#            return 0
#        fi
#    fi

    echo -e "${yellow}Установка/обновление завершено! В целях безопасности рекомендую изменить настройки панели ${plain}"
    read -p "Хотите изменить настройки панели сейчас? (Если нет - данные сгенерируются автоматически) [y/N]: " config_confirm

    if [[ "${config_confirm}" == "y" || "${config_confirm}" == "Y" || "${config_confirm}" == "д" || "${config_confirm}" == "Д" ]]; then
        read -p "Установите имя пользователя: " config_account
        echo -e "${yellow}Имя пользователя: ${config_account}${plain}"
        read -p "Установите пароль: " config_password
        echo -e "${yellow}Пароль: ${config_password}${plain}"
        read -p "Установите порт диспетчерской: " config_port
        echo -e "${yellow}Порт диспетчерской: ${config_port}${plain}"
        read -p "Установите путь диспетчерской ({ip}:{порт}/путь-диспетчерской/): " config_webBasePath
        echo -e "${yellow}Путь диспетчерской: ${config_webBasePath}${plain}"

        /usr/local/x-ui/x-ui setting -username "${config_account}" -password "${config_password}" -port "${config_port}" -webBasePath "${config_webBasePath}"
        echo -e "${yellow}Данные сохранены!${plain}"
    else
        if [[ ! -f "/etc/x-ui/x-ui.db" ]]; then
            local usernameTemp=$(gen_random_string 10)
            local passwordTemp=$(gen_random_string 10)
            local portTemp=$(shuf -i 1024-62000 -n 1)
            local webBasePathTemp=$(gen_random_string 15)

            /usr/local/x-ui/x-ui setting -username "${usernameTemp}" -password "${passwordTemp}" -port "${portTemp}" -webBasePath "${webBasePathTemp}"

            echo -e "Это свежая установка, генерируем случайные данные в целях безопасности:"
            echo -e "###############################################"
            echo -e "${green}Имя пользователя: ${usernameTemp}${plain}"
            echo -e "${green}Пароль: ${passwordTemp}${plain}"
            echo -e "${green}Путь диспетчерской: ${webBasePathTemp}${plain}"
            echo -e "###############################################"
            echo -e "${yellow}Если вы забыли данные для входа, выполните "x-ui settings" для проверки после установки${plain}"
        else
            echo -e "${yellow}Это обновление, оставляем старые данные. Если вы забыли данные для входа, выполните "x-ui settings" для проверки${plain}"
        fi
    fi
    /usr/local/x-ui/x-ui migrate
}

install_x-ui() {
    cd /usr/local/

    if [ $# == 0 ]; then
        tag_version=$(curl -Ls "https://api.github.com/repos/localzet/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$tag_version" ]]; then
            echo -e "${red}Ошибка получения версии x-ui, возможно, это связано с ограничениями API Github, попробуйте позже${plain}"
            exit 1
        fi
        echo -e "Получена версия x-ui: ${tag_version}, запуск установки..."
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-$(arch).tar.gz https://github.com/localzet/x-ui/releases/download/${tag_version}/x-ui-linux-$(arch).tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Ошибка загрузки x-ui, пожалуйста, убедитесь, что ваш сервер имеет доступ к Github ${plain}"
            exit 1
        fi
    else
        tag_version=$1
        tag_version_numeric=${tag_version#v}
        min_version="2.4.4"

        if [[ "$(printf '%s\n' "$min_version" "$tag_version_numeric" | sort -V | head -n1)" != "$min_version" ]]; then
            echo -e "${red}Пожалуйста используйте более новую версию (v2.4.4 или новее).${plain}"
            exit 1
        fi

        url="https://github.com/localzet/x-ui/releases/download/${tag_version}/x-ui-linux-$(arch).tar.gz"
        echo -e "Запуск установки x-ui $1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-$(arch).tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Ошибка загрузки x-ui $1, пожалуйста, проверьте, существует ли версия ${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        systemctl stop x-ui
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-$(arch).tar.gz
    rm x-ui-linux-$(arch).tar.gz -f
    cd x-ui
    chmod +x x-ui

    # Проверка архитектуры системы и именование файла соответствующим образом.
    if [[ $(arch) == "armv5" || $(arch) == "armv6" || $(arch) == "armv7" ]]; then
        mv bin/xray-linux-$(arch) bin/xray-linux-arm
        chmod +x bin/xray-linux-arm
    fi

    chmod +x x-ui bin/xray-linux-$(arch)
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/localzet/x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    config_after_install

    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}x-ui ${tag_version}${plain} установка завершена, программа запущена..."
    echo -e ""
    show_usage
}

show_usage() {
    echo -e "Аппаратная панель управления X-UI: "
    echo -e "----------------------------------------------"
    echo -e "КОМАНДЫ:"
    echo -e "x-ui              - Панель управления"
    echo -e "x-ui start        - Запуск"
    echo -e "x-ui stop         - Остановка"
    echo -e "x-ui restart      - Перезапуск"
    echo -e "x-ui status       - Текущий статус"
    echo -e "x-ui settings     - Текущие настройки"
    echo -e "x-ui enable       - Включить автозапуск при запуске ОС"
    echo -e "x-ui disable      - Отключить автозапуск при запуске ОС"
    echo -e "x-ui log          - Проверка журналов"
    echo -e "x-ui banlog       - Проверка журналов бана Fail2ban"
    echo -e "x-ui update       - Обновление"
    echo -e "x-ui custom       - Пользовательская версия"
    echo -e "x-ui install      - Установка"
    echo -e "x-ui uninstall    - Удаление"
    echo -e "----------------------------------------------"
}

echo -e "${green}Запуск...${plain}"
install_base
install_x-ui $1
