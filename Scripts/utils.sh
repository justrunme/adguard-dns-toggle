#!/bin/bash

is_process_running() {
    local proc="$1"
    pgrep -x "$proc" > /dev/null 2>&1
}

get_primary_interface() {
    netstat -rn | awk '/^default/ {print $6; exit}'
}
