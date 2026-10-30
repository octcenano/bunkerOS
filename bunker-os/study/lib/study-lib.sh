#!/bin/bash
# =============================================================================
# Bunker OS - Bunker Study Library
# Ubicaci3n: /usr/lib/bunker/study/lib/study-lib.sh
# Propsito: Funciones comunes para Bunker Study
# =============================================================================

set -o pipefail

BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

# -----------------------------------------------------------------------------
# Directorios de Study
# -----------------------------------------------------------------------------
STUDY_DIR="$BUNKER_VAR/study"
STUDY_LIBRARY="$STUDY_DIR/library"
STUDY_SUMMARIES="$STUDY_DIR/summaries"
STUDY_EXAMS="$STUDY_DIR/exams"
STUDY_PROFILES="$STUDY_DIR/profiles"
STUDY_PLANS="$STUDY_DIR/plans"
STUDY_CACHE="$STUDY_DIR/cache"

# -----------------------------------------------------------------------------
# Inicializacin
# -----------------------------------------------------------------------------
study_lib_init() {
    mkdir -p "$STUDY_DIR" "$STUDY_LIBRARY" "$STUDY_SUMMARIES" "$STUDY_EXAMS" "$STUDY_PROFILES" "$STUDY_PLANS" "$STUDY_CACHE"
    chmod 700 "$STUDY_DIR" "$STUDY_LIBRARY" "$STUDY_SUMMARIES" "$STUDY_EXAMS" "$STUDY_PROFILES" "$STUDY_PLANS" "$STUDY_CACHE"
}

# -----------------------------------------------------------------------------
# Logging para Study
# -----------------------------------------------------------------------------
study_log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="$STUDY_DIR/study.log"
    
    case "$level" in
        DEBUG)
            echo "[$timestamp] [STUDY-DEBUG] $message" >> "$log_file"
            ;;
        INFO)
            echo "[$timestamp] [STUDY-INFO] $message" | tee -a "$log_file"
            ;;
        WARN)
            echo "[$timestamp] [STUDY-WARN] $message" | tee -a "$log_file" >&2
            ;;
        ERROR)
            echo "[$timestamp] [STUDY-ERROR] $message" | tee -a "$log_file" >&2
            ;;
    esac
}

study_debug() { study_log "DEBUG" "$@"; }
study_info() { study_log "INFO" "$@"; }
study_warn() { study_log "WARN" "$@"; }
study_error() { study_log "ERROR" "$@"; }

# -----------------------------------------------------------------------------
# Validacin de archivos
# -----------------------------------------------------------------------------
study_validate_file() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        study_error "Archivo no encontrado: $file"
        return 1
    fi
    
    # Verificar que el archivo es legible
    if [[ ! -r "$file" ]]; then
        study_error "No se puede leer el archivo: $file"
        return 1
    fi
    
    # Verificar tamano maximo (100MB por defecto)
    local max_size=$((100 * 1024 * 1024))
    local file_size
    file_size=$(stat -c %s "$file" 2>/dev/null || echo 0)
    
    if [[ "$file_size" -gt "$max_size" ]]; then
        study_error "El archivo es demasiado grande: $file ($file_size bytes > $max_size bytes)"
        return 1
    fi
    
    return 0
}

# -----------------------------------------------------------------------------
# Extraccin de texto
# -----------------------------------------------------------------------------
study_extract_text() {
    local file="$1"
    local ext
    ext="${file##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    
    case "$ext" in
        pdf)
            pdftotext "$file" - 2>/dev/null
            ;;
        txt|text)
            cat "$file"
            ;;
        md|markdown)
            # Convertir markdown a texto plano
            sed 's/^[#*_~`]*//' "$file" | sed 's/^[-*+] //' | sed 's/^> //'
            ;;
        docx)
            # Requiere pandoc
            if command -v pandoc &>/dev/null; then
                pandoc "$file" -f docx -t plain 2>/dev/null
            else
                study_warn "pandoc no disponible para archivos .docx"
                return 1
            fi
            ;;
        odt)
            # Requiere pandoc
            if command -v pandoc &>/dev/null; then
                pandoc "$file" -f odt -t plain 2>/dev/null
            else
                study_warn "pandoc no disponible para archivos .odt"
                return 1
            fi
            ;;
        *)
            study_warn "Formato no soportado: $ext"
            return 1
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Procesamiento de texto
# -----------------------------------------------------------------------------
study_clean_text() {
    local text="$1"
    
    # Eliminar caracteres de control
    text=$(echo "$text" | tr -d '\000-\037')
    
    # Eliminar espacios duplicados
    text=$(echo "$text" | tr -s ' ')
    
    # Eliminar lineas vacias
    text=$(echo "$text" | sed '/^[[:space:]]*$/d')
    
    echo "$text"
}

study_normalize_text() {
    local text="$1"
    
    # Convertir a minusculas
    text=$(echo "$text" | tr '[:upper:]' '[:lower:]')
    
    # Eliminar acentos (simplificado)
    text=$(echo "$text" | sed 's/[\xE0-\xFC]//g')
    
    echo "$text"
}

# -----------------------------------------------------------------------------
# Analisis de texto
# -----------------------------------------------------------------------------
study_count_words() {
    local text="$1"
    echo "$text" | wc -w
}

study_count_lines() {
    local text="$1"
    echo "$text" | wc -l
}

study_count_paragraphs() {
    local text="$1"
    echo "$text" | awk '/^$/ {count++} END {print count+1}'
}

# -----------------------------------------------------------------------------
# Extraccin de palabras clave
# -----------------------------------------------------------------------------
study_extract_keywords() {
    local text="$1"
    local num_keywords="${2:-10}"
    
    # Normalizar texto
    text=$(study_normalize_text "$text")
    
    # Eliminar palabras comunes
    local stop_words="el la los las de del en y a al por con para con sin sobre bajo entre"
    
    # Contar frecuencias
    echo "$text" | tr ' ' '\n' | grep -vE "^($stop_words)$" | grep -E "^[a-z]{3,}$" | sort | uniq -c | sort -rn | head -n "$num_keywords" | awk '{print $2}'
}

# -----------------------------------------------------------------------------
# Similaridad de texto (Jaccard simplificado)
# -----------------------------------------------------------------------------
study_text_similarity() {
    local text1="$1"
    local text2="$2"
    
    # Obtener palabras unicas de cada texto
    local words1
    words1=$(echo "$text1" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    local words2
    words2=$(echo "$text2" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    
    # Contar interseccion
    local intersection
    intersection=$(echo -e "$words1\n$words2" | tr ' ' '\n' | sort | uniq -d | wc -l)
    
    # Contar union
    local union
    union=$(echo -e "$words1\n$words2" | tr ' ' '\n' | sort -u | wc -l)
    
    if [[ "$union" -eq 0 ]]; then
        echo 0
    else
        echo "scale=2; $intersection / $union" | bc 2>/dev/null || echo 0
    fi
}

# -----------------------------------------------------------------------------
# Gestin de cache
# -----------------------------------------------------------------------------
STUDY_CACHE_MAX_SIZE_MB=100
STUDY_CACHE_MAX_AGE_DAYS=7

study_cache_cleanup() {
    study_info "Limpieza de cache..."
    
    # Limpiar archivos viejos
    find "$STUDY_CACHE" -type f -mtime +"$STUDY_CACHE_MAX_AGE_DAYS" -delete 2>/dev/null || true
    
    # Limpiar si el cache es demasiado grande
    local cache_size
    cache_size=$(du -sm "$STUDY_CACHE" 2>/dev/null | awk '{print $1}' || echo 0)
    
    if [[ "$cache_size" -gt "$STUDY_CACHE_MAX_SIZE_MB" ]]; then
        study_info "Cache demasiado grande ($cache_size MB > $STUDY_CACHE_MAX_SIZE_MB MB), limpiando..."
        find "$STUDY_CACHE" -type f -delete 2>/dev/null || true
    fi
    
    study_info "Cache limpiada"
}

# -----------------------------------------------------------------------------
# Utilidades de archivo
# -----------------------------------------------------------------------------
study_generate_filename() {
    local prefix="$1"
    local ext="$2"
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    echo "${prefix}_${timestamp}.${ext}"
}

study_sanitize_filename() {
    local filename="$1"
    # Eliminar caracteres no seguros
    filename=$(echo "$filename" | tr -d '/\:*?"<>| ')
    echo "$filename"
}

# -----------------------------------------------------------------------------
# Validacin de asignaturas
# -----------------------------------------------------------------------------
study_validate_subject() {
    local subject="$1"
    
    # Validar longitud
    if [[ ${#subject} -gt 50 ]]; then
        study_error "Nombre de asignatura demasiado largo: $subject"
        return 1
    fi
    
    # Validar caracteres
    if ! [[ "$subject" =~ ^[a-zA-Z0-9\ _-]+$ ]]; then
        study_error "Nombre de asignatura contiene caracteres invalidos: $subject"
        return 1
    fi
    
    return 0
}

# -----------------------------------------------------------------------------
# Validacin de fechas
# -----------------------------------------------------------------------------
study_validate_date() {
    local date="$1"
    
    # Formato: YYYY-MM-DD
    if ! [[ "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        study_error "Formato de fecha invalido: $date (esperado YYYY-MM-DD)"
        return 1
    fi
    
    # Validar fecha
    if ! date -d "$date" &>/dev/null; then
        study_error "Fecha invalida: $date"
        return 1
    fi
    
    return 0
}

# -----------------------------------------------------------------------------
# Generacin de IDs unicos
# -----------------------------------------------------------------------------
study_generate_id() {
    local prefix="$1"
    local timestamp
    timestamp=$(date '+%Y%m%d%H%M%S')
    local random
    random=$((RANDOM % 10000))
    echo "${prefix}_${timestamp}_${random}"
}

# -----------------------------------------------------------------------------
# Mensajes de progreso
# -----------------------------------------------------------------------------
study_progress_start() {
    local task="$1"
    local total="$2"
    echo "Iniciando: $task (0/$total)..."
}

study_progress_update() {
    local current="$1"
    local total="$2"
    local task="$3"
    local percent=$((current * 100 / total))
    echo -ne "\r$task ($current/$total) - $percent%..."
}

study_progress_end() {
    echo ""
}

# -----------------------------------------------------------------------------
# Inicializacin automatica
# -----------------------------------------------------------------------------
study_lib_init
