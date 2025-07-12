#!/bin/bash
set -e

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Variables
TEST_DOMAIN="doubleclick.net"

# Require root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Этот скрипт нужно запускать от root"
   exit 1
fi

# Set DNS to localhost
INTERFACE=$(get_primary_interface)
if [[ -z "$INTERFACE" ]]; then
    INTERFACE="Wi-Fi"
fi
echo " Устанавливаем DNS для $INTERFACE → 127.0.0.1"
networksetup -setdnsservers "$INTERFACE" 127.0.0.1

# Flush DNS
dscacheutil -flushcache
killall -HUP mDNSResponder

# Verify
echo " Проверка блокировки рекламы через $TEST_DOMAIN..."
RES=$(dig @127.0.0.1 "$TEST_DOMAIN" +short)

if [[ "$RES" == "0.0.0.0" || "$RES" == "::" ]]; then
    echo "✅ Блокировка работает: $TEST_DOMAIN → $RES"
else
    echo "❌ Блокировка не сработала (ответ: $RES)"
    echo "Проверь лог: /tmp/adguard-daemon.log"
fi

echo "===================================="
echo "✅ AdGuard DNS включён."
echo "===================================="
exit 0
