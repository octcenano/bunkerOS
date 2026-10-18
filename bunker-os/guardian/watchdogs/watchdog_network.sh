#!/bin/bash
# Bunker OS - Watchdog: Red
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

watchdog_network() {
    local interval=20
    local alert_log="$BUNKER_VAR/network-alerts.log"
    bunker_debug "Watchdog de red iniciado"
    while true; do
        if ! command -v ss &>/dev/null; then
            sleep "$interval"
            continue
        fi
        local connections
        connections=$(ss -tunap 2>/dev/null)
        while IFS= read -r line; do
            echo "$line" | grep -q "Netid" && continue
            local proto local_addr remote_addr state pid
            proto=$(echo "$line" | awk '{print $1}')
            local_addr=$(echo "$line" | awk '{print $5}')
            remote_addr=$(echo "$line" | awk '{print $6}')
            state=$(echo "$line" | awk '{print $3}')
            pid=$(echo "$line" | awk '{print $7}')
            local port
            port=$(echo "$local_addr" | rev | cut -d: -f1 | rev)
            if [[ "$port" =~ ^[0-9]+$ ]] && [[ "$port" -gt 49152 ]]; then
                if [[ "$state" == "LISTEN" ]]; then
                    bunker_warn "Watchdog red: puerto escuchando no estándar: $port ($proto)"
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERTA: puerto $port escuchando ($proto) PID=$pid" >> "$alert_log"
                fi
            fi
        done <<< "$connections"
        sleep "$interval"
    done
}

run_watchdog() {
    watchdog_network
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_watchdog
fi