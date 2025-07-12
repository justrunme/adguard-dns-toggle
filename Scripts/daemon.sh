#!/bin/bash
set -e

# Configuration - can be overridden by environment variables
DNSPROXY_PATH="${DNSPROXY_PATH:-/opt/homebrew/bin/dnsproxy}"
CONFIG_PATH="${CONFIG_PATH:-/Users/justrunme/adguard-dns-toggle/Scripts/dnsproxy-config.yml}"
PID_FILE="${PID_FILE:-/tmp/dnsproxy.pid}"
CMD_PIPE="${CMD_PIPE:-/tmp/adguard-cmd-pipe}"
LOG_FILE="${LOG_FILE:-/tmp/adguard-daemon.log}"
PORT="${PORT:-53535}"
LISTEN_ADDR="${LISTEN_ADDR:-127.0.0.1}"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if we can run as user (no root required)
log "Starting AdGuard DNS daemon as user..."

# Cleanup function
cleanup() {
    log "Daemon cleanup..."
    if [[ -f "$PID_FILE" ]]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null; then
            log "Killing dnsproxy (PID: $PID)..."
            kill "$PID" || true # Use || true to prevent script from exiting if process is already gone
        fi
        rm -f "$PID_FILE"
    fi
    if [[ -p "$CMD_PIPE" ]]; then
        rm -f "$CMD_PIPE"
    fi
    log "Cleanup complete."
}

# Trap signals for cleanup
trap cleanup EXIT TERM INT

# Initial cleanup in case of previous unclean exit
cleanup

log "Starting AdGuard DNS daemon..."

# Start dnsproxy (will run on localhost only, no system DNS changes)
log "Starting dnsproxy on $LISTEN_ADDR:$PORT..."
nohup "$DNSPROXY_PATH" --config-path "$CONFIG_PATH" --port "$PORT" --listen "$LISTEN_ADDR" >> "$LOG_FILE" 2>&1 & 
DNSPROXY_PID=$!
echo "$DNSPROXY_PID" > "$PID_FILE"
log "dnsproxy started with PID: $DNSPROXY_PID on $LISTEN_ADDR:$PORT"

# Create named pipe
if [[ ! -p "$CMD_PIPE" ]]; then
    mkfifo "$CMD_PIPE"
    log "Created command pipe: $CMD_PIPE"
fi

# Monitor command pipe
log "Monitoring command pipe for commands..."
while true; do
    if read command < "$CMD_PIPE"; then
        log "Received command: $command"
        case "$command" in
            "disable")
                log "Disabling AdGuard DNS..."
                if [[ -f "$PID_FILE" ]]; then
                    PID=$(cat "$PID_FILE")
                    if ps -p "$PID" > /dev/null; then
                        log "Killing dnsproxy (PID: $PID)..."
                        kill "$PID" || true
                    fi
                    rm -f "$PID_FILE"
                fi
                log "AdGuard DNS disabled. Waiting for enable command..."
                ;;
            "enable")
                log "Enabling AdGuard DNS..."
                if [[ ! -f "$PID_FILE" ]]; then
                    log "Starting dnsproxy on $LISTEN_ADDR:$PORT..."
                    nohup "$DNSPROXY_PATH" --config-path "$CONFIG_PATH" --port "$PORT" --listen "$LISTEN_ADDR" >> "$LOG_FILE" 2>&1 & 
                    DNSPROXY_PID=$!
                    echo "$DNSPROXY_PID" > "$PID_FILE"
                    log "dnsproxy started with PID: $DNSPROXY_PID on $LISTEN_ADDR:$PORT"
                else
                    log "dnsproxy is already running."
                fi
                ;;
            *)
                log "Unknown command: $command"
                ;;
        esac
    fi
done