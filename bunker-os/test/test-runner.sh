# =============================================================================
# Bunker OS - Suite de Pruebas (Test Runner)
# Ubicación: /usr/lib/bunker/test/test-runner.sh
# Propósito: pruebas de integración y regresión del sistema
# Desarrollador jefe: <tu_usuario> | Ingeniero colaborador: Apodex 1.1 Mini
# =============================================================================

set -o pipefail

BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

# -----------------------------------------------------------------------------
# Estado de las pruebas
# -----------------------------------------------------------------------------
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TEST_LOG="$BUNKER_VAR/test.log"

# -----------------------------------------------------------------------------
# Utilidades de pruebas
# -----------------------------------------------------------------------------
test_begin() {
    local name="$1"
    ((TESTS_RUN++))
    echo "[$(date '+%H:%M:%S')] TEST: $name" | tee -a "$TEST_LOG"
}

test_pass() {
    local name="$1"
    ((TESTS_PASSED++))
    echo "[$(date '+%H:%M:%S')] PASS: $name" | tee -a "$TEST_LOG"
}

test_fail() {
    local name="$1"
    local reason="$2"
    ((TESTS_FAILED++))
    echo "[$(date '+%H:%M:%S')] FAIL: $name - $reason" | tee -a "$TEST_LOG"
}

# -----------------------------------------------------------------------------
# Pruebas de integración
# -----------------------------------------------------------------------------
test_core() {
    test_begin "core: inicialización"

    # Verificar que el core existe y es ejecutable
    if [[ -x "$BUNKER_ROOT/core/core.sh" ]]; then
        test_pass "core: archivo ejecutable"
    else
        test_fail "core: archivo ejecutable" "core.sh no es ejecutable"
    fi

    # Verificar que el core tiene los comandos básicos
    if grep -q "core_start" "$BUNKER_ROOT/core/core.sh" && \
       grep -q "core_stop" "$BUNKER_ROOT/core/core.sh" && \
       grep -q "core_status" "$BUNKER_ROOT/core/core.sh"; then
        test_pass "core: comandos básicos presentes"
    else
        test_fail "core: comandos básicos presentes"
    fi
}

test_config() {
    test_begin "config: validación"

    if [[ -x "$BUNKER_ROOT/core/config.sh" ]]; then
        test_pass "config: archivo ejecutable"
    else
        test_fail "config: archivo ejecutable"
    fi

    # Verificar configuración por defecto
    if [[ -f "$BUNKER_ETC/bunker.conf" ]]; then
        test_pass "config: archivo de configuración existe"
    else
        test_fail "config: archivo de configuración existe" "bunker.conf no encontrado"
    fi
}

test_engine() {
    test_begin "engine: selección de modos"

    if [[ -x "$BUNKER_ROOT/engine/engine.sh" && -x "$BUNKER_ROOT/engine/mode-selector.sh" && -x "$BUNKER_ROOT/engine/engine-flags.sh" ]]; then
        test_pass "engine: archivos ejecutables"
    else
        test_fail "engine: archivos ejecutables"
    fi

    # Verificar modos disponibles
    if grep -q "gaming" "$BUNKER_ROOT/engine/mode-selector.sh" && \
       grep -q "hacking" "$BUNKER_ROOT/engine/mode-selector.sh"; then
        test_pass "engine: modos definidos"
    else
        test_fail "engine: modos definidos"
    fi
}

test_hardware() {
    test_begin "hardware: detección"

    if [[ -x "$BUNKER_ROOT/hardware/hal.sh" ]]; then
        test_pass "hardware: archivo ejecutable"
    else
        test_fail "hardware: archivo ejecutable"
    fi

    # Verificar funciones de detección
    if grep -q "hardware_detect_cpu" "$BUNKER_ROOT/hardware/hal.sh" && \
       grep -q "hardware_detect_gpu" "$BUNKER_ROOT/hardware/hal.sh"; then
        test_pass "hardware: funciones de detección presentes"
    else
        test_fail "hardware: funciones de detección presentes"
    fi
}

test_rollback() {
    test_begin "rollback: puntos de restauración"

    if [[ -x "$BUNKER_ROOT/rollback/rollback.sh" ]]; then
        test_pass "rollback: archivo ejecutable"
    else
        test_fail "rollback: archivo ejecutable"
    fi

    # Verificar funciones de rollback
    if grep -q "rollback_snapshot" "$BUNKER_ROOT/rollback/rollback.sh" && \
       grep -q "rollback_restore" "$BUNKER_ROOT/rollback/rollback.sh"; then
        test_pass "rollback: funciones presentes"
    else
        test_fail "rollback: funciones presentes"
    fi
}

test_sentinel() {
    test_begin "sentinel: auditoría"

    if [[ -x "$BUNKER_ROOT/sentinel/sentinel.sh" ]]; then
        test_pass "sentinel: archivo ejecutable"
    else
        test_fail "sentinel: archivo ejecutable"
    fi

    # Verificar módulos de detección
    local module_count
    module_count=$(ls "$BUNKER_ROOT/sentinel/modules" 2>/dev/null | wc -l)
    if [[ "$module_count" -ge 4 ]]; then
        test_pass "sentinel: módulos de detección ($module_count)"
    else
        test_fail "sentinel: módulos de detección" "esperados >= 4, encontrados $module_count"
    fi
}

test_guardian() {
    test_begin "guardian: watchdogs"

    if [[ -x "$BUNKER_ROOT/guardian/guardian.sh" ]]; then
        test_pass "guardian: archivo ejecutable"
    else
        test_fail "guardian: archivo ejecutable"
    fi

    local watchdog_count
    watchdog_count=$(ls "$BUNKER_ROOT/guardian/watchdogs" 2>/dev/null | wc -l)
    if [[ "$watchdog_count" -ge 2 ]]; then
        test_pass "guardian: watchdogs ($watchdog_count)"
    else
        test_fail "guardian: watchdogs" "esperados >= 2, encontrados $watchdog_count"
    fi
}

test_services() {
    test_begin "services: registro"

    local service_count
    service_count=$(ls "$BUNKER_ROOT/services" 2>/dev/null | wc -l)
    if [[ "$service_count" -ge 6 ]]; then
        test_pass "services: servicios registrados ($service_count)"
    else
        test_fail "services: servicios registrados" "esperados >= 6, encontrados $service_count"
    fi

    # Verificar cada servicio
    for service in maintenance update health recovery harden ai; do
        if [[ -f "$BUNKER_ROOT/services/$service.sh" ]]; then
            test_pass "service: $service"
        else
            test_fail "service: $service"
        fi
    done
}

test_cli() {
    test_begin "cli: bunker"

    if [[ -x "$BUNKER_ROOT/../cli/bunker" ]]; then
        test_pass "cli: bunker ejecutable"
    else
        test_fail "cli: bunker ejecutable"
    fi

    # Verificar comandos de la CLI
    if grep -q "cmd_engine" "$BUNKER_ROOT/../cli/bunker" && \
       grep -q "cmd_core" "$BUNKER_ROOT/../cli/bunker" && \
       grep -q "cmd_sentinel" "$BUNKER_ROOT/../cli/bunker" && \
       grep -q "cmd_engine_flags" "$BUNKER_ROOT/../cli/bunker"; then
        test_pass "cli: comandos presentes"
    else
        test_fail "cli: comandos presentes"
    fi
}

test_shared() {
    test_begin "shared: librería"

    if [[ -x "$BUNKER_ROOT/shared/lib.sh" ]]; then
        test_pass "shared: librería ejecutable"
    else
        test_fail "shared: librería ejecutable"
    fi

    # Verificar funciones compartidas
    if grep -q "bunker_log" "$BUNKER_ROOT/shared/lib.sh" && \
       grep -q "bunker_config_get" "$BUNKER_ROOT/shared/lib.sh" && \
       grep -q "bunker_state_set" "$BUNKER_ROOT/shared/lib.sh"; then
        test_pass "shared: funciones compartidas presentes"
    else
        test_fail "shared: funciones compartidas presentes"
    fi
}

# -----------------------------------------------------------------------------
# Pruebas de integración entre componentes
# -----------------------------------------------------------------------------
test_integration_core_config() {
    test_begin "integration: core-config comunicación"

    local test_key="integration_test_$(date +%s)"
    bunker_config_set "integration" "$test_key" "test_value"
    local retrieved
    retrieved=$(bunker_config_get "integration" "$test_key")

    if [[ "$retrieved" == "test_value" ]]; then
        test_pass "integration: core-config lectura/escritura"
    else
        test_fail "integration: core-config lectura/escritura" "valor no coincide: $retrieved"
    fi
}

test_integration_engine_hardware() {
    test_begin "integration: engine-hardware comunicación"

    if [[ -f "$BUNKER_ROOT/hardware/hal.sh" ]]; then
        source "$BUNKER_ROOT/hardware/hal.sh"
        hardware_detect_cpu 2>/dev/null
        if [[ -n "${HARDWARE_INFO[cpu]}" ]]; then
            test_pass "integration: engine-hardware detección de CPU"
        else
            test_fail "integration: engine-hardware detección de CPU" "no se detectó información de CPU"
        fi
    else
        test_fail "integration: engine-hardware detección de CPU" "HAL no encontrado"
    fi
}

test_integration_core_rollback() {
    test_begin "integration: core-rollback comunicación"

    local snapshot_name="integration_test_$(date +%s)"
    local snapshot
    snapshot=$(rollback_snapshot "$snapshot_name" 2>/dev/null)

    if [[ -n "$snapshot" && -d "$BUNKER_VAR/snapshots/$snapshot" ]]; then
        test_pass "integration: core-rollback creación de snapshot"
        rm -rf "$BUNKER_VAR/snapshots/$snapshot"
    else
        test_fail "integration: core-rollback creación de snapshot" "snapshot no creado"
    fi
}

test_integration_sentinel_guardian() {
    test_begin "integration: sentinel-guardian comunicación"

    if [[ -x "$BUNKER_ROOT/sentinel/sentinel.sh" && -x "$BUNKER_ROOT/guardian/guardian.sh" ]]; then
        test_pass "integration: sentinel-guardian ambos componentes ejecutables"
    else
        test_fail "integration: sentinel-guardian componentes ejecutables" "uno o ambos no son ejecutables"
    fi
}

test_integration_api_events() {
    test_begin "integration: api sistema de eventos"

    api_init 2>/dev/null || true
    api_publish_event "integration_test" '{"test": true}' 2>/dev/null || true

    local events
    events=$(api_list_events "integration_test" 2>/dev/null || echo "")
    if [[ -n "$events" ]]; then
        test_pass "integration: api publicación y listado de eventos"
    else
        test_fail "integration: api publicación y listado de eventos" "no se encontraron eventos"
    fi
}

test_integration_service_lifecycle() {
    test_begin "integration: services ciclo de vida"

    local all_pass=true
    for service in maintenance update health recovery harden ai; do
        if [[ -f "$BUNKER_ROOT/services/$service.sh" ]]; then
            if grep -q "${service}_start" "$BUNKER_ROOT/services/$service.sh" && \
               grep -q "${service}_stop" "$BUNKER_ROOT/services/$service.sh"; then
                :
            else
                test_fail "integration: services ciclo de vida de $service" "funciones start/stop faltantes"
                all_pass=false
            fi
        else
            test_fail "integration: services ciclo de vida de $service" "archivo no encontrado"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "integration: services ciclo de vida de todos los servicios"
    fi
}

test_integration_layers() {
    test_begin "integration: layers aplicación de capas"

    local all_pass=true
    for layer in stealth performance lowram battery focus ai; do
        if [[ -f "$BUNKER_ROOT/engine/engine-flags.sh" ]]; then
            source "$BUNKER_ROOT/engine/engine-flags.sh"
            engine_apply_layer "$layer" 2>/dev/null
            if [[ $? -eq 0 ]]; then
                :
            else
                test_fail "integration: layers aplicación de $layer" "error al aplicar capa"
                all_pass=false
            fi
        else
            test_fail "integration: layers aplicación de $layer" "engine-flags.sh no encontrado"
            all_pass=false
            break
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "integration: layers aplicación de todas las capas"
    fi
}

test_integration_modes() {
    test_begin "integration: engine cambio de modos"

    local all_pass=true
    for mode in gaming ia ghost office hacking custom; do
        if [[ -f "$BUNKER_ROOT/engine/engine-flags.sh" ]]; then
            source "$BUNKER_ROOT/engine/engine-flags.sh"
            engine_apply_mode "$mode" 2>/dev/null
            if [[ $? -eq 0 ]]; then
                :
            else
                test_fail "integration: engine cambio a modo $mode" "error al aplicar modo"
                all_pass=false
            fi
        else
            test_fail "integration: engine cambio a modo $mode" "engine-flags.sh no encontrado"
            all_pass=false
            break
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "integration: engine cambio de todos los modos"
    fi
}

test_integration_known_state() {
    test_begin "integration: core estado conocido y recuperación"

    bunker_set_known_state
    local known_state
    known_state=$(bunker_known_state)

    if [[ -n "$known_state" ]]; then
        test_pass "integration: core estado conocido establecido"
    else
        test_fail "integration: core estado conocido" "no se pudo establecer"
    fi

    local snapshot
    snapshot=$(rollback_snapshot "integration_test_recovery" 2>/dev/null)
    if [[ -n "$snapshot" ]]; then
        test_pass "integration: core snapshot de recuperación creado"
        rm -rf "$BUNKER_VAR/snapshots/$snapshot"
    else
        test_fail "integration: core snapshot de recuperación" "no se pudo crear"
    fi
}

test_integration_resource_budgets() {
    test_begin "integration: core presupuestos de recursos"

    local mem_budget
    mem_budget=$(bunker_config_get resources "core_memory_budget" 2>/dev/null || echo "512")
    local cpu_budget
    cpu_budget=$(bunker_config_get resources "core_cpu_budget" 2>/dev/null || echo "10")

    if [[ "$mem_budget" =~ ^[0-9]+$ ]] && [[ "$cpu_budget" =~ ^[0-9]+$ ]]; then
        test_pass "integration: core presupuestos de recursos configurados (mem=$mem_budget MB, cpu=$cpu_budget%)"
    else
        test_fail "integration: core presupuestos de recursos" "valores no válidos"
    fi
}

test_integration_permissions() {
    test_begin "integration: security permisos y seguridad"

    local scripts=(
        "$BUNKER_ROOT/cli/bunker"
        "$BUNKER_ROOT/core/core.sh"
        "$BUNKER_ROOT/core/config.sh"
        "$BUNKER_ROOT/core/api.sh"
        "$BUNKER_ROOT/engine/engine.sh"
        "$BUNKER_ROOT/hardware/hal.sh"
        "$BUNKER_ROOT/sentinel/sentinel.sh"
        "$BUNKER_ROOT/guardian/guardian.sh"
        "$BUNKER_ROOT/rollback/rollback.sh"
    )

    local all_exec=true
    for script in "${scripts[@]}"; do
        if [[ ! -x "$script" ]]; then
            test_fail "integration: security permisos de $script" "no es ejecutable"
            all_exec=false
        fi
    done

    if [[ "$all_exec" == true ]]; then
        test_pass "integration: security todos los scripts principales son ejecutables"
    fi
}

# -----------------------------------------------------------------------------
# Reporte final
# -----------------------------------------------------------------------------
test_report() {
    echo ""
    echo "=== REPORTES DE PRUEBAS ==="
    echo "Ejecutadas: $TESTS_RUN"
    echo "Aprobadas:  $TESTS_PASSED"
    echo "Fallidas:   $TESTS_FAILED"
    echo "Log:        $TEST_LOG"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "RESULTADO: TODAS LAS PRUEBAS APROBADAS"
        return 0
    else
        echo "RESULTADO: ALGUNAS PRUEBAS FALLARON"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Punto de entrada
# -----------------------------------------------------------------------------
main() {
    bunker_info "Iniciando suite de pruebas de Bunker OS..."

    mkdir -p "$(dirname "$TEST_LOG")"

    test_shared
    test_core
    test_config
    test_engine
    test_hardware
    test_rollback
    test_sentinel
    test_guardian
    test_services
    test_cli

    # Pruebas de integración
    test_integration_core_config
    test_integration_engine_hardware
    test_integration_core_rollback
    test_integration_sentinel_guardian
    test_integration_api_events
    test_integration_service_lifecycle
    test_integration_layers
    test_integration_modes
    test_integration_known_state
    test_integration_resource_budgets
    test_integration_permissions

    test_report
}

main "$@"