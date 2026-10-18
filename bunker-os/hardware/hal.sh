#!/bin/bash
# =============================================================================
# Bunker OS - Capa de Abstracción de Hardware (HAL)
# Ubicación: /usr/lib/bunker/hardware/hal.sh
# Propósito: detección, información y optimización de hardware
# Desarrollador jefe: <tu_usuario> | Ingeniero colaborador: Apodex 1.1 Mini
# =============================================================================

set -o pipefail

BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

# -----------------------------------------------------------------------------
# Estado del hardware
# -----------------------------------------------------------------------------
declare -A HARDWARE_INFO
HARDWARE_INFO[cpu]=""
HARDWARE_INFO[gpu]=""
HARDWARE_INFO[ram]=""
HARDWARE_INFO[storage]=""
HARDWARE_INFO[network]=""
HARDWARE_INFO[audio]=""
HARDWARE_INFO[peripherals]=""

# -----------------------------------------------------------------------------
# Detección de hardware
# -----------------------------------------------------------------------------
hardware_detect_all() {
    bunker_info "Iniciando detección de hardware..."

    hardware_detect_cpu
    hardware_detect_gpu
    hardware_detect_ram
    hardware_detect_storage
    hardware_detect_network
    hardware_detect_audio
    hardware_detect_peripherals

    bunker_info "Detección de hardware completada"
}

hardware_detect_cpu() {
    bunker_debug "Detectando CPU..."

    local model=""
    local cores=""
    local flags=""

    if [[ -f /proc/cpuinfo ]]; then
        model=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs)
        cores=$(grep -c "^processor" /proc/cpuinfo)
        flags=$(grep -m1 "flags" /proc/cpuinfo | cut -d: -f2 | xargs)
    fi

    HARDWARE_INFO[cpu]="$model ($cores núcleos)"
    bunker_info "CPU: $model"
    bunker_info "Núcleos: $cores"
    bunker_info "Flags: $flags"
}

hardware_detect_gpu() {
    bunker_debug "Detectando GPU..."

    local gpus=()

    if command -v lspci &>/dev/null; then
        while IFS= read -r line; do
            if [[ "$line" =~ VGA|3D|Display ]]; then
                gpus+=("$line")
            fi
        done < <(lspci 2>/dev/null | grep -iE "vga|3d|display")
    fi

    if command -v nvidia-smi &>/dev/null; then
        local vram
        vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1)
        HARDWARE_INFO[gpu_vram]="$vram MiB"
    fi

    if [[ ${#gpus[@]} -eq 0 ]]; then
        HARDWARE_INFO[gpu]="integrada"
        bunker_info "GPU: integrada"
    else
        for gpu in "${gpus[@]}"; do
            bunker_info "GPU: $gpu"
        done
        HARDWARE_INFO[gpu]="${gpus[*]}"
    fi
}

hardware_detect_ram() {
    bunker_debug "Detectando RAM..."

    local total_kb=""

    if [[ -f /proc/meminfo ]]; then
        total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    fi

    local total_gb=$(( total_kb / 1048576 ))
    HARDWARE_INFO[ram]="${total_gb} GB"
    bunker_info "RAM: ${total_gb} GB"
}

hardware_detect_storage() {
    bunker_debug "Detectando almacenamiento..."

    local storage=()

    if command -v lsblk &>/dev/null; then
        while IFS= read -r line; do
            storage+=("$line")
        done < <(lsblk -d -o NAME,MODEL,SIZE,TYPE 2>/dev/null | tail -n +2)
    fi

    for dev in "${storage[@]}"; do
        bunker_info "Almacenamiento: $dev"
    done
    HARDWARE_INFO[storage]="${storage[*]}"
}

hardware_detect_network() {
    bunker_debug "Detectando red..."

    local interfaces=()

    if command -v ip &>/dev/null; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^[0-9]+:\ [a-z0-9]+ ]]; then
                interfaces+=("$line")
            fi
        done < <(ip link 2>/dev/null)
    fi

    for iface in "${interfaces[@]}"; do
        bunker_info "Red: $iface"
    done
    HARDWARE_INFO[network]="${interfaces[*]}"
}

hardware_detect_audio() {
    bunker_debug "Detectando audio..."

    if command -v pactl &>/dev/null; then
        local devices
        devices=$(pactl list short sinks 2>/dev/null)
        if [[ -n "$devices" ]]; then
            bunker_info "Audio: $devices"
        fi
    fi
}

hardware_detect_peripherals() {
    bunker_debug "Detectando periféricos..."

    if command -v lsusb &>/dev/null; then
        local devices
        devices=$(lsusb 2>/dev/null | head -20)
        bunker_info "USB: $devices"
    fi
}

# -----------------------------------------------------------------------------
# Información de hardware
# -----------------------------------------------------------------------------
hardware_info() {
    bunker_info "=== INFORMACIÓN DE HARDWARE ==="
    echo "CPU: ${HARDWARE_INFO[cpu]}"
    echo "GPU: ${HARDWARE_INFO[gpu]}"
    echo "RAM: ${HARDWARE_INFO[ram]}"
    echo "Almacenamiento: ${HARDWARE_INFO[storage]}"
    echo "Red: ${HARDWARE_INFO[network]}"
    echo "Audio: ${HARDWARE_INFO[audio]}"
    echo "Periféricos: ${HARDWARE_INFO[peripherals]}"
}

# -----------------------------------------------------------------------------
# Optimización de hardware
# -----------------------------------------------------------------------------
hardware_optimize() {
    bunker_info "Optimizando sistema para el hardware detectado..."

    # Detectar tipo de almacenamiento
    if [[ -f /sys/block/sda/queue/rotational ]]; then
        local rotational
        rotational=$(cat /sys/block/sda/queue/rotational 2>/dev/null)
        if [[ "$rotational" == "0" ]]; then
            bunker_info "SSD detectado: aplicando optimizaciones"
            optimize_ssd
        else
            bunker_info "HDD detectado: optimizaciones conservadoras"
        fi
    fi

    # Detectar CPU y aplicar governor
    if command -v cpupower &>/dev/null; then
        cpupower frequency-governor performance 2>/dev/null || true
    fi
}

optimize_ssd() {
    bunker_info "Aplicando optimizaciones SSD..."
    # TRIM
    if command -v fstrim &>/dev/null; then
        fstrim -v / 2>/dev/null || true
    fi
    # Mount options
    bunker_info "Configurando opciones de montaje para SSD..."
}

# -----------------------------------------------------------------------------
# Punto de entrada
# -----------------------------------------------------------------------------
main() {
    local command="${1:-info}"
    shift || true

    case "$command" in
        info)      hardware_info "$@" ;;
        detect)    hardware_detect_all "$@" ;;
        optimize)  hardware_optimize "$@" ;;
        cpu)       hardware_detect_cpu "$@" ;;
        gpu)       hardware_detect_gpu "$@" ;;
        ram)       hardware_detect_ram "$@" ;;
        storage)   hardware_detect_storage "$@" ;;
        network)   hardware_detect_network "$@" ;;
        audio)     hardware_detect_audio "$@" ;;
        *)
            bunker_error "Comando desconocido: $command"
            bunker_exit 1
            ;;
    esac
}

main "$@"
