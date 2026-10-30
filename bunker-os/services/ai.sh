#!/bin/bash
# =============================================================================
# Bunker OS - Servicio: IA
# Ubicaci3n: /usr/lib/bunker/services/ai.sh
# Propsito: Gestion de recursos para IA local
# =============================================================================

BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

# -----------------------------------------------------------------------------
# Configuracion de recursos para IA
# -----------------------------------------------------------------------------
MIN_RAM_FOR_AI_MB=4096  # 4GB minimo para modelos de IA
MIN_RAM_FOR_LARGE_MODELS_MB=8192  # 8GB para modelos grandes

# Modelos compatibles y sus requisitos de memoria (en MB)
declare -A AI_MODELS=(
    ["llama-2-7b"]="7000"
    ["llama-2-13b"]="13000"
    ["mistral-7b"]="7000"
    ["phi-2"]="3000"
    ["tinyllama"]="1000"
)

ai_start() {
    bunker_info "Iniciando servicio de IA..."
    
    # Verificar memoria disponible
    local available_mem_mb
    available_mem_mb=$(get_available_memory_mb)
    
    bunker_info "Memoria disponible: ${available_mem_mb}MB"
    
    # Verificar si hay suficiente memoria para IA
    if [[ "$available_mem_mb" -lt "$MIN_RAM_FOR_AI_MB" ]]; then
        bunker_error "No hay suficiente memoria para ejecutar modelos de IA"
        bunker_error "Minimo requerido: ${MIN_RAM_FOR_AI_MB}MB"
        bunker_error "Memoria disponible: ${available_mem_mb}MB"
        bunker_exit 1
    fi
    
    # Seleccionar modelo adecuado basado en memoria
    local selected_model
    selected_model=$(select_compatible_model "$available_mem_mb")
    
    if [[ -z "$selected_model" ]]; then
        bunker_warn "No se pudo seleccionar un modelo compatible automaticamente"
        bunker_warn "Puedes especificar un modelo manualmente"
    else
        bunker_info "Modelo seleccionado automaticamente: $selected_model"
        bunker_config_set "ai" "default_model" "$selected_model"
    fi
    
    tune_ai_resources
}

ai_stop() {
    bunker_info "Deteniendo servicio de IA..."
}

# Obtener memoria disponible en MB
get_available_memory_mb() {
    if [[ -f /proc/meminfo ]]; then
        local free_mem
        free_mem=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        local free_mem_mb=$((free_mem / 1024))
        echo "$free_mem_mb"
    else
        # Fallback: usar free
        free -m 2>/dev/null | awk '/^Mem:/{print $4}'
    fi
}

# Seleccionar modelo compatible basado en memoria disponible
select_compatible_model() {
    local available_mem_mb="$1"
    local best_model=""
    local best_size=0
    
    for model in "${!AI_MODELS[@]}"; do
        local required_mem="${AI_MODELS[$model]}"
        if [[ "$required_mem" -le "$available_mem_mb" && "$required_mem" -gt "$best_size" ]]; then
            best_model="$model"
            best_size="$required_mem"
        fi
    done
    
    echo "$best_model"
}

# Verificar si un modelo es compatible con la memoria disponible
is_model_compatible() {
    local model="$1"
    local available_mem_mb="$2"
    
    if [[ -z "${AI_MODELS[$model]}" ]]; then
        bunker_error "Modelo desconocido: $model"
        return 1
    fi
    
    local required_mem="${AI_MODELS[$model]}"
    if [[ "$required_mem" -le "$available_mem_mb" ]]; then
        return 0
    else
        bunker_error "Modelo $model requiere ${required_mem}MB, solo hay ${available_mem_mb}MB disponibles"
        return 1
    fi
}

# Listar modelos disponibles
list_ai_models() {
    bunker_info "=== MODELOS DE IA DISPONIBLES ==="
    for model in "${!AI_MODELS[@]}"; do
        local required_mem="${AI_MODELS[$model]}"
        echo "  $model: ${required_mem}MB"
    done
}

# Listar modelos compatibles con la memoria actual
list_compatible_models() {
    local available_mem_mb
    available_mem_mb=$(get_available_memory_mb)
    
    bunker_info "=== MODELOS COMPATIBLES (${available_mem_mb}MB disponibles) ==="
    for model in "${!AI_MODELS[@]}"; do
        local required_mem="${AI_MODELS[$model]}"
        if [[ "$required_mem" -le "$available_mem_mb" ]]; then
            echo "  $model: ${required_mem}MB"
        else
            echo "  $model: ${required_mem}MB (NO COMPATIBLE)"
        fi
    done
}

tune_ai_resources() {
    bunker_info "Optimizando recursos para IA..."
    
    local current_mem
    current_mem=$(bunker_config_get resources "core_memory_budget" 2>/dev/null || echo "512")
    
    # Asignar mas memoria para IA
    local new_mem=$((current_mem * 2))
    bunker_config_set resources "core_memory_budget" "$new_mem"
    
    # Configurar swap para IA
    if [[ -f /proc/swaps ]]; then
        local swap_size
        swap_size=$(grep -v Filename /proc/swaps 2>/dev/null | awk '{print $3}')
        if [[ -z "$swap_size" || "$swap_size" -lt 2048 ]]; then
            bunker_warn "Se recomienda al menos 2GB de swap para IA"
        fi
    fi
    
    if command -v renice &>/dev/null; then
        # Prioridad para procesos de IA
        :
    fi
    
    bunker_info "Recursos de IA optimizados"
}

# Verificar dependencias para IA
check_ai_dependencies() {
    local missing_deps=()
    
    # Verificar si hay aceleracion GPU
    if ! command -v nvidia-smi &>/dev/null && ! command -v rocm-smi &>/dev/null; then
        bunker_warn "No se detecto aceleracion GPU (NVIDIA/AMD). Usando CPU."
    fi
    
    # Verificar dependencias comunes
    for dep in python3 python3-pip; do
        if ! command -v "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        bunker_warn "Dependencias faltantes para IA: ${missing_deps[*]}"
        bunker_warn "Instalalas con: pacman -S ${missing_deps[*]}"
    fi
}

# -----------------------------------------------------------------------------
# Punto de entrada
# -----------------------------------------------------------------------------
main() {
    local command="${1:-start}"
    shift || true

    case "$command" in
        start)
            check_ai_dependencies
            ai_start "$@"
            ;;
        stop)
            ai_stop "$@"
            ;;
        models)
            list_ai_models
            ;;
        compatible)
            list_compatible_models
            ;;
        check-model)
            local model="$1"
            local available_mem_mb
            available_mem_mb=$(get_available_memory_mb)
            if is_model_compatible "$model" "$available_mem_mb"; then
                bunker_info "Modelo $model es compatible"
            else
                bunker_error "Modelo $model NO es compatible"
                bunker_exit 1
            fi
            ;;
        check-mem)
            local available_mem_mb
            available_mem_mb=$(get_available_memory_mb)
            echo "$available_mem_mb"
            ;;
        help|--help|-h)
            echo "Uso: bunker ai <comando>"
            echo "Comandos: start | stop | models | compatible | check-model <model> | check-mem | help"
            ;;
        *)
            bunker_error "Comando desconocido: $command"
            bunker_exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
