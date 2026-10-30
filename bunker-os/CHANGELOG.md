# Bunker OS - CHANGELOG

## [v2.6.1-stabilization] - 2024-10-30

### ✅ Correcciones Criticas (P0)

#### Seguridad
- **ISO Installer**: Eliminadas contraseñas hardcodeadas (`root:bunker`, `bunker:bunker`)
- **ISO Installer**: SSH y Tor deshabilitados por defecto
- **ISO Installer**: Implementado script de primer arranque para configuracion de credenciales
- **ISO Installer**: Locale es_ES.UTF-8 por defecto (cambiable durante instalacion)
- **Permisos**: Todos los scripts con permisos seguros (755/644)
- **Permisos**: Directorios sensibles con permisos 700

#### Arquitectura
- **Directorio typo**: Eliminado `bunker-os/hadware/` (duplicado de `hardware/`)
- **Workflows**: Eliminados workflows duplicados en `bunker-os/.github/workflows/`
- **Workflows**: Unificados en `.github/workflows/` (raiz)

#### Búnker Study
- **Root**: Eliminada la necesidad de root para operaciones normales
- **Resumenes**: Implementada extraccion real de texto (sin simulacion de IA)
- **Integracion Adapt**: Adapt es ahora la fuente unica de verdad para modelos de IA
- **CSV**: Escaping correcto de campos en indices CSV
- **Dependencias**: Corregida verificacion de `poppler` (antes `poppler-utils`)

#### Workflows
- **build-iso.yml**: Corregidos parametros de `mkarchiso`
- **build-iso.yml**: Eliminadas credenciales hardcodeadas
- **build-iso.yml**: Anadido primer arranque seguro
- **test-all.yml**: Eliminado `|| true` que ocultaba errores
- **test-all.yml**: Tests ahora fallan correctamente

#### Bug Fixes
- **analyze-exam.sh:145**: Corregido error de sintaxis en regex (unescaped `]`)
- **Todos los scripts**: Validados con `bash -n` (40 scripts, 0 errores)

---

## [v2.6.0] - 2024-10-29

### ✅ Nuevas Funcionalidades

#### Búnker Study (Nuevo Modulo)
- Estructura completa del modulo Study
- Herramientas: analyze-exam, summarize, library management
- CLI: `bunker study start/stop/status`
- UI: Interfaz CLI para Study
- Tests: 12 pruebas unitarias para Study

#### Búnker Adapt (Mejoras)
- Seleccion de modelos basada en memoria disponible
- Validacion de backend y cuantizacion
- Configuracion de modelos de IA

#### Core
- Registro central de comandos (`shared/command-registry.sh`)
- Deteccion de puertos exacta (no subcadenas)
- Permisos seguros por defecto (600/700)
- Verificacion de Tor para modo hacking

#### Workflows
- build-iso.yml: Compilacion de ISO
- test-all.yml: Tests completos
- lint-code.yml: Linting de codigo
- deploy-docs.yml: Despliegue de documentacion

### 📝 Cambios

#### Version Unificada
- Todos los archivos actualizados a version 2.6.0
- Documentacion actualizada
- CHANGELOG creado

---

## [v2.5.1] - 2024-10-28

### ⚠️ Version Inicial (Pre-Auditoria)

- Version base antes de correcciones
- Problemas conocidos:
  - Credenciales hardcodeadas en ISO
  - Errores de sintaxis en scripts
  - Duplicacion de directorios
  - Workflows con errores
  - Study con simulaciones

---

## Formato de Version

- `vX.Y.Z`: Version estable
- `vX.Y.Z-stabilization`: Version de estabilizacion
- `vX.Y.Z-rcN`: Release Candidate
- `vX.Y.Z-alpha`: Alpha
- `vX.Y.Z-beta`: Beta

---

## Convenciones

- ✅ = Implementado y probado
- ⚠️ = Implementado sin validar
- ⏳ = Pendiente
- 🐛 = Bug fix
- 📝 = Documentacion
- 🔧 = Refactor

---

*Generado automaticamente por Vibe Code - Ingeniero Principal de Bunker OS*
