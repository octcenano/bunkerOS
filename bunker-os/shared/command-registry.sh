#!/bin/bash
# =============================================================================
# Bunker OS - Registro Central de Comandos y Capacidades
# Ubicaci3n: /usr/lib/bunker/shared/command-registry.sh
# Propsito: mantener un registro centralizado de todos los comandos disponibles
# y sus capacidades para evitar sugerencias de comandos inexistentes
# =============================================================================

# -----------------------------------------------------------------------------
# Versin del sistema
# -----------------------------------------------------------------------------
BUNKER_VERSION="2.6.0"
BUNKER_NAME="Bunker OS"

# -----------------------------------------------------------------------------
# Comandos principales de la CLI
# -----------------------------------------------------------------------------
declare -A BUNKER_COMMANDS=(
    ["engine"]="Iniciar el motor del sistema con seleccion de modo"
    ["engine-flags"]="Gestionar flags, adapt, modos y capas del engine"
    ["core"]="Gestionar el nucleo del sistema (start|stop|restart|status)"
    ["config"]="Gestionar la configuracion (get|set|validate|migrate|backup|restore)"
    ["api"]="Interactuar con la API del nucleo"
    ["hardware"]="Informacion y deteccion de hardware"
    ["rollback"]="Gestionar puntos de restauracion"
    ["service"]="Gestionar servicios del sistema"
    ["layer"]="Gestionar capas del sistema"
    ["sentinel"]="Iniciar/detener Bunker Sentinel"
    ["guardian"]="Iniciar/detener Bunker Guardian"
    ["update"]="Actualizar el sistema (all|bunker|aur)"
    ["status"]="Mostrar estado del sistema"
    ["help"]="Mostrar ayuda"
    ["version"]="Mostrar version"
)

# -----------------------------------------------------------------------------
# Subcomandos por modulo
# -----------------------------------------------------------------------------
declare -A BUNKER_ENGINE_SUBCOMMANDS=(
    ["run"]="Ejecutar el motor"
    ["init"]="Inicializar el motor"
    ["help"]="Mostrar ayuda del motor"
)

declare -A BUNKER_ENGINE_FLAGS_SUBCOMMANDS=(
    ["adapt"]="Adaptar al hardware detectado"
    ["mode"]="Seleccionar modo"
    ["layer"]="Seleccionar capa"
    ["list-modes"]="Listar modos disponibles"
    ["list-layers"]="Listar capas disponibles"
    ["help"]="Mostrar ayuda"
)

declare -A BUNKER_CORE_SUBCOMMANDS=(
    ["start"]="Iniciar el nucleo"
    ["stop"]="Detener el nucleo"
    ["restart"]="Reiniciar el nucleo"
    ["status"]="Mostrar estado del nucleo"
    ["post-install"]="Ejecutar post-instalacion"
    ["help"]="Mostrar ayuda"
)

declare -A BUNKER_CONFIG_SUBCOMMANDS=(
    ["init"]="Inicializar configuracion"
    ["get"]="Obtener valor de configuracion"
    ["set"]="Establecer valor de configuracion"
    ["sections"]="Listar secciones"
    ["keys"]="Listar claves"
    ["validate"]="Validar configuracion"
    ["migrate"]="Migrar configuracion"
    ["backup"]="Crear backup de configuracion"
    ["restore"]="Restaurar configuracion"
    ["export-json"]="Exportar a JSON"
    ["help"]="Mostrar ayuda"
)

declare -A BUNKER_API_SUBCOMMANDS=(
    ["init"]="Inicializar API"
    ["send"]="Enviar mensaje"
    ["receive"]="Recibir mensaje"
    ["publish"]="Publicar evento"
    ["subscribe"]="Suscribirse a evento"
    ["events"]="Listar eventos"
    ["query"]="Consultar nucleo"
    ["start-process"]="Iniciar proceso"
    ["stop-process"]="Detener proceso"
    ["processes"]="Listar procesos"
    ["resources"]="Obtener recursos"
    ["audit"]="Registro de auditoria"
    ["help"]="Mostrar ayuda"
)

declare -A BUNKER_HARDWARE_SUBCOMMANDS=(
    ["info"]="Mostrar informacion de hardware"
    ["detect"]="Detectar hardware"
    ["optimize"]="Optimizar hardware"
    ["help"]="Mostrar ayuda"
)

declare -A BUNKER_ROLLBACK_SUBCOMMANDS=(
    ["init"]="Inicializar rollback"
    ["create"]="Crear snapshot"
    ["list"]="Listar snapshots"
    ["restore"]="Restaurar snapshot"
    ["verify"]="Verificar snapshots"
    ["on-failure"]="Rollback automatico"
    ["help"]="Mostrar ayuda"
)

declare -A BUNKER_SERVICE_SUBCOMMANDS=(
    ["list"]="Listar servicios"
    ["enable"]="Habilitar servicio"
    ["disable"]="Deshabilitar servicio"
    ["help"]="Mostrar ayuda"
)

declare -A BUNKER_LAYER_SUBCOMMANDS=(
    ["list"]="Listar capas"
    ["enable"]="Habilitar capa"
    ["disable"]="Deshabilitar capa"
    ["help"]="Mostrar ayuda"
)

declare -A BUNKER_SENTINEL_SUBCOMMANDS=(
    ["start"]="Iniciar Sentinel"
    ["stop"]="Detener Sentinel"
    ["status"]="Mostrar estado"
    ["audit"]="Realizar auditoria"
    ["help"]="Mostrar ayuda"
)

declare -A BUNKER_GUARDIAN_SUBCOMMANDS=(
    ["start"]="Iniciar Guardian"
    ["stop"]="Detener Guardian"
    ["status"]="Mostrar estado"
    ["help"]="Mostrar ayuda"
)

# -----------------------------------------------------------------------------
# Modos de operacion disponibles
# -----------------------------------------------------------------------------
declare -A BUNKER_MODES=(
    ["gaming"]="Optimizado para juegos: maximo rendimiento de GPU/CPU"
    ["ia"]="Optimizado para IA local y desarrollo de codigo"
    ["ghost"]="Modo fantasma: privacidad maxima, sin telemetria"
    ["office"]="Optimizado para oficina: ahorro de energia, productividad"
    ["hacking"]="Modo hacking: herramientas de seguridad, red avanzada"
    ["custom"]="Personalizado: configuracion manual"
)

# -----------------------------------------------------------------------------
# Capas disponibles
# -----------------------------------------------------------------------------
declare -A BUNKER_LAYERS=(
    ["stealth"]="Sin telemetria, auditoria reducida, logs minimos"
    ["performance"]="Governor de CPU performance, optimizaciones de GPU"
    ["lowram"]="Optimizaciones para sistemas con poca memoria"
    ["battery"]="Ahorro de energia, governor powersave"
    ["focus"]="Prioridad a procesos interactivos"
    ["ai"]="Asignacion de recursos para inferencia de IA"
)

# -----------------------------------------------------------------------------
# Servicios disponibles
# -----------------------------------------------------------------------------
declare -A BUNKER_SERVICES=(
    ["maintenance"]="Tareas de mantenimiento periodico"
    ["update"]="Gestion de actualizaciones con rollback"
    ["health"]="Monitoreo de salud del sistema"
    ["recovery"]="Recuperacion automatica ante fallos"
    ["harden"]="Hardening del kernel y politicas"
    ["ai"]="Gestion de recursos para IA"
)

# -----------------------------------------------------------------------------
# Funciones para consultar el registro
# -----------------------------------------------------------------------------

# Verificar si un comando existe
bunker_command_exists() {
    local cmd="$1"
    if [[ -n "${BUNKER_COMMANDS[$cmd]}" ]]; then
        return 0
    fi
    return 1
}

# Obtener descripcion de un comando
bunker_get_command_description() {
    local cmd="$1"
    echo "${BUNKER_COMMANDS[$cmd]:-Comando desconocido}"
}

# Listar todos los comandos
bunker_list_commands() {
    for cmd in "${!BUNKER_COMMANDS[@]}"; do
        echo "  $cmd: ${BUNKER_COMMANDS[$cmd]}"
    done
}

# Listar todos los modos
bunker_list_modes() {
    for mode in "${!BUNKER_MODES[@]}"; do
        echo "  $mode: ${BUNKER_MODES[$mode]}"
    done
}

# Listar todas las capas
bunker_list_layers() {
    for layer in "${!BUNKER_LAYERS[@]}"; do
        echo "  $layer: ${BUNKER_LAYERS[$layer]}"
    done
}

# Listar todos los servicios
bunker_list_services() {
    for svc in "${!BUNKER_SERVICES[@]}"; do
        echo "  $svc: ${BUNKER_SERVICES[$svc]}"
    done
}

# Validar modo
bunker_validate_mode() {
    local mode="$1"
    if [[ -n "${BUNKER_MODES[$mode]}" ]]; then
        return 0
    fi
    return 1
}

# Validar capa
bunker_validate_layer() {
    local layer="$1"
    if [[ -n "${BUNKER_LAYERS[$layer]}" ]]; then
        return 0
    fi
    return 1
}

# Validar servicio
bunker_validate_service() {
    local svc="$1"
    if [[ -n "${BUNKER_SERVICES[$svc]}" ]]; then
        return 0
    fi
    return 1
}

# -----------------------------------------------------------------------------
# Inicializacion
# -----------------------------------------------------------------------------
command_registry_init() {
    # Exportar variables para que esten disponibles en otros modulos
    export BUNKER_VERSION
    export BUNKER_NAME
}

# Inicializar al cargar
command_registry_init
