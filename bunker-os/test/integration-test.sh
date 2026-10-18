#!/bin/bash
# =============================================================================
# Bunker OS - Pruebas de Integración
# Ubicación: /usr/lib/bunker/test/integration-test.sh
# Propósito: verificar comunicación entre componentes, flujos de trabajo
# Desarrollador jefe: <tu_usuario> | Ingeniero colaborador: Apodex 1.1 Mini
# =============================================================================

set -o pipefail

BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

# -----------------------------------------------------------------------------
# Estado de pruebas
# -----------------------------------------------------------------------------
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TEST_LOG="$BUNKER_VAR/integration-test.log"

# -----------------------------------------------------------------------------
# Utilidades
# -----------------------------------------------------------------------------
test_begin() {
    local name="$1"
    ((TESTS_RUN++))
    echo "[$(date '+%H:%M:%S')] INTEGRATION TEST: $name" | tee -a "$TEST_LOG"
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
# Pruebas de comunicación entre componentes
# -----------------------------------------------------------------------------
test_core_config_communication() {
    test_begin "core-config: comunicación"

    # Verificar que core puede leer/escribir configuración
    local test_key="integration_test_$(date +%s)"
    bunker_config_set "integration" "$test_key" "test_value"
    local retrieved
    retrieved=$(bunker_config_get "integration" "$test_key")

    if [[ "$retrieved" == "test_value" ]]; then
        test_pass "core-config: lectura/escritura de configuración"
    else
        test_fail "core-config: lectura/escritura" "valor no coincide: $retrieved"
    fi

    # Limpiar
    bunker_state_clear "$test_key" 2>/dev/null || true
}

test_engine_hardware_communication() {
    test_begin "engine-hardware: comunicación"

    # Verificar que engine puede llamar a HAL
    if [[ -f "$BUNKER_ROOT/hardware/hal.sh" ]]; then
        source "$BUNKER_ROOT/hardware/hal.sh"
        hardware_detect_cpu 2>/dev/null
        if [[ -n "${HARDWARE_INFO[cpu]}" ]]; then
            test_pass "engine-hardware: detección de CPU"
        else
            test_fail "engine-hardware: detección de CPU" "no se detectó información de CPU"
        fi
    else
        test_fail "engine-hardware: detección de CPU" "HAL no encontrado"
    fi
}

test_core_rollback_communication() {
    test_begin "core-rollback: comunicación"

    # Verificar que core puede crear snapshots de rollback
    local snapshot_name="integration_test_$(date +%s)"
    local snapshot
    snapshot=$(rollback_snapshot "$snapshot_name" 2>/dev/null)

    if [[ -n "$snapshot" && -d "$BUNKER_VAR/snapshots/$snapshot" ]]; then
        test_pass "core-rollback: creación de snapshot"
        # Limpiar
        rm -rf "$BUNKER_VAR/snapshots/$snapshot"
    else
        test_fail "core-rollback: creación de snapshot" "snapshot no creado"
    fi
}

test_sentinel_guardian_communication() {
    test_begin "sentinel-guardian: comunicación"

    # Verificar que ambos componentes existen y son ejecutables
    if [[ -x "$BUNKER_ROOT/sentinel/sentinel.sh" && -x "$BUNKER_ROOT/guardian/guardian.sh" ]]; then
        test_pass "sentinel-guardian: ambos componentes ejecutables"
    else
        test_fail "sentinel-guardian: componentes ejecutables" "uno o ambos no son ejecutables"
    fi
}

test_api_event_system() {
    test_begin "api: sistema de eventos"

    # Verificar que la API puede publicar y listar eventos
    api_init 2>/dev/null || true
    api_publish_event "integration_test" '{"test": true}' 2>/dev/null || true

    local events
    events=$(api_list_events "integration_test" 2>/dev/null || echo "")
    if [[ -n "$events" ]]; then
        test_pass "api: publicación y listado de eventos"
    else
        test_fail "api: publicación y listado de eventos" "no se encontraron eventos"
    fi
}

test_service_lifecycle() {
    test_begin "services: ciclo de vida"

    local all_pass=true
    for service in maintenance update health recovery harden ai; do
        if [[ -f "$BUNKER_ROOT/services/$service.sh" ]]; then
            # Verificar que tiene funciones start y stop
            if grep -q "${service}_start" "$BUNKER_ROOT/services/$service.sh" && \
               grep -q "${service}_stop" "$BUNKER_ROOT/services/$service.sh"; then
                :
            else
                test_fail "services: ciclo de vida de $service" "funciones start/stop faltantes"
                all_pass=false
            fi
        else
            test_fail "services: ciclo de vida de $service" "archivo no encontrado"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "services: ciclo de vida de todos los servicios"
    fi
}

test_layer_application() {
    test_begin "layers: aplicación de capas"

    local all_pass=true
    for layer in stealth performance lowram battery focus ai; do
        if [[ -f "$BUNKER_ROOT/engine/engine-flags.sh" ]]; then
            source "$BUNKER_ROOT/engine/engine-flags.sh"
            engine_apply_layer "$layer" 2>/dev/null
            if [[ $? -eq 0 ]]; then
                :
            else
                test_fail "layers: aplicación de $layer" "error al aplicar capa"
                all_pass=false
            fi
        else
            test_fail "layers: aplicación de $layer" "engine-flags.sh no encontrado"
            all_pass=false
            break
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "layers: aplicación de todas las capas"
    fi
}

test_mode_switching() {
    test_begin "engine: cambio de modos"

    local all_pass=true
    for mode in gaming ia ghost office hacking custom; do
        if [[ -f "$BUNKER_ROOT/engine/engine-flags.sh" ]]; then
            source "$BUNKER_ROOT/engine/engine-flags.sh"
            engine_apply_mode "$mode" 2>/dev/null
            if [[ $? -eq 0 ]]; then
                :
            else
                test_fail "engine: cambio a modo $mode" "error al aplicar modo"
                all_pass=false
            fi
        else
            test_fail "engine: cambio a modo $mode" "engine-flags.sh no encontrado"
            all_pass=false
            break
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "engine: cambio de todos los modos"
    fi
}

test_known_state_and_recovery() {
    test_begin "core: estado conocido y recuperación"

    # Establecer estado conocido
    bunker_set_known_state
    local known_state
    known_state=$(bunker_known_state)

    if [[ -n "$known_state" ]]; then
        test_pass "core: estado conocido establecido"
    else
        test_fail "core: estado conocido" "no se pudo establecer"
    fi

    # Verificar que se puede crear snapshot antes de cambios
    local snapshot
    snapshot=$(rollback_snapshot "integration_test_recovery" 2>/dev/null)
    if [[ -n "$snapshot" ]]; then
        test_pass "core: snapshot de recuperación creado"
        rm -rf "$BUNKER_VAR/snapshots/$snapshot"
    else
        test_fail "core: snapshot de recuperación" "no se pudo crear"
    fi
}

test_resource_budgets() {
    test_begin "core: presupuestos de recursos"

    local mem_budget
    mem_budget=$(bunker_config_get resources "core_memory_budget" 2>/dev/null || echo "512")
    local cpu_budget
    cpu_budget=$(bunker_config_get resources "core_cpu_budget" 2>/dev/null || echo "10")

    if [[ "$mem_budget" =~ ^[0-9]+$ ]] && [[ "$cpu_budget" =~ ^[0-9]+$ ]]; then
        test_pass "core: presupuestos de recursos configurados (mem=$mem_budget MB, cpu=$cpu_budget%)"
    else
        test_fail "core: presupuestos de recursos" "valores no válidos"
    fi
}

test_permissions_and_security() {
    test_begin "security: permisos y seguridad"

    # Verificar que los scripts principales son ejecutables
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
            test_fail "security: permisos de $script" "no es ejecutable"
            all_exec=false
        fi
    done

    if [[ "$all_exec" == true ]]; then
        test_pass "security: todos los scripts principales son ejecutables"
    fi

    # Verificar que los unit files de systemd existen
    local units=(
        "$BUNKER_ROOT/../base/systemd/bunker-core.service"
        "$BUNKER_ROOT/../base/systemd/bunker-guardian.service"
        "$BUNKER_ROOT/../base/systemd/bunker-sentinel.service"
    )

    local all_units=true
    for unit in "${units[@]}"; do
        if [[ ! -f "$unit" ]]; then
            test_fail "security: unit de systemd $unit" "no encontrado"
            all_units=false
        fi
    done

    if [[ "$all_units" == true ]]; then
        test_pass "security: units de systemd presentes"
    fi
}

# -----------------------------------------------------------------------------
# Reporte final
# -----------------------------------------------------------------------------
test_report() {
    echo ""
    echo "=== REPORTE DE PRUEBAS DE INTEGRACIÓN ==="
    echo "Ejecutadas: $TESTS_RUN"
    echo "Aprobadas:  $TESTS_PASSED"
    echo "Fallidas:   $TESTS_FAILED"
    echo "Log:        $TEST_LOG"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "RESULTADO: TODAS LAS PRUEBAS DE INTEGRACIÓN APROBADAS"
        return 0
    else
        echo "RESULTADO: ALGUNAS PRUEBAS DE INTEGRACIÓN FALLARON"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Punto de entrada
# -----------------------------------------------------------------------------
main() {
    bunker_info "Iniciando pruebas de integración de Bunker OS..."

    mkdir -p "$(dirname "$TEST_LOG")"

    test_core_config_communication
    test_engine_hardware_communication
    test_core_rollback_communication
    test_sentinel_guardian_communication
    test_api_event_system
    test_service_lifecycle
    test_layer_application
    test_mode_switching
    test_known_state_and_recovery
    test_resource_budgets
    test_permissions_and_security

    test_report
}

main "$@"