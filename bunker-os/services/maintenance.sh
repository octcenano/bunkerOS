#!/bin/bash
# Bunker OS - Servicio: Mantenimiento
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

maintenance_start() {
    bunker_info "Iniciando servicio de mantenimiento..."
    run_maintenance_tasks
}

maintenance_stop() {
    bunker_info "Deteniendo servicio de mantenimiento..."
}

run_maintenance_tasks() {
    bunker_info "Ejecutando tareas de mantenimiento..."
    find /var/log/bunker -name "*.log.*" -mtime +30 -delete 2>/dev/null || true
    find "$BUNKER_VAR/snapshots" -mindepth 1 -maxdepth 1 -mtime +90 -exec rm -rf {} + 2>/dev/null || true
    if command -v pacman &>/dev/null; then
        pacman -Qkk 2>/dev/null | head -10
    fi
    bunker_info "Mantenimiento completado"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    maintenance_start "$@"
fi