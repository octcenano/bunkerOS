#!/bin/bash
# Bunker OS - Módulo: Red
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

detect_network() {
    bunker_debug "Ejecutando detección de red..."
    if ! command -v ss &>/dev/null; then
        bunker_warn "ss no disponible, detección de red omitida"
        return 0
    fi
    local connections
    connections=$(ss -tln 2>/dev/null)
    while IFS= read -r line; do
        local port
        port=$(echo "$line" | awk '{print $4}' | rev | cut -d: -f1 | rev)
        if [[ -n "$port" && "$port" =~ ^[0-9]+$ ]]; then
            if [[ "$port" -gt 1024 && "$port" -lt 5000 ]]; then
                bunker_warn "Puerto inusual escuchando: $port"
                log_incident "network" "$port" "puerto_inusual"
            fi
        fi
    done <<< "$connections"
}

run_detection() {
    detect_network
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_detection
fi