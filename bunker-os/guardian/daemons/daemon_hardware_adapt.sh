#!/bin/bash
# Bunker OS - Daemon: Adaptación de Hardware
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

daemon_hardware_adapt() {
    local interval=3600
    bunker_info "Daemon de adaptación de hardware iniciado"
    while true; do
        bunker_info "Re-evaluando adaptación de hardware..."
        hardware_detect_all
        hardware_optimize
        sleep "$interval"
    done
}

run_daemon() {
    daemon_hardware_adapt
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_daemon
fi