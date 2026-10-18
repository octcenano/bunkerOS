#!/bin/bash
# Bunker OS - Servicio: IA
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

ai_start() {
    bunker_info "Iniciando servicio de IA..."
    tune_ai_resources
}

ai_stop() {
    bunker_info "Deteniendo servicio de IA..."
}

tune_ai_resources() {
    bunker_info "Optimizando recursos para IA..."
    local current_mem
    current_mem=$(bunker_config_get resources "core_memory_budget" 2>/dev/null || echo "512")
    bunker_config_set resources "core_memory_budget" "$((current_mem * 2))"
    if command -v renice &>/dev/null; then
        :
    fi
    bunker_info "Recursos de IA optimizados"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ai_start "$@"
fi