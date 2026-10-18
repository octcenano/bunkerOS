#!/bin/bash
# =============================================================================
# Bunker OS - Motor de Ejecución (Engine)
# Ubicación: /usr/lib/bunker/engine/engine.sh
# Propósito: interpretar y ejecutar el grafo del núcleo, gestionar modos
# Desarrollador jefe: <tu_usuario> | Ingeniero colaborador: Apodex 1.1 Mini
# =============================================================================

set -o pipefail

BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

# -----------------------------------------------------------------------------
# Flags del engine
# -----------------------------------------------------------------------------
ENGINE_MODE="${ENGINE_MODE:-}"
ENGINE_LAYERS="${ENGINE_LAYERS:-}"
ENGINE_ADAPT="${ENGINE_ADAPT:-false}"

# -----------------------------------------------------------------------------
# Ayuda del engine
# -----------------------------------------------------------------------------
engine_help() {
    cat <<EOF
Bunker OS Engine - Motor de Ejecución

Uso: bunker engine [opciones]

Opciones:
  --mode <m>        Modo de operación: gaming | ia | ghost | office | hacking | custom
  --layer <l>       Activar capa: stealth | performance | lowram | battery | focus | ai
  --service      Activar servicio: maintenance | update | health | recovery | harden | ai
  --adapt           Adaptar el sistema al hardware detectado
  --modes           Listar modos disponibles
  --help, -h        Mostrar esta ayuda

Ejemplos:
  bunker engine --mode gaming --layer performance
  bunker engine --adapt
  bunker engine --mode ia --service ai --service harden

EOF
}

# -----------------------------------------------------------------------------
# Inicialización del engine
# -----------------------------------------------------------------------------
engine_init() {
    bunker_info "Inicializando motor de Bunker OS..."

    # Cargar módulos dependientes
    bunker_load_module "core/core.sh"
    bunker_load_module "core/config.sh"
    bunker_load_module "core/api.sh"
    bunker_load_module "hardware/hal.sh"
    bunker_load_module "engine/mode-selector.sh"
    bunker_load_module "engine/engine-flags.sh"
    bunker_load_module "rollback/rollback.sh"

    # Inicializar API
    api_init

    bunker_info "Motor inicializado"
}

# -----------------------------------------------------------------------------
# Ejecución principal
# -----------------------------------------------------------------------------
engine_run() {
    bunker_info "Ejecutando motor con modo: ${ENGINE_MODE:-custom}"

    # 1. Adaptar al hardware si se solicitó (usando engine-flags)
    if [[ "$ENGINE_ADAPT" == "true" ]]; then
        engine_adapt_hardware
    fi

    # 2. Seleccionar modo
    if [[ -z "$ENGINE_MODE" ]]; then
        ENGINE_MODE=$(detect_hardware_for_mode)
    fi

    # 3. Aplicar modo (usando engine-flags para consistencia)
    engine_apply_mode "$ENGINE_MODE"

    # 4. Aplicar capas adicionales
    if [[ -n "$ENGINE_LAYERS" ]]; then
        IFS=' ' read -ra extra_layers <<< "$ENGINE_LAYERS"
        for layer in "${extra_layers[@]}"; do
            engine_apply_layer "$layer"
        done
    fi

    # 5. Iniciar servicios
    start_system_services

    # 6. Establecer estado conocido
    bunker_set_known_state

    bunker_info "Motor ejecutándose en modo: $ENGINE_MODE"

    # Ciclo principal de ejecución
    engine_main_loop
}

engine_main_loop() {
    bunker_info "Entrando en ciclo principal del motor..."

    while true; do
        # Verificar salud del sistema
        health_check

        # Esperar eventos
        sleep 60
    done
}

health_check() {
    # Verificar que los componentes críticos estén funcionando
    local issues=0

    if ! bunker_is_running "bunker-core"; then
        bunker_error "El núcleo no está ejecutándose"
        ((issues++))
    fi

    if [[ $issues -gt 0 ]]; then
        bunker_error "Se detectaron $issues problemas de salud"
        # Intentar recuperación automática
        if [[ "$(bunker_config_get services recovery)" == "true" ]]; then
            recovery_start
        fi
    fi
}

# -----------------------------------------------------------------------------
# Punto de entrada
# -----------------------------------------------------------------------------
main() {
    local command="${1:-run}"
    shift || true

    case "$command" in
        init)     engine_init "$@" ;;
        run)      engine_run "$@" ;;
        help)     engine_help "$@" ;;
        *)
            bunker_error "Comando desconocido: $command"
            bunker_exit 1
            ;;
    esac
}

main "$@"