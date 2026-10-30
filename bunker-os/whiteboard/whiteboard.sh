#!/bin/bash
# =============================================================================
# Bunker OS - Whiteboard (Pizarra Inteligente)
# Ubicacion: /usr/lib/bunker/whiteboard/whiteboard.sh
# Proposito: Sistema de pizarra visual para conectar componentes logicamente
# =============================================================================

set -o pipefail

# Whiteboard standalone mode - can work without full Bunker OS installation
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"

# Set BUNKER_VAR for whiteboard
if [[ -z "$BUNKER_VAR" ]]; then
    BUNKER_VAR="$HOME/.bunker/var"
fi
mkdir -p "$BUNKER_VAR"

# Define minimal bunker functions for standalone mode
bunker_info() { echo "[WHITEBOARD-INFO] $*"; }
bunker_debug() { echo "[WHITEBOARD-DEBUG] $*" >&2; }
bunker_warn() { echo "[WHITEBOARD-WARN] $*" >&2; }
bunker_error() { echo "[WHITEBOARD-ERROR] $*" >&2; }

# Try to load full Bunker OS lib if available
if [[ -f "$BUNKER_ROOT/shared/lib.sh" ]]; then
    source "$BUNKER_ROOT/shared/lib.sh"
fi

# -----------------------------------------------------------------------------
# Configuracion
# -----------------------------------------------------------------------------
WHITEBOARD_DIR="$BUNKER_VAR/whiteboard"
WHITEBOARD_NODES="$WHITEBOARD_DIR/nodes"
WHITEBOARD_EDGES="$WHITEBOARD_DIR/edges"
WHITEBOARD_GRAPH="$WHITEBOARD_DIR/graph.json"
WHITEBOARD_LOG="$WHITEBOARD_DIR/whiteboard.log"

# Colores de conexion (por nivel de seguridad)
CONNECTION_SECURE="#000000"      # Negro - Conexion logica segura
CONNECTION_ALMOST_SECURE="#808080" # Gris - Conexion logica casi segura
CONNECTION_MEDIUM="#0000FF"      # Azul - Conexion logica media
CONNECTION_WEAK="#00FF00"        # Verde - Conexion logica poco segura
CONNECTION_NONE="#FF0000"        # Rojo - Sin conexion

# -----------------------------------------------------------------------------
# Inicializacion
# -----------------------------------------------------------------------------
whiteboard_init() {
    bunker_info "Inicializando Whiteboard..."
    
    mkdir -p "$WHITEBOARD_DIR" "$WHITEBOARD_NODES" "$WHITEBOARD_EDGES"
    
    # Archivo de grafo en formato JSON (compatible con herramientas de visualizacion)
    cat > "$WHITEBOARD_GRAPH" <<'EOF'
{
  "directed": true,
  "nodes": [],
  "edges": []
}
EOF
    
    bunker_info "Whiteboard inicializado en: $WHITEBOARD_DIR"
}

# -----------------------------------------------------------------------------
# Crear un nodo (componente)
# Parametros:
#   $1: id del nodo (ej: "sentinel", "study", "adapt")
#   $2: etiqueta (ej: "Bunker Sentinel", "Bunker Study")
#   $3: descripcion
#   $4: tipo (ej: "module", "service", "tool")
#   $5: color (opcional, default: #FFFFFF)
# -----------------------------------------------------------------------------
whiteboard_add_node() {
    local id="$1"
    local label="$2"
    local description="$3"
    local type="${4:-module}"
    local color="${5:-#FFFFFF}"
    
    if [[ -z "$id" || -z "$label" ]]; then
        bunker_error "ID y etiqueta son obligatorios para crear un nodo"
        return 1
    fi
    
    bunker_info "Agregando nodo: $id ($label)"
    
    # Crear archivo del nodo
    local node_file="$WHITEBOARD_NODES/${id}.json"
    cat > "$node_file" <<EOF
{
  "id": "$id",
  "label": "$label",
  "description": "$description",
  "type": "$type",
  "color": "$color",
  "created_at": "$(date '+%Y-%m-%d %H:%M:%S')",
  "updated_at": "$(date '+%Y-%m-%d %H:%M:%S')"
}
EOF
    
    # Actualizar grafo
    whiteboard_update_graph
    
    bunker_info "Nodo creado: $node_file"
}

# -----------------------------------------------------------------------------
# Crear una conexion (edge) entre nodos
# Parametros:
#   $1: id de origen
#   $2: id de destino
#   $3: tipo de conexion (secure|almost_secure|medium|weak|none)
#   $4: descripcion (opcional)
#   $5: peso (opcional, default: 1)
# -----------------------------------------------------------------------------
whiteboard_add_edge() {
    local source="$1"
    local target="$2"
    local connection_type="$3"
    local description="${4:-}"
    local weight="${5:-1}"
    
    if [[ -z "$source" || -z "$target" || -z "$connection_type" ]]; then
        bunker_error "Origen, destino y tipo de conexion son obligatorios"
        return 1
    fi
    
    # Validar tipo de conexion
    case "$connection_type" in
        secure) color="$CONNECTION_SECURE" ;;
        almost_secure) color="$CONNECTION_ALMOST_SECURE" ;;
        medium) color="$CONNECTION_MEDIUM" ;;
        weak) color="$CONNECTION_WEAK" ;;
        none) color="$CONNECTION_NONE" ;;
        *) 
            bunker_error "Tipo de conexion invalido: $connection_type"
            bunker_error "Tipos validos: secure, almost_secure, medium, weak, none"
            return 1
            ;;
    esac
    
    bunker_info "Agregando conexion: $source -> $target ($connection_type)"
    
    # Crear archivo de la conexion
    local edge_id="${source}_to_${target}_${connection_type}"
    local edge_file="$WHITEBOARD_EDGES/${edge_id}.json"
    cat > "$edge_file" <<EOF
{
  "id": "$edge_id",
  "source": "$source",
  "target": "$target",
  "type": "$connection_type",
  "color": "$color",
  "description": "$description",
  "weight": $weight,
  "created_at": "$(date '+%Y-%m-%d %H:%M:%S')"
}
EOF
    
    # Actualizar grafo
    whiteboard_update_graph
    
    bunker_info "Conexion creada: $edge_file"
}

# -----------------------------------------------------------------------------
# Actualizar el grafo JSON con todos los nodos y conexiones
# -----------------------------------------------------------------------------
whiteboard_update_graph() {
    bunker_debug "Actualizando grafo..."
    
    # Construir JSON del grafo
    local nodes_json=""
    local edges_json=""
    
    # Leer nodos
    if [[ -d "$WHITEBOARD_NODES" ]]; then
        nodes_json=$(for f in "$WHITEBOARD_NODES"/*.json; do
            if [[ -f "$f" ]]; then
                cat "$f"
                echo ""
            fi
        done | sed '$ d' | paste -sd ',' -)
    fi
    
    # Leer conexiones
    if [[ -d "$WHITEBOARD_EDGES" ]]; then
        edges_json=$(for f in "$WHITEBOARD_EDGES"/*.json; do
            if [[ -f "$f" ]]; then
                cat "$f"
                echo ""
            fi
        done | sed '$ d' | paste -sd ',' -)
    fi
    
    # Crear grafo completo
    cat > "$WHITEBOARD_GRAPH" <<EOF
{
  "directed": true,
  "nodes": [$nodes_json],
  "edges": [$edges_json]
}
EOF
    
    bunker_debug "Grafo actualizado"
}

# -----------------------------------------------------------------------------
# Visualizar el grafo en formato texto
# -----------------------------------------------------------------------------
whiteboard_display() {
    bunker_info "=== BUNKER OS WHITEBOARD ==="
    echo ""
    
    echo "Nodos:"
    echo "------"
    if [[ -d "$WHITEBOARD_NODES" ]]; then
        for f in "$WHITEBOARD_NODES"/*.json; do
            if [[ -f "$f" ]]; then
                local id=$(grep '"id"' "$f" | head -1 | cut -d'"' -f4)
                local label=$(grep '"label"' "$f" | head -1 | cut -d'"' -f4)
                local type=$(grep '"type"' "$f" | head -1 | cut -d'"' -f4)
                local color=$(grep '"color"' "$f" | head -1 | cut -d'"' -f4)
                echo "  [$type] $id - $label ($color)"
            fi
        done
    else
        echo "  (ninguno)"
    fi
    
    echo ""
    echo "Conexiones:"
    echo "------------"
    if [[ -d "$WHITEBOARD_EDGES" ]]; then
        for f in "$WHITEBOARD_EDGES"/*.json; do
            if [[ -f "$f" ]]; then
                local source=$(grep '"source"' "$f" | head -1 | cut -d'"' -f4)
                local target=$(grep '"target"' "$f" | head -1 | cut -d'"' -f4)
                local type=$(grep '"type"' "$f" | head -1 | cut -d'"' -f4)
                local color=$(grep '"color"' "$f" | head -1 | cut -d'"' -f4)
                local desc=$(grep '"description"' "$f" | head -1 | cut -d'"' -f4)
                
                local type_label=""
                case "$type" in
                    secure) type_label="[NEGRO - Segura]" ;;
                    almost_secure) type_label="[GRIS - Casi segura]" ;;
                    medium) type_label="[AZUL - Media]" ;;
                    weak) type_label="[VERDE - Poco segura]" ;;
                    none) type_label="[ROJO - Sin conexion]" ;;
                esac
                
                echo "  $source -> $target $type_label"
                if [[ -n "$desc" ]]; then
                    echo "    Descripcion: $desc"
                fi
            fi
        done
    else
        echo "  (ninguna)"
    fi
    
    echo ""
    echo "Grafo guardado en: $WHITEBOARD_GRAPH"
}

# -----------------------------------------------------------------------------
# Exportar grafo a formato DOT (Graphviz)
# -----------------------------------------------------------------------------
whiteboard_export_dot() {
    local output="${1:-/tmp/whiteboard.dot}"
    
    bunker_info "Exportando grafo a formato DOT: $output"
    
    echo "digraph BunkerOS {" > "$output"
    echo "  rankdir=LR;" >> "$output"
    echo "  node [shape=box, style=filled];" >> "$output"
    echo "" >> "$output"
    
    # Nodos
    if [[ -d "$WHITEBOARD_NODES" ]]; then
        for f in "$WHITEBOARD_NODES"/*.json; do
            if [[ -f "$f" ]]; then
                local id=$(grep '"id"' "$f" | head -1 | cut -d'"' -f4)
                local label=$(grep '"label"' "$f" | head -1 | cut -d'"' -f4)
                local color=$(grep '"color"' "$f" | head -1 | cut -d'"' -f4)
                echo "  \"$id\" [label=\"$label\", fillcolor=\"$color\"];" >> "$output"
            fi
        done
    fi
    
    echo "" >> "$output"
    
    # Conexiones
    if [[ -d "$WHITEBOARD_EDGES" ]]; then
        for f in "$WHITEBOARD_EDGES"/*.json; do
            if [[ -f "$f" ]]; then
                local source=$(grep '"source"' "$f" | head -1 | cut -d'"' -f4)
                local target=$(grep '"target"' "$f" | head -1 | cut -d'"' -f4)
                local color=$(grep '"color"' "$f" | head -1 | cut -d'"' -f4)
                local weight=$(grep '"weight"' "$f" | head -1 | cut -d'"' -f4)
                echo "  \"$source\" -> \"$target\" [color=\"$color\", penwidth=$weight];" >> "$output"
            fi
        done
    fi
    
    echo "}" >> "$output"
    
    bunker_info "Grafo DOT exportado: $output"
    echo "Para visualizar: dot -Tpng $output -o whiteboard.png"
}

# -----------------------------------------------------------------------------
# Exportar grafo a formato JSON (para herramientas web)
# -----------------------------------------------------------------------------
whiteboard_export_json() {
    local output="${1:-/tmp/whiteboard.json}"
    
    bunker_info "Exportando grafo a JSON: $output"
    cp "$WHITEBOARD_GRAPH" "$output"
    bunker_info "Grafo JSON exportado: $output"
}

# -----------------------------------------------------------------------------
# Limpiar la pizarra
# -----------------------------------------------------------------------------
whiteboard_clear() {
    bunker_warn "Limpiando pizarra..."
    rm -rf "$WHITEBOARD_NODES"/* "$WHITEBOARD_EDGES"/* "$WHITEBOARD_GRAPH"
    whiteboard_init
    bunker_info "Pizarra limpiada"
}

# -----------------------------------------------------------------------------
# Inicializacion automatica de Bunker OS en el whiteboard
# -----------------------------------------------------------------------------
whiteboard_init_bunker() {
    bunker_info "Inicializando whiteboard con componentes de Bunker OS..."
    
    # Nodos principales
    whiteboard_add_node "core" "Bunker Core" "Nucleo del sistema" "core" "#FFD700"
    whiteboard_add_node "engine" "Bunker Engine" "Motor de modos de operacion" "engine" "#FFD700"
    whiteboard_add_node "sentinel" "Bunker Sentinel" "Auditoria y seguridad" "security" "#FF6347"
    whiteboard_add_node "guardian" "Bunker Guardian" "Proteccion y recuperacion" "security" "#FF6347"
    whiteboard_add_node "study" "Bunker Study" "Asistente de estudio" "module" "#4169E1"
    whiteboard_add_node "adapt" "Bunker Adapt" "Adaptacion de IA" "module" "#4169E1"
    whiteboard_add_node "hardware" "Bunker Hardware" "Deteccion de hardware" "module" "#32CD32"
    whiteboard_add_node "rollback" "Bunker Rollback" "Recuperacion de sistema" "module" "#8A2BE2"
    
    # Conexiones seguras (negro)
    whiteboard_add_edge "core" "engine" "secure" "Conexion directa del nucleo al motor"
    whiteboard_add_edge "core" "sentinel" "secure" "Nucleo controla la auditoria"
    whiteboard_add_edge "core" "guardian" "secure" "Nucleo protege el sistema"
    
    # Conexiones casi seguras (gris)
    whiteboard_add_edge "engine" "sentinel" "almost_secure" "Motor activa auditoria segun modo"
    whiteboard_add_edge "engine" "hardware" "almost_secure" "Motor detecta hardware"
    whiteboard_add_edge "sentinel" "guardian" "almost_secure" "Sentinel activa protecciones"
    
    # Conexiones medias (azul)
    whiteboard_add_edge "adapt" "study" "medium" "Adapt proporciona modelos a Study"
    whiteboard_add_edge "core" "adapt" "medium" "Nucleo gestiona Adapt"
    
    # Conexiones poco seguras (verde)
    whiteboard_add_edge "hardware" "adapt" "weak" "Hardware influye en seleccion de modelos"
    
    # Sin conexion (rojo) - Ejemplo
    whiteboard_add_edge "study" "rollback" "none" "Study no interactua directamente con Rollback"
    
    bunker_info "Whiteboard de Bunker OS inicializado"
}

# -----------------------------------------------------------------------------
# CLI
# -----------------------------------------------------------------------------
case "${1:-help}" in
    init)
        whiteboard_init
        ;;
    add-node)
        whiteboard_add_node "$2" "$3" "$4" "$5" "$6"
        ;;
    add-edge)
        whiteboard_add_edge "$2" "$3" "$4" "$5" "$6"
        ;;
    display)
        whiteboard_display
        ;;
    export-dot)
        whiteboard_export_dot "$2"
        ;;
    export-json)
        whiteboard_export_json "$2"
        ;;
    clear)
        whiteboard_clear
        ;;
    init-bunker)
        whiteboard_init
        whiteboard_init_bunker
        whiteboard_display
        ;;
    help|*)
        echo "Uso: whiteboard.sh <comando> O bunker whiteboard <comando>"
        echo ""
        echo "Comandos:"
        echo "  init              Inicializar pizarra"
        echo "  add-node ID LABEL DESC TYPE COLOR  Agregar nodo"
        echo "  add-edge SRC TGT TYPE [DESC] [WEIGHT]  Agregar conexion"
        echo "  display           Mostrar pizarra"
        echo "  export-dot [file] Exportar a formato DOT"
        echo "  export-json [file] Exportar a formato JSON"
        echo "  clear             Limpiar pizarra"
        echo "  init-bunker       Inicializar con componentes de Bunker OS"
        echo ""
        echo "Tipos de conexion:"
        echo "  secure           Conexion logica segura (NEGRO)"
        echo "  almost_secure    Conexion logica casi segura (GRIS)"
        echo "  medium           Conexion logica media (AZUL)"
        echo "  weak             Conexion logica poco segura (VERDE)"
        echo "  none             Sin conexion (ROJO)"
        ;;
esac
