#!/bin/bash
# =============================================================================
# Bunker OS - Bunker Study - Interfaz CLI
# Ubicaci3n: /usr/lib/bunker/study/ui/study-cli.sh
# Propsito: Interfaz de linea de comandos para Bunker Study
# =============================================================================

set -o pipefail

BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"
source "$BUNKER_ROOT/study/lib/study-lib.sh"

# -----------------------------------------------------------------------------
# Colores
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Mostrar menu principal
# -----------------------------------------------------------------------------
show_main_menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}       BUNKER STUDY v$BUNKER_VERSION       ${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${GREEN}1${NC}. ${YELLOW}Mi Biblioteca${NC}"
    echo -e "${GREEN}2${NC}. ${YELLOW}Resumenes${NC}"
    echo -e "${GREEN}3${NC}. ${YELLOW}Investigacion Academica${NC}"
    echo -e "${GREEN}4${NC}. ${YELLOW}Examenes Anteriores${NC}"
    echo -e "${GREEN}5${NC}. ${YELLOW}Perfil Docente${NC}"
    echo -e "${GREEN}6${NC}. ${YELLOW}Simulacros${NC}"
    echo -e "${GREEN}7${NC}. ${YELLOW}Correccion${NC}"
    echo -e "${GREEN}8${NC}. ${YELLOW}Plan de Estudio${NC}"
    echo -e "${GREEN}9${NC}. ${YELLOW}Progreso${NC}"
    echo ""
    echo -e "${RED}0${NC}. ${YELLOW}Salir${NC}"
    echo ""
}

# -----------------------------------------------------------------------------
# Menu Biblioteca
# -----------------------------------------------------------------------------
show_library_menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}          MI BIBLIOTECA              ${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${GREEN}1${NC}. ${YELLOW}Agregar documento${NC}"
    echo -e "${GREEN}2${NC}. ${YELLOW}Listar documentos${NC}"
    echo -e "${GREEN}3${NC}. ${YELLOW}Buscar documentos${NC}"
    echo -e "${GREEN}4${NC}. ${YELLOW}Organizar por asignatura${NC}"
    echo ""
    echo -e "${RED}0${NC}. ${YELLOW}Volver${NC}"
    echo ""
}

# -----------------------------------------------------------------------------
# Menu Resumenes
# -----------------------------------------------------------------------------
show_summaries_menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}           RESUMENES                 ${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${GREEN}1${NC}. ${YELLOW}Generar resumen${NC}"
    echo -e "${GREEN}2${NC}. ${YELLOW}Resumen por capitulos${NC}"
    echo -e "${GREEN}3${NC}. ${YELLOW}Extraer conceptos clave${NC}"
    echo -e "${GREEN}4${NC}. ${YELLOW}Crear glosario${NC}"
    echo -e "${GREEN}5${NC}. ${YELLOW}Listar resumenes${NC}"
    echo ""
    echo -e "${RED}0${NC}. ${YELLOW}Volver${NC}"
    echo ""
}

# -----------------------------------------------------------------------------
# Menu Investigacion Academica
# -----------------------------------------------------------------------------
show_research_menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}      INVESTIGACION ACADEMICA         ${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${GREEN}1${NC}. ${YELLOW}Buscar libros${NC}"
    echo -e "${GREEN}2${NC}. ${YELLOW}Buscar manuales${NC}"
    echo -e "${GREEN}3${NC}. ${YELLOW}Buscar recursos educativos${NC}"
    echo -e "${GREEN}4${NC}. ${YELLOW}Identificar autores${NC}"
    echo -e "${GREEN}5${NC}. ${YELLOW}Localizar recursos gratuitos${NC}"
    echo ""
    echo -e "${RED}0${NC}. ${YELLOW}Volver${NC}"
    echo ""
}

# -----------------------------------------------------------------------------
# Menu Examenes Anteriores
# -----------------------------------------------------------------------------
show_exams_menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}        EXAMENES ANTERIORES           ${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${GREEN}1${NC}. ${YELLOW}Importar examen${NC}"
    echo -e "${GREEN}2${NC}. ${YELLOW}Analizar examen${NC}"
    echo -e "${GREEN}3${NC}. ${YELLOW}Identificar temas recurrentes${NC}"
    echo -e "${GREEN}4${NC}. ${YELLOW}Detectar estructuras de preguntas${NC}"
    echo -e "${GREEN}5${NC}. ${YELLOW}Clasificar dificultad${NC}"
    echo -e "${GREEN}6${NC}. ${YELLOW}Generar estadisticas${NC}"
    echo ""
    echo -e "${RED}0${NC}. ${YELLOW}Volver${NC}"
    echo ""
}

# -----------------------------------------------------------------------------
# Menu Perfil Docente
# -----------------------------------------------------------------------------
show_profile_menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}        PERFIL DOCENTE               ${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${GREEN}1${NC}. ${YELLOW}Crear perfil${NC}"
    echo -e "${GREEN}2${NC}. ${YELLOW}Actualizar perfil${NC}"
    echo -e "${GREEN}3${NC}. ${YELLOW}Analizar estilo de evaluacion${NC}"
    echo -e "${GREEN}4${NC}. ${YELLOW}Identificar criterios de puntuacion${NC}"
    echo -e "${GREEN}5${NC}. ${YELLOW}Listar perfiles${NC}"
    echo ""
    echo -e "${RED}0${NC}. ${YELLOW}Volver${NC}"
    echo ""
}

# -----------------------------------------------------------------------------
# Menu Plan de Estudio
# -----------------------------------------------------------------------------
show_plan_menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}        PLAN DE ESTUDIO               ${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${GREEN}1${NC}. ${YELLOW}Crear plan de estudio${NC}"
    echo -e "${GREEN}2${NC}. ${YELLOW}Distribuir asignaturas${NC}"
    echo -e "${GREEN}3${NC}. ${YELLOW}Organizar fechas de examenes${NC}"
    echo -e "${GREEN}4${NC}. ${YELLOW}Recomendar sesiones de repaso${NC}"
    echo -e "${GREEN}5${NC}. ${YELLOW}Detectar lagunas de conocimiento${NC}"
    echo -e "${GREEN}6${NC}. ${YELLOW}Generar informe de progreso${NC}"
    echo -e "${GREEN}7${NC}. ${YELLOW}Listar planes${NC}"
    echo ""
    echo -e "${RED}0${NC}. ${YELLOW}Volver${NC}"
    echo ""
}

# -----------------------------------------------------------------------------
# Acciones
# -----------------------------------------------------------------------------
do_library_add() {
    local file
    local subject
    
    read -p "Ruta del archivo: " file
    read -p "Asignatura: " subject
    
    if [[ -f "$file" ]]; then
        library_add "$file" "$subject"
        read -p "Presiona Enter para continuar..."
    else
        echo -e "${RED}Archivo no encontrado: $file${NC}"
        read -p "Presiona Enter para continuar..."
    fi
}

do_library_list() {
    echo -e "${CYAN}=== DOCUMENTOS EN BIBLIOTECA ===${NC}"
    library_list
    read -p "Presiona Enter para continuar..."
}

do_summarize() {
    local file
    local subject
    
    read -p "Ruta del archivo a resumir: " file
    read -p "Asignatura (opcional): " subject
    
    if [[ -f "$file" ]]; then
        local output="$STUDY_SUMMARIES/$(basename "$file").summary"
        summarize_document "$file" "$output"
        echo -e "${GREEN}Resumen generado: $output${NC}"
        read -p "Presiona Enter para continuar..."
    else
        echo -e "${RED}Archivo no encontrado: $file${NC}"
        read -p "Presiona Enter para continuar..."
    fi
}

do_exam_import() {
    local file
    local subject
    
    read -p "Ruta del examen: " file
    read -p "Asignatura: " subject
    
    if [[ -f "$file" ]]; then
        exam_import "$file" "$subject"
        read -p "Presiona Enter para continuar..."
    else
        echo -e "${RED}Archivo no encontrado: $file${NC}"
        read -p "Presiona Enter para continuar..."
    fi
}

do_profile_create() {
    local name
    local subject
    
    read -p "Nombre del docente: " name
    read -p "Asignatura: " subject
    
    profile_create "$name" "$subject"
    read -p "Presiona Enter para continuar..."
}

do_plan_create() {
    local name
    local subject
    local exam_date
    
    read -p "Nombre del plan: " name
    read -p "Asignatura: " subject
    read -p "Fecha del examen (YYYY-MM-DD): " exam_date
    
    plan_create "$name" "$subject" "$exam_date"
    read -p "Presiona Enter para continuar..."
}

# -----------------------------------------------------------------------------
# Bucle principal
# -----------------------------------------------------------------------------
main() {
    local running=true
    
    while $running; do
        show_main_menu
        read -p "Selecciona una opcion: " choice
        
        case "$choice" in
            1)
                # Mi Biblioteca
                local library_running=true
                while $library_running; do
                    show_library_menu
                    read -p "Selecciona una opcion: " lib_choice
                    case "$lib_choice" in
                        1) do_library_add ;;
                        2) do_library_list ;;
                        3)
                            read -p "Buscar: " query
                            library_search "$query"
                            read -p "Presiona Enter para continuar..."
                            ;;
                        4)
                            read -p "Asignatura: " subject
                            library_list "$subject"
                            read -p "Presiona Enter para continuar..."
                            ;;
                        0) library_running=false ;;
                        *) echo -e "${RED}Opcion invalida${NC}" ;;
                    esac
                done
                ;;
            2)
                # Resumenes
                local summaries_running=true
                while $summaries_running; do
                    show_summaries_menu
                    read -p "Selecciona una opcion: " sum_choice
                    case "$sum_choice" in
                        1) do_summarize ;;
                        2)
                            read -p "Ruta del archivo: " file
                            read -p "Directorio de salida: " output_dir
                            if [[ -z "$output_dir" ]]; then
                                output_dir="$STUDY_SUMMARIES/chapters"
                            fi
                            summarize_by_chapters "$file" "$output_dir"
                            read -p "Presiona Enter para continuar..."
                            ;;
                        3)
                            read -p "Ruta del archivo: " file
                            extract_key_concepts "$file" 20
                            read -p "Presiona Enter para continuar..."
                            ;;
                        4)
                            read -p "Ruta del archivo: " file
                            create_glossary "$file"
                            read -p "Presiona Enter para continuar..."
                            ;;
                        5)
                            echo -e "${CYAN}=== RESUMENES GENERADOS ===${NC}"
                            ls "$STUDY_SUMMARIES" 2>/dev/null
                            read -p "Presiona Enter para continuar..."
                            ;;
                        0) summaries_running=false ;;
                        *) echo -e "${RED}Opcion invalida${NC}" ;;
                    esac
                done
                ;;
            3)
                # Investigacion Academica
                local research_running=true
                while $research_running; do
                    show_research_menu
                    read -p "Selecciona una opcion: " res_choice
                    case "$res_choice" in
                        1|2|3|4|5)
                            echo -e "${YELLOW}Funcionalidad en desarrollo...${NC}"
                            read -p "Presiona Enter para continuar..."
                            ;;
                        0) research_running=false ;;
                        *) echo -e "${RED}Opcion invalida${NC}" ;;
                    esac
                done
                ;;
            4)
                # Examenes Anteriores
                local exams_running=true
                while $exams_running; do
                    show_exams_menu
                    read -p "Selecciona una opcion: " exam_choice
                    case "$exam_choice" in
                        1) do_exam_import ;;
                        2)
                            read -p "Ruta del examen: " file
                            read -p "Asignatura: " subject
                            analyze_exam "$file" "$subject" "$STUDY_EXAMS/analysis"
                            read -p "Presiona Enter para continuar..."
                            ;;
                        3|4|5|6)
                            echo -e "${YELLOW}Funcionalidad en desarrollo...${NC}"
                            read -p "Presiona Enter para continuar..."
                            ;;
                        0) exams_running=false ;;
                        *) echo -e "${RED}Opcion invalida${NC}" ;;
                    esac
                done
                ;;
            5)
                # Perfil Docente
                local profile_running=true
                while $profile_running; do
                    show_profile_menu
                    read -p "Selecciona una opcion: " prof_choice
                    case "$prof_choice" in
                        1) do_profile_create ;;
                        2|3|4)
                            echo -e "${YELLOW}Funcionalidad en desarrollo...${NC}"
                            read -p "Presiona Enter para continuar..."
                            ;;
                        5)
                            echo -e "${CYAN}=== PERFILES DOCENTES ===${NC}"
                            ls "$STUDY_PROFILES" 2>/dev/null
                            read -p "Presiona Enter para continuar..."
                            ;;
                        0) profile_running=false ;;
                        *) echo -e "${RED}Opcion invalida${NC}" ;;
                    esac
                done
                ;;
            6|7)
                # Simulacros y Correccion
                echo -e "${YELLOW}Funcionalidad en desarrollo...${NC}"
                read -p "Presiona Enter para continuar..."
                ;;
            8)
                # Plan de Estudio
                local plan_running=true
                while $plan_running; do
                    show_plan_menu
                    read -p "Selecciona una opcion: " plan_choice
                    case "$plan_choice" in
                        1) do_plan_create ;;
                        2|3|4|5|6)
                            echo -e "${YELLOW}Funcionalidad en desarrollo...${NC}"
                            read -p "Presiona Enter para continuar..."
                            ;;
                        7)
                            plan_list
                            read -p "Presiona Enter para continuar..."
                            ;;
                        0) plan_running=false ;;
                        *) echo -e "${RED}Opcion invalida${NC}" ;;
                    esac
                done
                ;;
            9)
                # Progreso
                echo -e "${YELLOW}Funcionalidad en desarrollo...${NC}"
                read -p "Presiona Enter para continuar..."
                ;;
            0)
                running=false
                ;;
            *)
                echo -e "${RED}Opcion invalida. Intenta de nuevo.${NC}"
                read -p "Presiona Enter para continuar..."
                ;;
        esac
    done
    
    echo -e "${GREEN}Gracias por usar Bunker Study!${NC}"
}

main "$@"
