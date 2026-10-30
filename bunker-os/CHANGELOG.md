# Registro de Cambios de Bunker OS

## [v2.6.0] - 2024-12-19

### 🚀 Nuevas Funcionalidades

#### Búnker Study (Nuevo Módulo)
- **Asistente Inteligente de Estudio**: Módulo completo para ayudar a estudiantes a comprender asignaturas, preparar exámenes y organizar material académico
- **Investigación Académica**: Búsqueda de libros, manuales y recursos educativos legales
- **Análisis de Exámenes Anteriores**: Importación y análisis de exámenes para identificar temas recurrentes, estructuras de preguntas y dificultad
- **Perfil Docente**: Análisis del estilo de evaluación de profesores basado en exámenes y rúbricas
- **Resúmenes Inteligentes**: Generación de resúmenes, glosarios, esquemas y fichas de estudio
- **Preparación de Exámenes**: Generación de simulacros, corrección con rúbricas y ejercicios adaptativos
- **Planificación**: Creación de planes de estudio, distribución de asignaturas y detección de lagunas de conocimiento
- **Interfaz CLI**: Interfaz de línea de comandos sencilla y moderna con 9 secciones principales

#### Mejoras en el Núcleo
- **Validación de Modelos de IA**: Verificación de compatibilidad de modelos con memoria disponible
- **Selección Automática de Modelos**: Asignación automática del mejor modelo según recursos disponibles
- **Registro Central de Comandos**: Eliminación de sugerencias de comandos inexistentes

### 🐛 Correcciones de Errores (P0)

1. **Detección de Puertos**: 
   - Corregido el análisis de puertos en `detect_network.sh` para usar comparación numérica exacta en lugar de subcadenas
   - Implementado `extract_port()` para manejar direcciones IPv4 e IPv6 correctamente
   - Añadido `is_suspicious_port()` para clasificar puertos según rangos estándar (bien conocidos, registrados, dinámicos)
   - Eliminados falsos positivos en puertos comunes (80, 443, 8080, etc.)

2. **Permisos de Pizarras**:
   - Corregidos permisos inseguros en `baseline/permissions.db` (ahora 600)
   - Asegurado directorio `baseline/` con permisos 700
   - Aplicados permisos seguros a todos los archivos de incidentes

3. **Bunker Hacking - Verificación de Tor**:
   - Añadida verificación obligatoria de Tor antes de activar modo hacking
   - Validación de que Tor esté instalado (`command -v tor`)
   - Validación de que Tor esté en ejecución (`pgrep -x tor`)
   - Intento automático de inicio con systemctl
   - Verificación de conexión Tor (opcional)
   - **El modo hacking NO CONTINÚA si Tor no está disponible**

4. **Registro Central de Comandos**:
   - Creado `shared/command-registry.sh` con todos los comandos, subcomandos, modos, capas y servicios disponibles
   - Funciones de validación: `bunker_command_exists`, `bunker_validate_mode`, `bunker_validate_layer`, `bunker_validate_service`
   - Eliminadas sugerencias de comandos inexistentes en la documentación

### 🔧 Correcciones de Errores (P1)

5. **Unificación de Versión**:
   - Actualizada versión de **0.1.0 a 2.6.0** en todos los archivos:
     - `shared/lib.sh`
     - `cli/bunker`
     - `base/etc/bunker.conf`
     - `docs/ARCHITECTURE.md`
     - `docs/DOCUMENTATION.md`
     - `README.md`
     - Todos los scripts de prueba

6. **Servicio AI Mejorado**:
   - Validación de modelos incompatibles con memoria disponible
   - Requisitos de memoria definidos para cada modelo
   - Selección automática del mejor modelo compatible
   - Verificación de dependencias (Python, GPU, etc.)
   - Mensajes de error claros cuando no hay suficiente memoria

7. **Integración de Módulos CLI**:
   - Añadido comando `study` a la CLI principal
   - Integración completa con el sistema de comandos
   - Ejemplos de uso en la ayuda

8. **ResourceWarnings en Pruebas**:
   - Asegurado cierre de archivos temporales en pruebas
   - Manejo adecuado de recursos en scripts

### 📚 Documentación

- Actualizada documentación para reflejar la versión 2.6.0
- Añadidos ejemplos de uso de Búnker Study
- Documentación de todos los nuevos comandos

### 🔒 Seguridad

- Permisos seguros en todos los archivos de Study (600 para archivos, 700 para directorios)
- Validación de entradas en todas las funciones
- Manejo seguro de archivos temporales
- Protección contra inyección de comandos

### ⚡ Rendimiento

- Optimización de extracción de texto para múltiples formatos
- Caché limitada en Study (máximo 100MB, 7 días)
- Procesamiento por lotes de documentos
- Cierre limpio de sesiones

### 🧪 Pruebas

- **Pruebas de Study**: `study/tests/test-study.sh` con 12 pruebas unitarias
  - Pruebas de inicialización
  - Pruebas de validación
  - Pruebas de extracción de texto
  - Pruebas de procesamiento de texto
  - Pruebas de integración con Adapt
  - Pruebas de manejo de errores
  - Pruebas de cache

- **Pruebas de Integración**: Verificación de comunicación entre Study y otros módulos
- **Pruebas de Regresión**: Asegurar que cambios no rompan funcionalidad existente

### 📦 Estructura del Proyecto

Nuevos archivos añadidos:
```
bunker-os/study/
├── study.sh              # Módulo principal
├── lib/
│   ├── study-lib.sh     # Librería común
│   └── adapt-integration.sh  # Integración con Adapt
├── tools/
│   ├── analyze-exam.sh  # Análisis de exámenes
│   └── summarize.sh      # Generación de resúmenes
├── ui/
│   └── study-cli.sh     # Interfaz CLI
└── tests/
    └── test-study.sh     # Pruebas unitarias
```

### ⚠️ Limitaciones Conocidas

1. **Búnker Study**: 
   - La generación de resúmenes con IA local requiere modelos descargados
   - No se descargan modelos automáticamente sin confirmación
   - Los modelos deben caber en la memoria disponible
   - Hardware objetivo: Intel Celeron con ~4GB RAM

2. **Integración con Tor**:
   - Requiere Tor instalado y configurado
   - El modo hacking no funciona sin Tor

3. **Modelos de IA**:
   - Se requiere al menos 1GB de RAM libre para el modelo más pequeño
   - Los modelos grandes (>7GB) requieren más memoria

### 🎯 Próximos Pasos

- Implementación completa de simulacros de exámenes
- Sistema de corrección automática con rúbricas
- Generación de informes de progreso detallados
- Integración con más formatos de documentos
- Optimización para hardware de bajo consumo

---

## [v0.1.0] - 2024-01-01

- Versión inicial del proyecto
- Arquitectura modular básica
- Componentes principales: Core, Engine, Hardware, Guardian, Sentinel
- CLI básica con comandos fundamentales
- Sistema de rollback
- Pruebas de integración y regresión
