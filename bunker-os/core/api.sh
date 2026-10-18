#!/bin/bash
# =============================================================================
# Bunker OS - API de Comunicación (Core API)
# Ubicación: /usr/lib/bunker/core/api.sh
# Propósito: comunicación IPC entre componentes, eventos, consultas
# Desarrollador jefe: <tu_usuario> | Ingeniero colaborador: Apodex 1.1 Mini
# =============================================================================

set -o pipefail

BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

# -----------------------------------------------------------------------------
# Directorios de comunicación
# -----------------------------------------------------------------------------
API_SOCKET_DIR="$BUNKER_RUN/api"
API_EVENT_DIR="$BUNKER_RUN/events"
API_DATA_DIR="$BUNKER_VAR/api"

# -----------------------------------------------------------------------------
# Inicialización de la API
# -----------------------------------------------------------------------------
api_init() {
    mkdir -p "$API_SOCKET_DIR" "$API_EVENT_DIR" "$API_DATA_DIR"
    bunker_debug "API inicializada en $API_SOCKET_DIR"
}

# -----------------------------------------------------------------------------
# Comunicación por sockets Unix (IPC)
# -----------------------------------------------------------------------------
api_send() {
    local target="$1"
    local message="$2"
    local socket="$API_SOCKET_DIR/$target.sock"

    # Enviar mensaje a un socket Unix
    if command -v socat &>/dev/null; then
        echo "$message" | socat - "$socket" 2>/dev/null
    else
        # Fallback: escribir en archivo
        echo "$message" > "$API_DATA_DIR/$target.msg"
    fi
}

api_receive() {
    local target="$1"
    local socket="$API_SOCKET_DIR/$target.sock"

    if command -v socat &>/dev/null; then
        echo "GET" | socat - "$socket" 2>/dev/null
    else
        cat "$API_DATA_DIR/$target.msg" 2>/dev/null
    fi
}

# -----------------------------------------------------------------------------
# Sistema de eventos
# -----------------------------------------------------------------------------
api_publish_event() {
    local event="$1"
    local payload="$2"
    local timestamp
    timestamp=$(date +%s)

    local event_file="$API_EVENT_DIR/${event}.$timestamp.json"
    cat > "$event_file" <<EOF
{
    "event": "$event",
    "timestamp": $timestamp,
    "payload": $payload
}
EOF
    bunker_debug "Evento publicado: $event"
}

api_subscribe_event() {
    local event="$1"
    bunker_info "Suscribiéndose al evento: $event"
    # Implementación de watcher de eventos
}

api_list_events() {
    local event="${1:-*}"
    ls "$API_EVENT_DIR/${event}.*.json" 2>/dev/null | sed 's/.*\///' | sed 's/\.json//'
}

# -----------------------------------------------------------------------------
# Consultas al núcleo
# -----------------------------------------------------------------------------
api_query_core() {
    local query="$1"

    case "$query" in
        status)
            echo "{\"state\": \"$CORE_STATE\", \"pid\": $CORE_PID}"
            ;;
        mode)
            echo "{\"engine_mode\": \"$ENGINE_MODE\"}"
            ;;
        layers)
            echo "{\"layers\": [$(printf '"%s",' "${LAYERS[@]}" | sed 's/,$//')]}"
            ;;
        state)
            local key="${2:-}"
            if [[ -n "$key" ]]; then
                bunker_state_get "$key"
            else
                ls "$BUNKER_VAR/state" 2>/dev/null
            fi
            ;;
        *)
            bunker_error "Consulta desconocida: $query"
            return 1
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Gestión de procesos del núcleo
# -----------------------------------------------------------------------------
api_start_process() {
    local name="$1"
    local command="$2"
    bunker_info "Iniciando proceso: $name"
    # Implementación de launcher de procesos
}

api_stop_process() {
    local name="$1"
    bunker_info "Deteniendo proceso: $name"
}

api_list_processes() {
    ps aux | grep -E "bunker" | grep -v grep
}

# -----------------------------------------------------------------------------
# Gestión de recursos
# -----------------------------------------------------------------------------
api_get_resources() {
    local metric="${1:-all}"
    case "$metric" in
        memory)
            free -m | awk '/^Mem:/{print "memory_total="$2" memory_free="$4}'
            ;;
        cpu)
            echo "cpu_usage=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2}')"
            ;;
        all)
            api_get_resources memory
            api_get_resources cpu
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Registro de auditoría (audit log)
# -----------------------------------------------------------------------------
api_audit_log() {
    local action="$1"
    local actor="$2"
    local target="$3"
    local result="$4"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    local audit_file="$BUNKER_VAR/audit.log"
    echo "[$timestamp] action=$action actor=$actor target=$target result=$result" >> "$audit_file"
    bunker_debug "Audit log: $action por $actor en $target"
}

# -----------------------------------------------------------------------------
# Punto de entrada
# -----------------------------------------------------------------------------
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        init)            api_init "$@" ;;
        send)            api_send "$@" ;;
        receive)         api_receive "$@" ;;
        publish)         api_publish_event "$@" ;;
        subscribe)       api_subscribe_event "$@" ;;
        events)          api_list_events "$@" ;;
        query)           api_query_core "$@" ;;
        start-process)   api_start_process "$@" ;;
        stop-process)    api_stop_process "$@" ;;
        processes)       api_list_processes "$@" ;;
        resources)       api_get_resources "$@" ;;
        audit)           api_audit_log "$@" ;;
        help|--help|-h)
            echo "Uso: bunker api <comando>"
            echo "Comandos: init | send | receive | publish | subscribe | events | query | start-process | stop-process | processes | resources | audit | help"
            ;;
        *)
            bunker_error "Comando desconocido: $command"
            bunker_exit 1
            ;;
    esac
}

main "$@"
