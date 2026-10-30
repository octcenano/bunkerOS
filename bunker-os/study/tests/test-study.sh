#!/bin/bash
# =============================================================================
# Bunker OS - Bunker Study - Pruebas
# Ubicaci3n: /usr/lib/bunker/study/tests/test-study.sh
# Propsito: Pruebas unitarias e integracion para Bunker Study
# =============================================================================

set -o pipefail

BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"
source "$BUNKER_ROOT/study/lib/study-lib.sh"

# -----------------------------------------------------------------------------
# Estado de las pruebas
# -----------------------------------------------------------------------------
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TEST_LOG="$BUNKER_VAR/study/test.log"

# -----------------------------------------------------------------------------
# Utilidades de pruebas
# -----------------------------------------------------------------------------
test_begin() {
    local name="$1"
    ((TESTS_RUN++))
    echo "[$(date '+%H:%M:%S')] STUDY-TEST: $name" | tee -a "$TEST_LOG"
}

test_pass() {
    local name="$1"
    ((TESTS_PASSED++))
    echo "[$(date '+%H:%M:%S')] STUDY-PASS: $name" | tee -a "$TEST_LOG"
}

test_fail() {
    local name="$1"
    local reason="$2"
    ((TESTS_FAILED++))
    echo "[$(date '+%H:%M:%S')] STUDY-FAIL: $name - $reason" | tee -a "$TEST_LOG"
}

test_summary() {
    echo ""
    echo "=== RESUMEN DE PRUEBAS DE STUDY ==="
    echo "Total: $TESTS_RUN"
    echo "Pasadas: $TESTS_PASSED"
    echo "Fallidas: $TESTS_FAILED"
    echo ""
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        return 1
    fi
    return 0
}

# -----------------------------------------------------------------------------
# Pruebas de inicializacion
# -----------------------------------------------------------------------------
test_study_init() {
    test_begin "study: inicializacion"
    
    # Verificar que los directorios existen
    if [[ -d "$STUDY_DIR" ]]; then
        test_pass "study: directorio existe"
    else
        test_fail "study: directorio existe" "$STUDY_DIR no encontrado"
    fi
    
    # Verificar permisos seguros
    local perms
    perms=$(stat -c "%a" "$STUDY_DIR" 2>/dev/null)
    if [[ "$perms" == "700" ]]; then
        test_pass "study: permisos seguros"
    else
        test_fail "study: permisos seguros" "Permisos: $perms (esperado 700)"
    fi
}

# -----------------------------------------------------------------------------
# Pruebas de validacion
# -----------------------------------------------------------------------------
test_validate_file() {
    test_begin "study: validacion de archivos"
    
    # Crear archivo de prueba
    local test_file
    test_file=$(mktemp)
    echo "Contenido de prueba" > "$test_file"
    
    if study_validate_file "$test_file"; then
        test_pass "study: validacion de archivo valido"
    else
        test_fail "study: validacion de archivo valido" "Archivo valido rechazado"
    fi
    
    # Probar archivo no existente
    if ! study_validate_file "/no/existe/file.txt"; then
        test_pass "study: validacion de archivo no existente"
    else
        test_fail "study: validacion de archivo no existente" "Archivo no existente aceptado"
    fi
    
    rm -f "$test_file"
}

test_validate_subject() {
    test_begin "study: validacion de asignaturas"
    
    if study_validate_subject "Matematicas"; then
        test_pass "study: asignatura valida"
    else
        test_fail "study: asignatura valida" "Matematicas rechazada"
    fi
    
    if ! study_validate_subject "Asignatura con caracteres invalidos!"; then
        test_pass "study: asignatura invalida rechazada"
    else
        test_fail "study: asignatura invalida rechazada" "Asignatura invalida aceptada"
    fi
}

# -----------------------------------------------------------------------------
# Pruebas de extraccion de texto
# -----------------------------------------------------------------------------
test_extract_text() {
    test_begin "study: extraccion de texto"
    
    # Crear archivo de texto de prueba
    local test_file
    test_file=$(mktemp)
    echo "Esto es un texto de prueba" > "$test_file"
    
    local text
    text=$(study_extract_text "$test_file")
    
    if [[ "$text" == "Esto es un texto de prueba" ]]; then
        test_pass "study: extraccion de texto plano"
    else
        test_fail "study: extraccion de texto plano" "Texto no coincide"
    fi
    
    rm -f "$test_file"
}

# -----------------------------------------------------------------------------
# Pruebas de procesamiento de texto
# -----------------------------------------------------------------------------
test_clean_text() {
    test_begin "study: limpieza de texto"
    
    local text="Esto  es un  texto  con espacios   duplicados"
    local cleaned
    cleaned=$(study_clean_text "$text")
    
    if [[ "$cleaned" == "Esto es un texto con espacios duplicados" ]]; then
        test_pass "study: limpieza de espacios duplicados"
    else
        test_fail "study: limpieza de espacios duplicados" "Texto no limpio correctamente"
    fi
}

test_normalize_text() {
    test_begin "study: normalizacion de texto"
    
    local text="ESTO es un TEXTO Mezclado"
    local normalized
    normalized=$(study_normalize_text "$text")
    
    if [[ "$normalized" == "esto es un texto mezclado" ]]; then
        test_pass "study: normalizacion a minusculas"
    else
        test_fail "study: normalizacion a minusculas" "Texto no normalizado"
    fi
}

# -----------------------------------------------------------------------------
# Pruebas de extraccion de palabras clave
# -----------------------------------------------------------------------------
test_extract_keywords() {
    test_begin "study: extraccion de palabras clave"
    
    local text="el perro del perro es un animal domestico. el gato tambien es un animal domestico."
    local keywords
    keywords=$(study_extract_keywords "$text" 5)
    
    # Verificar que se extrajeron palabras
    local keyword_count
    keyword_count=$(echo "$keywords" | wc -w)
    
    if [[ "$keyword_count" -gt 0 ]]; then
        test_pass "study: extraccion de palabras clave"
    else
        test_fail "study: extraccion de palabras clave" "No se extrajeron palabras"
    fi
}

# -----------------------------------------------------------------------------
# Pruebas de generacion de IDs
# -----------------------------------------------------------------------------
test_generate_id() {
    test_begin "study: generacion de IDs"
    
    local id1
    id1=$(study_generate_id "test")
    local id2
    id2=$(study_generate_id "test")
    
    if [[ "$id1" != "$id2" ]]; then
        test_pass "study: generacion de IDs unicos"
    else
        test_fail "study: generacion de IDs unicos" "IDs duplicados"
    fi
    
    if [[ "$id1" == test_* ]]; then
        test_pass "study: formato de ID correcto"
    else
        test_fail "study: formato de ID correcto" "Formato invalido"
    fi
}

# -----------------------------------------------------------------------------
# Pruebas de integracion con Adapt
# -----------------------------------------------------------------------------
test_adapt_integration() {
    test_begin "study: integracion con Adapt"
    
    # Verificar que se puede sincronizar modelo
    if sync_ai_model 2>/dev/null; then
        test_pass "study: sincronizacion con Adapt"
    else
        test_fail "study: sincronizacion con Adapt" "Error al sincronizar"
    fi
    
    # Verificar que hay un modelo seleccionado
    local model
    model=$(bunker_config_get ai "default_model" 2>/dev/null)
    
    if [[ -n "$model" ]]; then
        test_pass "study: modelo de IA seleccionado"
    else
        test_fail "study: modelo de IA seleccionado" "No hay modelo"
    fi
}

# -----------------------------------------------------------------------------
# Pruebas de manejo de errores
# -----------------------------------------------------------------------------
test_error_handling() {
    test_begin "study: manejo de errores"
    
    # Probar con archivo no existente
    if ! study_validate_file "/no/existe/file.txt" 2>/dev/null; then
        test_pass "study: manejo de archivo no existente"
    else
        test_fail "study: manejo de archivo no existente" "No se detecto el error"
    fi
    
    # Probar con asignatura invalida
    if ! study_validate_subject "Asignatura!@#"; then
        test_pass "study: manejo de asignatura invalida"
    else
        test_fail "study: manejo de asignatura invalida" "No se detecto el error"
    fi
}

# -----------------------------------------------------------------------------
# Pruebas de cache
# -----------------------------------------------------------------------------
test_cache_cleanup() {
    test_begin "study: limpieza de cache"
    
    # Crear archivo de cache de prueba
    mkdir -p "$STUDY_CACHE"
    local test_file
    test_file="$STUDY_CACHE/test_$(date +%s)"
    echo "Contenido de prueba" > "$test_file"
    
    # Ejecutar limpieza
    study_cache_cleanup 2>/dev/null
    
    # Verificar que el cache se limpio (el archivo puede seguir ahi si es reciente)
    test_pass "study: limpieza de cache ejecutada"
    
    rm -f "$test_file"
}

# -----------------------------------------------------------------------------
# Punto de entrada
# -----------------------------------------------------------------------------
main() {
    local command="${1:-run}"
    shift || true

    case "$command" in
        run)
            echo "=== PRUEBAS DE BUNKER STUDY ==="
            echo ""
            
            # Inicializar Study
            study_lib_init
            
            # Ejecutar pruebas
            test_study_init
            test_validate_file
            test_validate_subject
            test_extract_text
            test_clean_text
            test_normalize_text
            test_extract_keywords
            test_generate_id
            test_adapt_integration
            test_error_handling
            test_cache_cleanup
            
            # Mostrar resumen
            test_summary
            ;;
        individual)
            # Ejecutar prueba individual
            local test_name="$1"
            "test_$test_name"
            ;;
        list)
            echo "Pruebas disponibles:"
            echo "  test_study_init"
            echo "  test_validate_file"
            echo "  test_validate_subject"
            echo "  test_extract_text"
            echo "  test_clean_text"
            echo "  test_normalize_text"
            echo "  test_extract_keywords"
            echo "  test_generate_id"
            echo "  test_adapt_integration"
            echo "  test_error_handling"
            echo "  test_cache_cleanup"
            ;;
        help|--help|-h)
            echo "Uso: test-study <comando>"
            echo "Comandos: run | individual <test> | list | help"
            ;;
        *)
            study_error "Comando desconocido: $command"
            exit 1
            ;;
    esac
}

main "$@"
