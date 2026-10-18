#!/bin/bash
# Bunker OS - Servicio: Actualización
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

update_start() {
    bunker_info "Iniciando servicio de actualización..."
}

update_stop() {
    bunker_info "Deteniendo servicio de actualización..."
}

update_system() {
    bunker_require_root
    bunker_info "Iniciando actualización del sistema..."
    local snapshot
    snapshot=$(rollback_snapshot "before_update")
    if command -v pacman &>/dev/null; then
        bunker_info "Actualizando paquetes (pacman)..."
        if pacman -Syu --noconfirm 2>&1 | tee /var/log/bunker/pacman-update.log; then
            bunker_info "Actualización completada"
        else
            bunker_error "Error en la actualización. Restaurando..."
            rollback_restore "$snapshot"
            return 1
        fi
    else
        bunker_error "pacman no encontrado"
        return 1
    fi
}

update_check() {
    bunker_info "Verificando actualizaciones disponibles..."
    if command -v pacman &>/dev/null; then
        pacman -Sy 2>&1 | tail -5
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    update_start "$@"
fi