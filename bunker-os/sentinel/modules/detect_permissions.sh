#!/bin/bash
# Bunker OS - M3dulo: Permisos
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

# -----------------------------------------------------------------------------
# Configuracin de seguridad
# -----------------------------------------------------------------------------
BASELINE_DIR="$BUNKER_VAR/baseline"
BASELINE_FILE="$BASELINE_DIR/permissions.db"
BASELINE_MODE="600"  # Solo root puede leer/escribir

detect_permissions() {
    bunker_debug "Ejecutando deteccin de permisos..."
    
    # Asegurar que el directorio baseline existe con permisos seguros
    mkdir -p "$BASELINE_DIR"
    chmod 700 "$BASELINE_DIR"
    
    # Asegurar que el archivo baseline tiene permisos seguros
    if [[ -f "$BASELINE_FILE" ]]; then
        chmod "$BASELINE_MODE" "$BASELINE_FILE"
        chown root:root "$BASELINE_FILE" 2>/dev/null || true
    fi
    
    local files=(
        "/etc/passwd"
        "/etc/shadow"
        "/etc/sudoers"
        "/usr/bin/sudo"
        "/etc/bunker/bunker.conf"
    )
    
    for file in "${files[@]}"; do
        if [[ -e "$file" ]]; then
            local perms
            perms=$(stat -c "%a" "$file" 2>/dev/null)
            local owner
            owner=$(stat -c "%U:%G" "$file" 2>/dev/null)
            
            if [[ -f "$BASELINE_FILE" ]]; then
                local stored
                stored=$(grep "^$file:" "$BASELINE_FILE" 2>/dev/null | awk -F: '{print $2}')
                if [[ "$stored" != "$perms" ]]; then
                    bunker_warn "Permisos cambiados: $file (ahora $perms, antes $stored, dueno: $owner)"
                    log_incident "permissions" "$file" "permisos_cambiados" "perms_antes=$stored,perms_ahora=$perms,dueno=$owner"
                fi
            else
                # Crear baseline con permisos seguros
                echo "$file:$perms" >> "$BASELINE_FILE"
                chmod "$BASELINE_MODE" "$BASELINE_FILE"
                chown root:root "$BASELINE_FILE" 2>/dev/null || true
            fi
        fi
    done
}

# Funcion para registrar incidentes (compatible con Sentinel)
log_incident() {
    local module="$1"
    local target="$2"
    local incident_type="$3"
    local details="${4:-}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local incident_file="$BUNKER_VAR/incidents/${module}_${target}_${timestamp}.incident"
    mkdir -p "$BUNKER_VAR/incidents"
    
    echo "type=$incident_type" > "$incident_file"
    echo "module=$module" >> "$incident_file"
    echo "target=$target" >> "$incident_file"
    echo "timestamp=$timestamp" >> "$incident_file"
    if [[ -n "$details" ]]; then
        echo "details=$details" >> "$incident_file"
    fi
    
    # Asegurar permisos seguros para el incidente
    chmod 600 "$incident_file" 2>/dev/null || true
}

run_detection() {
    detect_permissions
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_detection
fi
