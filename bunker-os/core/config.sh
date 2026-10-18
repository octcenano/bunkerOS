#!/bin/bash
# =============================================================================
# Bunker OS - Módulo de Configuración (Config)
# Ubicación: /usr/lib/bunker/core/config.sh
# Propósito: gestión centralizada de configuración, validación, migración
# Desarrollador jefe: <tu_usuario> | Ingeniero colaborador: Apodex 1.1 Mini
# =============================================================================

set -o pipefail

BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

# -----------------------------------------------------------------------------
# Archivos de configuración
# -----------------------------------------------------------------------------
CONFIG_MAIN="$BUNKER_ETC/bunker.conf"
CONFIG_MODES="$BUNKER_ETC/modes/"
CONFIG_LAYERS="$BUNKER_ETC/layers/"

# -----------------------------------------------------------------------------
# Inicialización de configuración
# -----------------------------------------------------------------------------
config_init() {
    if [[ ! -f "$CONFIG_MAIN" ]]; then
        bunker_info "Creando configuración por defecto..."
        mkdir -p "$(dirname "$CONFIG_MAIN")"
        cp "$BUNKER_ROOT/etc/bunker.conf" "$CONFIG_MAIN"
        bunker_info "Configuración inicial creada en $CONFIG_MAIN"
    fi
}

# -----------------------------------------------------------------------------
# Operaciones CRUD sobre la configuración
# -----------------------------------------------------------------------------
config_get() {
    local section="$1"
    local key="$2"
    bunker_config_get "$section" "$key"
}

config_set() {
    local section="$1"
    local key="$2"
    local value="$3"
    bunker_config_set "$section" "$key" "$value"
}

config_list_sections() {
    local file="${1:-$CONFIG_MAIN}"
    grep -oP '^\s*\[\K[^\]]+' "$file" | sort -u
}

config_list_keys() {
    local section="$1"
    local file="${2:-$CONFIG_MAIN}"
    local in_section=false
    while IFS= read -r line; do
        local k="${line%%#*}"
        k="${k%%=*}"
        k="${k#"${k%%[![:space:]]*}"}"
        if [[ "$k" == "[$section]" ]]; then
            in_section=true
            continue
        fi
        if [[ "$k" == "["* ]]; then
            in_section=false
            continue
        fi
        if [[ "$in_section" == true && -n "$k" ]]; then
            echo "$k"
        fi
    done < "$file"
}

# -----------------------------------------------------------------------------
# Validación de configuración
# -----------------------------------------------------------------------------
config_validate() {
    bunker_info "Validando configuración..."
    local errors=0

    if [[ ! -f "$CONFIG_MAIN" ]]; then
        bunker_error "Configuración no encontrada: $CONFIG_MAIN"
        return 1
    fi

    # Validar secciones conocidas
    local known_sections=("system" "engine" "hardware" "layers" "services" "security" "evolution" "resources" "logging")
    local sections
    sections=$(config_list_sections)

    for section in "${known_sections[@]}"; do
        if ! echo "$sections" | grep -q "^$section$"; then
            bunker_warn "Sección desconocida en configuración: $section"
            ((errors++))
        fi
    done

    # Validar valores críticos
    local default_mode
    default_mode=$(config_get "engine" "default_mode")
    local valid_modes=("gaming" "ia" "ghost" "office" "hacking" "custom")
    local mode_valid=false
    for m in "${valid_modes[@]}"; do
        if [[ "$m" == "$default_mode" ]]; then
            mode_valid=true
            break
        fi
    done
    if [[ "$mode_valid" == false ]]; then
        bunker_error "Modo por defecto inválido: $default_mode"
        ((errors++))
    fi

    if [[ $errors -gt 0 ]]; then
        bunker_error "Se encontraron $errors errores en la configuración"
        return 1
    fi

    bunker_info "Configuración válida"
    return 0
}

# -----------------------------------------------------------------------------
# Migración de configuración
# -----------------------------------------------------------------------------
config_migrate() {
    local from_version="$1"
    local to_version="$2"

    bunker_info "Migrando configuración de $from_version a $to_version..."

    # Ejemplos de migraciones
    if [[ "$from_version" == "0.0.1" && "$to_version" == "0.1.0" ]]; then
        # Migrar formato antiguo a nuevo
        if grep -q "mode=" "$CONFIG_MAIN" 2>/dev/null; then
            local old_mode
            old_mode=$(grep "^mode=" "$CONFIG_MAIN" | cut -d'=' -f2)
            config_set "engine" "default_mode" "$old_mode"
            bunker_info "Migrado: mode -> engine.default_mode"
        fi
    fi

    bunker_info "Migración completada"
}

# -----------------------------------------------------------------------------
# Backup y restauración de configuración
# -----------------------------------------------------------------------------
config_backup() {
    local backup_dir="$BUNKER_VAR/backups"
    mkdir -p "$backup_dir"
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    cp "$CONFIG_MAIN" "$backup_dir/bunker.conf.$timestamp"
    bunker_info "Backup de configuración creado: $backup_dir/bunker.conf.$timestamp"
}

config_restore() {
    local backup_file="$1"
    if [[ ! -f "$backup_file" ]]; then
        bunker_error "Backup no encontrado: $backup_file"
        return 1
    fi
    cp "$backup_file" "$CONFIG_MAIN"
    bunker_info "Configuración restaurada desde: $backup_file"
}

# -----------------------------------------------------------------------------
# Exportar configuración (JSON)
# -----------------------------------------------------------------------------
config_export_json() {
    python3 - <<'PY'
import json
import re

config = {}
current_section = None
with open('/etc/bunker/bunker.conf') as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if line.startswith('[') and line.endswith(']'):
            current_section = line[1:-1]
            config[current_section] = {}
            continue
        if '=' in line and current_section:
            key, value = line.split('=', 1)
            config[current_section][key.strip()] = value.strip()

print(json.dumps(config, indent=2))
PY
}

# -----------------------------------------------------------------------------
# Punto de entrada
# -----------------------------------------------------------------------------
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        init)          config_init "$@" ;;
        get)           config_get "$@" ;;
        set)           config_set "$@" ;;
        sections)      config_list_sections "$@" ;;
        keys)          config_list_keys "$@" ;;
        validate)      config_validate "$@" ;;
        migrate)       config_migrate "$@" ;;
        backup)        config_backup "$@" ;;
        restore)       config_restore "$@" ;;
        export-json)   config_export_json "$@" ;;
        help|--help|-h)
            echo "Uso: bunker config <comando>"
            echo "Comandos: init | get | set | sections | keys | validate | migrate | backup | restore | export-json | help"
            ;;
        *)
            bunker_error "Comando desconocido: $command"
            bunker_exit 1
            ;;
    esac
}

main "$@"
