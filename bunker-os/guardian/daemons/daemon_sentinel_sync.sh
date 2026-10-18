#!/bin/bash
# Bunker OS - Daemon: Sincronización Sentinel
BUNKER_ROOT="${BUNKER_ROOT:-/usr/lib/bunker}"
source "$BUNKER_ROOT/shared/lib.sh"

daemon_sentinel_sync() {
    local interval=30
    local sentinel_incidents="$BUNKER_VAR/incidents"
    local sentinel_hypotheses="$BUNKER_VAR/hypotheses"
    bunker_info "Daemon de sincronización Sentinel iniciado"
    while true; do
        if [[ -d "$sentinel_incidents" ]]; then
            for incident in "$sentinel_incidents"/*.incident; do
                [[ -f "$incident" ]] || continue
                local name
                name=$(basename "$incident")
                local hyp_file="$sentinel_hypotheses/hypothesis_${name}.json"
                if [[ ! -f "$hyp_file" ]]; then
                    bunker_debug "Sincronizando incidente sin hipótesis: $name"
                    if [[ -f "$BUNKER_ROOT/sentinel/sentinel.sh" ]]; then
                        source "$BUNKER_ROOT/sentinel/sentinel.sh"
                        generate_hypothesis "$name" 2>/dev/null || true
                    fi
                fi
            done
        fi
        if [[ -d "$sentinel_hypotheses" ]]; then
            for hyp in "$sentinel_hypotheses"/hypothesis_*.json; do
                [[ -f "$hyp" ]] || continue
                local id result
                id=$(python3 -c "import json; print(json.load(open('$hyp'))['hypotheses'][0]['id'])" 2>/dev/null)
                if [[ -n "$id" ]]; then
                    result=$(python3 -c "import json; print(json.load(open('$hyp'))['hypotheses'][0].get('confirmed', 'pending'))" 2>/dev/null)
                    if [[ "$result" == "confirmed" ]]; then
                        bunker_info "Hipótesis confirmada detectada: $id, aplicando remediación"
                        python3 -c "
import json
with open('$hyp', 'r') as f:
    data = json.load(f)
for h in data['hypotheses']:
    if h['id'] == '$id':
        h['remediated'] = True
with open('$hyp', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true
                    fi
                fi
            done
        fi
        sleep "$interval"
    done
}

run_daemon() {
    daemon_sentinel_sync
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_daemon
fi