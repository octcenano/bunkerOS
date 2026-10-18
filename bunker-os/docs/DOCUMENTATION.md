# Documentación de Bunker OS

## Tabla de contenidos

1. [Arquitectura](#arquitectura)
2. [Componentes](#componentes)
3. [CLI](#cli)
4. [Modos de operación](#modos-de-operación)
5. [Capas](#capas)
6. [Servicios](#servicios)
7. [Seguridad](#seguridad)
8. [Rollback](#rollback)
9. [Desarrollo](#desarrollo)

---

## Arquitectura

Bunker OS es una distribución Linux basada en Arch con systemd, diseñada con una arquitectura modular de componentes que se comunican entre sí.

```
┌─────────────────────────────────────────────────────────────────┐
│                         USUARIOS / CLI                          │
├─────────────────────────────────────────────────────────────────┤
│  cli/bunker  ──┐                                               │
│                 ├─→ API (sockets Unix, eventos)                 │
│  core/api.sh   ─┘                                               │
├─────────────────────────────────────────────────────────────────┤
│  core/ (núcleo)  │  engine/ (motor)  │  core-graph/ (grafo)     │
│                  │                   │                          │
│  hardware/ (HAL) ──→ engine/mode-selector (selección de modos)  │
├─────────────────────────────────────────────────────────────────┤
│  services/ (maintenance, update, health, recovery, harden, ai)   │
│  guardian/ (watchdogs + daemons)                                 │
│  sentinel/ (detección → correlación → hipótesis → remediación)   │
│  detect/  │  response/  │  rollback/                             │
├─────────────────────────────────────────────────────────────────┤
│  shared/ (librería común: logging, config, estado, recursos)     │
├─────────────────────────────────────────────────────────────────┤
│  base/ (PKGBUILD, systemd units, pacman hooks)                   │
│  kernel-extensions/ (C + assembly)                               │
│  drivers/                                                        │
├─────────────────────────────────────────────────────────────────┤
│              KERNEL LINUX + SYSTEMD (base Arch)                   │
└─────────────────────────────────────────────────────────────────┘
```

### Flujo de inicio

1. **Boot** → systemd inicia `bunker-core.service`
2. **Core** → detecta hardware, selecciona modo, aplica capas
3. **Engine** → interpreta el grafo del núcleo
4. **Guardian** → inicia watchdogs y daemons
5. **Sentinel** → inicia auditoría continua

---

## Componentes

| Componente | Ruta | Descripción |
|------------|------|-------------|
| CLI | `cli/bunker` | Interfaz de línea de comandos principal |
| Core | `core/core.sh` | Núcleo: procesos, memoria, planificación, ciclo de vida |
| Config | `core/config.sh` | Gestión centralizada de configuración |
| API | `core/api.sh` | Comunicación IPC entre componentes |
| Engine | `engine/engine.sh` | Motor de ejecución del grafo del núcleo |
| Mode Selector | `engine/mode-selector.sh` | Selección y aplicación de modos |
| HAL | `hardware/hal.sh` | Detección, información y optimización de hardware |
| Shared | `shared/lib.sh` | Librería común: logging, config, estado, recursos |
| Guardian | `guardian/guardian.sh` | Monitorización, watchdogs, auto-reparación |
| Sentinel | `sentinel/sentinel.sh` | Auditoría modular: detecta, correlaciona, hipotetiza, remedia |
| Services | `services/*.sh` | Servicios del sistema |
| Rollback | `rollback/rollback.sh` | Puntos de restauración y recuperación |
| Base | `base/` | PKGBUILD, systemd units, pacman hooks |
| Test | `test/test-runner.sh` | Pruebas de integración y regresión |

---

## CLI

La CLI `bunker` es el punto de entrada principal del sistema.

### Comandos

```bash
bunker engine [opciones]    # Iniciar el motor con selección de modo
bunker core <cmd>           # Gestionar el núcleo (start|stop|restart|status)
bunker config <cmd>         # Gestionar configuración
bunker api <cmd>            # Interactuar con la API
bunker hardware <cmd>       # Información y detección de hardware
bunker rollback <cmd>       # Gestionar puntos de restauración
bunker service <cmd>        # Gestionar servicios
bunker layer <cmd>          # Gestionar capas
bunker sentinel <cmd>       # Iniciar/detener Bunker Sentinel
bunker guardian <cmd>       # Iniciar/detener Bunker Guardian
bunker update [tipo]        # Actualizar (all|bunker|aur)
bunker status               # Estado del sistema
bunker help                 # Ayuda
```

### Opciones globales

```bash
--mode <m>        Modo: gaming | ia | ghost | office | hacking | custom
--layer <l>       Capa: stealth | performance | lowram | battery | focus | ai
--service <s>     Servicio: maintenance | update | health | recovery | harden | ai
--adapt           Adaptar al hardware detectado
--modes           Listar modos
--verbose         Información detallada
--quiet           Solo errores
```

### Ejemplos

```bash
# Iniciar en modo gaming con optimización de rendimiento
bunker engine --mode gaming --layer performance

# Adaptar el sistema al hardware
bunker engine --adapt

# Activar capa stealth y modo fantasma
bunker engine --mode ghost --layer stealth

# Actualizar el sistema
bunker update all

# Actualizar AUR
bunker update aur
```

---

## Modos de operación

| Modo | Descripción | Capas | Servicios |
|------|-------------|-------|-----------|
| gaming | Máximo rendimiento para juegos | performance | — |
| ia | IA local y desarrollo de código | performance, ai | ai |
| ghost | Privacidad máxima (modo fantasma) | stealth, lowram | — |
| office | Oficina: ahorro de energía | battery, focus | maintenance |
| hacking | Herramientas de seguridad y red | performance | — |
| custom | Personalizado | — | update, health, recovery, harden |

El motor detecta automáticamente el hardware y sugiere un modo:
- GPU NVIDIA/AMD + RAM ≥ 32GB → **ia**
- GPU NVIDIA/AMD + RAM < 32GB → **gaming**
- Sin GPU dedicada → **custom**

---

## Capas

Las capas son configuraciones que se superponen a un modo:

| Capa | Efecto |
|------|--------|
| stealth | Sin telemetría, auditoría reducida, logs mínimos |
| performance | Governor de CPU performance, optimizaciones de GPU |
| lowram | Optimizaciones para sistemas con poca memoria |
| battery | Ahorro de energía, governor powersave |
| focus | Prioridad a procesos interactivos |
| ai | Asignación de recursos para inferencia de IA |

---

## Servicios

Los servicios se activan como flags y se gestionan con `bunker service`:

| Servicio | Descripción |
|----------|-------------|
| maintenance | Tareas de mantenimiento periódico |
| update | Gestión de actualizaciones con rollback |
| health | Monitoreo de salud del sistema |
| recovery | Recuperación automática ante fallos |
| harden | Hardening del kernel y políticas |
| ai | Gestión de recursos para IA |

```bash
bunker service list       # Ver estado de servicios
bunker service enable ai  # Habilitar servicio
bunker service disable ai # Deshabilitar servicio
```

---

## Seguridad

Bunker OS está diseñado con seguridad desde el inicio:

- **Bunker Sentinel**: auditoría modular que detecta fallos, los correlaciona, formula hipótesis, las prueba y remedia automáticamente
- **Hardening del kernel**: sysctl hardening aplicado automáticamente
- **Aislamiento de procesos**: namespaces y restricciones de privilegios
- **Rollback automático**: si un modo falla, el sistema se revierte
- **Puntos de restauración**: antes de cambios críticos
- **Niveles de seguridad**: minimal | standard | high | maximum

### Bunker Sentinel

Arquitectura del Sentinel:

```
detectores → correlacionador → hipotetizador → probador → remediar
```

Módulos de detección:
- `detect_integrity.sh` — integridad de archivos
- `detect_processes.sh` — procesos maliciosos
- `detect_network.sh` — actividad de red anómala
- `detect_permissions.sh` — cambios de permisos

---

## Rollback

El sistema de rollback protege contra fallos:

```bash
bunker rollback create <nombre>   # Crear punto de restauración
bunker rollback list              # Listar puntos
bunker rollback restore <nombre>  # Restaurar punto
bunker rollback verify            # Verificar integridad
```

- Se crea un snapshot antes de aplicar modos
- Si un modo falla, se revierte automáticamente
- Se crea un snapshot antes de cada remediación del Sentinel

---

## Desarrollo

### Estructura de archivos

```
bunker-os/
├── base/           # PKGBUILD, systemd, pacman hooks
├── cli/            # CLI bunker
├── core/           # core, config, api
├── engine/         # engine, mode-selector
├── hardware/       # HAL
├── shared/         # lib.sh
├── guardian/       # guardian, watchdogs, daemons
├── services/       # maintenance, update, health, recovery, harden, ai
├── sentinel/       # sentinel, modules/
├── rollback/       # rollback.sh
├── test/           # test-runner.sh
├── docs/           # documentación
├── kernel-extensions/  # extensión del kernel (C + assembly)
├── drivers/        # drivers Bunker
├── README.md
├── ARCHITECTURE.md
├── LICENSE
└── Makefile
```

### Compilación de extensiones del kernel

```bash
cd kernel-extensions
make
```

### Ejecutar pruebas

```bash
./test/test-runner.sh
```

### Empaquetar para Arch

```bash
cd base
makepkg -si
```

---

## Bunker Evolution

Bunker Evolution es la mejora continua del sistema:
- Recopila métricas anónimas
- Ajusta automáticamente la configuración según el uso
- Aplica optimizaciones basadas en el hardware
- Intervalo: 24 horas

---

## Criterios de finalización

Cada componente se considera completo cuando:
1. ✅ Tiene lógica funcional y coherente
2. ✅ Se comunica con otros componentes (API, eventos, shared)
3. ✅ Tiene presupuestos de recursos definidos
4. ✅ Tiene pruebas de integración
5. ✅ Tiene recuperación ante fallos
6. ✅ Tiene permisos adecuados (root, no-new-privileges)
7. ✅ Tiene documentación

---

## Licencia

MIT — ver [LICENSE](../LICENSE).
