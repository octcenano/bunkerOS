#!/bin/bash
# =============================================================================
# Bunker OS - Bunker Study - Integracion con Bunker Adapt
# Ubicaci3n: /usr/lib/bunker/study/lib/adapt-integration.sh
# Propsito: Integrar Bunker Study con Bunker Adapt para gestion de modelos de IA
# =============================================================================

set -o pipefail

BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"
source "$BUNKER_ROOT/study/lib/study-lib.sh"

# -----------------------------------------------------------------------------
# Configuracin
# -----------------------------------------------------------------------------
ADAPT_CONFIG="$BUNKER_ETC/bunker.conf"
# STUDY_AI_CONFIG removed - using ADAPT_CONFIG as single source

# -----------------------------------------------------------------------------
# Verificar y sincronizar modelo de IA con Adapt
# -----------------------------------------------------------------------------
sync_ai_model() {
    study_info "Sincronizando modelo de IA con Bunker Adapt..."
    
    # Obtener modelo configurado en Adapt
    local adapt_model
    adapt_model=$(bunker_config_get ai "default_model" "$ADAPT_CONFIG" 2>/dev/null)
    
    # Obtener modelo configurado en Study
    local study_model
    study_model=$(bunker_config_get ai "default_model" "$ADAPT_CONFIG" 2>/dev/null)
    
    # Si Adapt tiene un modelo configurado, usarlo
    if [[ -n "$adapt_model" ]]; then
        # Verificar si el modelo es compatible con Study
        if is_model_supported "$adapt_model"; then
            study_info "Usando modelo de Adapt: $adapt_model"
            bunker_config_set ai "default_model" "$adapt_model" "$ADAPT_CONFIG"
            export STUDY_AI_MODEL="$adapt_model"
            return 0
        else
            study_warn "Modelo de Adapt no compatible con Study: $adapt_model"
            study_warn "Seleccionando modelo compatible..."
            select_compatible_model_for_study
        fi
    fi
    
    # Si no hay modelo en Adapt, usar el de Study o seleccionar uno
    if [[ -n "$study_model" ]]; then
        if is_model_supported "$study_model"; then
            study_info "Usando modelo de Study: $study_model"
            export STUDY_AI_MODEL="$study_model"
            return 0
        fi
    fi
    
    # Seleccionar modelo compatible automaticamente
    select_compatible_model_for_study
}

# -----------------------------------------------------------------------------
# Verificar si un modelo es compatible con Study
# -----------------------------------------------------------------------------
is_model_supported() {
    local model="$1"
    
    # Modelos soportados por Study (optimizados para bajo consumo)
    local supported_models=("llama-2-7b" "mistral-7b" "phi-2" "tinyllama" "llama-2-13b")
    
    for supported in "${supported_models[@]}"; do
        if [[ "$model" == "$supported" ]]; then
            return 0
        fi
    done
    
    return 1
}

# -----------------------------------------------------------------------------
# Seleccionar modelo compatible automaticamente
# -----------------------------------------------------------------------------
select_compatible_model_for_study() {
    local available_mem_mb
    available_mem_mb=$(get_available_memory_mb)
    
    study_info "Memoria disponible: ${available_mem_mb}MB"
    
    # Modelos y sus requisitos de memoria (en MB)
    declare -A MODEL_REQUIREMENTS=(
        ["tinyllama"]="1000"
        ["phi-2"]="3000"
        ["llama-2-7b"]="7000"
        ["mistral-7b"]="7000"
        ["llama-2-13b"]="13000"
    )
    
    # Orden de preferencia (de mas eficiente a menos)
    local preferred_models=("tinyllama" "phi-2" "llama-2-7b" "mistral-7b" "llama-2-13b")
    
    local best_model=""
    local best_size=0
    
    for model in "${preferred_models[@]}"; do
        local required_mem="${MODEL_REQUIREMENTS[$model]}"
        if [[ "$required_mem" -le "$available_mem_mb" && "$required_mem" -gt "$best_size" ]]; then
            best_model="$model"
            best_size="$required_mem"
        fi
    done
    
    if [[ -n "$best_model" ]]; then
        study_info "Modelo seleccionado: $best_model (requiere ${best_size}MB)"
        bunker_config_set ai "default_model" "$best_model" "$ADAPT_CONFIG"
        export STUDY_AI_MODEL="$best_model"
        return 0
    else
        study_error "No se pudo encontrar un modelo compatible"
        study_error "Se requiere al menos 1GB de RAM libre"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Verificar recursos para IA
# -----------------------------------------------------------------------------
check_ai_resources() {
    study_info "Verificando recursos para IA..."
    
    local available_mem_mb
    available_mem_mb=$(get_available_memory_mb)
    
    # Minimo requerido para Study
    local min_mem=1024
    
    if [[ "$available_mem_mb" -lt "$min_mem" ]]; then
        study_error "Memoria insuficiente para Study"
        study_error "Minimo requerido: ${min_mem}MB"
        study_error "Memoria disponible: ${available_mem_mb}MB"
        return 1
    fi
    
    # Verificar si hay modelo asignado
    local model
    model=$(bunker_config_get ai "default_model" "$ADAPT_CONFIG" 2>/dev/null)
    
    if [[ -z "$model" ]]; then
        study_warn "No hay modelo de IA asignado. Intentando seleccionar..."
        sync_ai_model
    fi
    
    # Verificar si el modelo asignado es compatible
    if ! is_model_supported "$model"; then
        study_warn "Modelo no compatible: $model. Seleccionando compatible..."
        select_compatible_model_for_study
    fi
    
    return 0
}

# -----------------------------------------------------------------------------
# Obtener informacin del modelo actual
# -----------------------------------------------------------------------------
get_ai_model_info() {
    local model="${STUDY_AI_MODEL:-}"
    
    if [[ -z "$model" ]]; then
        model=$(bunker_config_get ai "default_model" "$ADAPT_CONFIG" 2>/dev/null)
    fi
    
    if [[ -z "$model" ]]; then
        echo "No hay modelo de IA asignado"
        return 1
    fi
    
    # Informacion de los modelos
    declare -A MODEL_INFO=(
        ["tinyllama"]="TinyLlama - Modelo ligero para pruebas (1GB RAM)"
        ["phi-2"]="Phi-2 - Modelo eficiente para razonamiento (3GB RAM)"
        ["llama-2-7b"]="Llama 2 7B - Modelo equilibrado (7GB RAM)"
        ["mistral-7b"]="Mistral 7B - Modelo de alto rendimiento (7GB RAM)"
        ["llama-2-13b"]="Llama 2 13B - Modelo avanzado (13GB RAM)"
    )
    
    echo "Modelo: $model"
    echo "Descripcion: ${MODEL_INFO[$model]:-Desconocido}"
    
    # Obtener requisitos de memoria
    declare -A MODEL_REQUIREMENTS=(
        ["tinyllama"]="1000"
        ["phi-2"]="3000"
        ["llama-2-7b"]="7000"
        ["mistral-7b"]="7000"
        ["llama-2-13b"]="13000"
    )
    
    echo "Memoria requerida: ${MODEL_REQUIREMENTS[$model]:-1000}MB"
    
    return 0
}

# -----------------------------------------------------------------------------
# Configurar modelo de IA
# -----------------------------------------------------------------------------
set_ai_model() {
    local model="$1"
    
    if ! is_model_supported "$model"; then
        study_error "Modelo no soportado por Study: $model"
        return 1
    fi
    
    # Verificar memoria
    local available_mem_mb
    available_mem_mb=$(get_available_memory_mb)
    
    declare -A MODEL_REQUIREMENTS=(
        ["tinyllama"]="1000"
        ["phi-2"]="3000"
        ["llama-2-7b"]="7000"
        ["mistral-7b"]="7000"
        ["llama-2-13b"]="13000"
    )
    
    local required_mem="${MODEL_REQUIREMENTS[$model]}"
    
    if [[ "$available_mem_mb" -lt "$required_mem" ]]; then
        study_error "Memoria insuficiente para el modelo $model"
        study_error "Requerido: ${required_mem}MB, Disponible: ${available_mem_mb}MB"
        return 1
    fi
    
    bunker_config_set ai "default_model" "$model" "$ADAPT_CONFIG"
    export STUDY_AI_MODEL="$model"
    study_info "Modelo configurado: $model"
    return 0
}

# -----------------------------------------------------------------------------
# Listar modelos disponibles para Study
# -----------------------------------------------------------------------------
list_study_models() {
    echo "=== MODELOS DISPONIBLES PARA BUNKER STUDY ==="
    echo ""
    
    declare -A MODEL_REQUIREMENTS=(
        ["tinyllama"]="1000"
        ["phi-2"]="3000"
        ["llama-2-7b"]="7000"
        ["mistral-7b"]="7000"
        ["llama-2-13b"]="13000"
    )
    
    declare -A MODEL_DESCRIPTIONS=(
        ["tinyllama"]="Modelo ligero para pruebas"
        ["phi-2"]="Modelo eficiente para razonamiento"
        ["llama-2-7b"]="Modelo equilibrado"
        ["mistral-7b"]="Modelo de alto rendimiento"
        ["llama-2-13b"]="Modelo avanzado"
    )
    
    local available_mem_mb
    available_mem_mb=$(get_available_memory_mb)
    
    for model in "${!MODEL_REQUIREMENTS[@]}"; do
        local required_mem="${MODEL_REQUIREMENTS[$model]}"
        local description="${MODEL_DESCRIPTIONS[$model]}"
        
        if [[ "$available_mem_mb" -ge "$required_mem" ]]; then
            echo -e "  ${GREEN}$model${NC} - $description (${required_mem}MB) [COMPATIBLE]"
        else
            echo -e "  ${RED}$model${NC} - $description (${required_mem}MB) [NO COMPATIBLE]"
        fi
    done
    
    echo ""
    echo "Memoria disponible: ${available_mem_mb}MB"
}

# -----------------------------------------------------------------------------
# Inicializacin
# -----------------------------------------------------------------------------
adapt_integration_init() {
    mkdir -p "$(dirname "$ADAPT_CONFIG")"
    
    # Crear configuracion de AI para Study si no existe
    if [[ ! -f "$ADAPT_CONFIG" ]]; then
        cat > "$ADAPT_CONFIG" <<EOF
[ai]
default_model = "llama-2-7b"

[resources]
max_memory_mb = 8192
max_cache_size_mb = 1024

[study]
max_document_size_mb = 100
max_processing_time_seconds = 300
EOF
        chmod 600 "$ADAPT_CONFIG"
    fi
    
    # Sincronizar con Adapt
    sync_ai_model
}

# Inicializar al cargar
adapt_integration_init
