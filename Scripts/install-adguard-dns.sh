#!/bin/bash

# Source the utility functions
source "$(dirname "$0")/utils.sh"

# Variables
ARCH="darwin-arm64"
DNSPROXY_URL="https://github.com/AdguardTeam/dnsproxy/releases/latest/download/dnsproxy-${ARCH}"
DNSPROXY_PATH="/opt/homebrew/bin/dnsproxy"
CONFIG_PATH="$(dirname "$0")/dnsproxy-config.yml"
LOG_FILE="/tmp/dnsproxy.log"

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo "❌ Этот скрипт должен быть запущен с правами root"
   exit 1
fi

# Проверка наличия конфигурационного файла
if [[ ! -f "$CONFIG_PATH" ]]; then
    echo "❌ Конфиг-файл $CONFIG_PATH не найден!"
    exit 1
fi

# Скачать и установить dnsproxy
echo " Скачиваем и устанавливаем dnsproxy..."
curl -fsSL "$DNSPROXY_URL" -o "$DNSPROXY_PATH"
chmod +x "$DNSPROXY_PATH"

# Запуск в фоне
echo " Запускаем dnsproxy..."
pkill dnsproxy || true
nohup "$DNSPROXY_PATH" --config-path "$CONFIG_PATH" > "$LOG_FILE" 2>&1 &

# Назначение DNS 127.0.0.1
INTERFACE=$(get_primary_interface)
echo " Устанавливаем DNS для $INTERFACE → 127.0.0.1"
networksetup -setdnsservers "$INTERFACE" 127.0.0.1

# Сброс DNS-кэша
dscacheutil -flushcache
killall -HUP mDNSResponder

echo "✅ AdGuard DNS включён через dnsproxy!"