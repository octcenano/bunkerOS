#!/bin/bash
# Bunker OS - Módulo: Procesos
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

declare -A ALLOWED_PROCESSES=(
    ["systemd"]=1
    ["bash"]=1
    ["init"]=1
    ["sshd"]=1
    ["cron"]=1
)

detect_processes() {
    bunker_debug "Ejecutando detección de procesos..."
    local pids
    pids=$(pgrep -f . 2>/dev/null)
    for pid in $pids; do
        local cmdline
        cmdline=$(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ')
        if echo "$cmdline" | grep -qiE "(/dev/tcp|nc -l|base64 -d|eval|wget.*\|.*sh|curl.*\|.*sh)"; then
            bunker_warn "Proceso sospechoso detectado: PID=$pid CMD=$cmdline"
            log_incident "process" "$pid" "comando_sospechoso"
        fi
        if [[ -f /proc/$pid/stat ]]; then
            local cpu_stat
            cpu_stat=$(ps -p "$pid" -o %cpu= 2>/dev/null | tr -d ' ')
            if [[ -n "$cpu_stat" ]]; then
                local cpu_int=${cpu_stat%.*}
                if [[ "$cpu_int" -gt 90 ]]; then
                    bunker_warn "Proceso consume recursos excesivos: PID=$pid CPU=${cpu_stat}%"
                    log_incident "process" "$pid" "alto_consumo"
                fi
            fi
        fi
    done
}

run_detection() {
    detect_processes
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_detection
fi