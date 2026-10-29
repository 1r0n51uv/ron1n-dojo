#!/usr/bin/env bash
# Gestione delle stanze del dojo (spec docs/specs/stanze.md).
#
#   scripts/dojo.sh up [stanza...]      avvia le stanze (tutte senza nomi)
#   scripts/dojo.sh down [stanza...]    spegne le stanze, i dati restano
#   scripts/dojo.sh status [stanza...]  stato dei container
#   scripts/dojo.sh sync <stanza>       copia config, SOUL e .env dei profili
#                                      nel volume della stanza e riavvia il gateway
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

# Cartella del profilo dentro il volume: il default è la radice di HERMES_HOME.
dir_profilo() {
  if [[ $1 == default ]]; then echo /opt/data; else echo "/opt/data/profiles/$1"; fi
}

sync_stanza() {
  local stanza=$1 base="stanze/$1" tmp p dest
  [[ -f "$base/.env" ]] || die "manca $base/.env: copia $base/.env.example e compilalo"
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN

  compose "$stanza" up -d --build
  compose "$stanza" exec -T hermes mkdir -p /opt/data/lavori

  for dir in "$base"/profili/*/; do
    p=$(basename "$dir")
    dest=$(dir_profilo "$p")
    if [[ $p != default ]] && ! compose "$stanza" exec -T hermes test -f "$dest/SOUL.md"; then
      # Profili stretti: nessuna skill inclusa, solo i flussi del dojo.
      compose "$stanza" exec -T hermes hermes profile create "$p" --no-skills
    fi
    # .env del profilo = valori comuni della stanza + quelli dell'agente.
    cat "$base/.env" >"$tmp/$p.env"
    if [[ -f "$dir/.env" ]]; then
      cat "$dir/.env" >>"$tmp/$p.env"
    elif [[ $p != default ]]; then
      die "manca $dir.env: copia $dir.env.example e compilalo"
    fi
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
    for c in $(scegli_stanze "$@"); do compose "$c" up -d --build; done
    ;;
  down)
    for c in $(scegli_stanze "$@"); do compose "$c" down; done
    ;;
  status)
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
  *)
    sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
    [[ -z $comando ]] || exit 1
    ;;
esac
