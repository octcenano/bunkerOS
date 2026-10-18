#!/bin/bash
# =============================================================================
# Bunker OS - Pruebas de Regresión
# Ubicación: /usr/lib/bunker/test/regression-test.sh
# Propósito: verificar que cambios no rompan funcionalidad existente
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
TEST_LOG="$BUNKER_VAR/regression-test.log"

# -----------------------------------------------------------------------------
# Utilidades
# -----------------------------------------------------------------------------
test_begin() {
    local name="$1"
    ((TESTS_RUN++))
    echo "[$(date '+%H:%M:%S')] REGRESSION TEST: $name" | tee -a "$TEST_LOG"
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
# Pruebas de regresión por componente
# -----------------------------------------------------------------------------
test_cli_commands() {
    test_begin "cli: comandos existentes"

    local commands=(
        "engine"
        "core"
        "config"
        "api"
        "hardware"
        "rollback"
        "service"
        "layer"
        "sentinel"
        "guardian"
        "update"
        "status"
        "help"
    )

    local all_pass=true
    for cmd in "${commands[@]}"; do
        if grep -q "cmd_${cmd}" "$BUNKER_ROOT/../cli/bunker" 2>/dev/null; then
            :
        else
            test_fail "cli: comando $cmd" "no encontrado en CLI"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "cli: todos los comandos existentes presentes"
    fi
}

test_core_functions() {
    test_begin "core: funciones existentes"

    local functions=(
        "core_start"
        "core_stop"
        "core_status"
        "detect_hardware"
        "select_engine_mode"
        "apply_system_layers"
        "start_system_services"
        "stop_system_services"
        "core_post_install"
    )

    local all_pass=true
    for func in "${functions[@]}"; do
        if grep -q "^${func}()" "$BUNKER_ROOT/core/core.sh" 2>/dev/null; then
            :
        else
            test_fail "core: función $func" "no encontrada"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "core: todas las funciones existentes presentes"
    fi
}

test_config_functions() {
    test_begin "config: funciones existentes"

    local functions=(
        "config_init"
        "config_get"
        "config_set"
        "config_validate"
        "config_migrate"
        "config_backup"
        "config_restore"
        "config_export_json"
    )

    local all_pass=true
    for func in "${functions[@]}"; do
        if grep -q "^${func}()" "$BUNKER_ROOT/core/config.sh" 2>/dev/null; then
            :
        else
            test_fail "config: función $func" "no encontrada"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "config: todas las funciones existentes presentes"
    fi
}

test_api_functions() {
    test_begin "api: funciones existentes"

    local functions=(
        "api_init"
        "api_send"
        "api_receive"
        "api_publish_event"
        "api_subscribe_event"
        "api_list_events"
        "api_query_core"
        "api_get_resources"
        "api_audit_log"
    )

    local all_pass=true
    for func in "${functions[@]}"; do
        if grep -q "^${func}()" "$BUNKER_ROOT/core/api.sh" 2>/dev/null; then
            :
        else
            test_fail "api: función $func" "no encontrada"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "api: todas las funciones existentes presentes"
    fi
}

test_engine_functions() {
    test_begin "engine: funciones existentes"

    local functions=(
        "engine_init"
        "engine_run"
        "engine_main_loop"
        "health_check"
    )

    local all_pass=true
    for func in "${functions[@]}"; do
        if grep -q "^${func}()" "$BUNKER_ROOT/engine/engine.sh" 2>/dev/null; then
            :
        else
            test_fail "engine: función $func" "no encontrada"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "engine: todas las funciones existentes presentes"
    fi
}

test_mode_selector_functions() {
    test_begin "mode-selector: funciones existentes"

    local functions=(
        "detect_hardware_for_mode"
        "run_mode_wizard"
        "apply_mode"
        "tune_gaming"
        "tune_ai_local"
        "tune_ghost"
        "tune_office"
        "tune_hacking"
    )

    local all_pass=true
    for func in "${functions[@]}"; do
        if grep -q "^${func}()" "$BUNKER_ROOT/engine/mode-selector.sh" 2>/dev/null; then
            :
        else
            test_fail "mode-selector: función $func" "no encontrada"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "mode-selector: todas las funciones existentes presentes"
    fi
}

test_hal_functions() {
    test_begin "hal: funciones existentes"

    local functions=(
        "hardware_detect_all"
        "hardware_detect_cpu"
        "hardware_detect_gpu"
        "hardware_detect_ram"
        "hardware_detect_storage"
        "hardware_detect_network"
        "hardware_detect_audio"
        "hardware_detect_peripherals"
        "hardware_info"
        "hardware_optimize"
    )

    local all_pass=true
    for func in "${functions[@]}"; do
        if grep -q "^${func}()" "$BUNKER_ROOT/hardware/hal.sh" 2>/dev/null; then
            :
        else
            test_fail "hal: función $func" "no encontrada"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "hal: todas las funciones existentes presentes"
    fi
}

test_rollback_functions() {
    test_begin "rollback: funciones existentes"

    local functions=(
        "rollback_init"
        "rollback_snapshot"
        "rollback_list"
        "rollback_restore"
        "rollback_verify"
        "rollback_on_failure"
    )

    local all_pass=true
    for func in "${functions[@]}"; do
        if grep -q "^${func}()" "$BUNKER_ROOT/rollback/rollback.sh" 2>/dev/null; then
            :
        else
            test_fail "rollback: función $func" "no encontrada"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "rollback: todas las funciones existentes presentes"
    fi
}

test_sentinel_functions() {
    test_begin "sentinel: funciones existentes"

    local functions=(
        "sentinel_start"
        "sentinel_stop"
        "sentinel_status"
        "load_detection_modules"
        "correlate_incidents"
        "generate_hypothesis"
        "test_hypothesis"
        "remediate"
        "sentinel_main_loop"
    )

    local all_pass=true
    for func in "${functions[@]}"; do
        if grep -q "^${func}()" "$BUNKER_ROOT/sentinel/sentinel.sh" 2>/dev/null; then
            :
        else
            test_fail "sentinel: función $func" "no encontrada"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "sentinel: todas las funciones existentes presentes"
    fi
}

test_guardian_functions() {
    test_begin "guardian: funciones existentes"

    local functions=(
        "guardian_start"
        "guardian_stop"
        "guardian_status"
        "start_watchdogs"
        "start_daemons"
        "guardian_main_loop"
        "health_check"
        "enforce_policies"
        "auto_repair"
    )

    local all_pass=true
    for func in "${functions[@]}"; do
        if grep -q "^${func}()" "$BUNKER_ROOT/guardian/guardian.sh" 2>/dev/null; then
            :
        else
            test_fail "guardian: función $func" "no encontrada"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "guardian: todas las funciones existentes presentes"
    fi
}

test_service_functions() {
    test_begin "services: funciones existentes"

    local services=("maintenance" "update" "health" "recovery" "harden" "ai")
    local all_pass=true

    for service in "${services[@]}"; do
        if [[ -f "$BUNKER_ROOT/services/${service}.sh" ]]; then
            if grep -q "^${service}_start()" "$BUNKER_ROOT/services/${service}.sh" 2>/dev/null && \
               grep -q "^${service}_stop()" "$BUNKER_ROOT/services/${service}.sh" 2>/dev/null; then
                :
            else
                test_fail "services: $service" "funciones start/stop faltantes"
                all_pass=false
            fi
        else
            test_fail "services: $service" "archivo no encontrado"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "services: todos los servicios tienen funciones start/stop"
    fi
}

test_shared_functions() {
    test_begin "shared: funciones existentes"

    local functions=(
        "bunker_log"
        "bunker_debug"
        "bunker_info"
        "bunker_warn"
        "bunker_error"
        "bunker_exit"
        "bunker_require_root"
        "bunker_config_get"
        "bunker_config_set"
        "bunker_state_get"
        "bunker_state_set"
        "bunker_known_state"
        "bunker_set_known_state"
        "bunker_is_running"
        "bunker_write_pid"
        "bunker_remove_pid"
        "bunker_load_module"
    )

    local all_pass=true
    for func in "${functions[@]}"; do
        if grep -q "^${func}()" "$BUNKER_ROOT/shared/lib.sh" 2>/dev/null; then
            :
        else
            test_fail "shared: función $func" "no encontrada"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "shared: todas las funciones existentes presentes"
    fi
}

test_systemd_units() {
    test_begin "systemd: units existentes"

    local units=(
        "bunker-core.service"
        "bunker-guardian.service"
        "bunker-sentinel.service"
        "bunker-maintenance.service"
        "bunker-update.service"
        "bunker-health.service"
        "bunker-recovery.service"
        "bunker-harden.service"
        "bunker-ai.service"
    )

    local all_pass=true
    for unit in "${units[@]}"; do
        if [[ -f "$BUNKER_ROOT/../base/systemd/$unit" ]]; then
            :
        else
            test_fail "systemd: unit $unit" "no encontrado"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "systemd: todos los units presentes"
    fi
}

test_kernel_extension_files() {
    test_begin "kernel: archivos de extensión existentes"

    local files=(
        "kernel-extensions/bunker-core.c"
        "kernel-extensions/bunker-mm.S"
        "kernel-extensions/Makefile"
    )

    local all_pass=true
    for file in "${files[@]}"; do
        if [[ -f "$BUNKER_ROOT/../$file" ]]; then
            :
        else
            test_fail "kernel: archivo $file" "no encontrado"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "kernel: todos los archivos de extensión presentes"
    fi
}

test_driver_files() {
    test_begin "drivers: archivos existentes"

    local files=(
        "drivers/bpm/bpm.c"
        "drivers/Makefile"
    )

    local all_pass=true
    for file in "${files[@]}"; do
        if [[ -f "$BUNKER_ROOT/../$file" ]]; then
            :
        else
            test_fail "drivers: archivo $file" "no encontrado"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "drivers: todos los archivos presentes"
    fi
}

test_watchdogs_and_daemons() {
    test_begin "guardian: watchdogs y daemons"

    local watchdogs=(
        "watchdog_core.sh"
        "watchdog_memory.sh"
        "watchdog_security.sh"
        "watchdog_network.sh"
    )

    local daemons=(
        "daemon_evolution.sh"
        "daemon_hardware_adapt.sh"
        "daemon_sentinel_sync.sh"
        "daemon_rollback_monitor.sh"
    )

    local all_pass=true
    for wd in "${watchdogs[@]}"; do
        if [[ -f "$BUNKER_ROOT/guardian/watchdogs/$wd" ]]; then
            :
        else
            test_fail "guardian: watchdog $wd" "no encontrado"
            all_pass=false
        fi
    done

    for d in "${daemons[@]}"; do
        if [[ -f "$BUNKER_ROOT/guardian/daemons/$d" ]]; then
            :
        else
            test_fail "guardian: daemon $d" "no encontrado"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "guardian: todos los watchdogs y daemons presentes"
    fi
}

test_sentinel_modules() {
    test_begin "sentinel: módulos de detección"

    local modules=(
        "detect_integrity.sh"
        "detect_processes.sh"
        "detect_network.sh"
        "detect_permissions.sh"
    )

    local all_pass=true
    for mod in "${modules[@]}"; do
        if [[ -f "$BUNKER_ROOT/sentinel/modules/$mod" ]]; then
            :
        else
            test_fail "sentinel: módulo $mod" "no encontrado"
            all_pass=false
        fi
    done

    if [[ "$all_pass" == true ]]; then
        test_pass "sentinel: todos los módulos de detección presentes"
    fi
}

test_rollback_on_failure() {
    test_begin "rollback: rollback_on_failure"

    # Verificar que la función existe y es llamable
    if grep -q "^rollback_on_failure()" "$BUNKER_ROOT/rollback/rollback.sh" 2>/dev/null; then
        test_pass "rollback: función rollback_on_failure presente"
    else
        test_fail "rollback: función rollback_on_failure" "no encontrada"
    fi
}

# -----------------------------------------------------------------------------
# Reporte final
# -----------------------------------------------------------------------------
test_report() {
    echo ""
    echo "=== REPORTE DE PRUEBAS DE REGRESIÓN ==="
    echo "Ejecutadas: $TESTS_RUN"
    echo "Aprobadas:  $TESTS_PASSED"
    echo "Fallidas:   $TESTS_FAILED"
    echo "Log:        $TEST_LOG"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "RESULTADO: TODAS LAS PRUEBAS DE REGRESIÓN APROBADAS"
        return 0
    else
        echo "RESULTADO: ALGUNAS PRUEBAS DE REGRESIÓN FALLARON"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Punto de entrada
# -----------------------------------------------------------------------------
main() {
    bunker_info "Iniciando pruebas de regresión de Bunker OS..."

    mkdir -p "$(dirname "$TEST_LOG")"

    test_cli_commands
    test_core_functions
    test_config_functions
    test_api_functions
    test_engine_functions
    test_mode_selector_functions
    test_hal_functions
    test_rollback_functions
    test_sentinel_functions
    test_guardian_functions
    test_service_functions
    test_shared_functions
    test_systemd_units
    test_kernel_extension_files
    test_driver_files
    test_watchdogs_and_daemons
    test_sentinel_modules
    test_rollback_on_failure

    test_report
}

main "$@"