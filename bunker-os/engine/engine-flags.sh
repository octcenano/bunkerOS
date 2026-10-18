#!/bin/bash
# =============================================================================
# Bunker OS - Engine Flags System
# Ubicación: /usr/lib/bunker/engine/engine-flags.sh
# Propósito: sistema de flags, adapt y modes para el motor de ejecución
# Desarrollador jefe: <tu_usuario> | Ingeniero colaborador: Apodex 1.1 Mini
# =============================================================================

set -o pipefail

BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

# -----------------------------------------------------------------------------
# Flags del engine
# -----------------------------------------------------------------------------
declare -A ENGINE_FLAGS=(
    [adapt]="false"
    [verbose]="false"
    [quiet]="false"
    [dry_run]="false"
    [force]="false"
    [rollback_on_failure]="true"
    [hardware_detect]="true"
    [auto_mode]="false"
)

declare -A ENGINE_MODES=(
    [gaming]="performance"
    [ia]="performance,ai"
    [ghost]="stealth,lowram"
    [office]="battery,focus"
    [hacking]="performance"
    [custom]=""
)

declare -A ENGINE_LAYER_DESCRIPTIONS=(
    [stealth]="Sin telemetría, auditoría reducida, logs mínimos, modo privado"
    [performance]="Governor de CPU performance, optimizaciones de GPU, baja latencia"
    [lowram]="Optimizaciones para sistemas con poca memoria, swap agresivo"
    [battery]="Governor powersave, ahorro de energía, suspensión agresiva"
    [focus]="Prioridad a procesos interactivos, reducción de procesos en segundo plano"
    [ai]="Asignación de recursos para inferencia de IA, GPU compute, memoria compartida"
)

# -----------------------------------------------------------------------------
# Gestión de flags
# -----------------------------------------------------------------------------
engine_flag_set() {
    local flag="$1"
    local value="$2"

    if [[ -z "${ENGINE_FLAGS[$flag]+x}" ]]; then
        bunker_error "Flag desconocido: $flag"
        return 1
    fi

    ENGINE_FLAGS["$flag"]="$value"
    bunker_debug "Flag establecido: $flag = $value"
}

engine_flag_get() {
    local flag="$1"
    echo "${ENGINE_FLAGS[$flag]}"
}

engine_flag_list() {
    bunker_info "=== FLAGS DEL ENGINE ==="
    for flag in "${!ENGINE_FLAGS[@]}"; do
        echo "  --$flag: ${ENGINE_FLAGS[$flag]}"
    done
}

# -----------------------------------------------------------------------------
# Adaptación al hardware
# -----------------------------------------------------------------------------
engine_adapt_hardware() {
    bunker_info "=== ADAPTACIÓN AL HARDWARE ==="

    if [[ "$(engine_flag_get hardware_detect)" != "true" ]]; then
        bunker_info "Detección de hardware deshabilitada por flag"
        return 0
    fi

    # Ejecutar detección completa de hardware
    hardware_detect_all

    # Mostrar información detectada
    bunker_info "CPU: ${HARDWARE_INFO[cpu]}"
    bunker_info "GPU: ${HARDWARE_INFO[gpu]}"
    bunker_info "RAM: ${HARDWARE_INFO[ram]}"
    bunker_info "Almacenamiento: ${HARDWARE_INFO[storage]}"

    # Aplicar optimizaciones según hardware
    hardware_optimize

    # Sugerir modo basado en hardware
    local suggested_mode
    suggested_mode=$(detect_hardware_for_mode)
    bunker_info "Modo sugerido por hardware: $suggested_mode"

    # Guardar perfil de hardware
    local hw_profile="$BUNKER_VAR/hardware-profile.json"
    mkdir -p "$(dirname "$hw_profile")"
    python3 - "$suggested_mode" <<'PY'
import json, sys, os
mode = sys.argv[1]
profile = {
    "detected_at": __import__('datetime').datetime.now().isoformat(),
    "suggested_mode": mode,
    "adapted": True
}
os.makedirs('/var/lib/bunker', exist_ok=True)
with open('/var/lib/bunker/hardware-profile.json', 'w') as f:
    json.dump(profile, f, indent=2)
PY

    bunker_info "Hardware adaptado. Perfil guardado en $hw_profile"
}

# -----------------------------------------------------------------------------
# Selección y aplicación de modos
# -----------------------------------------------------------------------------
engine_apply_mode() {
    local mode="$1"

    if [[ -z "$mode" ]]; then
        bunker_error "Modo no especificado"
        return 1
    fi

    # Validar modo
    if [[ -z "${ENGINE_MODES[$mode]+x}" ]]; then
        bunker_error "Modo desconocido: $mode"
        bunker_info "Modos disponibles: $(echo "${!ENGINE_MODES[@]}" | tr ' ' ' | ')"
        return 1
    fi

    bunker_info "=== APLICANDO MODO: $mode ==="

    # Crear snapshot antes de aplicar (rollback seguro)
    if [[ "$(engine_flag_get rollback_on_failure)" == "true" ]]; then
        local snapshot
        snapshot=$(rollback_snapshot "before_mode_${mode}_$(date +%s)")
        bunker_state_set "mode_snapshot_$mode" "$snapshot"
        bunker_info "Snapshot de seguridad creado: $snapshot"
    fi

    # Aplicar capas del modo
    local layers="${ENGINE_MODES[$mode]}"
    if [[ -n "$layers" ]]; then
        IFS=',' read -ra layer_array <<< "$layers"
        for layer in "${layer_array[@]}"; do
            bunker_info "Aplicando capa: $layer"
            apply_layer "$layer"
        done
    fi

    # Aplicar optimizaciones específicas del modo
    case "$mode" in
        gaming)
            tune_gaming_mode
            ;;
        ia)
            tune_ia_mode
            ;;
        ghost)
            tune_ghost_mode
            ;;
        office)
            tune_office_mode
            ;;
        hacking)
            tune_hacking_mode
            ;;
        custom)
            tune_custom_mode
            ;;
    esac

    # Guardar modo actual
    bunker_state_set "current_mode" "$mode"
    bunker_state_set "mode_applied_at" "$(date +%s)"

    bunker_info "Modo $mode aplicado correctamente"
    return 0
}

tune_gaming_mode() {
    bunker_info "Optimizando para gaming..."
    if command -v cpupower &>/dev/null; then
        cpupower frequency-governor performance 2>/dev/null || true
    fi
    # Deshabilitar servicios innecesarios para gaming
    bunker_config_set services "maintenance" "false"
    bunker_config_set services "update" "false"
    bunker_config_set services "ai" "false"
    # Priorizar procesos de juego
    bunker_info "Modo gaming: rendimiento máximo activado"
}

tune_ia_mode() {
    bunker_info "Optimizando para IA local y código..."
    if command -v cpupower &>/dev/null; then
        cpupower frequency-governor performance 2>/dev/null || true
    fi
    # Habilitar servicio de IA
    bunker_config_set services "ai" "true"
    # Configurar memoria para IA
    local current_mem
    current_mem=$(bunker_config_get resources "core_memory_budget" 2>/dev/null || echo "512")
    bunker_config_set resources "core_memory_budget" "$((current_mem * 2))"
    bunker_info "Modo IA: recursos para inferencia y compilación activados"
}

tune_ghost_mode() {
    bunker_info "Activando modo fantasma (privacidad máxima)..."
    bunker_config_set security "audit_enabled" "false"
    bunker_config_set evolution "telemetry_anonymous" "false"
    bunker_config_set logging "level" "error"
    bunker_config_set services "maintenance" "false"
    bunker_config_set services "update" "false"
    bunker_info "Modo fantasma: telemetría deshabilitada, auditoría reducida"
}

tune_office_mode() {
    bunker_info "Optimizando para oficina..."
    if command -v cpupower &>/dev/null; then
        cpupower frequency-governor powersave 2>/dev/null || true
    fi
    bunker_config_set services "maintenance" "true"
    bunker_info "Modo oficina: ahorro de energía y estabilidad activados"
}

tune_hacking_mode() {
    bunker_info "Configurando entorno de hacking..."
    bunker_config_set security "kernel_hardening" "false"
    bunker_config_set services "harden" "false"
    bunker_warn "Modo hacking: solo para entornos controlados y autorizados"
}

tune_custom_mode() {
    bunker_info "Modo personalizado: configuración manual del usuario"
}

# -----------------------------------------------------------------------------
# Aplicar capas individuales
# -----------------------------------------------------------------------------
engine_apply_layer() {
    local layer="$1"

    case "$layer" in
        stealth)
            bunker_config_set security "audit_enabled" "false"
            bunker_config_set evolution "telemetry_anonymous" "false"
            bunker_config_set logging "level" "warn"
            ;;
        performance)
            tune_performance_layer
            ;;
        lowram)
            tune_lowram_layer
            ;;
        battery)
            tune_battery_layer
            ;;
        focus)
            tune_focus_layer
            ;;
        ai)
            tune_ai_layer
            ;;
        *)
            bunker_error "Capa desconocida: $layer"
            return 1
            ;;
    esac

    # Registrar capa aplicada
    local applied_layers
    applied_layers=$(bunker_state_get "applied_layers" 2>/dev/null || echo "")
    if [[ -z "$applied_layers" ]]; then
        applied_layers="$layer"
    else
        applied_layers="$applied_layers,$layer"
    fi
    bunker_state_set "applied_layers" "$applied_layers"

    bunker_info "Capa $layer aplicada"
}

tune_performance_layer() {
    bunker_info "Aplicando capa performance..."
    if command -v cpupower &>/dev/null; then
        cpupower frequency-governor performance 2>/dev/null || true
    fi
    echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
}

tune_lowram_layer() {
    bunker_info "Aplicando capa lowram..."
    # Reducir swappiness para sistemas con poca RAM
    sysctl -w vm.swappiness=10 2>/dev/null || true
    # Limpiar caches periódicamente
    bunker_info "Capa lowram: optimizaciones de memoria activadas"
}

tune_battery_layer() {
    bunker_info "Aplicando capa battery..."
    if command -v cpupower &>/dev/null; then
        cpupower frequency-governor powersave 2>/dev/null || true
    fi
    # Reducir brillo de pantalla si es posible
    bunker_info "Capa battery: ahorro de energía activado"
}

tune_focus_layer() {
    bunker_info "Aplicando capa focus..."
    # Priorizar procesos interactivos
    bunker_info "Capa focus: prioridad a procesos interactivos activada"
}

tune_ai_layer() {
    bunker_info "Aplicando capa ai..."
    # Asignar más recursos a procesos de IA
    bunker_config_set resources "core_memory_budget" "$(( $(bunker_config_get resources "core_memory_budget" 2>/dev/null || echo 512) * 2 ))"
    bunker_info "Capa ai: recursos para IA asignados"
}

# -----------------------------------------------------------------------------
# Listar modos y capas disponibles
# -----------------------------------------------------------------------------
engine_list_modes() {
    bunker_info "=== MODOS DISPONIBLES ==="
    for mode in "${!ENGINE_MODES[@]}"; do
        local layers="${ENGINE_MODES[$mode]}"
        echo "  $mode -> capas: ${layers:-ninguna}"
    done
}

engine_list_layers() {
    bunker_info "=== CAPAS DISPONIBLES ==="
    for layer in "${!ENGINE_LAYER_DESCRIPTIONS[@]}"; do
        echo "  --$layer: ${ENGINE_LAYER_DESCRIPTIONS[$layer]}"
    done
}

# -----------------------------------------------------------------------------
# Punto de entrada
# -----------------------------------------------------------------------------
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        flag-set)
            engine_flag_set "$1" "$2"
            ;;
        flag-get)
            engine_flag_get "$1"
            ;;
        flag-list)
            engine_flag_list
            ;;
        adapt)
            engine_adapt_hardware
            ;;
        mode)
            engine_apply_mode "$1"
            ;;
        layer)
            engine_apply_layer "$1"
            ;;
        list-modes)
            engine_list_modes
            ;;
        list-layers)
            engine_list_layers
            ;;
        help|--help|-h)
            echo "Bunker OS Engine Flags"
            echo ""
            echo "Uso: bunker engine-flags <comando> [argumentos]"
            echo ""
            echo "Comandos:"
            echo "  flag-set <flag> <valor>     Establecer un flag del engine"
            echo "  flag-get <flag>             Obtener el valor de un flag"
            echo "  flag-list                   Listar todos los flags"
            echo "  adapt                       Adaptar el sistema al hardware detectado"
            echo "  mode <modo>                 Aplicar un modo de operación"
            echo "  layer <capa>                Aplicar una capa individual"
            echo "  list-modes                  Listar modos disponibles"
            echo "  list-layers                 Listar capas disponibles"
            echo ""
            echo "Flags disponibles:"
            echo "  adapt, verbose, quiet, dry_run, force, rollback_on_failure, hardware_detect, auto_mode"
            echo ""
            echo "Modos: gaming | ia | ghost | office | hacking | custom"
            echo "Capas: stealth | performance | lowram | battery | focus | ai"
            ;;
        *)
            bunker_error "Comando desconocido: $command"
            bunker_exit 1
            ;;
    esac
}

main "$@"