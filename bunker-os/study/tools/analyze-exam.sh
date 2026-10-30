#!/bin/bash
# =============================================================================
# Bunker OS - Bunker Study - Herramienta: Analizar Examen
# Ubicaci3n: /usr/lib/bunker/study/tools/analyze-exam.sh
# Propsito: Analizar examenes anteriores para identificar patrones
# =============================================================================

set -o pipefail

BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/study/lib/study-lib.sh"

# -----------------------------------------------------------------------------
# Analizar examen
# -----------------------------------------------------------------------------
analyze_exam() {
    local file="$1"
    local subject="$2"
    local output_dir="$3"
    
    study_info "Analizando examen: $file"
    
    # Validar archivo
    if ! study_validate_file "$file"; then
        return 1
    fi
    
    # Extraer texto
    local text
    text=$(study_extract_text "$file")
    if [[ -z "$text" ]]; then
        study_error "No se pudo extraer texto del examen"
        return 1
    fi
    
    # Crear directorio de salida
    mkdir -p "$output_dir"
    local base_name
    base_name=$(basename "$file" .pdf | basename "$file" .txt | basename "$file" .md)
    
    # Contar preguntas
    local question_count
    question_count=$(echo "$text" | grep -ci "pregunta\|question\|ejercicio\|problema\|item")
    
    # Identificar tipo de preguntas
    local question_types
    question_types=$(identify_question_types "$text")
    
    # Identificar temas
    local topics
    topics=$(study_extract_keywords "$text" 15)
    
    # Analizar estructura
    local structure
    structure=$(analyze_exam_structure "$text")
    
    # Guardar resultados
    local result_file="$output_dir/${base_name}.analysis"
    cat > "$result_file" <<EOF
=== ANALISIS DE EXAMEN ===

Asignatura: $subject
Archivo: $file
Fecha de analisis: $(date '+%Y-%m-%d %H:%M:%S')

--- Estadisticas ---
Preguntas detectadas: $question_count

--- Tipos de preguntas ---
$question_types

--- Temas identificados ---
$(echo "$topics" | sed 's/^/  - /')

--- Estructura ---
$structure

--- Resumen ---
Este examen contiene aproximadamente $question_count preguntas sobre los siguientes temas principales:
$(echo "$topics" | head -5 | sed 's/^/  - /')

=== FIN DEL ANALISIS ===
EOF
    
    study_info "Analisis guardado en: $result_file"
    echo "$result_file"
}

# -----------------------------------------------------------------------------
# Identificar tipos de preguntas
# -----------------------------------------------------------------------------
identify_question_types() {
    local text="$1"
    
    local multiple_choice=0
    local true_false=0
    local short_answer=0
    local essay=0
    local code=0
    local other=0
    
    # Contar tipos de preguntas
    # Multiple choice: a), b), c), d)
    if echo "$text" | grep -qE "^[[:space:]]*[a-zA-Z]\.[[:space:]]\(\|[[:space:]]*[a-zA-Z]\.[[:space:]]\)"; then
        multiple_choice=$(echo "$text" | grep -cE "^[[:space:]]*[a-zA-Z]\.[[:space:]]\(\|[[:space:]]*[a-zA-Z]\.[[:space:]]\)" || echo 0)
    fi
    
    # True/False
    true_false=$(echo "$text" | grep -ci "verdadero\|falso\|true\|false" || echo 0)
    
    # Short answer
    short_answer=$(echo "$text" | grep -ci "respuesta corta\|short answer\|completar" || echo 0)
    
    # Essay
    essay=$(echo "$text" | grep -ci "desarrollo\|ensayo\|explicar\|discutir" || echo 0)
    
    # Code
    code=$(echo "$text" | grep -ci "código\|code\|programa\|funcion\|clase" || echo 0)
    
    # Calcular otros
    local total_questions
    total_questions=$((multiple_choice + true_false + short_answer + essay + code))
    
    cat <<EOF
  - Opcion multiple: $multiple_choice
  - Verdadero/Falso: $true_false
  - Respuesta corta: $short_answer
  - Desarrollo: $essay
  - Programacion: $code
EOF
}

# -----------------------------------------------------------------------------
# Analizar estructura del examen
# -----------------------------------------------------------------------------
analyze_exam_structure() {
    local text="$1"
    
    local sections=()
    local current_section=""
    local line_count=0
    
    while IFS= read -r line; do
        # Detectar secciones (lineas que parecen titulos)
        if [[ "$line" =~ ^[A-Z][A-Z\ ]+[:.]?$ ]] || [[ "$line" =~ ^[0-9]+[\.\ )]+[A-Za-z] ]]; then
            if [[ -n "$current_section" ]]; then
                sections+=("$current_section: $line_count lineas")
            fi
            current_section="$line"
            line_count=0
        else
            line_count=$((line_count + 1))
        fi
    done <<< "$text"
    
    if [[ -n "$current_section" ]]; then
        sections+=("$current_section: $line_count lineas")
    fi
    
    if [[ ${#sections[@]} -eq 0 ]]; then
        echo "  Examen sin secciones claras"
    else
        echo "  Secciones detectadas:"
        for section in "${sections[@]}"; do
            echo "    - $section"
        done
    fi
}

# -----------------------------------------------------------------------------
# Comparar examenes
# -----------------------------------------------------------------------------
compare_exams() {
    local file1="$1"
    local file2="$2"
    
    study_info "Comparando examenes: $file1 vs $file2"
    
    # Extraer texto
    local text1
    text1=$(study_extract_text "$file1")
    local text2
    text2=$(study_extract_text "$file2")
    
    if [[ -z "$text1" || -z "$text2" ]]; then
        study_error "No se pudo extraer texto de los examenes"
        return 1
    fi
    
    # Calcular similaridad
    local similarity
    similarity=$(study_text_similarity "$text1" "$text2")
    
    # Extraer temas
    local topics1
    topics1=$(study_extract_keywords "$text1" 10)
    local topics2
    topics2=$(study_extract_keywords "$text2" 10)
    
    # Temas comunes
    local common_topics
    common_topics=$(echo -e "$topics1\n$topics2" | sort | uniq -d)
    
    echo "Similaridad entre examenes: ${similarity}%"
    echo ""
    echo "Temas en examen 1: $(echo "$topics1" | tr '\n' ' ')"
    echo "Temas en examen 2: $(echo "$topics2" | tr '\n' ' ')"
    echo "Temas comunes: $(echo "$common_topics" | tr '\n' ' ')"
}

# -----------------------------------------------------------------------------
# Punto de entrada
# -----------------------------------------------------------------------------
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        analyze)
            local file="$1"
            local subject="$2"
            local output_dir="$3"
            if [[ -z "$output_dir" ]]; then
                output_dir="$STUDY_EXAMS/analysis"
            fi
            analyze_exam "$file" "$subject" "$output_dir"
            ;;
        compare)
            local file1="$1"
            local file2="$2"
            compare_exams "$file1" "$file2"
            ;;
        help|--help|-h)
            echo "Uso: analyze-exam <comando>"
            echo ""
            echo "Comandos:"
            echo "  analyze <file> <subject> [output_dir]  - Analizar examen"
            echo "  compare <file1> <file2>                - Comparar dos examenes"
            echo "  help                                  - Mostrar ayuda"
            ;;
        *)
            study_error "Comando desconocido: $command"
            exit 1
            ;;
    esac
}

main "$@"
