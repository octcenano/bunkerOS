#!/bin/bash
# Bunker OS - Módulo: Permisos
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

detect_permissions() {
    bunker_debug "Ejecutando detección de permisos..."
    local baseline="$BUNKER_VAR/baseline/permissions.db"
    local files=(
        "/etc/passwd"
        "/etc/shadow"
        "/etc/sudoers"
        "/usr/bin/sudo"
        "/etc/bunker/bunker.conf"
    )
    for file in "${files[@]}"; do
        if [[ -e "$file" ]]; then
            local perms
            perms=$(stat -c "%a" "$file" 2>/dev/null)
            local owner
            owner=$(stat -c "%U:%G" "$file" 2>/dev/null)
            if [[ -f "$baseline" ]]; then
                local stored
                stored=$(grep "^$file:" "$baseline" 2>/dev/null | awk -F: '{print $2}')
                if [[ "$stored" != "$perms" ]]; then
                    bunker_warn "Permisos cambiados: $file (ahora $perms)"
                    log_incident "permissions" "$file" "permisos_cambiados"
                fi
            else
                echo "$file:$perms" >> "$baseline"
            fi
        fi
    done
}

run_detection() {
    detect_permissions
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_detection
fi