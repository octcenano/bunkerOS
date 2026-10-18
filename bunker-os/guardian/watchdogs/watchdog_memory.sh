#!/bin/bash
# Bunker OS - Watchdog: Memoria
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

watchdog_memory() {
    local interval=30
    local threshold=90
    while true; do
        local mem_used
        mem_used=$(free | awk '/^Mem:/{printf "%.0f", $3/$2*100}')
        if [[ "$mem_used" -gt "$threshold" ]]; then
            bunker_warn "Watchdog: uso de memoria alto ($mem_used%). Liberando caché..."
            sync
            echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
        fi
        sleep "$interval"
    done
}

run_watchdog() {
    watchdog_memory
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_watchdog
fi