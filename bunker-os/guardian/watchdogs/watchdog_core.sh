#!/bin/bash
# Bunker OS - Watchdog: Núcleo
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

watchdog_core() {
    local interval=10
    while true; do
        if ! bunker_is_running "bunker-core"; then
            bunker_error "Watchdog: núcleo no responde. Reiniciando..."
            /usr/lib/bunker/core/core.sh restart 2>/dev/null || true
        fi
        sleep "$interval"
    done
}

run_watchdog() {
    watchdog_core
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_watchdog
fi