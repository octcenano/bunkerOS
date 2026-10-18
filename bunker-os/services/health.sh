#!/bin/bash
# Bunker OS - Servicio: Salud del Sistema
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

HEALTH_LOG="$BUNKER_VAR/health.log"

health_start() {
    bunker_info "Iniciando servicio de salud..."
    log_health "info" "Servicio de salud iniciado"
}

health_stop() {
    bunker_info "Deteniendo servicio de salud..."
    log_health "info" "Servicio de salud detenido"
}

health_check() {
    local issues=0
    local disk_usage
    disk_usage=$(df / 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
    if [[ -n "$disk_usage" && "$disk_usage" -gt 90 ]]; then
        log_health "warn" "Uso de disco alto: ${disk_usage}%"
        ((issues++))
    fi
    local mem_usage
    mem_usage=$(free | awk '/^Mem:/{printf "%.0f", $3/$2*100}')
    if [[ "$mem_usage" -gt 90 ]]; then
        log_health "warn" "Uso de memoria alto: ${mem_usage}%"
        ((issues++))
    fi
    local zombie_count
    zombie_count=$(ps aux | awk '$8 ~ /Z/ {count++} END {print count+0}')
    if [[ "$zombie_count" -gt 5 ]]; then
        log_health "warn" "Procesos zombi detectados: $zombie_count"
        ((issues++))
    fi
    log_health "info" "Health check completado. Problemas: $issues"
    return $issues
}

log_health() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$HEALTH_LOG"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    health_start "$@"
fi