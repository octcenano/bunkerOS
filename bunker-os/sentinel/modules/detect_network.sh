#!/bin/bash
# Bunker OS - M3dulo: Red
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

# -----------------------------------------------------------------------------
# Funciones de utilidad para anlisis exacto de puertos
# -----------------------------------------------------------------------------

# Extraer numero de puerto de una direccion (IPv4 o IPv6)
# Ejemplo: "0.0.0.0:8080" -> 8080, "[::1]:443" -> 443, "*:*" -> ""
extract_port() {
    local address="$1"
    
    # Para IPv6: [::1]:8080
    if [[ "$address" =~ ^\[*\[] ]]; then
        # Extraer el puerto despues del ultimo :
        local port_part
        port_part="${address##*:}"
        # Si hay ], quitarlo
        port_part="${port_part%]}"
        # Verificar que es solo numeros
        if [[ "$port_part" =~ ^[0-9]+$ ]]; then
            echo "$port_part"
        else
            echo ""
        fi
    else
        # Para IPv4: 0.0.0.0:8080 o *:8080
        local port_part
        port_part="${address##*:}"
        if [[ "$port_part" =~ ^[0-9]+$ ]]; then
            echo "$port_part"
        else
            echo ""
        fi
    fi
}

# Verificar si un puerto esta en un rango
# Uso: is_port_in_range <port> <start> <end>
is_port_in_range() {
    local port="$1"
    local start="$2"
    local end="$3"
    
    if [[ "$port" =~ ^[0-9]+$ ]] && [[ "$start" =~ ^[0-9]+$ ]] && [[ "$end" =~ ^[0-9]+$ ]]; then
        if [[ "$port" -ge "$start" && "$port" -le "$end" ]]; then
            return 0
        fi
    fi
    return 1
}

# Verificar si un puerto es sospechoso
# Los puertos bien conocidos (0-1023) y registrados (1024-49151) tienen usos estandares
# Los puertos dinamicos/privados (49152-65535) son mas sospechosos
is_suspicious_port() {
    local port="$1"
    
    # Validar que es un numero
    if [[ ! "$port" =~ ^[0-9]+$ ]]; then
        return 1
    fi
    
    # Puerto 0 es invalido
    if [[ "$port" -eq 0 ]]; then
        return 1
    fi
    
    # Puertos bien conocidos (0-1023) - pueden ser legtimos
    if [[ "$port" -le 1023 ]]; then
        return 1
    fi
    
    # Puertos registrados (1024-49151) - verificar contra lista de comunes
    if [[ "$port" -le 49151 ]]; then
        # Lista de puertos comunes que son seguros
        local common_ports="80 443 8080 8443 3000 5000 5432 6379 27017 9200 9300 8000 3306 22"
        for common in $common_ports; do
            if [[ "$port" -eq "$common" ]]; then
                return 1
            fi
        done
        # Si no es un puerto comun, puede ser sospechoso
        return 0
    fi
    
    # Puertos dinamicos/privados (49152-65535)
    # Estos son asignados dinamicamente y pueden indicar malware
    if [[ "$port" -ge 49152 && "$port" -le 65535 ]]; then
        return 0
    fi
    
    return 1
}

detect_network() {
    bunker_debug "Ejecutando deteccin de red..."
    
    if ! command -v ss &>/dev/null; then
        bunker_warn "ss no disponible, deteccin de red omitida"
        return 0
    fi
    
    # Obtener conexiones en estado LISTEN
    local connections
    connections=$(ss -tlnp 2>/dev/null)
    
    if [[ -z "$connections" ]]; then
        bunker_debug "No se encontraron conexiones en estado LISTEN"
        return 0
    fi
    
    # Procesar cada linea
    while IFS= read -r line; do
        # Saltar la linea de encabezado
        if [[ "$line" == State* || "$line" == Netid* ]]; then
            continue
        fi
        
        # Extraer la columna de direccion local (columna 4 en ss -tlnp)
        local address
        address=$(echo "$line" | awk '{print $4}')
        
        # Extraer el puerto
        local port
        port=$(extract_port "$address")
        
        # Validar que el puerto es un numero valido
        if [[ -z "$port" ]]; then
            continue
        fi
        
        # Verificar si el puerto es sospechoso
        if is_suspicious_port "$port"; then
            # Obtener el proceso asociado
            local pid_and_program
            pid_and_program=$(echo "$line" | grep -oP 'pid=\K[0-9]+' | head -1)
            local program=""
            if [[ -n "$pid_and_program" ]]; then
                program=$(ps -p "$pid_and_program" -o comm= 2>/dev/null || echo "desconocido")
            fi
            
            bunker_warn "Puerto sospechoso escuchando: $port (proceso: $program, direccion: $address)"
            log_incident "network" "$port" "puerto_sospechoso" "proceso=$program,direccion=$address"
        fi
        
    done <<< "$connections"
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
}

run_detection() {
    detect_network
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_detection
fi
