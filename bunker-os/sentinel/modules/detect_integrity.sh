#!/bin/bash
# Bunker OS - Módulo: Integridad de Archivos
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

detect_integrity() {
    bunker_debug "Ejecutando detección de integridad..."
    local baseline="$BUNKER_VAR/baseline/integrity.db"
    local files=(
        "/etc/bunker/bunker.conf"
        "/usr/lib/bunker/core/core.sh"
        "/usr/lib/bunker/engine/engine.sh"
        "/usr/bin/bunker"
    )
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            local hash
            hash=$(sha256sum "$file" 2>/dev/null | awk '{print $1}')
            if [[ -f "$baseline" ]]; then
                local stored
                stored=$(grep "^$file:" "$baseline" 2>/dev/null | awk -F: '{print $2}')
                if [[ "$stored" != "$hash" ]]; then
                    bunker_warn "Integridad comprometida: $file"
                    log_incident "integrity" "$file" "cambio_no_autorizado"
                fi
            else
                echo "$file:$hash" >> "$baseline"
            fi
        fi
    done
}

run_detection() {
    detect_integrity
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_detection
fi