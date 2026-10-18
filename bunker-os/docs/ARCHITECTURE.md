# Arquitectura de Bunker OS

> "Ves poco a poco, primero por lo más importante" — Cada componente cuenta como una pieza más del sistema.

## Visión General

Bunker OS es una distribución Linux segura y auto-gestionada basada en Arch Linux, con kernel Linux y systemd. Sigue una arquitectura modular donde cada componente es independiente pero se comunica a través de una API compartida, eventos y estado conocido.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CAPA DE USUARIO                                 │
│                         CLI: bunker <comando>                                │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          API DE COMUNICACIÓN (IPC)                          │
│              Sockets Unix • Eventos • Auditoría • Consultas al núcleo        │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
          ┌───────────────┬───────────┼───────────┬───────────────┐
          ▼               ▼           ▼           ▼               ▼
┌───────────────┐ ┌─────────────┐ ┌──────────┐ ┌─────────────┐ ┌─────────────┐
│   CORE        │ │   ENGINE    │ │ HARDWARE │ │  GUARDIAN   │ │  SENTINEL   │
│   (núcleo)    │ │   (motor)   │ │   (HAL)  │ │ (watchdogs  │ │ (auditoría │
│               │ │             │ │          │ │  + daemons) │ │  modular)   │
│ core.sh       │ │ engine.sh   │ │ hal.sh   │ │ guardian.sh │ │ sentinel.sh │
│ config.sh     │ │ mode-select │ │          │ │ watchdogs/  │ │ modules/    │
│ api.sh        │ │ engine-flags│ │          │ │ daemons/    │ │ detect_*.sh │
└───────────────┘ └─────────────┘ └──────────┘ └─────────────┘ └─────────────┘
          │               │           │           │           │
          └───────────────┴───────────┴───────────┴───────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     SERVICIOS (como flags)                                    │
│  maintenance • update • health • recovery • harden • ai                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     CAPAS DEL SISTEMA                                         │
│  --stealth • --performance • --lowram • --battery • --focus • --ai           │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     MODO DE OPERACIÓN                                         │
│  gaming • ia • ghost • office • hacking • custom                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     ROLLBACK (puntos de restauración)                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│              EXTENSIÓN DEL KERNEL (C + assembly) • DRIVERS (BPM)            │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     KERNEL LINUX + SYSTEMD (base Arch Linux)                │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Componentes y Responsabilidades

### 1. CLI (`cli/bunker`)
Punto de entrada único del sistema. Todos los comandos pasan por aquí.

**Comandos:**
- `engine` — Iniciar motor con modos, capas y flags
- `core` — Gestionar núcleo (start/stop/restart/status)
- `config` — Gestión de configuración (get/set/validate/migrate)
- `api` — Comunicación IPC (send/receive/publish/subscribe/query)
- `hardware` — Detección e información de hardware
- `rollback` — Puntos de restauración
- `service` — Gestión de servicios (list/enable/disable)
- `layer` — Gestión de capas (list/enable/disable)
- `sentinel` — Auditoría de seguridad (start/stop/status/audit)
- `guardian` — Monitorización (start/stop/status)
- `update` — Actualización del sistema (all/bunker/aur)
- `status` — Estado general del sistema

### 2. Core (`core/core.sh`)
Núcleo del sistema. Gestiona el ciclo de vida completo.

**Responsabilidades:**
- Inicio y detención del sistema
- Detección de hardware al arranque
- Selección de modo de operación
- Aplicación de capas del sistema
- Inicio y detención de servicios
- Gestión de estado conocido

### 3. Config (`core/config.sh`)
Gestión centralizada de configuración en formato INI.

**Responsabilidades:**
- Operaciones CRUD sobre configuración
- Validación de secciones y valores
- Migración entre versiones
- Backup y restauración
- Exportación a JSON

### 4. API (`core/api.sh`)
Comunicación entre componentes mediante sockets Unix y eventos.

**Responsabilidades:**
- Envío y recepción de mensajes
- Publicación y suscripción a eventos
- Consultas al núcleo (status, mode, layers, state)
- Gestión de procesos
- Consultas de recursos (memoria, CPU)
- Registro de auditoría

### 5. Engine (`engine/engine.sh` + `engine/mode-selector.sh` + `engine/engine-flags.sh`)
Motor de ejecución que interpreta modos, capas y flags.

**Responsabilidades:**
- Selección de modo basada en hardware
- Aplicación de capas del sistema
- Sistema de flags (adapt, verbose, quiet, dry_run, force, etc.)
- Adaptación al hardware en tiempo real
- Bucle principal de ejecución con health check

### 6. Hardware HAL (`hardware/hal.sh`)
Capa de abstracción de hardware.

**Responsabilidades:**
- Detección de CPU, GPU, RAM, almacenamiento, red, audio, periféricos
- Optimización según tipo de almacenamiento (SSD/HDD)
- Ajuste de governor de CPU
- Información detallada de hardware

### 7. Guardian (`guardian/guardian.sh`)
Monitorización continua, watchdogs y daemons exclusivos del OS.

**Watchdogs:**
- `watchdog_core.sh` — Vigila que el núcleo esté vivo
- `watchdog_memory.sh` — Vigila uso de memoria
- `watchdog_security.sh` — Vigila eventos de seguridad
- `watchdog_network.sh` — Vigila actividad de red anómala

**Daemons:**
- `daemon_evolution.sh` — Mejora continua (Bunker Evolution)
- `daemon_hardware_adapt.sh` — Adaptación dinámica de hardware
- `daemon_sentinel_sync.sh` — Sincronización con Sentinel
- `daemon_rollback_monitor.sh` — Monitor de rollback automático

### 8. Sentinel (`sentinel/sentinel.sh`)
Auditoría modular: detecta → correlaciona → hipotetiza → remedia.

**Módulos de detección:**
- `detect_integrity.sh` — Integridad de archivos del sistema
- `detect_processes.sh` — Procesos maliciosos o anómalos
- `detect_network.sh` — Actividad de red inusual
- `detect_permissions.sh` — Cambios de permisos en archivos críticos

**Flujo del Sentinel:**
1. **Detect**: Ejecutar todos los módulos de detección
2. **Correlate**: Conectar incidentes relacionados en tiempo
3. **Hypothesis**: Generar hipótesis para incidentes no resueltos
4. **Test**: Probar cada hipótesis
5. **Remediate**: Aplicar remediación si la hipótesis se confirma

### 9. Servicios (`services/*.sh`)
Servicios del sistema activados como flags.

| Servicio | Descripción |
|----------|-------------|
| maintenance | Tareas de mantenimiento periódico |
| update | Gestión de actualizaciones con rollback |
| health | Monitoreo de salud del sistema |
| recovery | Recuperación automática ante fallos |
| harden | Hardening del kernel y políticas |
| ai | Gestión de recursos para IA local |

### 10. Rollback (`rollback/rollback.sh`)
Sistema de puntos de restauración y recuperación.

**Responsabilidades:**
- Crear snapshots antes de cambios críticos
- Listar y restaurar snapshots
- Rollback automático si un modo falla
- Verificación de integridad de snapshots

### 11. Extensión del Kernel (`kernel-extensions/`)
Módulo del kernel Linux en C + assembly.

**Archivos:**
- `bunker-core.c` — Módulo del kernel con monitoreo de recursos, sysfs attributes, notificador de CPU
- `bunker-mm.S` — Gestión de memoria en assembly (alloc, free, flush cache, prefetch)
- `Makefile` — Compilación del módulo

### 12. Drivers (`drivers/`)
Drivers del sistema.

**Archivos:**
- `drivers/bpm/bpm.c` — Driver de gestión de energía con modos gaming/ai/office/battery/stealth
- `drivers/Makefile` — Compilación de drivers

### 13. Shared (`shared/lib.sh`)
Librería común utilizada por todos los componentes.

**Responsabilidades:**
- Logging con niveles (debug, info, warn, error)
- Gestión de configuración (get/set)
- Gestión de estado (get/set/known_state)
- Gestión de PID y verificación de procesos
- Carga de módulos del núcleo
- Presupuestos de recursos

## Flujo de Inicio (Boot)

1. **systemd** inicia `bunker-core.service`
2. **Core** detecta hardware automáticamente (HAL)
3. **Core** selecciona modo de operación (config o wizard)
4. **Core** aplica capas del sistema
5. **Core** inicia servicios habilitados
6. **Core** establece estado conocido
7. **Guardian** inicia watchdogs y daemons
8. **Sentinel** inicia auditoría continua

## Flujo de Cambio de Modo

1. Usuario selecciona modo (gaming, ia, ghost, office, hacking, custom)
2. Se crea snapshot de seguridad (rollback)
3. Se aplican capas asociadas al modo
4. Se aplican optimizaciones específicas del modo
5. Se guardan configuraciones y estado
6. Si el modo falla, se revierte automáticamente al snapshot

## Comunicación entre Componentes

Todos los componentes se comunican a través de:

1. **API compartida** (`core/api.sh`) — Sockets Unix y eventos
2. **Estado conocido** (`shared/lib.sh`) — Archivos de estado en `/var/lib/bunker/state/`
3. **Configuración centralizada** (`core/config.sh`) — `/etc/bunker/bunker.conf`
4. **Eventos** — Archivos JSON en `/run/bunker/events/`

## Presupuestos de Recursos

Cada componente tiene presupuestos definidos en `[resources]` de `bunker.conf`:

| Recurso | Valor por defecto | Descripción |
|---------|------------------|-------------|
| core_memory_budget | 512 MB | Memoria máxima para el núcleo |
| core_cpu_budget | 10 % | CPU máxima para el núcleo |
| max_processes | 1024 | Máximo de procesos del sistema |
| max_open_files | 65536 | Límite de archivos abiertos |

## Seguridad

### Diseño seguro desde el inicio

- **systemd units** con `NoNewPrivileges=true`, `ProtectSystem=strict`, `ProtectHome=read-only`
- **PrivateTmp=true** para aislamiento de archivos temporales
- **ReadWritePaths** limitado a `/var/lib/bunker` y `/run/bunker`
- **Kernel hardening** mediante sysctl (rp_filter, kptr_restrict, dmesg_restrict, etc.)
- **Bunker Sentinel** auditoría continua con detección, correlación, hipótesis y remediación
- **Rollback automático** si un modo o cambio falla
- **Niveles de seguridad**: minimal, standard, high, maximum

### Permisos

- Todos los scripts requieren root para operaciones críticas (`bunker_require_root`)
- Verificación de PID para evitar procesos duplicados
- Auditoría de acciones mediante `api_audit_log`

## Bunker Evolution (Mejora Continua)

Daemon que se ejecuta cada 24 horas para:

1. Recopilar métricas anónimas del sistema
2. Ajustar automáticamente la configuración según el uso
3. Aplicar optimizaciones basadas en el hardware detectado
4. Mejorar presupuestos de recursos dinámicamente

## Pruebas

### Pruebas de Integración (`test/integration-test.sh`)
Verifican la comunicación entre componentes:
- Core ↔ Config
- Engine ↔ Hardware
- Core ↔ Rollback
- Sentinel ↔ Guardian
- API evento sistema
- Ciclo de vida de servicios
- Aplicación de capas
- Cambio de modos
- Estado conocido y recuperación
- Presupuestos de recursos
- Permisos y seguridad

### Pruebas de Regresión (`test/regression-test.sh`)
Verifican que cambios no rompan funcionalidad existente:
- Comandos de CLI
- Funciones de core, config, api, engine
- Funciones de mode-selector, hal, rollback
- Funciones de sentinel, guardian
- Funciones de servicios
- Funciones de shared
- Units de systemd
- Archivos de kernel y drivers
- Watchdogs y daemons
- Módulos de sentinel

## Criterios de Finalización por Componente

Cada componente se considera completo cuando:

1. ✅ Tiene lógica funcional y coherente
2. ✅ Se comunica con otros componentes (API, eventos, shared)
3. ✅ Tiene presupuestos de recursos definidos
4. ✅ Tiene pruebas de integración
5. ✅ Tiene pruebas de regresión
6. ✅ Tiene recuperación ante fallos (rollback)
7. ✅ Tiene permisos adecuados (root, systemd restrictions)
8. ✅ Tiene documentación

## Instalación

```bash
# Inicializar directorios
make init

# Instalar todos los componentes
make install

# Compilar extensiones del kernel y drivers
make build

# Ejecutar pruebas
make test

# Empaquetar para Arch Linux
make package
```

## Uso Rápido

```bash
# Iniciar el motor en modo gaming con capa performance
bunker engine --mode gaming --layer performance

# Adaptar el sistema al hardware detectado
bunker engine --adapt

# Ver estado del sistema
bunker status

# Iniciar Bunker Sentinel
bunker sentinel start

# Actualizar el sistema (pacman + AUR)
bunker update all

# Crear punto de restauración
bunker rollback create antes_de_cambios

# Listar modos disponibles
bunker engine-flags list-modes

# Listar capas disponibles
bunker engine-flags list-layers
```

## Estructura de Archivos

```
bunker-os/
├── base/                 # PKGBUILD, systemd units, pacman hooks
│   ├── etc/bunker.conf
│   ├── pacman/bunker-post-install.hook
│   └── systemd/*.service
├── cli/bunker            # CLI principal
├── core/                 # Núcleo: core.sh, config.sh, api.sh
├── engine/               # Motor: engine.sh, mode-selector.sh, engine-flags.sh
├── hardware/             # HAL: hal.sh
├── shared/               # Librería común: lib.sh
├── guardian/             # Monitorización
│   ├── guardian.sh
│   ├── watchdogs/        # watchdog_*.sh
│   └── daemons/          # daemon_*.sh
├── services/             # Servicios: *.sh
├── sentinel/             # Auditoría: sentinel.sh, modules/detect_*.sh
├── rollback/             # rollback.sh
├── test/                 # Pruebas: test-runner.sh, integration-test.sh, regression-test.sh
├── docs/                 # Documentación: DOCUMENTATION.md, ARCHITECTURE.md
├── kernel-extensions/    # Extensión del kernel: bunker-core.c, bunker-mm.S, Makefile
├── drivers/              # Drivers: bpm/bpm.c, Makefile
├── README.md
├── ARCHITECTURE.md
├── LICENSE
└── Makefile
```

## Licencia

MIT — ver [LICENSE](../LICENSE).