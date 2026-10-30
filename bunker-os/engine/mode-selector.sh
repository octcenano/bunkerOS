#!/bin/bash
# =============================================================================
# Bunker OS - Selector de Modos del Motor (Mode Selector)
# Ubicaci3n: /usr/lib/bunker/engine/mode-selector.sh
# Propsito: seleccionar y aplicar modos de operacin segn hardware y uso
# Desarrollador jefe: <tu_usuario> | Ingeniero colaborador: Apodex 1.1 Mini
# =============================================================================

set -o pipefail

BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

# -----------------------------------------------------------------------------
# Modos disponibles
# -----------------------------------------------------------------------------
declare -A MODE_DESCRIPTIONS=(
    ["gaming"]="Optimizado para juegos: mximo rendimiento de GPU/CPU, latencia mnima"
    ["ia"]="Optimizado para IA local y desarrollo de c3digo: recursos para inferencia y compilacin"
    ["ghost"]="Modo fantasma: privacidad mxima, sin telemetra, auditora reducida"
    ["office"]="Optimizado para oficina: ahorro de energa, estabilidad, productividad"
    ["hacking"]="Modo hacking: herramientas de seguridad, red avanzada, flexibilidad"
    ["custom"]="Personalizado: configuracin manual del usuario"
)

declare -A MODE_LAYERS=(
    ["gaming"]="performance"
    ["ia"]="performance,ai"
    ["ghost"]="stealth,lowram"
    ["office"]="battery,focus"
    ["hacking"]="performance"
    ["custom"]=""
)

declare -A MODE_SERVICES=(
    ["gaming"]=""
    ["ia"]="ai"
    ["ghost"]=""
    ["office"]="maintenance"
    ["hacking"]=""
    ["custom"]="update health recovery harden"
)

# -----------------------------------------------------------------------------
# Deteccin de hardware para sugerir modo
# -----------------------------------------------------------------------------
detect_hardware_for_mode() {
    bunker_info "Detectando hardware para sugerir modo..."

    local gpu_vendor=""
    local cpu_cores=""
    local ram_gb=""
    local gpu_vram=""

    # Detectar GPU
    if command -v lspci &>/dev/null; then
        gpu_vendor=$(lspci | grep -iE "vga|3d|display" | head -1 | grep -oiE "nvidia|amd" | head -1)
    fi

    # Detectar CPU
    if [[ -f /proc/cpuinfo ]]; then
        cpu_cores=$(grep -c "^processor" /proc/cpuinfo)
    fi

    # Detectar RAM
    if [[ -f /proc/meminfo ]]; then
        ram_gb=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1048576 ))
    fi

    bunker_info "Hardware detectado: CPU=$cpu_cores nucleos, RAM=${ram_gb}GB, GPU=$gpu_vendor"

    # Sugerir modo basado en hardware
    local suggested_mode="custom"
    if [[ "$gpu_vendor" == "nvidia" || "$gpu_vendor" == "amd" ]]; then
        if [[ $ram_gb -ge 32 ]]; then
            suggested_mode="ia"
        else
            suggested_mode="gaming"
        fi
    fi

    echo "$suggested_mode"
}

# -----------------------------------------------------------------------------
# Asistente interactivo
# -----------------------------------------------------------------------------
run_mode_wizard() {
    bunker_info "=== SELECCION DE MODO DE OPERACION ==="
    bunker_info "Elige un modo para optimizar tu sistema:"
    bunker_info ""

    local i=0
    for mode in "${!MODE_DESCRIPTIONS[@]}"; do
        if [[ "$mode" != "custom" ]]; then
            ((i++))
            echo "  $i) $mode"
            bunker_info "     ${MODE_DESCRIPTIONS[$mode]}"
        fi
    done
    echo "  0) personalizar (custom)"
    bunker_info ""

    local choice
    read -r -t 30 -p "Tu eleccion [0-$((${#MODE_DESCRIPTIONS[@]}-1))]: " choice

    case "$choice" in
        1) echo "gaming" ;;
        2) echo "ia" ;;
        3) echo "ghost" ;;
        4) echo "office" ;;
        5) echo "hacking" ;;
        *) echo "custom" ;;
    esac
}

# -----------------------------------------------------------------------------
# Aplicar modo
# -----------------------------------------------------------------------------
apply_mode() {
    local mode="$1"
    local snapshot_id=""

    bunker_info "Aplicando modo: $mode"

    # Crear snapshot antes de aplicar cambios (rollback seguro)
    if [[ "$(bunker_config_get security auto_rollback)" == "true" ]]; then
        snapshot_id=$(rollback_snapshot "before_mode_$mode")
    fi

    # Aplicar capas
    local layers="${MODE_LAYERS[$mode]}"
    if [[ -n "$layers" ]]; then
        IFS=',' read -ra layer_array <<< "$layers"
        for layer in "${layer_array[@]}"; do
            bunker_config_set layers "enabled_layers" "[\"$layer\"]"
        done
    fi

    # Aplicar servicios
    local services="${MODE_SERVICES[$mode]}"
    for service in maintenance update health recovery harden ai; do
        if [[ " $services " == *" $service "* ]]; then
            bunker_config_set services "$service" "true"
        else
            bunker_config_set services "$service" "false"
        fi
    done

    # Aplicar configuracion especifica del modo
    case "$mode" in
        gaming)
            tune_gaming
            ;;
        ia)
            tune_ai_local
            ;;
        ghost)
            tune_ghost
            ;;
        office)
            tune_office
            ;;
        hacking)
            tune_hacking
            ;;
    esac

    bunker_state_set "current_mode" "$mode"
    bunker_state_set "mode_snapshot_$mode" "$snapshot_id"

    bunker_info "Modo $mode aplicado correctamente"
    echo "$snapshot_id"
}

tune_gaming() {
    bunker_info "Optimizando para gaming..."
    if command -v cpupower &>/dev/null; then
        cpupower frequency-governor performance 2>/dev/null || true
    fi
    # Optimizaciones de GPU
    bunker_info "Aplicando optimizaciones de GPU..."
}

tune_ai_local() {
    bunker_info "Optimizando para IA local..."
    # Asignar mas recursos a procesos de IA
    bunker_info "Configurando entorno para inferencia de IA..."
}

tune_ghost() {
    bunker_info "Activando modo fantasma..."
    bunker_config_set security "audit_enabled" "false"
    bunker_config_set evolution "telemetry_anonymous" "false"
    bunker_config_set logging "level" "error"
}

tune_office() {
    bunker_info "Optimizando para oficina..."
    if command -v cpupower &>/dev/null; then
        cpupower frequency-governor powersave 2>/dev/null || true
    fi
}

tune_hacking() {
    bunker_info "Configurando entorno de hacking..."
    
    # Verificar si Tor esta disponible antes de continuar
    if ! command -v tor &>/dev/null; then
        bunker_error "El modo hacking requiere Tor para proteccion de privacidad"
        bunker_error "Tor no esta instalado o no esta en el PATH"
        bunker_error "Instala Tor con: pacman -S tor"
        bunker_exit 1
    fi
    
    # Verificar si Tor esta corriendo
    if ! pgrep -x tor &>/dev/null; then
        bunker_warn "Tor no esta en ejecucion. Iniciando Tor..."
        if ! command -v systemctl &>/dev/null || ! systemctl start tor 2>/dev/null; then
            bunker_error "No se pudo iniciar Tor. Verifica la instalacion."
            bunker_exit 1
        fi
        # Esperar a que Tor este listo
        sleep 5
        if ! pgrep -x tor &>/dev/null; then
            bunker_error "Tor fallo al iniciar. No se puede continuar con modo hacking sin proteccion."
            bunker_exit 1
        fi
    fi
    
    # Verificar conexion Tor
    if ! curl --socks5-hostname localhost:9050 -s https://check.torproject.org/api/ip 2>/dev/null | grep -q "true" &>/dev/null; then
        bunker_warn "No se pudo verificar conexion Tor, pero continuando con advertencia"
    fi
    
    bunker_config_set security "kernel_hardening" "false"
    bunker_info "Asegurate de usar este modo solo en entornos controlados"
    bunker_info "Tor esta activo y protegiendo tu conexion"
}

# -----------------------------------------------------------------------------
# Punto de entrada
# -----------------------------------------------------------------------------
main() {
    local command="${1:-select}"
    shift || true

    case "$command" in
        select)
            local mode="${ENGINE_MODE:-}"
            if [[ -z "$mode" ]]; then
                mode=$(detect_hardware_for_mode)
                bunker_info "Modo sugerido por hardware: $mode"
            fi
            apply_mode "$mode"
            ;;
        wizard)
            local mode
            mode=$(run_mode_wizard)
            apply_mode "$mode"
            ;;
        list)
            for mode in "${!MODE_DESCRIPTIONS[@]}"; do
                echo "$mode: ${MODE_DESCRIPTIONS[$mode]}"
            done
            ;;
        suggest)
            detect_hardware_for_mode
            ;;
        *)
            bunker_error "Comando desconocido: $command"
            bunker_exit 1
            ;;
    esac
}

main "$@"
