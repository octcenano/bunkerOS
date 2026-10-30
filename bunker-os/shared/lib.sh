#!/bin/bash
# =============================================================================
# Bunker OS - Librería compartida (Shared Library)
# Ubicación: /usr/lib/bunker/shared/lib.sh
# Propósito: utilidades comunes, logging, manejo de errores, configuración
# Desarrollador jefe: <tu_usuario> | Ingeniero colaborador: Apodex 1.1 Mini
# =============================================================================

set -o pipefail

# -----------------------------------------------------------------------------
# Constantes globales
# -----------------------------------------------------------------------------
export BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
export BUNKER_ETC="${BUNKER_ETC:-/etc/bunker}"
export BUNKER_VAR="${BUNKER_VAR:-/var/lib/bunker}"
export BUNKER_RUN="${BUNKER_RUN:-/run/bunker}"
export BUNKER_LOG="${BUNKER_LOG:-/var/log/bunker}"

export BUNKER_VERSION="2.6.0"
export BUNKER_NAME="Bunker OS"

# -----------------------------------------------------------------------------
# Niveles de log
# -----------------------------------------------------------------------------
readonly LOG_DEBUG=0
readonly LOG_INFO=1
readonly LOG_WARN=2
readonly LOG_ERROR=3

# Nivel de log actual (se sobrescribe con bunker_set_log_level)
BUNKER_LOG_LEVEL="${BUNKER_LOG_LEVEL:-$LOG_INFO}"

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
bunker_log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Escribir en stdout/stderr según el nivel
    case "$level" in
        $LOG_DEBUG) return 0 ;;  # Debug no se muestra por defecto
        $LOG_INFO)  echo "[$timestamp] [INFO]  $message" ;;
        $LOG_WARN)  echo "[$timestamp] [WARN]  $message" >&2 ;;
        $LOG_ERROR) echo "[$timestamp] [ERROR] $message" >&2 ;;
        *)          echo "[$timestamp] [UNKNOWN] $message" >&2 ;;
    esac
}

bunker_debug() { bunker_log "$LOG_DEBUG" "$@"; }
bunker_info()    { bunker_log "$LOG_INFO" "$@"; }
bunker_warn()    { bunker_log "$LOG_WARN" "$@"; }
bunker_error()   { bunker_log "$LOG_ERROR" "$@"; }

bunker_set_log_level() {
    local level="$1"
    case "$level" in
        debug) BUNKER_LOG_LEVEL=$LOG_DEBUG ;;
        info)  BUNKER_LOG_LEVEL=$LOG_INFO ;;
        warn)  BUNKER_LOG_LEVEL=$LOG_WARN ;;
        error) BUNKER_LOG_LEVEL=$LOG_ERROR ;;
        *)     bunker_warn "Nivel de log desconocido: $level" ;;
    esac
}

# -----------------------------------------------------------------------------
# Manejo de errores
# -----------------------------------------------------------------------------
bunker_exit() {
    local code="$1"
    shift
    if [[ $# -gt 0 ]]; then
        bunker_error "$@"
    fi
    exit "$code"
}

bunker_require_root() {
    if [[ $EUID -ne 0 ]]; then
        bunker_error "Este comando debe ejecutarse como root"
        bunker_exit 1
    fi
}

bunker_require_command() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        bunker_error "Se requiere el comando: $cmd"
        bunker_exit 127
    fi
}

# -----------------------------------------------------------------------------
# Configuración
# -----------------------------------------------------------------------------
bunker_config_get() {
    local section="$1"
    local key="$2"
    local file="${3:-$BUNKER_ETC/bunker.conf}"

    if [[ ! -f "$file" ]]; then
        bunker_error "Archivo de configuración no encontrado: $file"
        return 1
    fi

    local in_section=false
    local value=""
    while IFS='=' read -r k v; do
        # Limpiar comentarios y espacios
        k="${k%%#*}"
        v="${v%%#*}"
        k="${k#"${k%%[![:space:]]*}"}"
        v="${v#"${v%%[![:space:]]*}"}"
        v="${v%"${v##*[![:space:]]}"}"

        if [[ -z "$k" ]]; then continue; fi

        if [[ "$k" == "[$section]" ]]; then
            in_section=true
            continue
        fi
        if [[ "$k" == "["* ]]; then
            in_section=false
            continue
        fi

        if [[ "$in_section" == true && "$k" == "$key" ]]; then
            value="$v"
            break
        fi
    done < "$file"

    echo "$value"
}

bunker_config_set() {
    local section="$1"
    local key="$2"
    local value="$3"
    local file="${4:-$BUNKER_ETC/bunker.conf}"

    if [[ ! -f "$file" ]]; then
        bunker_error "Archivo de configuración no encontrado: $file"
        return 1
    fi

    local tmp_file
    tmp_file=$(mktemp)
    local in_section=false
    local found=false
    local written=false

    while IFS= read -r line || [[ -n "$line" ]]; do
        local k="${line%%#*}"
        k="${k%%=*}"
        k="${k#"${k%%[![:space:]]*}"}"

        if [[ "$k" == "[$section]" ]]; then
            in_section=true
            echo "$line" >> "$tmp_file"
            continue
        fi
        if [[ "$k" == "["* ]]; then
            in_section=false
        fi

        if [[ "$in_section" == true && "$k" == "$key" ]]; then
            echo "$key = $value" >> "$tmp_file"
            found=true
            written=true
            continue
        fi
        echo "$line" >> "$tmp_file"
    done < "$file"

    if [[ "$found" == false ]]; then
        echo "" >> "$tmp_file"
        echo "[$section]" >> "$tmp_file"
        echo "$key = $value" >> "$tmp_file"
    fi

    mv "$tmp_file" "$file"
    bunker_info "Configuración actualizada: $section.$key = $value"
}

# -----------------------------------------------------------------------------
# Estado del sistema y recuperación
# -----------------------------------------------------------------------------
bunker_state_dir() { echo "$BUNKER_VAR/state"; }
bunker_state_get() {
    local key="$1"
    local state_file="$BUNKER_VAR/state/$key"
    if [[ -f "$state_file" ]]; then
        cat "$state_file"
    fi
}

bunker_state_set() {
    local key="$1"
    local value="$2"
    mkdir -p "$(bunker_state_dir)"
    echo "$value" > "$BUNKER_VAR/state/$key"
}

bunker_state_clear() {
    local key="$1"
    rm -f "$BUNKER_VAR/state/$key"
}

bunker_known_state() {
    # Devuelve el "estado conocido" del sistema (punto de referencia estable)
    bunker_state_get "known_state"
}

bunker_set_known_state() {
    bunker_state_set "known_state" "$(date +%s)"
}

# -----------------------------------------------------------------------------
# Presupuesto de recursos
# -----------------------------------------------------------------------------
bunker_resource_budget() {
    # Devuelve el presupuesto de recursos del núcleo
    bunker_config_get "resources" "core_memory_budget"
}

# -----------------------------------------------------------------------------
# Utilidades
# -----------------------------------------------------------------------------
bunker_is_root() { [[ $EUID -eq 0 ]]; }

bunker_pid_file() {
    local name="$1"
    echo "$BUNKER_RUN/$name.pid"
}

bunker_is_running() {
    local name="$1"
    local pid_file
    pid_file=$(bunker_pid_file "$name")
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

bunker_write_pid() {
    local name="$1"
    local pid="$2"
    mkdir -p "$(dirname "$(bunker_pid_file "$name")")"
    echo "$pid" > "$(bunker_pid_file "$name")"
}

bunker_remove_pid() {
    local name="$1"
    rm -f "$(bunker_pid_file "$name")"
}

# -----------------------------------------------------------------------------
# Importar otros módulos del núcleo
# -----------------------------------------------------------------------------
bunker_load_module() {
    local module="$1"
    local module_path="$BUNKER_ROOT/$module"
    if [[ -f "$module_path" ]]; then
        # shellcheck disable=SC1090
        source "$module_path"
        bunker_debug "Módulo cargado: $module"
    else
        bunker_error "Módulo no encontrado: $module_path"
        return 1
    fi
}

# =============================================================================
# Fin de shared/lib.sh
# =============================================================================
