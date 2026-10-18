# Bunker OS

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Bunker OS** — Una distribución Linux segura y auto-gestionada basada en Arch Linux, con kernel Linux y systemd.

> "Ves poco a poco, primero por lo más importante" — Cada componente cuenta como una pieza más del sistema.

## 🎯 Características principales

| Característica | Descripción |
|----------------|-------------|
| 🐧 **Base Arch Linux** | Kernel Linux + systemd + pacman + AUR |
| 🔍 **Detección de hardware instantánea** | Optimización automática al arranque |
| 🎮 **Modos de operación** | Gaming, IA, Fantasma, Oficina, Hacking, Custom |
| 🛡️ **Bunker Sentinel** | Auditoría modular: detecta → correlaciona → hipótesis → remedia |
| 🛡️ **Guardian** | Watchdogs y daemons exclusivos del OS |
| 🔄 **Rollback automático** | Si un modo falla, el sistema se revierte |
| ⚙️ **Capas** | `--stealth`, `--performance`, `--lowram`, `--battery`, `--focus`, `--ai` |
| 🔧 **Servicios como flags** | `maintenance`, `update`, `health`, `recovery`, `harden`, `ai` |
| 🧬 **Extensión del kernel** | Código C + assembly para gestión de recursos |
| 🚀 **Bunker Evolution** | Mejora continua del sistema |

## 📁 Estructura del proyecto

```
bunker-os/
├── base/                 # PKGBUILD, systemd units, pacman hooks
├── cli/                  # CLI bunker (punto de entrada)
├── core/                 # Core: core.sh, config.sh, api.sh
├── engine/               # Motor: engine.sh, mode-selector.sh
├── hardware/             # HAL: detección y optimización de hardware
├── shared/               # Librería común: lib.sh
├── guardian/             # Guardian: watchdogs + daemons
│   ├── watchdogs/        # watchdog_core.sh, watchdog_memory.sh
│   └── daemons/          # daemon_evolution.sh, daemon_hardware_adapt.sh
├── services/             # Servicios: maintenance, update, health, recovery, harden, ai
├── sentinel/             # Bunker Sentinel
│   └── modules/          # detect_integrity, detect_processes, detect_network, detect_permissions
├── rollback/             # Sistema de puntos de restauración
├── test/                 # Suite de pruebas de integración y regresión
├── docs/                 # Documentación
├── kernel-extensions/    # Extensión del kernel (C + assembly)
│   ├── bunker-core.c     # Módulo del kernel en C
│   ├── bunker-mm.S       # Gestión de memoria en assembly
│   └── Makefile
├── drivers/              # Drivers del sistema
│   ├── bpm/              # Driver de gestión de energía
│   └── Makefile
├── README.md
├── ARCHITECTURE.md
├── LICENSE
└── Makefile
```

## 🚀 Inicio rápido

```bash
# Instalar
make install

# Iniciar el motor en modo gaming
bunker engine --mode gaming --layer performance

# Adaptar el sistema al hardware
bunker engine --adapt

# Ver estado
bunker status

# Iniciar Bunker Sentinel
bunker sentinel start

# Actualizar el sistema
bunker update all

# Ejecutar pruebas
./test/test-runner.sh
```

## 🎮 Modos de operación

| Modo | Capas | Servicios | Uso |
|------|-------|-----------|-----|
| `gaming` | performance | — | Solo para jugar |
| `ia` | performance, ai | ai | IA local y código |
| `ghost` | stealth, lowram | — | Modo fantasma (privacidad) |
| `office` | battery, focus | maintenance | Oficina |
| `hacking` | performance | — | Hacking / seguridad |
| `custom` | — | update, health, recovery, harden | Personalizado |

## 📚 Documentación

- [DOCUMENTACIÓN COMPLETA](docs/DOCUMENTATION.md) — Guía completa del sistema
- [ARCHITECTURA](ARCHITECTURE.md) — Diseño de la arquitectura

## 👥 Equipo

- **Desarrollador jefe**: `<tu_usuario>`
- **Ingeniero colaborador**: Apodex 1.1 Mini

## 📄 Licencia

MIT — ver [LICENSE](LICENSE).
