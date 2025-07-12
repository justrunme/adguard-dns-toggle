#!/bin/bash

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Variables
CMD_PIPE="/tmp/adguard-cmd-pipe"
PID_FILE="/tmp/dnsproxy.pid"
TEST_DOMAIN="doubleclick.net"

# Проверка прав
if [[ $EUID -ne 0 ]]; then
   echo "❌ Этот скрипт нужно запускать от root"
   exit 1
fi

# Send disable command to daemon
if [[ -p "$CMD_PIPE" ]]; then
    echo "Sending 'disable' command to daemon..."
    echo "disable" > "$CMD_PIPE"
    sleep 1 # Give daemon a moment to process
else
    echo "ℹ️ Command pipe not found. Daemon might not be running."
fi

# Remove PID file if it exists (daemon should handle this, but as a fallback)
if [[ -f "$PID_FILE" ]]; then
    echo "Removing PID file: $PID_FILE"
    rm -f "$PID_FILE"
fi

# Сброс DNS
INTERFACE=$(get_primary_interface)
echo " Сброс DNS для $INTERFACE..."
networksetup -setdnsservers "$INTERFACE" empty

# Очистка кэша
dscacheutil -flushcache
killall -HUP mDNSResponder

# Проверка
echo " Проверка восстановления DNS..."
RES=$(dig "$TEST_DOMAIN" +short)

if [[ -z "$RES" ]]; then
    echo "⚠️ Не удалось получить IP-адрес для $TEST_DOMAIN. Проверь интернет-соединение."
elif [[ "$RES" == "0.0.0.0" || "$RES" == "::" ]]; then
    echo "❌ Блокировка всё ещё активна — DNS не сброшен."
else
    echo "✅ DNS успешно восстановлен. Ответ: $RES"
fi

echo " AdGuard DNS отключён."
