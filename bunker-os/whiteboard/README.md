# Bunker OS - Whiteboard (Pizarra Inteligente)

## Descripcion

El modulo **Whiteboard** de Bunker OS proporciona un sistema de pizarra visual para conectar componentes logicamente. Permite representar las relaciones entre los diferentes modulos, servicios y herramientas del sistema usando un grafo direccionado con conexiones de diferentes niveles de seguridad.

## Caracteristicas

- **Nodos**: Representan componentes del sistema (modulos, servicios, herramientas)
- **Conexiones**: Representan relaciones logicas entre componentes
- **Niveles de seguridad**: 5 tipos de conexiones con colores asociados
- **Exportacion**: Formatos JSON y DOT (Graphviz) para visualizacion

## Niveles de Seguridad de Conexiones

| Tipo | Color | Descripcion | Ejemplo |
|------|-------|-------------|---------|
| `secure` | Negro (#000000) | Conexion logica segura | Core -> Sentinel |
| `almost_secure` | Gris (#808080) | Conexion logica casi segura | Engine -> Sentinel |
| `medium` | Azul (#0000FF) | Conexion logica media | Adapt -> Study |
| `weak` | Verde (#00FF00) | Conexion logica poco segura | Hardware -> Adapt |
| `none` | Rojo (#FF0000) | Sin conexion | Study -> Rollback |

## Uso

### Inicializacion

```bash
# Inicializar pizarra vacia
bunker whiteboard init

# Inicializar con componentes de Bunker OS (recomendado)
bunker whiteboard init-bunker
```

### Agregar Nodos

```bash
# Sintaxis
bunker whiteboard add-node ID LABEL DESCRIPCION TIPO COLOR

# Ejemplo
bunker whiteboard add-node "new_module" "Nuevo Modulo" "Modulo de prueba" "module" "#FFFFFF"
```

Parametros:
- `ID`: Identificador unico (requerido)
- `LABEL`: Nombre visible (requerido)
- `DESCRIPCION`: Descripcion del nodo (opcional)
- `TIPO`: Tipo de componente (module, service, tool, core, security) (default: module)
- `COLOR`: Color en formato hexadecimal (default: #FFFFFF)

### Agregar Conexiones

```bash
# Sintaxis
bunker whiteboard add-edge ORIGEN DESTINO TIPO [DESCRIPCION] [PESO]

# Ejemplo: Conexion segura
bunker whiteboard add-edge "core" "sentinel" "secure" "Conexion directa"

# Ejemplo: Conexion media
bunker whiteboard add-edge "adapt" "study" "medium" "Modelos para Study"

# Ejemplo: Conexion poco segura
bunker whiteboard add-edge "hardware" "adapt" "weak" "Influencia en modelos"
```

Parametros:
- `ORIGEN`: ID del nodo de origen (requerido)
- `DESTINO`: ID del nodo de destino (requerido)
- `TIPO`: Tipo de conexion (secure, almost_secure, medium, weak, none) (requerido)
- `DESCRIPCION`: Descripcion de la conexion (opcional)
- `PESO`: Peso de la conexion (default: 1)

### Visualizar Pizarra

```bash
bunker whiteboard display
```

Muestra todos los nodos y conexiones en formato texto.

### Exportar Grafos

#### Formato DOT (Graphviz)

```bash
# Exportar a archivo
bunker whiteboard export-dot /ruta/a/whiteboard.dot

# Visualizar con Graphviz
bunker whiteboard export-dot /tmp/whiteboard.dot
dot -Tpng /tmp/whiteboard.dot -o /tmp/whiteboard.png
```

#### Formato JSON

```bash
# Exportar a archivo JSON (compatible con herramientas web)
bunker whiteboard export-json /ruta/a/whiteboard.json
```

### Limpiar Pizarra

```bash
bunker whiteboard clear
```

Elimina todos los nodos y conexiones, reiniciando la pizarra.

## Estructura de Archivos

```
bunker-os/whiteboard/
├── whiteboard.sh      # Script principal
└── README.md          # Este archivo

/var/lib/bunker/whiteboard/  (creado en tiempo de ejecucion)
├── nodes/             # Nodos del grafo
│   └── *.json         # Archivos JSON de nodos
├── edges/             # Conexiones del grafo
│   └── *.json         # Archivos JSON de conexiones
└── graph.json         # Grafo completo en formato JSON
```

## Formato de Archivos

### Nodo (node.json)

```json
{
  "id": "identificador",
  "label": "Nombre visible",
  "description": "Descripcion del nodo",
  "type": "module",
  "color": "#FFFFFF",
  "created_at": "2024-10-30 15:00:00",
  "updated_at": "2024-10-30 15:00:00"
}
```

### Conexion (edge.json)

```json
{
  "id": "origen_a_destino_tipo",
  "source": "origen",
  "target": "destino",
  "type": "secure",
  "color": "#000000",
  "description": "Descripcion de la conexion",
  "weight": 1,
  "created_at": "2024-10-30 15:00:00"
}
```

### Grafo Completo (graph.json)

```json
{
  "directed": true,
  "nodes": [
    {
      "id": "core",
      "label": "Bunker Core",
      "description": "Nucleo del sistema",
      "type": "core",
      "color": "#FFD700",
      "created_at": "2024-10-30 15:00:00",
      "updated_at": "2024-10-30 15:00:00"
    },
    ...
  ],
  "edges": [
    {
      "id": "core_to_sentinel_secure",
      "source": "core",
      "target": "sentinel",
      "type": "secure",
      "color": "#000000",
      "description": "Conexion directa del nucleo al sistema de auditoria",
      "weight": 1,
      "created_at": "2024-10-30 15:00:00"
    },
    ...
  ]
}
```

## Integracion con Bunker OS

El modulo Whiteboard esta diseñado para:

1. **Visualizar la arquitectura**: Mostrar como los componentes de Bunker OS se relacionan
2. **Documentar el sistema**: Crear diagramas automaticos de la arquitectura
3. **Analizar dependencias**: Identificar conexiones entre modulos
4. **Planificar cambios**: Visualizar el impacto de cambios en el sistema

## Ejemplo de Uso Completo

```bash
# Inicializar con Bunker OS
bunker whiteboard init-bunker

# Agregar un nuevo modulo
bunker whiteboard add-node "new_ai" "New AI Module" "Modulo de IA experimental" "module" "#9932CC"

# Conectar el nuevo modulo a Adapt
bunker whiteboard add-edge "adapt" "new_ai" "medium" "Adapt gestiona el nuevo modulo"

# Visualizar
bunker whiteboard display

# Exportar para documentacion
bunker whiteboard export-dot /tmp/bunker_architecture.dot
bunker whiteboard export-json /tmp/bunker_architecture.json
```

## Herramientas de Visualizacion

### Graphviz

Instalar Graphviz:
```bash
# Arch Linux
pacman -S graphviz

# Ubuntu/Debian
sudo apt-get install graphviz

# Fedora
sudo dnf install graphviz
```

Generar imagen PNG:
```bash
bunker whiteboard export-dot /tmp/whiteboard.dot
dot -Tpng /tmp/whiteboard.dot -o /tmp/whiteboard.png
```

### Herramientas Web

El formato JSON puede ser visualizado con herramientas como:
- D3.js
- Vis.js
- Cytoscape.js
- Sigma.js

Ejemplo con Python:
```python
import json
import networkx as nx
import matplotlib.pyplot as plt

# Cargar grafo
with open('whiteboard.json') as f:
    data = json.load(f)

# Crear grafo NetworkX
g = nx.DiGraph()

# Anadir nodos
for node in data['nodes']:
    g.add_node(node['id'], label=node['label'], color=node['color'])

# Anadir conexiones
for edge in data['edges']:
    g.add_edge(edge['source'], edge['target'], color=edge['color'], weight=edge['weight'])

# Dibujar
pos = nx.spring_layout(g)
colors = [g.nodes[n]['color'] for n in g.nodes()]
nx.draw(g, pos, node_color=colors, with_labels=True)
plt.show()
```

## Desarrollo

El modulo Whiteboard esta diseñado para ser extensible. Puedes:

1. **Anadir nuevos tipos de nodos**: Modificando `whiteboard_add_node`
2. **Anadir nuevos tipos de conexiones**: Modificando `whiteboard_add_edge`
3. **Anadir nuevas funcionalidades de exportacion**: Creando nuevas funciones `whiteboard_export_*`
4. **Integracion automatica**: Conectar con el sistema de deteccion de Bunker OS

## Notas de Seguridad

- Los archivos de la pizarra se guardan en `$BUNKER_VAR/whiteboard/`
- Los archivos JSON pueden contener informacion sensible sobre la arquitectura del sistema
- Se recomienda proteger el directorio con permisos adecuados
- No exponer los archivos JSON publicamente

## Licencia

Este modulo forma parte de Bunker OS y esta bajo la misma licencia.

---

**Desarrollador:** Vibe Code - Ingeniero Principal de Bunker OS  
**Version:** 1.0  
**Fecha:** 2024-10-30
