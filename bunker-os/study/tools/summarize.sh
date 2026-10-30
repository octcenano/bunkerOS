#!/bin/bash
# =============================================================================
# Bunker OS - Bunker Study - Herramienta: Resumir Documentos
# Ubicaci3n: /usr/lib/bunker/study/tools/summarize.sh
# Propsito: Generar resumenes inteligentes de documentos
# =============================================================================

set -o pipefail

BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/study/lib/study-lib.sh"

# -----------------------------------------------------------------------------
# Configuracin
# -----------------------------------------------------------------------------
SUMMARY_LENGTH="medium"  # short, medium, long
SUMMARY_FORMAT="markdown"  # text, markdown, html

# -----------------------------------------------------------------------------
# Generar resumen
# -----------------------------------------------------------------------------
generate_summary() {
    local file="$1"
    local output="$2"
    local subject="$3"
    
    study_info "Generando resumen de: $file"
    
    # Validar archivo
    if ! study_validate_file "$file"; then
        return 1
    fi
    
    # Extraer texto
    local text
    text=$(study_extract_text "$file")
    if [[ -z "$text" ]]; then
        study_error "No se pudo extraer texto del documento"
        return 1
    fi
    
    # Limpiar texto
    text=$(study_clean_text "$text")
    
    # Generar resumen
    local summary
    summary=$(create_summary "$text" "$SUMMARY_LENGTH" "$SUMMARY_FORMAT")
    
    # Guardar resumen
    if [[ -z "$output" ]]; then
        local base_name
        base_name=$(basename "$file" .pdf | basename "$file" .txt | basename "$file" .md)
        output="$STUDY_SUMMARIES/${base_name}.summary"
    fi
    
    mkdir -p "$(dirname "$output")"
    echo "$summary" > "$output"
    chmod 600 "$output"
    
    study_info "Resumen generado: $output"
    echo "$output"
}

# -----------------------------------------------------------------------------
# Crear resumen basado en longitud
# -----------------------------------------------------------------------------
create_summary() {
    local text="$1"
    local length="$2"
    local format="$3"
    
    local num_paragraphs
    num_paragraphs=$(study_count_paragraphs "$text")
    local num_sentences
    num_sentences=$(echo "$text" | grep -cE "[.!?]" || echo 0)
    local word_count
    word_count=$(study_count_words "$text")
    
    # Determinar longitud del resumen
    local summary_length
    case "$length" in
        short)
            summary_length=$((num_paragraphs / 4))
            ;;
        medium)
            summary_length=$((num_paragraphs / 2))
            ;;
        long)
            summary_length=$((num_paragraphs * 3 / 4))
            ;;
        *)
            summary_length=$((num_paragraphs / 2))
            ;;
    esac
    
    # Extraer parrafos clave
    local summary
    summary=$(echo "$text" | awk -v n="$summary_length" 'BEGIN {count=0} /^[[:space:]]*$/ {next} {if (count < n) {print; count++}}')
    
    # Formatear resumen
    case "$format" in
        markdown)
            summary=$(format_markdown "$summary")
            ;;
        html)
            summary=$(format_html "$summary")
            ;;
    esac
    
    # Agregar metadatos
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat <<EOF
=== RESUMEN ===

Asignatura: ${subject:-Desconocida}
Fecha: $timestamp
Longitud: $length
Formato: $format

--- Estadisticas ---
Parrafos originales: $num_paragraphs
Oraciones: $num_sentences
Palabras: $word_count

--- Resumen ---

$summary

=== FIN DEL RESUMEN ===
EOF
}

# -----------------------------------------------------------------------------
# Formatear como Markdown
# -----------------------------------------------------------------------------
format_markdown() {
    local text="$1"
    
    # Agregar encabezados
    echo "$text" | sed 's/^# /## /'
}

# -----------------------------------------------------------------------------
# Formatear como HTML
# -----------------------------------------------------------------------------
format_html() {
    local text="$1"
    
    echo "<html><body>"
    echo "<h1>Resumen</h1>"
    echo "<p>$text</p>"
    echo "</body></html>"
}

# -----------------------------------------------------------------------------
# Resumir por capitulos
# -----------------------------------------------------------------------------
summarize_by_chapters() {
    local file="$1"
    local output_dir="$2"
    
    study_info "Generando resumenes por capitulos de: $file"
    
    # Extraer texto
    local text
    text=$(study_extract_text "$file")
    if [[ -z "$text" ]]; then
        study_error "No se pudo extraer texto"
        return 1
    fi
    
    # Detectar capitulos
    local chapters
    chapters=$(detect_chapters "$text")
    
    # Crear directorio de salida
    mkdir -p "$output_dir"
    
    # Generar resumen para cada capitulo
    local chapter_count=0
    while IFS= read -r chapter; do
        chapter_count=$((chapter_count + 1))
        local chapter_text
        chapter_text=$(extract_chapter_text "$text" "$chapter")
        
        local chapter_summary
        chapter_summary=$(create_summary "$chapter_text" "short" "text")
        
        local chapter_file="$output_dir/cap_${chapter_count}.summary"
        echo "$chapter_summary" > "$chapter_file"
        chmod 600 "$chapter_file"
        
        study_info "Resumen del capitulo $chapter_count: $chapter_file"
    done <<< "$chapters"
    
    echo "$output_dir"
}

detect_chapters() {
    local text="$1"
    
    # Detectar lineas que parecen titulos de capitulo
    echo "$text" | grep -E "^CAPITULO|^Capitulo|^Chapter|^[0-9]+[\.\ )]+" | head -20
}

extract_chapter_text() {
    local text="$1"
    local chapter_title="$2"
    
    # Extraer texto desde el capitulo hasta el siguiente capitulo
    echo "$text" | awk -v chapter="$chapter_title" '
        BEGIN {in_chapter=0; found=0}
        $0 ~ chapter {in_chapter=1; found=1; next}
        in_chapter && /^CAPITULO|^Capitulo|^Chapter|^[0-9]+[\.\ )]+/ && !found {exit}
        in_chapter {print}
    '
}

# -----------------------------------------------------------------------------
# Extraer conceptos clave
# -----------------------------------------------------------------------------
extract_key_concepts() {
    local file="$1"
    local num_concepts="${2:-20}"
    
    study_info "Extrayendo conceptos clave de: $file"
    
    # Extraer texto
    local text
    text=$(study_extract_text "$file")
    if [[ -z "$text" ]]; then
        study_error "No se pudo extraer texto"
        return 1
    fi
    
    # Normalizar y limpiar
    text=$(study_normalize_text "$text")
    text=$(study_clean_text "$text")
    
    # Extraer palabras clave
    local keywords
    keywords=$(study_extract_keywords "$text" "$num_concepts")
    
    # Formatear salida
    echo "=== CONCEPTOS CLAVE ==="
    echo ""
    local i=1
    for keyword in $keywords; do
        echo "$i. $keyword"
        i=$((i + 1))
    done
    echo ""
    echo "=== FIN ==="
}

# -----------------------------------------------------------------------------
# Crear glosario
# -----------------------------------------------------------------------------
create_glossary() {
    local file="$1"
    local output="$2"
    
    study_info "Creando glosario de: $file"
    
    # Extraer texto
    local text
    text=$(study_extract_text "$file")
    if [[ -z "$text" ]]; then
        study_error "No se pudo extraer texto"
        return 1
    fi
    
    # Extraer terminos y definiciones
    local glossary
    glossary=$(extract_glossary_entries "$text")
    
    if [[ -z "$output" ]]; then
        local base_name
        base_name=$(basename "$file" .pdf | basename "$file" .txt | basename "$file" .md)
        output="$STUDY_SUMMARIES/${base_name}.glossary"
    fi
    
    mkdir -p "$(dirname "$output")"
    echo "$glossary" > "$output"
    chmod 600 "$output"
    
    study_info "Glosario creado: $output"
    echo "$output"
}

extract_glossary_entries() {
    local text="$1"
    
    # Buscar patrones de definiciones
    echo "$text" | grep -E "^[A-Z][a-z]+:|^[A-Z][a-z]+ -|^[A-Z][a-z]+\. " | head -50
}

# -----------------------------------------------------------------------------
# Punto de entrada
# -----------------------------------------------------------------------------
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        generate)
            local file="$1"
            local output="$2"
            local subject="$3"
            generate_summary "$file" "$output" "$subject"
            ;;
        by-chapters)
            local file="$1"
            local output_dir="$2"
            summarize_by_chapters "$file" "$output_dir"
            ;;
        key-concepts)
            local file="$1"
            local num_concepts="${2:-20}"
            extract_key_concepts "$file" "$num_concepts"
            ;;
        glossary)
            local file="$1"
            local output="$2"
            create_glossary "$file" "$output"
            ;;
        help|--help|-h)
            echo "Uso: summarize <comando>"
            echo ""
            echo "Comandos:"
            echo "  generate <file> [output] [subject]  - Generar resumen"
            echo "  by-chapters <file> [output_dir]       - Resumir por capitulos"
            echo "  key-concepts <file> [num]             - Extraer conceptos clave"
            echo "  glossary <file> [output]               - Crear glosario"
            echo "  help                                  - Mostrar ayuda"
            ;;
        *)
            study_error "Comando desconocido: $command"
            exit 1
            ;;
    esac
}

main "$@"
