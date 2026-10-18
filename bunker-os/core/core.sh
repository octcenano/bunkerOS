#!/bin/bash
# =============================================================================
# Bunker OS - Núcleo del sistema (Core Engine)
# Ubicación: /usr/lib/bunker/core/core.sh
# Propósito: gestión de procesos, memoria, planificación, ciclo de vida
# Desarrollador jefe: <tu_usuario> | Ingeniero colaborador: Apodex 1.1 Mini
# =============================================================================

set -o pipefail

# Cargar librería compartida
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

# -----------------------------------------------------------------------------
# Estado del núcleo
# -----------------------------------------------------------------------------
CORE_STATE="stopped"
CORE_PID=$$

# -----------------------------------------------------------------------------
# Ciclo de vida
# -----------------------------------------------------------------------------
core_start() {
    bunker_require_root

    bunker_info "Iniciando núcleo de Bunker OS v$BUNKER_VERSION..."

    # 1. Inicializar directorios de estado y ejecución
    mkdir -p "$(bunker_state_dir)"
    mkdir -p "$BUNKER_RUN"
    mkdir -p "$(dirname "$BUNKER_LOG")"

    # 2. Cargar configuración
    bunker_info "Cargando configuración..."
    load_config

    # 3. Detectar hardware automáticamente
    bunker_info "Detectando hardware..."
    detect_hardware

    # 4. Seleccionar modo de operación
    bunker_info "Seleccionando modo de operación..."
    select_engine_mode

    # 5. Aplicar capas del sistema
    apply_system_layers

    # 6. Iniciar servicios del sistema
    start_system_services

    # 7. Establecer estado conocido
    bunker_set_known_state

    CORE_STATE="running"
    bunker_write_pid "bunker-core" "$CORE_PID"

    bunker_info "Núcleo de Bunker OS iniciado correctamente"
    bunker_info "Modo: $ENGINE_MODE | Capas: ${LAYERS[*]:-ninguna}"
}

core_stop() {
    bunker_require_root

    bunker_info "Deteniendo núcleo de Bunker OS..."

    # Detener servicios
    stop_system_services

    # Detener guardian y sentinel
    if bunker_is_running "bunker-guardian"; then
        /usr/lib/bunker/guardian/guardian.sh stop
    fi
    if bunker_is_running "bunker-sentinel"; then
        /usr/lib/bunker/sentinel/sentinel.sh stop
    fi

    # Guardar estado final
    bunker_state_set "last_shutdown" "$(date +%s)"

    CORE_STATE="stopped"
    bunker_remove_pid "bunker-core"

    bunker_info "Núcleo de Bunker OS detenido"
}

core_status() {
    echo "Estado del núcleo: $CORE_STATE"
    echo "PID: $CORE_PID"
    echo "Modo: ${ENGINE_MODE:-no seleccionado}"
    echo "Capas activas: ${LAYERS[*]:-ninguna}"
    echo "Estado conocido: $(bunker_known_state)"
    echo "Último reinicio: $(bunker_state_get last_restart 2>/dev/null || echo 'nunca')"
}

# -----------------------------------------------------------------------------
# Configuración
# -----------------------------------------------------------------------------
load_config() {
    local config_file="$BUNKER_ETC/bunker.conf"
    if [[ ! -f "$config_file" ]]; then
        bunker_warn "Configuración no encontrada en $config_file, usando valores por defecto"
        return 1
    fi
    bunker_debug "Configuración cargada desde $config_file"
}

# -----------------------------------------------------------------------------
# Detección de hardware
# -----------------------------------------------------------------------------
detect_hardware() {
    # Cargar HAL
    if [[ -f "$BUNKER_ROOT/hardware/hal.sh" ]]; then
        source "$BUNKER_ROOT/hardware/hal.sh"
        hardware_detect_all
    else
        bunker_warn "HAL no encontrado, detección de hardware deshabilitada"
    fi
}

# -----------------------------------------------------------------------------
# Motor de selección de modos
# -----------------------------------------------------------------------------
ENGINE_MODE="custom"
ENGINE_MODES=("gaming" "ia" "ghost" "office" "hacking" "custom")
LAYERS=()

select_engine_mode() {
    local mode
    mode=$(bunker_config_get "engine" "default_mode")

    if [[ -z "$mode" || "$mode" == "custom" ]]; then
        # Ejecutar asistente de selección si está habilitado
        if [[ "$(bunker_config_get "engine" "show_mode_wizard")" == "true" ]]; then
            mode=$(run_mode_wizard)
        fi
    fi

    # Validar modo
    local valid=false
    for m in "${ENGINE_MODES[@]}"; do
        if [[ "$m" == "$mode" ]]; then
            valid=true
            break
        fi
    done

    if [[ "$valid" == false ]]; then
        bunker_warn "Modo '$mode' no válido, usando 'custom'"
        mode="custom"
    fi

    ENGINE_MODE="$mode"
    bunker_state_set "engine_mode" "$mode"
    bunker_info "Modo seleccionado: $mode"

    # Aplicar configuración específica del modo
    apply_mode_config "$mode"
}

run_mode_wizard() {
    bunker_info "=== SELECCIÓN DE MODO DE OPERACIÓN ==="
    bunker_info "Selecciona un modo para optimizar el sistema:"
    local i=1
    for m in "${ENGINE_MODES[@]}"; do
        if [[ "$m" != "custom" ]]; then
            echo "  $i) $m"
            ((i++))
        fi
    done
    echo "  0) personalizar (custom)"

    local choice
    read -r -t "$(bunker_config_get "engine" "wizard_timeout" 30)" -p "Tu elección [0-$((${#ENGINE_MODES[@]}-1))]: " choice

    case "$choice" in
        1) echo "gaming" ;;
        2) echo "ia" ;;
        3) echo "ghost" ;;
        4) echo "office" ;;
        5) echo "hacking" ;;
        *) echo "custom" ;;
    esac
}

apply_mode_config() {
    local mode="$1"
    bunker_info "Aplicando configuración para modo: $mode"

    case "$mode" in
        gaming)
            bunker_config_set "layers" "enabled_layers" '["performance"]'
            bunker_config_set "services" "ai" "false"
            bunker_config_set "security" "kernel_hardening" "true"
            ;;
        ia)
            bunker_config_set "layers" "enabled_layers" '["performance", "ai"]'
            bunker_config_set "services" "ai" "true"
            ;;
        ghost)
            bunker_config_set "layers" "enabled_layers" '["stealth", "lowram"]'
            bunker_config_set "security" "audit_enabled" "false"
            bunker_config_set "evolution" "telemetry_anonymous" "false"
            ;;
        office)
            bunker_config_set "layers" "enabled_layers" '["battery", "focus"]'
            bunker_config_set "services" "maintenance" "true"
            ;;
        hacking)
            bunker_config_set "layers" "enabled_layers" '["performance"]'
            bunker_config_set "services" "harden" "false"
            ;;
        custom)
            bunker_config_set "layers" "enabled_layers" '[]'
            ;;
    esac

    bunker_state_set "mode_applied_$mode" "$(date +%s)"
}

# -----------------------------------------------------------------------------
# Capas del sistema
# -----------------------------------------------------------------------------
apply_system_layers() {
    local layers_json
    layers_json=$(bunker_config_get "layers" "enabled_layers")

    # Parsear JSON simple (array de strings)
    LAYERS=()
    local layer
    for layer in $(echo "$layers_json" | tr -d '[],"' | tr ',' ' '); do
        if [[ -n "$layer" ]]; then
            LAYERS+=("$layer")
        fi
    done

    bunker_info "Aplicando capas: ${LAYERS[*]:-ninguna}"

    for layer in "${LAYERS[@]}"; do
        apply_layer "$layer"
    done
}

apply_layer() {
    local layer="$1"
    bunker_info "Aplicando capa: $layer"

    case "$layer" in
        stealth)
            bunker_config_set "security" "audit_enabled" "false"
            bunker_config_set "evolution" "telemetry_anonymous" "false"
            ;;
        performance)
            tune_performance
            ;;
        lowram)
            tune_lowram
            ;;
        battery)
            tune_battery
            ;;
        focus)
            tune_focus
            ;;
        ai)
            tune_ai
            ;;
        *)
            bunker_warn "Capa desconocida: $layer"
            ;;
    esac
}

tune_performance() {
    bunker_info "Optimizando para rendimiento..."
    if command -v cpupower &>/dev/null; then
        cpupower frequency-governor performance 2>/dev/null || true
    fi
    echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
}

tune_lowram() {
    bunker_info "Optimizando para baja memoria..."
    sysctl -w vm.swappiness=10 2>/dev/null || true
}

tune_battery() {
    bunker_info "Optimizando para batería..."
    if command -v cpupower &>/dev/null; then
        cpupower frequency-governor powersave 2>/dev/null || true
    fi
}

tune_focus() {
    bunker_info "Optimizando para concentración..."
}

tune_ai() {
    bunker_info "Optimizando para IA..."
    local current_mem
    current_mem=$(bunker_config_get resources "core_memory_budget" 2>/dev/null || echo "512")
    bunker_config_set resources "core_memory_budget" "$((current_mem * 2))"
}

# -----------------------------------------------------------------------------
# Servicios del sistema
# -----------------------------------------------------------------------------
start_system_services() {
    local services_json
    services_json=$(bunker_config_get "services" "")

    for service in maintenance update health recovery harden ai; do
        local enabled
        enabled=$(bunker_config_get "services" "$service")
        if [[ "$enabled" == "true" ]]; then
            start_service "$service"
        fi
    done
}

start_service() {
    local service="$1"
    bunker_info "Iniciando servicio: $service"

    case "$service" in
        maintenance)
            if [[ -f "$BUNKER_ROOT/services/maintenance.sh" ]]; then
                source "$BUNKER_ROOT/services/maintenance.sh"
                maintenance_start
            fi
            ;;
        update)
            if [[ -f "$BUNKER_ROOT/services/update.sh" ]]; then
                source "$BUNKER_ROOT/services/update.sh"
                update_start
            fi
            ;;
        health)
            if [[ -f "$BUNKER_ROOT/services/health.sh" ]]; then
                source "$BUNKER_ROOT/services/health.sh"
                health_start
            fi
            ;;
        recovery)
            if [[ -f "$BUNKER_ROOT/services/recovery.sh" ]]; then
                source "$BUNKER_ROOT/services/recovery.sh"
                recovery_start
            fi
            ;;
        harden)
            if [[ -f "$BUNKER_ROOT/services/harden.sh" ]]; then
                source "$BUNKER_ROOT/services/harden.sh"
                harden_start
            fi
            ;;
        ai)
            if [[ -f "$BUNKER_ROOT/services/ai.sh" ]]; then
                source "$BUNKER_ROOT/services/ai.sh"
                ai_start
            fi
            ;;
    esac
}

stop_system_services() {
    for service in maintenance update health recovery harden ai; do
        local enabled
        enabled=$(bunker_config_get "services" "$service")
        if [[ "$enabled" == "true" ]]; then
            stop_service "$service"
        fi
    done
}

stop_service() {
    local service="$1"
    bunker_info "Deteniendo servicio: $service"

    case "$service" in
        maintenance) [[ -f "$BUNKER_ROOT/services/maintenance.sh" ]] && maintenance_stop ;;
        update)      [[ -f "$BUNKER_ROOT/services/update.sh" ]]      && update_stop ;;
        health)      [[ -f "$BUNKER_ROOT/services/health.sh" ]]      && health_stop ;;
        recovery)    [[ -f "$BUNKER_ROOT/services/recovery.sh" ]]    && recovery_stop ;;
        harden)      [[ -f "$BUNKER_ROOT/services/harden.sh" ]]      && harden_stop ;;
        ai)          [[ -f "$BUNKER_ROOT/services/ai.sh" ]]          && ai_stop ;;
    esac
}

# -----------------------------------------------------------------------------
# Post-install
# -----------------------------------------------------------------------------
core_post_install() {
    bunker_info "Ejecutando post-instalación de Bunker OS..."

    # Crear directorios necesarios
    mkdir -p /var/lib/bunker/state
    mkdir -p /var/lib/bunker/snapshots
    mkdir -p /var/lib/bunker/incidents
    mkdir -p /var/lib/bunker/hypotheses
    mkdir -p /var/lib/bunker/baseline
    mkdir -p /var/log/bunker
    mkdir -p /etc/bunker

    # Establecer estado conocido
    bunker_set_known_state

    bunker_info "Post-instalación completada"
}

# -----------------------------------------------------------------------------
# Punto de entrada
# -----------------------------------------------------------------------------
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        start)      core_start "$@" ;;
        stop)       core_stop "$@" ;;
        restart)    core_stop "$@"; core_start "$@" ;;
        status)     core_status "$@" ;;
        post-install) core_post_install "$@" ;;
        help|--help|-h)
            echo "Uso: bunker core <comando>"
            echo "Comandos: start | stop | restart | status | post-install | help"
            ;;
        *)
            bunker_error "Comando desconocido: $command"
            bunker_exit 1
            ;;
    esac
}

main "$@"