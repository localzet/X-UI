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

# Проверка прав
[[ $EUID -ne 0 ]] && LOGE "Ошибка: Пожалуйста, запустите скрипт с root-правами! \n" && exit 1

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
os_version=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)

if [[ "${release}" == "arch" ]]; then
    echo "Ваша OS - Arch Linux"
elif [[ "${release}" == "parch" ]]; then
    echo "Ваша OS - Parch linux"
elif [[ "${release}" == "manjaro" ]]; then
    echo "Ваша OS - Manjaro"
elif [[ "${release}" == "armbian" ]]; then
    echo "Ваша OS - Armbian"
elif [[ "${release}" == "alpine" ]]; then
    echo "Ваша OS - Alpine Linux"
elif [[ "${release}" == "opensuse-tumbleweed" ]]; then
    echo "Ваша OS - OpenSUSE Tumbleweed"
elif [[ "${release}" == "centos" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} Пожалуйста используйте CentOS 8 или выше ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ubuntu" ]]; then
    if [[ ${os_version} -lt 20 ]]; then
        echo -e "${red} Пожалуйста используйте Ubuntu 20 или выше ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "fedora" ]]; then
    if [[ ${os_version} -lt 36 ]]; then
        echo -e "${red} Пожалуйста используйте Fedora 36 или выше ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "debian" ]]; then
    if [[ ${os_version} -lt 11 ]]; then
        echo -e "${red} Пожалуйста используйте Debian 11 или выше ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "almalinux" ]]; then
    if [[ ${os_version} -lt 9 ]]; then
        echo -e "${red} Пожалуйста используйте AlmaLinux 9 или выше ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "rocky" ]]; then
    if [[ ${os_version} -lt 9 ]]; then
        echo -e "${red} Пожалуйста используйте Rocky Linux 9 или выше ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "oracle" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} Пожалуйста используйте Oracle Linux 8 или выше ${plain}\n" && exit 1
    fi
else
    echo -e "${red}Ваша операционная система не поддерживается данным скриптом.${plain}\n"
    echo "Убедитесь, что вы используете одну из поддерживаемых операционных систем:"
    echo "- Ubuntu 20.04+"
    echo "- Debian 11+"
    echo "- CentOS 8+"
    echo "- Fedora 36+"
    echo "- Arch Linux"
    echo "- Parch Linux"
    echo "- Manjaro"
    echo "- Armbian"
    echo "- AlmaLinux 9+"
    echo "- Rocky Linux 9+"
    echo "- Oracle Linux 8+"
    echo "- OpenSUSE Tumbleweed"
    exit 1
fi

log_folder="${XUI_LOG_FOLDER:=/var/log}"
iplimit_log_path="${log_folder}/3xipl.log"
iplimit_banned_log_path="${log_folder}/3xipl-banned.log"

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [По умолчанию $2]: " temp
        if [[ "${temp}" == "" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [д/Н]: " temp
    fi
    if [[ "${temp}" == "y" || "${temp}" == "Y" || "${temp}" == "д" || "${temp}" == "Д" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Перезапустите панель. Внимание: перезапуск панели также приведет к перезапуску Xray [Д/н]" "д"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Нажмите Enter, чтобы вернуться в главное меню.: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/localzet/x-ui/main/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    confirm "Эта функция принудительно переустановит последнюю версию, и данные не будут потеряны. Хотите продолжить? [Д/н]" "д"
    if [[ $? != 0 ]]; then
        LOGE "Отмена..."
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/localzet/x-ui/main/install.sh)
    if [[ $? == 0 ]]; then
        LOGI "Обновление завершено, панель автоматически перезагрузилась."
        before_show_menu
    fi
}

update_menu() {
    echo -e "${yellow}Обновление скрипта${plain}"
    confirm "Эта функция обновит скрипт до последних изменений.. [Д/н]" "д"
    if [[ $? != 0 ]]; then
        LOGE "Отмена..."
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/localzet/x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    
     if [[ $? == 0 ]]; then
        echo -e "${green}Обновление прошло успешно. Панель автоматически перезагрузилась..${plain}"
        before_show_menu
    else
        echo -e "${red}Не удалось обновить скрипт..${plain}"
        return 1
    fi
}

custom_version() {
    echo "Введите версию панели (Например, 2.0.0):"
    read panel_version

    if [ -z "$panel_version" ]; then
        echo "Версия панели не может быть пустой. Выход."
        exit 1
    fi

    download_link="https://raw.githubusercontent.com/localzet/x-ui/master/install.sh"
    install_command="bash <(curl -Ls $download_link) v$panel_version"

    echo "Загрузка и установка версии панели $panel_version..."
    eval $install_command
}

delete_script() {
    rm "$0"  # Удалить сам файл скрипта
    exit 1
}

uninstall() {
    confirm "Вы уверены, что хотите удалить панель? XRay также будет удален! [д/Н]" "н"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop x-ui
    systemctl disable x-ui
    rm /etc/systemd/system/x-ui.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/x-ui/ -rf
    rm /usr/local/x-ui/ -rf

    echo ""
    echo -e "Успешно удалено.\n"
    echo "Если вам нужно установить эту панель снова, вы можете использовать следующую команду:"
    echo -e "${green}bash <(curl -Ls https://raw.githubusercontent.com/localzet/x-ui/master/install.sh)${plain}"
    echo ""

    # Перехват сигнала SIGTERM
    trap delete_script SIGTERM
    delete_script
}

reset_user() {
    confirm "Вы уверены, что хотите сбросить имя пользователя и пароль панели?? [д/Н]" "н"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    read -rp "Установите имя пользователя [По умолчанию - случайные данные]: " config_account
    [[ -z $config_account ]] && config_account=$(date +%s%N | md5sum | cut -c 1-8)
    read -rp "Установите пароль [По умолчанию - случайные данные]: " config_password
    [[ -z $config_password ]] && config_password=$(date +%s%N | md5sum | cut -c 1-8)
    /usr/local/x-ui/x-ui setting -username ${config_account} -password ${config_password} >/dev/null 2>&1
    /usr/local/x-ui/x-ui setting -remove_secret >/dev/null 2>&1
    echo -e "Имя пользователя: ${green} ${config_account} ${plain}"
    echo -e "Пароль: ${green} ${config_password} ${plain}"
    echo -e "${yellow} Секретный токен входа в панель отключен ${plain}"
    echo -e "${green} Пожалуйста, используйте новое имя пользователя и пароль для входа в панель X-UI. Запомните их! ${plain}"
    confirm_restart
}

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
    echo "$random_string"
}

reset_webbasepath() {
    echo -e "${yellow}Сброс пути диспетчерской${plain}"
    read -rp "Укажите новый путь диспетчерской [Введите 'y' для генерации рандомного]: " config_webBasePath
    
    if [[ $config_webBasePath == "y" ]]; then
        config_webBasePath=$(gen_random_string 10)
    fi
    
    /usr/local/x-ui/x-ui setting -webBasePath "${config_webBasePath}" >/dev/null 2>&1
    systemctl restart x-ui
    
    echo -e "Новый путь диспетчерской: ${green}${config_webBasePath}${plain}"
    echo -e "${green}Используйте новый URL для доступа к панели диспетчера.${plain}"
}

reset_config() {
    confirm "Вы уверены, что хотите сбросить все настройки панели? Данные учетной записи не будут потеряны, имя пользователя и пароль не изменятся. [д/Н]" "н"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -reset
    echo -e "Все настройки панели сброшены до значений по умолчанию. Пожалуйста, перезапустите панель сейчас и используйте порт ${green}2053${plain} для доступа к веб-панели."
    confirm_restart
}

check_config() {
    local info=$(/usr/local/x-ui/x-ui setting -show true)
    if [[ $? != 0 ]]; then
        LOGE "Ошибка текущих настроек. Проверьте журналы."
        show_menu
        return
    fi
    LOGI "${info}"

    local existing_webBasePath=$(echo "$info" | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(echo "$info" | grep -Eo 'port: .+' | awk '{print $2}')
    local existing_cert=$(/usr/local/x-ui/x-ui setting -getCert true | grep -Eo 'cert: .+' | awk '{print $2}')
    local server_ip=$(curl -s https://api.ipify.org)

    if [[ -n "$existing_cert" ]]; then
        local domain=$(basename "$(dirname "$existing_cert")")

        if [[ "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo -e "${green}URL: https://${domain}:${existing_port}${existing_webBasePath}${plain}"
        else
            echo -e "${green}URL: https://${server_ip}:${existing_port}${existing_webBasePath}${plain}"
        fi
    else
        echo -e "${green}URL: http://${server_ip}:${existing_port}${existing_webBasePath}${plain}"
    fi
}

set_port() {
    echo && echo -n -e "Введите порт [1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        LOGD "Cancelled"
        before_show_menu
    else
        /usr/local/x-ui/x-ui setting -port ${port}
        echo -e "Порт установлен. Пожалуйста, перезагрузите панель и используйте новый порт ${green}${port}${plain} для доступа к веб-панели"
        confirm_restart
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        LOGI "Панель уже запущена. Если нужно её перезапустить, выберите «Перезапустить»."
    else
        systemctl start x-ui
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            LOGI "X-UI запущен!"
        else
            LOGE "Не удалось запустить панель. Вероятно, запуск занял больше двух секунд. Проверьте информацию журнала позже."
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        LOGI "Панель уже остановлена!"
    else
        systemctl stop x-ui
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            LOGI "X-UI и XRay остановлены!"
        else
            LOGE "Не удалось остановить панель. Вероятно, остановка заняла больше двух секунд. Проверьте информацию журнала позже."
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart x-ui
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        LOGI "X-UI и XRay перезапущены!"
    else
        LOGE "Перезапуск панели не удался. Вероятно, перезапуск занял больше двух секунд. Проверьте информацию журнала позже."
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status x-ui -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable x-ui
    if [[ $? == 0 ]]; then
        LOGI "Автозапуск X-UI активирован!"
    else
        LOGE "Не удалось активировать автозапуск X-UI"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable x-ui
    if [[ $? == 0 ]]; then
        LOGI "Автозапуск X-UI деактивирован!"
    else
        LOGE "Не удалось деактивировать автозапуск X-UI"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    echo -e "${green}\t1.${plain} Журнал отладки"
    echo -e "${green}\t2.${plain} Очистить все журналы"
    echo -e "${green}\t0.${plain} Вернуться в главное меню"
    read -p "Выберите вариант: " choice

    case "$choice" in
    0) show_menu ;;
    1)
        journalctl -u x-ui -e --no-pager -f -p debug
        if [[ $# == 0 ]]; then
            before_show_menu
        fi ;;
    2)
        sudo journalctl --rotate
        sudo journalctl --vacuum-time=1s
        echo "Все журналы очищены."
        restart ;;
    *)
      echo "Неверный выбор"
      show_log;;
    esac
}

show_banlog() {
    local system_log="/var/log/fail2ban.log"

    echo -e "${green}Проверка журнала блокировок...${plain}\n"

    if ! systemctl is-active --quiet fail2ban; then
        echo -e "${red}Fail2ban не запущен!${plain}\n"
        return 1
    fi

    if [[ -f "$system_log" ]]; then
        echo -e "${green}Последние действия по системному бану из fail2ban.log:${plain}"
        grep "x-ipl" "$system_log" | grep -E "Ban|Unban" | tail -n 10 || echo -e "${yellow}Недавних действий по системному бану не обнаружено${plain}"
        echo ""
    fi

    if [[ -f "${iplimit_banned_log_path}" ]]; then
        echo -e "${green}Записи в журнале запретов X-IPL:${plain}"
        if [[ -s "${iplimit_banned_log_path}" ]]; then
            grep -v "INIT" "${iplimit_banned_log_path}" | tail -n 10 || echo -e "${yellow}Записи о бане не найдены${plain}"
                    else
            echo -e "${red}Файл журнала банов пуст.${plain}\n"
        fi
    else
        echo -e "${red}Файл журнала банов не найден в ${iplimit_banned_log_path}${plain}\n"
    fi

        echo -e "\n${green}Текущий статус jail:${plain}"
        fail2ban-client status x-ipl || echo -e "${yellow}Невозможно получить статус jail${plain}"
}

bbr_menu() {
    echo -e "${green}\t1.${plain} Включить BBR"
    echo -e "${green}\t2.${plain} Отключить BBR"
    echo -e "${green}\t0.${plain} Вернуться в главное меню"
    read -p "Выберите вариант: " choice

    case "$choice" in
      0) show_menu ;;
      1)
        enable_bbr
        bbr_menu
        ;;
      2)
        disable_bbr
        bbr_menu
        ;;
    *)
        echo -e "${red}Неверный вариант. Выберите корректный номер.${plain}\n"
        bbr_menu
        ;;
      esac
}

disable_bbr() {
    if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf || ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
        echo -e "${yellow}BBR в настоящее время не включен.${plain}"
        before_show_menu
    fi

    sed -i 's/net.core.default_qdisc=fq/net.core.default_qdisc=pfifo_fast/' /etc/sysctl.conf
    sed -i 's/net.ipv4.tcp_congestion_control=bbr/net.ipv4.tcp_congestion_control=cubic/' /etc/sysctl.conf

    sysctl -p

    if [[ $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}') == "cubic" ]]; then
        echo -e "${green}BBR был успешно заменен на CUBIC.${plain}"
    else
        echo -e "${red}Не удалось заменить BBR на CUBIC. Проверьте конфигурацию системы.${plain}"
    fi
}

enable_bbr() {
    if grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf && grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
        echo -e "${green}BBR уже включен!${plain}"
        before_show_menu
    fi

    case "${release}" in
    ubuntu | debian | armbian)
        apt-get update && apt-get install -yqq --no-install-recommends ca-certificates
        ;;
    centos | almalinux | rocky | oracle)
        yum -y update && yum -y install ca-certificates
        ;;
    fedora)
        dnf -y update && dnf -y install ca-certificates
        ;;
    arch | manjaro | parch)
        pacman -Sy --noconfirm ca-certificates
        ;;
    *)
        echo -e "${red}Неподдерживаемая операционная система. Проверьте скрипт и установите необходимые пакеты вручную.${plain}\n"
        exit 1
        ;;
    esac

    echo "net.core.default_qdisc=fq" | tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | tee -a /etc/sysctl.conf

    sysctl -p

    if [[ $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}') == "bbr" ]]; then
        echo -e "${green}BBR был успешно включен.${plain}"
    else
        echo -e "${red}Не удалось включить BBR. Проверьте конфигурацию системы.${plain}"
    fi
}

update_shell() {
    wget -O /usr/bin/x-ui -N --no-check-certificate https://github.com/localzet/x-ui/raw/main/x-ui.sh
    if [[ $? != 0 ]]; then
        echo ""
        LOGE "Не удалось загрузить скрипт. Проверьте, может ли устройство подключиться к Github."
        before_show_menu
    else
        chmod +x /usr/bin/x-ui
        LOGI "Обновление скрипта прошло успешно. Пожалуйста, перезапустите его."
        before_show_menu
    fi
}

# 0: работает, 1: не работает, 2: не установлено
check_status() {
    if [[ ! -f /etc/systemd/system/x-ui.service ]]; then
        return 2
    fi
    temp=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ "${temp}" == "running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled x-ui)
    if [[ "${temp}" == "enabled" ]]; then
        return 0
    else
        return 1
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        LOGE "Панель установлена. Пожалуйста, не переустанавливайте."
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        LOGE "Сначала установите панель"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
      0)
          echo -e "Состояние панели: ${green}Запущена${plain}"
          show_enable_status ;;
      1)
          echo -e "Состояние панели: ${yellow}Не запущена${plain}"
          show_enable_status ;;
      2)
          echo -e "Состояние панели: ${red}Не установлена${plain}" ;;
    esac
    show_xray_status
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Автозапуск: ${green}Да${plain}"
    else
        echo -e "Автозапуск: ${red}Нет${plain}"
    fi
}

check_xray_status() {
    count=$(ps -ef | grep "xray-linux" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_xray_status() {
    check_xray_status
    if [[ $? == 0 ]]; then
        echo -e "Состояние XRay: ${green}Запущен${plain}"
    else
        echo -e "Состояние XRay: ${red}Не запущен${plain}"
    fi
}

firewall_menu() {
    echo -e "${green}\t1.${plain} Установить брандмауэр и открыть порты"
    echo -e "${green}\t2.${plain} Разрешенный список"
    echo -e "${green}\t3.${plain} Удалить порты из списка"
    echo -e "${green}\t4.${plain} Отключить брандмауэр"
    echo -e "${green}\t5.${plain} Статус брандмауэра"
    echo -e "${green}\t0.${plain} Вернуться в главное меню"
    read -p "Выберите вариант: " choice
    case "$choice" in
      0) show_menu ;;
      1)
        open_ports
        firewall_menu
        ;;
      2) ufw status numbered
        firewall_menu
        ;;
      3) delete_ports
        firewall_menu
        ;;
      4) ufw disable
        firewall_menu
        ;;
      5)
        ufw status verbose
        firewall_menu
        ;;
      *) echo "Неверный выбор"
        firewall_menu
        ;;
    esac
}

open_ports() {
    if ! command -v ufw &>/dev/null; then
        echo "Не установлен брандмауэр ufw. Установка..."
        apt-get update
        apt-get install -y ufw
    else
        echo "Брандмауэр ufw уже установлен"
    fi

    if ufw status | grep -q "Status: active"; then
        echo "Брандмауэр уже активен"
    else
        echo "Активация брандмауэра..."

        ufw allow ssh
        ufw allow http
        ufw allow https
        ufw allow 2053/tcp
        ufw allow 2096/tcp

        ufw --force enable
    fi

    read -p "Введите порты, которые вы хотите открыть (например, 80,443,2053 или диапазон 400-500): " ports

    if ! [[ $ports =~ ^([0-9]+|[0-9]+-[0-9]+)(,([0-9]+|[0-9]+-[0-9]+))*$ ]]; then
        echo "Ошибка: Неверный ввод. Введите список портов, разделенных запятыми, или диапазон портов (например, 80,443,2053 или 400-500)." >&2
        exit 1
    fi

    IFS=',' read -ra PORT_LIST <<<"$ports"
    for port in "${PORT_LIST[@]}"; do
        if [[ $port == *-* ]]; then
            start_port=$(echo $port | cut -d'-' -f1)
            end_port=$(echo $port | cut -d'-' -f2)

            ufw allow $start_port:$end_port/tcp
            ufw allow $start_port:$end_port/udp
        else
            ufw allow "$port"
        fi
    done

    echo "Следующие порты теперь открыты:"
    for port in "${PORT_LIST[@]}"; do
        if [[ $port == *-* ]]; then
            start_port=$(echo $port | cut -d'-' -f1)
            end_port=$(echo $port | cut -d'-' -f2)
            # Check if the port range has been successfully opened
            (ufw status | grep -q "$start_port:$end_port") && echo "$start_port-$end_port"
        else
            # Check if the individual port has been successfully opened
            (ufw status | grep -q "$port") && echo "$port"
        fi
    done
}

delete_ports() {
    read -p "Введите порты, которые вы хотите удалить (например, 80,443,2053 или диапазон 400-500): " ports

    if ! [[ $ports =~ ^([0-9]+|[0-9]+-[0-9]+)(,([0-9]+|[0-9]+-[0-9]+))*$ ]]; then
        echo "Ошибка: Неверный ввод. Введите список портов, разделенных запятыми, или диапазон портов (например, 80,443,2053 или 400-500)." >&2
        exit 1
    fi

    IFS=',' read -ra PORT_LIST <<<"$ports"
    for port in "${PORT_LIST[@]}"; do
        if [[ $port == *-* ]]; then
            start_port=$(echo $port | cut -d'-' -f1)
            end_port=$(echo $port | cut -d'-' -f2)

            ufw delete allow $start_port:$end_port/tcp
            ufw delete allow $start_port:$end_port/udp
        else
            ufw delete allow "$port"
        fi
    done
    
    echo "Удаляю указанные порты:"
    for port in "${PORT_LIST[@]}"; do
        if [[ $port == *-* ]]; then
            start_port=$(echo $port | cut -d'-' -f1)
            end_port=$(echo $port | cut -d'-' -f2)
            (ufw status | grep -q "$start_port:$end_port") || echo "$start_port-$end_port"
        else
            (ufw status | grep -q "$port") || echo "$port"
        fi
    done
}

update_geo() {
    local defaultBinFolder="/usr/local/x-ui/bin"
    read -p "Введите путь к папке x-ui bin. Оставьте пустым для значения по умолчанию. (По умолчанию: '${defaultBinFolder}')" binFolder
    binFolder=${binFolder:-${defaultBinFolder}}
    if [[ ! -d ${binFolder} ]]; then
        LOGE "Папка ${binFolder} не существует!"
        LOGI "Создание папки: ${binFolder}..."
        mkdir -p ${binFolder}
    fi

    cd ${binFolder}
    systemctl stop x-ui
    rm -f geoip.dat geosite.dat
    wget -N https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
    wget -N https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
    echo -e "${green}Geosite.dat + Geoip.dat успешно обновлены в '${binfolder}'!${plain}"
    restart
    before_show_menu
}

install_acme() {
    cd ~
    LOGI "Установка acme..."
    curl https://get.acme.sh | sh
    if [ $? -ne 0 ]; then
        LOGE "Установка acme не удалась"
        return 1
    else
        LOGI "Установка acme прошла успешно"
    fi
    return 0
}

ssl_cert_issue_main() {
    echo -e "${green}\t1.${plain} Получить SSL"
    echo -e "${green}\t2.${plain} Отозвать"
    echo -e "${green}\t3.${plain} Принудительно продлить"
    echo -e "${green}\t4.${plain} Показать существующие домены"
    echo -e "${green}\t5.${plain} Set Cert paths for the panel"
    echo -e "${green}\t0.${plain} Вернуться в главное меню"
    read -p "Выберите вариант: " choice
    case "$choice" in
    0) show_menu ;;
    1)
      ssl_cert_issue
      ssl_cert_issue_main
      ;;
    2)
        local domains=$(find /root/cert/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
        if [ -z "$domains" ]; then
            echo "Сертификаты для отзыва не найдены."
        else
            echo "Существующие домены:"
            echo "$domains"
            read -p "Выберите домен из списка для отзыва сертификата.: " domain
            if echo "$domains" | grep -qw "$domain"; then
                ~/.acme.sh/acme.sh --revoke -d ${domain}
                LOGI "Сертификат отозван для домена: $domain"
            else
                echo "Введен неверный домен."
            fi
        fi
        ssl_cert_issue_main
        ;;    3)
        local domain=""
        read -p "Введите свой домен для принудительного продления SSL-сертификата.: " domain
        ~/.acme.sh/acme.sh --renew -d ${domain} --force
        ;;
    3)
        local domains=$(find /root/cert/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
        if [ -z "$domains" ]; then
            echo "Сертификаты для продления не найдены."
        else
            echo "Существующие домены:"
            echo "$domains"
            read -p "Пожалуйста, введите домен из списка для обновления SSL-сертификата: " domain
            if echo "$domains" | grep -qw "$domain"; then
                ~/.acme.sh/acme.sh --renew -d ${domain} --force
                LOGI "Сертификат принудительно продлен для домена: $domain"
            else
                echo "Введен неверный домен."
            fi
        fi
        ssl_cert_issue_main
        ;;
    4)
        local domains=$(find /root/cert/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
        if [ -z "$domains" ]; then
            echo "Сертификаты не найдены."
        else
            echo "Существующие домены и их пути:"
            for domain in $domains; do
                local cert_path="/root/cert/${domain}/fullchain.pem"
                local key_path="/root/cert/${domain}/privkey.pem"
                if [[ -f "${cert_path}" && -f "${key_path}" ]]; then
                    echo -e "Домен: ${domain}"
                    echo -e "\tСертификат: ${cert_path}"
                    echo -e "\tПриватный ключ: ${key_path}"
                else
                    echo -e "Домен: ${domain} -  Отсутствует сертификат или ключ."
                fi
            done
        fi
        ssl_cert_issue_main
        ;;
    5)
        local domains=$(find /root/cert/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
        if [ -z "$domains" ]; then
            echo "Сертификаты не найдены."
        else
            echo "Доступные домены:"
            echo "$domains"
            read -p "Пожалуйста, выберите домен, чтобы задать пути панели: " domain
            if echo "$domains" | grep -qw "$domain"; then
                local webCertFile="/root/cert/${domain}/fullchain.pem"
                local webKeyFile="/root/cert/${domain}/privkey.pem"
                if [[ -f "${webCertFile}" && -f "${webKeyFile}" ]]; then
                    /usr/local/x-ui/x-ui cert -webCert "$webCertFile" -webCertKey "$webKeyFile"
                    echo "Пути панели установлены для: $domain"
                    echo "  - Файл сертификата: $webCertFile"
                    echo "  - Приватный ключ: $webKeyFile"
                    restart
                else
                    echo "Сертификат или закрытый ключ не найден для домена: $domain."
                fi
            else
                echo "Введен неверный домен."
            fi
        fi
        ssl_cert_issue_main
        ;;
    *)
      echo "Неверный выбор"
      ssl_cert_issue_main
      ;;
    esac
}

ssl_cert_issue() {
    local existing_webBasePath=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'port: .+' | awk '{print $2}')

    # Сначала проверим скрипт
    if ! command -v ~/.acme.sh/acme.sh &>/dev/null; then
        echo "acme.sh не найден. Так установим же его!"
        install_acme
        if [ $? -ne 0 ]; then
            LOGE "Установка acme не удалась, проверьте журналы"
            exit 1
        fi
    fi
    # Теперь установим socat
    case "${release}" in
      ubuntu | debian | armbian)
          apt update && apt install socat -y ;;
      centos | almalinux | rocky | oracle)
          yum -y update && yum -y install socat ;;
      fedora)
          dnf -y update && dnf -y install socat ;;
      arch | manjaro | parch)
          pacman -Sy --noconfirm socat ;;
      *)
          echo -e "${red}Неподдерживаемая операционная система. Проверьте скрипт и установите необходимые пакеты вручную.${plain}\n"
          exit 1 ;;
    esac
    if [ $? -ne 0 ]; then
        LOGE "Установка socat не удалась, проверьте журналы"
        exit 1
    else
        LOGI "Установка socat прошла успешно..."
    fi

    # Проверка домена
    local domain=""
    read -p "Пожалуйста, введите домен:" domain
    LOGD "Ваш домен: ${domain}, проверка..."
    # Проверим, существует ли сертификат
    local currentCert=$(~/.acme.sh/acme.sh --list | tail -1 | awk '{print $1}')

    if [ ${currentCert} == ${domain} ]; then
        local certInfo=$(~/.acme.sh/acme.sh --list)
        LOGE "Система уже имеет сертификаты здесь и не может выпустить их снова, текущие сведения о сертификатах:"
        LOGI "$certInfo"
        exit 1
    else
        LOGI "Ваш домен готов к выпуску сертификата прямо сейчас..."
    fi

    # Создание папки для сертификатов
    certPath="/root/cert/${domain}"
    if [ ! -d "$certPath" ]; then
        mkdir -p "$certPath"
    else
        rm -rf "$certPath"
        mkdir -p "$certPath"
    fi

    # Получение порта
    local WebPort=80
    read -p "Выберите, какой порт использовать (По умолчанию: 80):" WebPort
    if [[ ${WebPort} -gt 65535 || ${WebPort} -lt 1 ]]; then
        LOGE "Вы ввели порт ${WebPort}, он недействителен, будем использован порт по умолчанию"
    fi
    LOGI "Мы будем использовать порт ${WebPort} для выдачи сертификатов убедитесь, что этот порт открыт..."
    # ПРИМЕЧАНИЕ: Это должен сделать пользователь
    # открыть порт и завершить занятый процесс
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    ~/.acme.sh/acme.sh --issue -d ${domain} --listen-v6 --standalone --httpport ${WebPort}
    if [ $? -ne 0 ]; then
        LOGE "Не удалось выдать сертификаты, проверьте журналы"
        rm -rf ~/.acme.sh/${domain}
        exit 1
    else
        LOGE "Сертификаты выпущены, установка..."
    fi

    # Установка сертификатов
    ~/.acme.sh/acme.sh --installcert -d ${domain} \
        --key-file /root/cert/${domain}/privkey.pem \
        --fullchain-file /root/cert/${domain}/fullchain.pem

    if [ $? -ne 0 ]; then
        LOGE "Установка сертификатов не удалась, выход..."
        rm -rf ~/.acme.sh/${domain}
        exit 1
    else
        LOGI "Установка сертификатов прошла успешно, включаю автоматическое продление..."
    fi

    ~/.acme.sh/acme.sh --upgrade --auto-upgrade
    if [ $? -ne 0 ]; then
        LOGE "Автопродление не удалось, сведения о сертификатах:"
        ls -lah cert/*
        chmod 755 $certPath/*
        exit 1
    else
        LOGI "Автопродление успешно, сведения о сертификатах:"
        ls -lah cert/*
        chmod 755 $certPath/*
    fi

    read -p "Хотите ли вы установить этот сертификат для панели?? (y/n): " setPanel
    if [[ "$setPanel" == "y" || "$setPanel" == "Y" ]]; then
        local webCertFile="/root/cert/${domain}/fullchain.pem"
        local webKeyFile="/root/cert/${domain}/privkey.pem"
        if [[ -f "$webCertFile" && -f "$webKeyFile" ]]; then
            /usr/local/x-ui/x-ui cert -webCert "$webCertFile" -webCertKey "$webKeyFile"
            LOGI "Пути панели установлены для: $domain"
            LOGI "  - Файл сертификата: $webCertFile"
            LOGI "  - Приватный ключ: $webKeyFile"
            echo -e "${green}URL: https://${domain}:${existing_port}${existing_webBasePath}${plain}"
            restart
        else
            LOGE "Ошибка: сертификат или файл закрытого ключа не найдены для домена: $domain."
        fi
    else
        LOGI "Пропуск настройки пути панели."
    fi
}

ssl_cert_issue_CF() {
    local existing_webBasePath=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'port: .+' | awk '{print $2}')
    LOGD "******Инструкция по применению******"
    LOGI "Для этого скрипта требуются следующие данные:"
    LOGI "1. Зарегистрированный Email Cloudflare"
    LOGI "2. Глобальный API-ключ Cloudflare"
    LOGI "3. Домен, добавленный в Cloudflare"
    LOGI "4. После выдачи сертификата вам будет предложено установить сертификат для панели (необязательно)"
    LOGI "5. Скрипт также поддерживает автоматическое обновление SSL-сертификата после установки"
    confirm "Продолжить? [Д/н]" "д"
    if [ $? -eq 0 ]; then
        # Сначала проверим скрипт
        if ! command -v ~/.acme.sh/acme.sh &>/dev/null; then
            echo "acme.sh не найден. Так установим же его!"
            install_acme
            if [ $? -ne 0 ]; then
                LOGE "Установка acme не удалась, проверьте журналы"
                exit 1
            fi
        fi
        CF_Domain=""
        certPath="/root/cert-CF"
        if [ ! -d "$certPath" ]; then
            mkdir -p $certPath
        else
            rm -rf $certPath
            mkdir -p $certPath
        fi

        read -p "Пожалуйста, укажите домен:" CF_Domain
        LOGD "Ваш домен: ${CF_Domain}"

        CF_GlobalKey=""
        CF_AccountEmail=""

        read -p "Пожалуйста, укажите ключ API:" CF_GlobalKey
        LOGD "Ваш ключ API: ${CF_GlobalKey}"

        read -p "Пожалуйста, укажите адрес электронной почты:" CF_AccountEmail
        LOGD "Ваш адрес электронной почты: ${CF_AccountEmail}"

        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        if [ $? -ne 0 ]; then
            LOGE "CA по умолчанию, Lets'Encrypt не работает... Хъюстон, мы его теряем..."
            exit 1
        fi
        export CF_Key="${CF_GlobalKey}"
        export CF_Email=${CF_AccountEmail}
        ~/.acme.sh/acme.sh --issue --dns dns_cf -d ${CF_Domain} -d *.${CF_Domain} --log
        if [ $? -ne 0 ]; then
            LOGE "Выдача сертификата не удалась, мы его теряем..."
            exit 1
        else
            LOGI "Сертификат успешно выдан, установка..."
        fi
        mkdir -p ${certPath}/${CF_Domain}
        if [ $? -ne 0 ]; then
            LOGE "Failed to create directory: ${certPath}/${CF_Domain}"
            exit 1
        fi

        ~/.acme.sh/acme.sh --installcert -d ${CF_Domain} -d *.${CF_Domain} \
            --fullchain-file ${certPath}/${CF_Domain}/fullchain.pem \
            --key-file ${certPath}/${CF_Domain}/privkey.pem
        if [ $? -ne 0 ]; then
            LOGE "Установка сертификата не удалась, мы его теряем..."
            exit 1
        else
            LOGI "Сертификат успешно установлен, активирую автоматическое обновление..."
        fi
        ~/.acme.sh/acme.sh --upgrade --auto-upgrade
        if [ $? -ne 0 ]; then
            LOGE "Настройка автоматического обновления не удалась, мы его теряем..."
            exit 1
        else
            LOGI "Сертификат установлен и включено автоматическое продление. Конкретная информация приведена ниже."
            ls -lah ${certPath}/${CF_Domain}
            chmod 755 ${certPath}/${CF_Domain}
        fi
        read -p "Хотите ли вы установить этот сертификат для панели?? (y/n): " setPanel
        if [[ "$setPanel" == "y" || "$setPanel" == "Y" ]]; then
            local webCertFile="${certPath}/${CF_Domain}/fullchain.pem"
            local webKeyFile="${certPath}/${CF_Domain}/privkey.pem"

            if [[ -f "$webCertFile" && -f "$webKeyFile" ]]; then
                /usr/local/x-ui/x-ui cert -webCert "$webCertFile" -webCertKey "$webKeyFile"
                LOGI "Пути панели установлены для: $CF_Domain"
                LOGI "  - Файл сертификата: $webCertFile"
                LOGI "  - Приватный ключ: $webKeyFile"
                echo -e "${green}URL: https://${CF_Domain}:${existing_port}${existing_webBasePath}${plain}"
                restart
            else
                LOGE "Ошибка: сертификат или файл закрытого ключа не найдены для домена: $CF_Domain."
            fi
        else
            LOGI "Пропуск настройки пути панели."
        fi
    else
        show_menu
    fi
}

run_speedtest() {
    # Проверим, установлен ли тот самый Speedtest
    if ! command -v speedtest &>/dev/null; then
        if command -v snap &>/dev/null; then
            echo "Установка Speedtest с помощью snap..."
            snap install speedtest
        else
            # Не можешь - научим, не хочешь - заставим
            local pkg_manager=""
            local speedtest_install_script=""

            if command -v dnf &>/dev/null; then
                pkg_manager="dnf"
                speedtest_install_script="https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh"
            elif command -v yum &>/dev/null; then
                pkg_manager="yum"
                speedtest_install_script="https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh"
            elif command -v apt-get &>/dev/null; then
                pkg_manager="apt-get"
                speedtest_install_script="https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh"
            elif command -v apt &>/dev/null; then
                pkg_manager="apt"
                speedtest_install_script="https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh"
            fi

            if [[ -z $pkg_manager ]]; then
                echo "Ошибка: Менеджер пакетов не найден. Возможно, придется установить Speedtest вручную."
                return 1
            else
                echo "Установка Speedtest с помощью $pkg_manager..."
                curl -s $speedtest_install_script | bash
                $pkg_manager install -y speedtest
            fi
        fi
    fi

    # Запуск Speedtest
    speedtest
}

create_iplimit_jails() {
    # Использовать время бана по умолчанию => 30 минут
    local bantime="${1:-30}"

    # Раскомментируем «allowipv6 = auto» в fail2ban.conf
    sed -i 's/#allowipv6 = auto/allowipv6 = auto/g' /etc/fail2ban/fail2ban.conf

    # В Debian 12+ бэкэнд fail2ban по умолчанию следует изменить на systemd
    if [[  "${release}" == "debian" && ${os_version} -ge 12 ]]; then
        sed -i '0,/action =/s/backend = auto/backend = systemd/' /etc/fail2ban/jail.conf
    fi

    cat << EOF > /etc/fail2ban/jail.d/x-ipl.conf
[x-ipl]
enabled=true
backend=auto
filter=x-ipl
action=x-ipl
logpath=${iplimit_log_path}
maxretry=2
findtime=32
bantime=${bantime}m
EOF

    cat << EOF > /etc/fail2ban/filter.d/x-ipl.conf
[Definition]
datepattern = ^%%Y/%%m/%%d %%H:%%M:%%S
failregex   = \[LIMIT_IP\]\s*Email\s*=\s*<F-USER>.+</F-USER>\s*\|\|\s*SRC\s*=\s*<ADDR>
ignoreregex =
EOF

    cat << EOF > /etc/fail2ban/action.d/x-ipl.conf
[INCLUDES]
before = iptables-allports.conf

[Definition]
actionstart = <iptables> -N f2b-<name>
              <iptables> -A f2b-<name> -j <returntype>
              <iptables> -I <chain> -p <protocol> -j f2b-<name>

actionstop = <iptables> -D <chain> -p <protocol> -j f2b-<name>
             <actionflush>
             <iptables> -X f2b-<name>

actioncheck = <iptables> -n -L <chain> | grep -q 'f2b-<name>[ \t]'

actionban = <iptables> -I f2b-<name> 1 -s <ip> -j <blocktype>
            echo "\$(date +"%%Y/%%m/%%d %%H:%%M:%%S")   BAN   [Email] = <F-USER> [IP] = <ip> забанен на <bantime> сек." >> ${iplimit_banned_log_path}

actionunban = <iptables> -D f2b-<name> -s <ip> -j <blocktype>
              echo "\$(date +"%%Y/%%m/%%d %%H:%%M:%%S")   UNBAN   [Email] = <F-USER> [IP] = <ip> разбанен." >> ${iplimit_banned_log_path}

[Init]
name = default
protocol = tcp
chain = INPUT
EOF

    echo -e "${green}Ограничения IP созданы на ${bantime} мин.${plain}"
}

iplimit_remove_conflicts() {
    local jail_files=(
        /etc/fail2ban/jail.conf
        /etc/fail2ban/jail.local
    )

    for file in "${jail_files[@]}"; do
        # Проверка наличия конфигурации [x-ipl] в файле jail, затем удаление.
        if test -f "${file}" && grep -qw 'x-ipl' ${file}; then
            sed -i "/\[x-ipl\]/,/^$/d" ${file}
            echo -e "${yellow}Устранение конфликтов [x-ipl] в jail (${file})!${plain}\n"
        fi
    done
}

ip_validation() {
    ipv6_regex="^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$"
    ipv4_regex="^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]?|0)\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]?|0)$"
}

iplimit_main() {
    echo -e "\n${green}\t1.${plain} Установить Fail2ban и настроить лимиты IP"
    echo -e "${green}\t2.${plain} Изменить длительность бана"
    echo -e "${green}\t3.${plain} Разбанить всех"
    echo -e "${green}\t4.${plain} Проверить журналы"
    echo -e "${green}\t5.${plain} Заблокировать IP-адрес"
    echo -e "${green}\t6.${plain} Разблокировать IP-адрес"
    echo -e "${green}\t7.${plain} Журналы в реальном времени"
    echo -e "${green}\t8.${plain} Статус службы"
    echo -e "${green}\t9.${plain} Перезапустить службу"
    echo -e "${green}\t10.${plain} Удалить Fail2ban и лимиты IP"
    echo -e "${green}\t0.${plain} Вернуться в главное меню"
    read -p "Выберите вариант: " choice
    case "$choice" in
    0)
        show_menu
        ;;
    1)
        confirm "Продолжить установку Fail2ban и ограничений IP? [Д/н]" "д"
        if [[ $? == 0 ]]; then
            install_iplimit
        else
            iplimit_main
        fi ;;
    2)
        read -rp "Введите новую продолжительность бана в минутах. [По умолчанию: 30]: " NUM
        if [[ $NUM =~ ^[0-9]+$ ]]; then
            create_iplimit_jails ${NUM}
            systemctl restart fail2ban
        else
            echo -e "${red}${NUM} не число! Попробуйте еще раз.${plain}"
        fi
        iplimit_main ;;
    3)
        confirm "Вы уверены, что хотите разбанить все IP? [Д/н]" "д"
        if [[ $? == 0 ]]; then
            fail2ban-client set x-ipl unban --all
            truncate -s 0 "${iplimit_banned_log_path}"
            echo -e "${green}Все пользователи успешно разбанены.${plain}"
            iplimit_main
        else
            echo -e "${yellow}Отмена...${plain}"
        fi
        iplimit_main ;;
    4)
      show_banlog
      iplimit_main
      ;;
    5)
      read -rp "Введите IP-адрес, который вы хотите забанить: " ban_ip
        ip_validation
        if [[ $ban_ip =~ $ipv4_regex || $ban_ip =~ $ipv6_regex ]]; then
          fail2ban-client set 3x-ipl banip "$ban_ip"
          echo -e "${green}IP-адрес ${ban_ip} был успешно забанен.${plain}"
      else
          echo -e "${red}Неверный формат IP-адреса! Попробуйте еще раз.${plain}"
      fi
      iplimit_main
      ;;
    6)
      read -rp "Введите IP-адрес, который вы хотите разбанить: " unban_ip
        ip_validation
        if [[ $unban_ip =~ $ipv4_regex || $unban_ip =~ $ipv6_regex ]]; then
          fail2ban-client set 3x-ipl unbanip "$unban_ip"
          echo -e "${green}IP-адрес ${unban_ip} был успешно разбанен.${plain}"
      else
          echo -e "${red}Неверный формат IP-адреса! Попробуйте еще раз.${plain}"
      fi
      iplimit_main
      ;;
    7)
      tail -f /var/log/fail2ban.log
      iplimit_main
      ;;
    8)
      service fail2ban status
      iplimit_main
      ;;
    9)
      systemctl restart fail2ban
      iplimit_main
      ;;
    10)
      remove_iplimit
      iplimit_main
      ;;
    *)
      echo "Неверный выбор"
      iplimit_main
      ;;
    esac
}

install_warp() {
    if ! command -v warp &> /dev/null; then
        case "${release}" in
          ubuntu)
              apt update && apt install wget net-tools -y ;;
          debian | armbian)
              apt update && apt install wget net-tools -y ;;
          centos | almalinux | rocky | oracle)
              yum update -y && yum install wget net-tools -y ;;
          fedora)
              dnf -y update && dnf -y install wget net-tools ;;
          *)
              echo -e "${red}Неподдерживаемая операционная система. Проверьте скрипт и установите необходимые пакеты вручную.${plain}\n"
              exit 1 ;;
        esac

        mkdir -p /etc/wireguard
        wget -N -P /etc/wireguard https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh
        chmod +x /etc/wireguard/menu.sh
        ln -sf /etc/wireguard/menu.sh /usr/bin/warp

        echo -e "${green}WARP успешно установлен!${plain}\n"
    else
        echo -e "${yellow}WARP уже установлен.${plain}\n"
    fi

    warp w <<< $'1\n1\n40000\n1\n'
    [[ $? -ne 0 ]] && STEP_STATUS=0 || STEP_STATUS=1
}

install_iplimit() {
    if ! command -v fail2ban-client &>/dev/null; then
        echo -e "${green}Fail2ban не установлен! Устанавливаю...${plain}\n"

        # Check the OS and install necessary packages
        case "${release}" in
        ubuntu)
            if [[ "${os_version}" -ge 24 ]]; then
                apt update && apt install python3-pip -y
                python3 -m pip install pyasynchat --break-system-packages
            fi
            apt update && apt install fail2ban -y ;;
        debian | armbian)
            apt update && apt install fail2ban -y ;;
        centos | almalinux | rocky | oracle)
            yum update -y && yum install epel-release -y
            yum -y install fail2ban ;;
        fedora)
            dnf -y update && dnf -y install fail2ban ;;
        arch | manjaro | parch)
            pacman -Syu --noconfirm fail2ban ;;
        *)
            echo -e "${red}Неподдерживаемая операционная система. Проверьте скрипт и установите необходимые пакеты вручную.${plain}\n"
            exit 1 ;;
        esac

        if ! command -v fail2ban-client &>/dev/null; then
            echo -e "${red}Установка Fail2ban не удалась.${plain}\n"
            exit 1
        fi

        echo -e "${green}Fail2ban успешно установлен!${plain}\n"
    else
        echo -e "${yellow}Fail2ban уже установлен.${plain}\n"
    fi

    echo -e "${green}Конфигурация ограничений IP...${plain}\n"

    # Проверка конфиликтов jail
    iplimit_remove_conflicts

    # Проверка существования логов
    if ! test -f "${iplimit_banned_log_path}"; then
        touch ${iplimit_banned_log_path}
    fi

    # Проверка существования логов службы
    if ! test -f "${iplimit_log_path}"; then
        touch ${iplimit_log_path}
    fi

    # Создание файлов jail
    create_iplimit_jails

    # Запуск fail2ban
    if ! systemctl is-active --quiet fail2ban; then
        systemctl start fail2ban
        systemctl enable fail2ban
    else
        systemctl restart fail2ban
    fi
    systemctl enable fail2ban

    echo -e "${green}Ограничения IP установлены и конфигурированы успешно!${plain}\n"
    before_show_menu
}

remove_iplimit() {
    echo -e "${green}\t1.${plain} Удалить только конфигурации ограничений IP"
    echo -e "${green}\t2.${plain} Удалить Fail2ban и ограничения IP"
    echo -e "${green}\t0.${plain} Отмена"
    read -p "Выберите вариант: " num
    case "$num" in
    1)
        rm -f /etc/fail2ban/filter.d/x-ipl.conf
        rm -f /etc/fail2ban/action.d/x-ipl.conf
        rm -f /etc/fail2ban/jail.d/x-ipl.conf
        systemctl restart fail2ban
        echo -e "${green}Все ограничения IP сняты!${plain}\n"
        before_show_menu ;;
    2)
        rm -rf /etc/fail2ban
        systemctl stop fail2ban
        case "${release}" in
        ubuntu | debian | armbian)
            apt-get remove -y fail2ban
            apt-get purge -y fail2ban -y
            apt-get autoremove -y ;;
        centos | almalinux | rocky | oracle)
            yum remove fail2ban -y
            yum autoremove -y ;;
        fedora)
            dnf remove fail2ban -y
            dnf autoremove -y ;;
        arch | manjaro | parch)
            pacman -Rns --noconfirm fail2ban ;;
        *)
            echo -e "${red}Неподдерживаемая операционная система. Пожалуйста, удалите Fail2ban вручную.${plain}\n"
            exit 1 ;;
        esac
        echo -e "${green}Fail2ban удалён, все ограничения IP сняты!${plain}\n"
        before_show_menu ;;
    0)
        show_menu ;;
    *)
        echo -e "${red}Неверный вариант. Выберите корректный номер.${plain}\n"
        remove_iplimit ;;
    esac
}

SSH_port_forwarding() {
    local server_ip=$(curl -s https://api.ipify.org)
    local existing_webBasePath=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'port: .+' | awk '{print $2}')
    local existing_listenIP=$(/usr/local/x-ui/x-ui setting -getListen true | grep -Eo 'listenIP: .+' | awk '{print $2}')
    local existing_cert=$(/usr/local/x-ui/x-ui setting -getCert true | grep -Eo 'cert: .+' | awk '{print $2}')
    local existing_key=$(/usr/local/x-ui/x-ui setting -getCert true | grep -Eo 'key: .+' | awk '{print $2}')

    local config_listenIP=""
    local listen_choice=""

    if [[ -n "$existing_cert" && -n "$existing_key" ]]; then
        echo -e "${green}Панель защищена с помощью SSL.${plain}"
        before_show_menu
    fi
    if [[ -z "$existing_cert" && -z "$existing_key" && (-z "$existing_listenIP" || "$existing_listenIP" == "0.0.0.0") ]]; then
        echo -e "\n${red}Внимание: Сертификат и ключ не найдены! Панель не защищена.${plain}"
        echo "Получите сертификат или настройте переадресацию портов SSH.."
    fi

    if [[ -n "$existing_listenIP" && "$existing_listenIP" != "0.0.0.0" && (-z "$existing_cert" && -z "$existing_key") ]]; then
        echo -e "\n${green}Текущая конфигурация переадресации портов SSH:${plain}"
        echo -e "Стандартная команда SSH:"
        echo -e "${yellow}ssh -L 2222:${existing_listenIP}:${existing_port} root@${server_ip}${plain}"
        echo -e "\nПри использовании SSH-ключа:"
        echo -e "${yellow}ssh -i <sshkeypath> -L 2222:${existing_listenIP}:${existing_port} root@${server_ip}${plain}"
        echo -e "\nПосле подключения войдите в панель по адресу:"
        echo -e "${yellow}http://localhost:2222${existing_webBasePath}${plain}"
    fi

    echo -e "\nВыберите вариант:"
    echo -e "${green}1.${plain} Установить прослушиваемый IP"
    echo -e "${green}2.${plain} Очистить прослушиваемый IP"
    echo -e "${green}0.${plain} Вернуться в главное меню"
    read -p "Выберите вариант: " num

    case "$num" in
    1)
        if [[ -z "$existing_listenIP" || "$existing_listenIP" == "0.0.0.0" ]]; then
            echo -e "\nПрослушиваемый IP не задан. Выберите вариант:"
            echo -e "1. По умолчанию IP (127.0.0.1)"
            echo -e "2. Установить пользовательский IP"
            read -p "Выберите вариант (1 или 2): " listen_choice

            config_listenIP="127.0.0.1"
            [[ "$listen_choice" == "2" ]] && read -p "Введите пользовательский IP-адрес для прослушивания: " config_listenIP

            /usr/local/x-ui/x-ui setting -listenIP "${config_listenIP}" >/dev/null 2>&1
            echo -e "${green}Прослушивание IP было установлено на ${config_listenIP}.${plain}"
            echo -e "\n${green}Конфигурация переадресации портов SSH:${plain}"
            echo -e "Стандартная команда SSH:"
            echo -e "${yellow}ssh -L 2222:${config_listenIP}:${existing_port} root@${server_ip}${plain}"
            echo -e "\nПри использовании SSH-ключа:"
            echo -e "${yellow}ssh -i <sshkeypath> -L 2222:${config_listenIP}:${existing_port} root@${server_ip}${plain}"
            echo -e "\nПосле подключения войдите в панель по адресу:"
            echo -e "${yellow}http://localhost:2222${existing_webBasePath}${plain}"
            restart
        else
            config_listenIP="${existing_listenIP}"
            echo -e "${green}Текущий IP-адрес прослушивания уже установлен на ${config_listenIP}.${plain}"
        fi
        ;;
    2)
        /usr/local/x-ui/x-ui setting -listenIP 0.0.0.0 >/dev/null 2>&1
        echo -e "${green}Прослушиваемый IP был очищен.${plain}"
        restart
        ;;
    0)
        show_menu
        ;;
    *)
        echo -e "${red}Неверный вариант. Выберите правильный номер.${plain}\n"
        SSH_port_forwarding
        ;;
    esac
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
    echo -e "x-ui log          - Управление журналами"
    echo -e "x-ui banlog       - Проверка журналов бана Fail2ban"
    echo -e "x-ui update       - Обновление"
    echo -e "x-ui custom       - Пользовательская версия"
    echo -e "x-ui install      - Установка"
    echo -e "x-ui uninstall    - Удаление"
    echo -e "----------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}Аппаратная панель управления X-UI${plain}
  ${green}0.${plain} Выход
————————————————
  ${green}1.${plain} Установить
  ${green}2.${plain} Обновить
  ${green}3.${plain} Обновить меню
  ${green}4.${plain} Пользовательская версия
  ${green}5.${plain} Удалить
————————————————
  ${green}6.${plain} Сброс имени пользователя, пароля и токена
  ${green}7.${plain} Сброс пути диспетчерской
  ${green}8.${plain} Сброс настроек
  ${green}9.${plain} Изменить порт
  ${green}10.${plain} Просмотреть текущие настройки
————————————————
  ${green}11.${plain} Запуск
  ${green}12.${plain} Остановка
  ${green}13.${plain} Перезапуск
  ${green}14.${plain} Проверка статуса
  ${green}15.${plain} Управление журналами
————————————————
  ${green}16.${plain} Включить автозапуск
  ${green}17.${plain} Отключить автозапуск
————————————————
  ${green}18.${plain} Управление сертификатом SSL
  ${green}19.${plain} Сертификат SSL Cloudflare
  ${green}20.${plain} Управление лимитом IP
  ${green}21.${plain} Управление брандмауэром
  ${green}22.${plain} Управление переадресацией портов SSH
————————————————
  ${green}23.${plain} Включить BBR
  ${green}24.${plain} Установить WARP
  ${green}25.${plain} Обновить файлы Geoip
  ${green}26.${plain} Speedtest от Ookla
"
    show_status
    echo && read -p "Пожалуйста, введите ваш выбор [0-26]: " num

    case "${num}" in
      0) exit 0 ;;
      1) check_uninstall && install ;;
      2) check_install && update ;;
      3) check_install && update_menu ;;
      4) check_install && custom_version ;;
      5) check_install && uninstall ;;
      6) check_install && reset_user ;;
      7) check_install && reset_webbasepath ;;
      8) check_install && reset_config ;;
      9) check_install && set_port ;;
      10) check_install && check_config ;;
      11) check_install && start ;;
      12) check_install && stop ;;
      13) check_install && restart ;;
      14) check_install && status ;;
      15) check_install && show_log ;;
      16) check_install && enable ;;
      17) check_install && disable ;;
      18) ssl_cert_issue_main ;;
      19) ssl_cert_issue_CF ;;
      20) iplimit_main ;;
      21) firewall_menu ;;
      22) SSH_port_forwarding ;;
      23) bbr_menu ;;
      24) install_warp ;;
      25) update_geo ;;
      26) run_speedtest ;;
      *) LOGE "Пожалуйста, введите корректный номер [0-26]" ;;
    esac
}

# shellcheck disable=SC2071
if [[ $# > 0 ]]; then
    case $1 in
      "start") check_install 0 && start 0 ;;
      "stop") check_install 0 && stop 0 ;;
      "restart") check_install 0 && restart 0 ;;
      "status") check_install 0 && status 0 ;;
      "settings") check_install 0 && check_config 0 ;;
      "enable") check_install 0 && enable 0 ;;
      "disable") check_install 0 && disable 0 ;;
      "log") check_install 0 && show_log 0 ;;
      "banlog") check_install 0 && show_banlog 0 ;;
      "update") check_install 0 && update 0 ;;
      "custom") check_install 0 && custom_version 0 ;;
      "install") check_uninstall 0 && install 0 ;;
      "uninstall") check_install 0 && uninstall 0 ;;
      *) show_usage ;;
    esac
else
    show_menu
fi
