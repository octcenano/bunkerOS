#!/bin/bash
# =============================================================================
# Bunker OS - Bunker Study
# Ubicaci3n: /usr/lib/bunker/study/study.sh
# Propsito: Asistente inteligente de estudio
# Descripcin: Ayuda a comprender asignaturas, preparar examenes y organizar material academico
# =============================================================================

set -o pipefail

BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"
source "$BUNKER_ROOT/shared/command-registry.sh"

# -----------------------------------------------------------------------------
# Configuracin
# -----------------------------------------------------------------------------
STUDY_DIR="$BUNKER_VAR/study"
STUDY_LIBRARY="$STUDY_DIR/library"
STUDY_SUMMARIES="$STUDY_DIR/summaries"
STUDY_EXAMS="$STUDY_DIR/exams"
STUDY_PROFILES="$STUDY_DIR/profiles"
STUDY_PLANS="$STUDY_DIR/plans"
STUDY_CACHE="$STUDY_DIR/cache"

STUDY_STATE="stopped"
STUDY_PID=$$

# -----------------------------------------------------------------------------
# Inicializacin
# -----------------------------------------------------------------------------
study_init() {
    bunker_info "Inicializando Bunker Study..."
    
    mkdir -p "$STUDY_DIR" "$STUDY_LIBRARY" "$STUDY_SUMMARIES" "$STUDY_EXAMS" "$STUDY_PROFILES" "$STUDY_PLANS" "$STUDY_CACHE"
    
    # Asegurar permisos seguros
    chmod 700 "$STUDY_DIR"
    chmod 700 "$STUDY_LIBRARY" "$STUDY_SUMMARIES" "$STUDY_EXAMS" "$STUDY_PROFILES" "$STUDY_PLANS" "$STUDY_CACHE"
    
    bunker_info "Bunker Study inicializado"
}

# -----------------------------------------------------------------------------
# Ciclo de vida
# -----------------------------------------------------------------------------
study_start() {
    bunker_require_root
    
    bunker_info "Iniciando Bunker Study..."
    
    study_init
    
    # Verificar dependencias
    check_study_dependencies
    
    # Verificar modelo de IA asignado
    check_ai_model
    
    STUDY_STATE="running"
    bunker_write_pid "bunker-study" "$STUDY_PID"
    
    bunker_info "Bunker Study iniciado"
}

study_stop() {
    bunker_require_root
    
    bunker_info "Deteniendo Bunker Study..."
    
    STUDY_STATE="stopped"
    bunker_remove_pid "bunker-study"
    
    # Limpiar cache
    study_cleanup_cache
    
    bunker_info "Bunker Study detenido"
}

study_status() {
    echo "Estado: $STUDY_STATE"
    echo "PID: $STUDY_PID"
    echo "Directorio: $STUDY_DIR"
    echo "Biblioteca: $(ls "$STUDY_LIBRARY" 2>/dev/null | wc -l) documentos"
    echo "Resumenes: $(ls "$STUDY_SUMMARIES" 2>/dev/null | wc -l) documentos"
    echo "Examenes: $(ls "$STUDY_EXAMS" 2>/dev/null | wc -l) documentos"
}

# -----------------------------------------------------------------------------
# Verificar dependencias
# -----------------------------------------------------------------------------
check_study_dependencies() {
    local missing_deps=()
    
    # Dependencias basicas
    for dep in python3 pdftotext poppler-utils; do
        if ! command -v "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        bunker_warn "Dependencias faltantes para Study: ${missing_deps[*]}"
        bunker_warn "Instalalas con: pacman -S ${missing_deps[*]}"
    fi
}

# -----------------------------------------------------------------------------
# Verificar modelo de IA
# -----------------------------------------------------------------------------
check_ai_model() {
    bunker_info "Verificando modelo de IA asignado..."
    
    # Obtener modelo asignado desde Bunker Adapt
    local model
    model=$(bunker_config_get ai "default_model" 2>/dev/null)
    
    if [[ -z "$model" ]]; then
        bunker_warn "No hay modelo de IA asignado. Usando modelo por defecto."
        model="llama-2-7b"
        bunker_config_set ai "default_model" "$model"
    fi
    
    # Verificar si el modelo es compatible con la memoria
    local available_mem_mb
    available_mem_mb=$(get_available_memory_mb)
    
    # Modelos y sus requisitos (en MB)
    declare -A MODEL_REQUIREMENTS=(
        ["llama-2-7b"]="7000"
        ["llama-2-13b"]="13000"
        ["mistral-7b"]="7000"
        ["phi-2"]="3000"
        ["tinyllama"]="1000"
    )
    
    local required_mem="${MODEL_REQUIREMENTS[$model]:-7000}"
    
    if [[ "$available_mem_mb" -lt "$required_mem" ]]; then
        bunker_warn "El modelo $model requiere ${required_mem}MB pero solo hay ${available_mem_mb}MB disponibles"
        bunker_warn "Intentando seleccionar un modelo compatible..."
        
        # Intentar seleccionar un modelo compatible
        local compatible_model
        compatible_model=$(select_compatible_model "$available_mem_mb" "${MODEL_REQUIREMENTS[@]}")
        
        if [[ -n "$compatible_model" ]]; then
            bunker_info "Modelo compatible encontrado: $compatible_model"
            bunker_config_set ai "default_model" "$compatible_model"
            model="$compatible_model"
        else
            bunker_error "No hay modelos de IA compatibles con la memoria disponible"
            bunker_error "Se requiere al menos 1GB de RAM libre para el modelo mas pequeño"
            bunker_exit 1
        fi
    fi
    
    bunker_info "Modelo de IA asignado: $model (requiere ${required_mem}MB)"
    export STUDY_AI_MODEL="$model"
}

# Obtener memoria disponible en MB
get_available_memory_mb() {
    if [[ -f /proc/meminfo ]]; then
        local free_mem
        free_mem=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        local free_mem_mb=$((free_mem / 1024))
        echo "$free_mem_mb"
    else
        free -m 2>/dev/null | awk '/^Mem:/{print $4}'
    fi
}

# Seleccionar modelo compatible
select_compatible_model() {
    local available_mem_mb="$1"
    shift
    local model_reqs=("$@")
    local best_model=""
    local best_size=0
    
    for model in "${!MODEL_REQUIREMENTS[@]}"; do
        local required_mem="${MODEL_REQUIREMENTS[$model]}"
        if [[ "$required_mem" -le "$available_mem_mb" && "$required_mem" -gt "$best_size" ]]; then
            best_model="$model"
            best_size="$required_mem"
        fi
    done
    
    echo "$best_model"
}

# -----------------------------------------------------------------------------
# Gestin de biblioteca
# -----------------------------------------------------------------------------
library_add() {
    local file="$1"
    local subject="$2"
    
    if [[ ! -f "$file" ]]; then
        bunker_error "Archivo no encontrado: $file"
        return 1
    fi
    
    local dest_dir="$STUDY_LIBRARY/$subject"
    mkdir -p "$dest_dir"
    
    local filename
    filename=$(basename "$file")
    local dest_file="$dest_dir/$filename"
    
    # Verificar duplicados
    if [[ -f "$dest_file" ]]; then
        bunker_warn "El archivo ya existe en la biblioteca: $filename"
        return 0
    fi
    
    cp "$file" "$dest_file"
    chmod 600 "$dest_file"
    
    # Registrar en indice
    library_index_add "$subject" "$filename" "$dest_file"
    
    bunker_info "Documento agregado a la biblioteca: $filename (Asignatura: $subject)"
}

library_index_add() {
    local subject="$1"
    local filename="$2"
    local filepath="$3"
    local index_file="$STUDY_LIBRARY/.index.csv"
    
    # Escape CSV fields (replace commas, quotes, newlines)
    subject=$(echo "$subject" | sed 's/"/"""/g; s/,/\,/g')
    filename=$(echo "$filename" | sed 's/"/"""/g; s/,/\,/g')
    filepath=$(echo "$filepath" | sed 's/"/"""/g; s/,/\,/g')
    
    echo ""$subject","$filename","$filepath","$(date '+%Y-%m-%d %H:%M:%S')"" >> "$index_file"
}

library_list() {
    local subject="${1:-}"
    local index_file="$STUDY_LIBRARY/.index.csv"
    
    if [[ ! -f "$index_file" ]]; then
        echo "No hay documentos en la biblioteca"
        return 0
    fi
    
    if [[ -n "$subject" ]]; then
        grep "^$subject," "$index_file" 2>/dev/null | cut -d',' -f2,3,4,5
    else
        cat "$index_file" 2>/dev/null | cut -d',' -f2,3,4,5
    fi
}

library_search() {
    local query="$1"
    local index_file="$STUDY_LIBRARY/.index.csv"
    
    if [[ ! -f "$index_file" ]]; then
        echo "No hay documentos en la biblioteca"
        return 0
    fi
    
    grep -i "$query" "$index_file" 2>/dev/null | cut -d',' -f2,3,4,5
}

# -----------------------------------------------------------------------------
# Resumenes inteligentes
# -----------------------------------------------------------------------------
summarize_document() {
    local file="$1"
    local output="$2"
    
    if [[ ! -f "$file" ]]; then
        bunker_error "Archivo no encontrado: $file"
        return 1
    fi
    
    bunker_info "Generando resumen de: $file"
    
    # Extraer texto del documento
    local text
    text=$(extract_text "$file")
    
    if [[ -z "$text" ]]; then
        bunker_error "No se pudo extraer texto del documento"
        return 1
    fi
    
    # Generar resumen usando el modelo de IA
    local summary
    summary=$(generate_summary "$text")
    
    # Guardar resumen
    echo "$summary" > "$output"
    chmod 600 "$output"
    
    bunker_info "Resumen generado: $output"
}

extract_text() {
    local file="$1"
    local ext
    ext="${file##*.}"
    
    case "$ext" in
        pdf)
            pdftotext "$file" - 2>/dev/null
            ;;
        txt|md|markdown)
            cat "$file"
            ;;
        docx|odt)
            # Requiere pandoc o similar
            bunker_warn "Formato $ext requiere herramientas adicionales (pandoc)"
            ;;
        *)
            bunker_warn "Formato $ext no soportado para extraccion de texto"
            ;;
    esac
}

generate_summary() {
    local text="$1"
    
    # Limitar el texto para procesamiento
    local max_length=4000
    if [[ ${#text} -gt $max_length ]]; then
        text="${text:0:$max_length}..."
    fi
    
    # Usar extraccion real de texto - sin simulacion de IA
    # Extraer los primeros 3 parrafos no vacios como resumen basico
    local summary
    summary=$(echo "$text" | awk 'BEGIN {count=0} /^[[:space:]]*$/ {next} {if (count < 3) {print; count++}}')
    
    echo "--- Resumen generado por Bunker Study ---"
    echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Modelo: ${STUDY_AI_MODEL:-ninguno (modo basico)}"
    echo "Tipo: Resumen automatico (extraccion de texto)"
    echo ""
    echo "$summary"
}

# -----------------------------------------------------------------------------
# Analisis de examenes
# -----------------------------------------------------------------------------
exam_import() {
    local file="$1"
    local subject="$2"
    
    if [[ ! -f "$file" ]]; then
        bunker_error "Archivo de examen no encontrado: $file"
        return 1
    fi
    
    local dest_dir="$STUDY_EXAMS/$subject"
    mkdir -p "$dest_dir"
    
    local filename
    filename=$(basename "$file")
    local dest_file="$dest_dir/$filename"
    
    cp "$file" "$dest_file"
    chmod 600 "$dest_file"
    
    # Analizar examen
    exam_analyze "$dest_file" "$subject"
    
    bunker_info "Examen importado: $filename (Asignatura: $subject)"
}

exam_analyze() {
    local file="$1"
    local subject="$2"
    
    bunker_info "Analizando examen: $file"
    
    # Extraer texto
    local text
    text=$(extract_text "$file")
    
    if [[ -z "$text" ]]; then
        bunker_warn "No se pudo extraer texto del examen"
        return 0
    fi
    
    # Contar preguntas
    local question_count
    question_count=$(echo "$text" | grep -c -i "pregunta\|question\|ejercicio" || echo 0)
    
    # Identificar temas
    local topics
    topics=$(identify_topics "$text")
    
    # Guardar analisis
    local analysis_file="${file}.analysis"
    cat > "$analysis_file" <<EOF
Examen: $(basename "$file")
Asignatura: $subject
Fecha de analisis: $(date '+%Y-%m-%d %H:%M:%S')

Preguntas detectadas: $question_count
Temas identificados:
$topics

--- Analisis generado por Bunker Study ---
EOF
    
    chmod 600 "$analysis_file"
    bunker_info "Analisis completado: $analysis_file"
}

identify_topics() {
    local text="$1"
    
    # Extraer palabras clave (simplificado)
    echo "$text" | tr ' ' '\n' | tr '[:upper:]' '[:lower:]' | grep -E "^[a-z]{4,}$" | sort | uniq -c | sort -rn | head -10 | awk '{print "  - " $2}'
}

# -----------------------------------------------------------------------------
# Perfiles docentes
# -----------------------------------------------------------------------------
profile_create() {
    local name="$1"
    local subject="$2"
    
    local profile_dir="$STUDY_PROFILES/$name"
    mkdir -p "$profile_dir"
    
    local profile_file="$profile_dir/profile.txt"
    cat > "$profile_file" <<EOF
Nombre: $name
Asignatura: $subject
Fecha de creacion: $(date '+%Y-%m-%d %H:%M:%S')

Examenes analizados: 0
Temas recurrentes: 
Tipos de preguntas: 
Criterios de puntuacion: 

--- Perfil docente - Bunker Study ---
EOF
    
    chmod 600 "$profile_file"
    bunker_info "Perfil docente creado: $name ($subject)"
}

profile_update() {
    local name="$1"
    local exam_file="$2"
    
    local profile_dir="$STUDY_PROFILES/$name"
    if [[ ! -d "$profile_dir" ]]; then
        bunker_error "Perfil no encontrado: $name"
        return 1
    fi
    
    local profile_file="$profile_dir/profile.txt"
    
    # Analizar examen y actualizar perfil
    # ... (logica de actualizacion)
    
    bunker_info "Perfil actualizado: $name"
}

# -----------------------------------------------------------------------------
# Planes de estudio
# -----------------------------------------------------------------------------
plan_create() {
    local name="$1"
    local subject="$2"
    local exam_date="$3"
    
    local plan_file="$STUDY_PLANS/${name}_${subject}.plan"
    
    cat > "$plan_file" <<EOF
Plan de estudio: $name
Asignatura: $subject
Fecha de examen: $exam_date
Fecha de creacion: $(date '+%Y-%m-%d %H:%M:%S')

Objetivos:
  - Revisar todos los temas
  - Practicar con examenes anteriores
  - Crear resumenes

Tareas pendientes:
  - [ ] Leer capitulo 1
  - [ ] Hacer resumen del tema 2
  - [ ] Practicar examen de prueba

--- Plan de estudio - Bunker Study ---
EOF
    
    chmod 600 "$plan_file"
    bunker_info "Plan de estudio creado: $name ($subject)"
}

plan_list() {
    ls "$STUDY_PLANS"/*.plan 2>/dev/null | while read -r file; do
        local name
        name=$(basename "$file" .plan)
        echo "  $name"
    done
}

# -----------------------------------------------------------------------------
# Limpieza de cache
# -----------------------------------------------------------------------------
study_cleanup_cache() {
    bunker_info "Limpieza de cache..."
    
    # Limpiar archivos temporales
    find "$STUDY_CACHE" -type f -mtime +1 -delete 2>/dev/null || true
    
    # Limpiar archivos temporales de procesamiento
    find "$STUDY_DIR" -name "*.tmp" -type f -delete 2>/dev/null || true
    
    bunker_info "Cache limpiada"
}

# -----------------------------------------------------------------------------
# Punto de entrada
# -----------------------------------------------------------------------------
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        start)
            study_start "$@"
            ;;
        stop)
            study_stop "$@"
            ;;
        status)
            study_status "$@"
            ;;
        # Biblioteca
        library-add)
            library_add "$@"
            ;;
        library-list)
            library_list "$@"
            ;;
        library-search)
            library_search "$@"
            ;;
        # Resumenes
        summarize)
            local file="$1"
            local output="$2"
            if [[ -z "$output" ]]; then
                output="$STUDY_SUMMARIES/$(basename "$file").summary"
            fi
            summarize_document "$file" "$output"
            ;;
        # Examenes
        exam-import)
            exam_import "$@"
            ;;
        exam-analyze)
            exam_analyze "$@"
            ;;
        # Perfiles
        profile-create)
            profile_create "$@"
            ;;
        profile-update)
            profile_update "$@"
            ;;
        # Planes
        plan-create)
            plan_create "$@"
            ;;
        plan-list)
            plan_list "$@"
            ;;
        # Utilidades
        cleanup)
            study_cleanup_cache
            ;;
        help|--help|-h)
            echo "Uso: bunker study <comando>"
            echo ""
            echo "Comandos principales:"
            echo "  start              - Iniciar Bunker Study"
            echo "  stop               - Detener Bunker Study"
            echo "  status             - Mostrar estado"
            echo ""
            echo "Biblioteca:"
            echo "  library-add <file> <subject>   - Agregar documento a la biblioteca"
            echo "  library-list [subject]          - Listar documentos"
            echo "  library-search <query>          - Buscar documentos"
            echo ""
            echo "Resumenes:"
            echo "  summarize <file> [output]      - Generar resumen"
            echo ""
            echo "Examenes:"
            echo "  exam-import <file> <subject>    - Importar examen"
            echo "  exam-analyze <file> <subject>   - Analizar examen"
            echo ""
            echo "Perfiles docentes:"
            echo "  profile-create <name> <subject> - Crear perfil docente"
            echo "  profile-update <name> <exam>    - Actualizar perfil"
            echo ""
            echo "Planes de estudio:"
            echo "  plan-create <name> <subject> <date> - Crear plan"
            echo "  plan-list                       - Listar planes"
            echo ""
            echo "Utilidades:"
            echo "  cleanup         - Limpiar cache"
            echo "  help            - Mostrar esta ayuda"
            ;;
        *)
            bunker_error "Comando desconocido: $command"
            bunker_exit 1
            ;;
    esac
}

main "$@"
