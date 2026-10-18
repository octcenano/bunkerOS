#!/bin/bash
# Bunker OS - Daemon: Monitor de Rollback
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

daemon_rollback_monitor() {
    local interval=10
    local last_mode=""
    local failure_count=0
    local max_failures=3
    bunker_info "Daemon de monitor de rollback iniciado"
    while true; do
        local current_mode
        current_mode=$(bunker_state_get "current_mode" 2>/dev/null || echo "custom")
        if [[ "$current_mode" != "$last_mode" && -n "$last_mode" ]]; then
            bunker_debug "Cambio de modo detectado: $last_mode -> $current_mode"
            failure_count=0
        fi
        if [[ -n "$current_mode" && "$current_mode" != "custom" ]]; then
            if ! bunker_is_running "bunker-core"; then
                bunker_error "Rollback monitor: núcleo caído después de aplicar modo $current_mode"
                ((failure_count++))
                if [[ $failure_count -ge $max_failures ]]; then
                    bunker_warn "Rollback monitor: demasiados fallos, revertiendo modo $current_mode"
                    rollback_on_failure "$current_mode"
                    failure_count=0
                fi
            fi
        fi
        last_mode="$current_mode"
        sleep "$interval"
    done
}

run_daemon() {
    daemon_rollback_monitor
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_daemon
fi