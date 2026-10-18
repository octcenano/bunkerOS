#!/bin/bash
# Bunker OS - Watchdog: Seguridad
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

watchdog_security() {
    local interval=15
    local alert_log="$BUNKER_VAR/security-alerts.log"
    bunker_debug "Watchdog de seguridad iniciado"
    while true; do
        if command -v journalctl &>/dev/null; then
            local failed_logins
            failed_logins=$(journalctl --since "$interval seconds ago" \
                -u sshd 2>/dev/null | grep -c "Failed password" 2>/dev/null || echo "0")
            if [[ "$failed_logins" -gt 5 ]]; then
                bunker_warn "Watchdog seguridad: $failed_logins intentos de acceso fallidos detectados"
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERTA: $failed_logins intentos fallidos de SSH" >> "$alert_log"
                if [[ "$(bunker_config_get services harden)" == "true" ]]; then
                    harden_start 2>/dev/null || true
                fi
            fi
        fi
        if command -v ss &>/dev/null; then
            local suspicious_ports
            suspicious_ports=$(ss -tln 2>/dev/null | awk 'NR>1 {print $4}' | rev | cut -d: -f1 | rev | grep -E '^(4444|5555|6666|7777|8888|9999|31337)$' || true)
            if [[ -n "$suspicious_ports" ]]; then
                bunker_warn "Watchdog seguridad: puertos sospechosos detectados: $suspicious_ports"
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERTA: puertos sospechosos: $suspicious_ports" >> "$alert_log"
            fi
        fi
        local reverse_shells
        reverse_shells=$(ps aux 2>/dev/null | grep -E "(/dev/tcp|nc -l|bash -i|sh -i)" | grep -v grep || true)
        if [[ -n "$reverse_shells" ]]; then
            bunker_error "Watchdog seguridad: posible shell inversa detectada"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] CRÍTICO: posible shell inversa" >> "$alert_log"
        fi
        sleep "$interval"
    done
}

run_watchdog() {
    watchdog_security
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_watchdog
fi