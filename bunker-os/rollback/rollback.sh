#!/bin/bash
# =============================================================================
# Bunker OS - Sistema de Rollback (Puntos de Restauración)
# Ubicación: /usr/lib/bunker/rollback/rollback.sh
# Propósito: crear, listar y restaurar puntos de restauración del sistema
# Desarrollador jefe: <tu_usuario> | Ingeniero colaborador: Apodex 1.1 Mini
# =============================================================================

set -o pipefail

BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

# -----------------------------------------------------------------------------
# Directorios
# -----------------------------------------------------------------------------
SNAPSHOT_DIR="$BUNKER_VAR/snapshots"
SNAPSHOT_META="$BUNKER_VAR/snapshots/.meta.json"

# -----------------------------------------------------------------------------
# Inicialización
# -----------------------------------------------------------------------------
rollback_init() {
    mkdir -p "$SNAPSHOT_DIR"
    if [[ ! -f "$SNAPSHOT_META" ]]; then
        echo '{"snapshots": []}' > "$SNAPSHOT_META"
    fi
}

# -----------------------------------------------------------------------------
# Crear snapshot
# -----------------------------------------------------------------------------
rollback_snapshot() {
    local name="${1:-snapshot_$(date +%Y%m%d_%H%M%S)}"
    local snapshot_dir="$SNAPSHOT_DIR/$name"

    bunker_info "Creando snapshot: $name"

    mkdir -p "$snapshot_dir"

    # Capturar configuración
    cp "$BUNKER_ETC/bunker.conf" "$snapshot_dir/bunker.conf" 2>/dev/null || true

    # Capturar estado del sistema
    bunker_state_get "engine_mode" > "$snapshot_dir/engine_mode" 2>/dev/null || true
    bunker_state_get "last_shutdown" > "$snapshot_dir/last_shutdown" 2>/dev/null || true

    # Capturar lista de paquetes instalados
    if command -v pacman &>/dev/null; then
        pacman -Qe > "$snapshot_dir/installed-packages.txt" 2>/dev/null || true
    fi

    # Registrar snapshot
    register_snapshot "$name"

    bunker_info "Snapshot creado: $name"
    echo "$name"
}

register_snapshot() {
    local name="$1"
    local timestamp
    timestamp=$(date +%s)

    # Leer meta actual
    local meta=""
    if [[ -f "$SNAPSHOT_META" ]]; then
        meta=$(cat "$SNAPSHOT_META")
    fi

    # Agregar nuevo snapshot (simple JSON array manipulation)
    local new_entry="{\"name\": \"$name\", \"timestamp\": $timestamp}"
    local new_meta
    new_meta=$(echo "$meta" | python3 -c "
import json, sys
data = json.load(sys.stdin)
data['snapshots'].append({'name': '$name', 'timestamp': $timestamp})
print(json.dumps(data))
" 2>/dev/null || echo "{\"snapshots\": [{\"name\": \"$name\", \"timestamp\": $timestamp}]}")

    echo "$new_meta" > "$SNAPSHOT_META"
}

# -----------------------------------------------------------------------------
# Listar snapshots
# -----------------------------------------------------------------------------
rollback_list() {
    bunker_info "=== PUNTOS DE RESTAURACIÓN ==="

    if [[ ! -f "$SNAPSHOT_META" ]]; then
        echo "No hay snapshots registrados"
        return 0
    fi

    python3 - <<'PY'
import json
try:
    with open('/var/lib/bunker/snapshots/.meta.json') as f:
        data = json.load(f)
    snapshots = data.get('snapshots', [])
    if not snapshots:
        print("No hay snapshots registrados")
    else:
        for s in sorted(snapshots, key=lambda x: x['timestamp'], reverse=True):
            from datetime import datetime
            dt = datetime.fromtimestamp(s['timestamp'])
            print(f"  {s['name']:40s} {dt.strftime('%Y-%m-%d %H:%M:%S')}")
except Exception as e:
    print(f"Error leyendo snapshots: {e}")
PY
}

# -----------------------------------------------------------------------------
# Restaurar snapshot
# -----------------------------------------------------------------------------
rollback_restore() {
    local name="$1"
    local snapshot_dir="$SNAPSHOT_DIR/$name"

    if [[ ! -d "$snapshot_dir" ]]; then
        bunker_error "Snapshot no encontrado: $name"
        return 1
    fi

    bunker_info "Restaurando snapshot: $name"

    # Restaurar configuración
    if [[ -f "$snapshot_dir/bunker.conf" ]]; then
        cp "$snapshot_dir/bunker.conf" "$BUNKER_ETC/bunker.conf"
        bunker_info "Configuración restaurada"
    fi

    # Restaurar estado
    if [[ -f "$snapshot_dir/engine_mode" ]]; then
        bunker_state_set "engine_mode" "$(cat "$snapshot_dir/engine_mode")"
    fi

    bunker_info "Snapshot restaurado: $name"
}

# -----------------------------------------------------------------------------
# Rollback automático (si un modo falla)
# -----------------------------------------------------------------------------
rollback_on_failure() {
    local failed_mode="$1"
    local snapshot_key="mode_snapshot_$failed_mode"
    local snapshot_id
    snapshot_id=$(bunker_state_get "$snapshot_key")

    if [[ -n "$snapshot_id" ]]; then
        bunker_warn "El modo '$failed_mode' falló. Restaurando desde snapshot..."
        rollback_restore "$snapshot_id"
        bunker_info "Sistema restaurado al estado anterior"
    else
        bunker_error "No hay snapshot disponible para revertir '$failed_mode'"
    fi
}

# -----------------------------------------------------------------------------
# Verificar integridad de snapshots
# -----------------------------------------------------------------------------
rollback_verify() {
    bunker_info "Verificando integridad de snapshots..."

    local valid=0
    local invalid=0

    if [[ ! -f "$SNAPSHOT_META" ]]; then
        bunker_warn "No hay meta de snapshots"
        return 1
    fi

    python3 - <<'PY'
import json, os
try:
    with open('/var/lib/bunker/snapshots/.meta.json') as f:
        data = json.load(f)
    snapshots = data.get('snapshots', [])
    for s in snapshots:
        path = f"/var/lib/bunker/snapshots/{s['name']}"
        if os.path.isdir(path):
            print(f"  OK: {s['name']}")
        else:
            print(f"  CORRUPTO: {s['name']}")
except Exception as e:
    print(f"Error: {e}")
PY
}

# -----------------------------------------------------------------------------
# Punto de entrada
# -----------------------------------------------------------------------------
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        init)        rollback_init "$@" ;;
        create)      rollback_snapshot "$@" ;;
        list)        rollback_list "$@" ;;
        restore)     rollback_restore "$@" ;;
        verify)      rollback_verify "$@" ;;
        on-failure)  rollback_on_failure "$@" ;;
        help|--help|-h)
            echo "Uso: bunker rollback <comando>"
            echo "Comandos: init | create <nombre> | list | restore <nombre> | verify | on-failure <modo> | help"
            ;;
        *)
            bunker_error "Comando desconocido: $command"
            bunker_exit 1
            ;;
    esac
}

main "$@"
