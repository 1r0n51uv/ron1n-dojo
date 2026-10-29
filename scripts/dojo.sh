#!/usr/bin/env bash
# Gestione delle stanze del dojo (spec docs/specs/stanze.md).
#
#   scripts/dojo.sh up [stanza...]      avvia le stanze (tutte senza nomi)
#   scripts/dojo.sh down [stanza...]    spegne le stanze, i dati restano
#   scripts/dojo.sh status [stanza...]  stato dei container
#   scripts/dojo.sh sync <stanza>       copia config, SOUL e .env dei profili
#                                      nel volume della stanza e riavvia il gateway
#   scripts/dojo.sh up-modelli         avvia solo il gateway dei modelli
#   scripts/dojo.sh chiave <stanza> [budget]
#                                      crea la chiave virtuale della stanza sul
#                                      gateway dei modelli (budget in dollari, 20)
#
# Senza nomi, up e down includono il gateway dei modelli (servizi/modelli):
# acceso per primo, spento per ultimo.
set -euo pipefail

cd "$(dirname "$0")/.."
radice=$PWD

die() {
  echo "dojo: $*" >&2
  exit 1
}

stanze_valide() {
  for c in stanze/*/compose.yaml; do basename "$(dirname "$c")"; done
}

scegli_stanze() {
  if [[ $# -eq 0 ]]; then
    stanze_valide
    return
  fi
  for c in "$@"; do
    [[ -f "stanze/$c/compose.yaml" ]] || die "stanza sconosciuta: $c (valide: $(stanze_valide | tr '\n' ' '))"
    echo "$c"
  done
}

compose() {
  local stanza=$1
  shift
  docker compose --project-directory "$radice/stanze/$stanza" -f "$radice/stanze/$stanza/compose.yaml" "$@"
}

modelli() {
  docker compose --project-directory "$radice/servizi/modelli" -f "$radice/servizi/modelli/compose.yaml" "$@"
}

# Ogni stanza ha una rete sua verso il gateway dei modelli, senza internet:
# così le stanze non si vedono fra loro. Le reti nascono dalle cartelle in
# stanze/ e il gateway, se è acceso, si collega a ognuna.
crea_reti() {
  local s id
  for s in $(stanze_valide); do
    docker network inspect "dojo-$s-modelli" >/dev/null 2>&1 ||
      docker network create --internal "dojo-$s-modelli" >/dev/null
  done
  id=$(modelli ps -q litellm 2>/dev/null) || id=
  [[ -n $id ]] || return 0
  for s in $(stanze_valide); do
    docker network connect --alias litellm "dojo-$s-modelli" "$id" 2>/dev/null || true
  done
}

up_modelli() {
  modelli up -d
  crea_reti
}

# Chiave virtuale LiteLLM per una stanza, con un budget che si azzera ogni
# mese. Vale per tutti i modelli del gateway, riserve comprese. La stampa: va nel .env della stanza.
chiave() {
  local stanza=$1 budget=${2:-20}
  modelli exec -T litellm python3 - "$stanza" "$budget" <<'PY'
import json, os, sys, urllib.request
stanza, budget = sys.argv[1], float(sys.argv[2])
corpo = {
    "key_alias": f"stanza-{stanza}",
    "max_budget": budget,
    "budget_duration": "30d",
}
req = urllib.request.Request(
    "http://localhost:4000/key/generate",
    data=json.dumps(corpo).encode(),
    headers={
        "Authorization": "Bearer " + os.environ["LITELLM_MASTER_KEY"],
        "Content-Type": "application/json",
    },
)
print("LITELLM_API_KEY=" + json.load(urllib.request.urlopen(req))["key"])
PY
}

# Cartella del profilo dentro il volume: il default è la radice di HERMES_HOME.
dir_profilo() {
  if [[ $1 == default ]]; then echo /opt/data; else echo "/opt/data/profiles/$1"; fi
}

sync_stanza() {
  local stanza=$1 base="stanze/$1" tmp p dest
  [[ -f "$base/.env" ]] || die "manca $base/.env: copia $base/.env.example e compilalo"
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN

  crea_reti
  compose "$stanza" up -d --build
  compose "$stanza" exec -T hermes mkdir -p /opt/data/lavori

  for dir in "$base"/profili/*/; do
    p=$(basename "$dir")
    dest=$(dir_profilo "$p")
    # Un agente senza .env non si attiva ancora: si può partire da uno solo.
    if [[ $p != default && ! -f "$dir/.env" ]]; then
      echo "salto $stanza/$p: manca ${dir}.env"
      continue
    fi
    if [[ $p != default ]] && ! compose "$stanza" exec -T hermes test -f "$dest/SOUL.md"; then
      # Profili stretti: nessuna skill inclusa, solo i flussi del dojo.
      compose "$stanza" exec -T hermes hermes profile create "$p" --no-skills
    fi
    # .env del profilo = valori comuni della stanza + quelli dell'agente.
    cat "$base/.env" >"$tmp/$p.env"
    [[ ! -f "$dir/.env" ]] || cat "$dir/.env" >>"$tmp/$p.env"
    compose "$stanza" cp "$dir/config.yaml" "hermes:$dest/config.yaml"
    compose "$stanza" cp "$dir/SOUL.md" "hermes:$dest/SOUL.md"
    compose "$stanza" cp "$tmp/$p.env" "hermes:$dest/.env"
    compose "$stanza" exec -T hermes chmod 600 "$dest/.env"
    echo "ok   $stanza/$p"
  done

  compose "$stanza" exec -T hermes chown -R hermes:hermes /opt/data
  compose "$stanza" exec -T hermes hermes gateway restart
}

comando=${1:-}
[[ $# -gt 0 ]] && shift
case $comando in
  up)
    if [[ $# -eq 0 ]]; then up_modelli; else crea_reti; fi
    for c in $(scegli_stanze "$@"); do compose "$c" up -d --build; done
    ;;
  down)
    for c in $(scegli_stanze "$@"); do compose "$c" down; done
    [[ $# -gt 0 ]] || modelli down
    ;;
  status)
    echo "== modelli"
    modelli ps
    for c in $(scegli_stanze "$@"); do
      echo "== $c"
      compose "$c" ps
    done
    ;;
  sync)
    [[ $# -eq 1 ]] || die "uso: dojo.sh sync <stanza>"
    scegli_stanze "$1" >/dev/null
    sync_stanza "$1"
    ;;
  up-modelli)
    up_modelli
    ;;
  chiave)
    [[ $# -ge 1 && $# -le 2 ]] || die "uso: dojo.sh chiave <stanza> [budget]"
    scegli_stanze "$1" >/dev/null
    chiave "$@"
    ;;
  *)
    sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
    [[ -z $comando ]] || exit 1
    ;;
esac
