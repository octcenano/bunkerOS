#!/bin/bash
# Bunker OS - Servicio: Hardening
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

harden_start() {
    bunker_info "Iniciando servicio de hardening..."
    apply_kernel_hardening
}

harden_stop() {
    bunker_info "Deteniendo servicio de hardening..."
}

apply_kernel_hardening() {
    bunker_info "Aplicando hardening del kernel..."
    local sysctl_config=(
        "net.ipv4.conf.all.rp_filter=1"
        "net.ipv4.conf.default.rp_filter=1"
        "net.ipv4.conf.all.accept_source_route=0"
        "net.ipv4.conf.default.accept_source_route=0"
        "net.ipv4.conf.all.accept_redirects=0"
        "net.ipv4.conf.default.accept_redirects=0"
        "net.ipv4.conf.all.log_martians=1"
        "net.ipv4.icmp_echo_ignore_broadcasts=1"
        "net.ipv4.icmp_ignore_bogus_error_responses=1"
        "kernel.kptr_restrict=2"
        "kernel.dmesg_restrict=1"
        "kernel.unprivileged_bpf_disabled=1"
        "vm.mmap_rnd_bits=32"
        "vm.mmap_rnd_compat_bits=16"
    )
    for setting in "${sysctl_config[@]}"; do
        local key="${setting%%=*}"
        local value="${setting##*=}"
        if command -v sysctl &>/dev/null; then
            sysctl -w "$key"="$value" 2>/dev/null || true
        fi
    done
    bunker_info "Hardening del kernel aplicado"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    harden_start "$@"
fi