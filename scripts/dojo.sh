#!/usr/bin/env bash
# Gestione delle celle del dojo (spec docs/specs/celle.md).
#
#   scripts/dojo.sh up [cella...]      avvia le celle (tutte senza nomi)
#   scripts/dojo.sh down [cella...]    spegne le celle, i dati restano
#   scripts/dojo.sh status [cella...]  stato dei container
#   scripts/dojo.sh sync <cella>       copia config, SOUL e .env dei profili
#                                      nel volume della cella e riavvia il gateway
set -euo pipefail

cd "$(dirname "$0")/.."
radice=$PWD

die() {
  echo "dojo: $*" >&2
  exit 1
}

celle_valide() {
  for c in celle/*/compose.yaml; do basename "$(dirname "$c")"; done
}

scegli_celle() {
  if [[ $# -eq 0 ]]; then
    celle_valide
    return
  fi
  for c in "$@"; do
    [[ -f "celle/$c/compose.yaml" ]] || die "cella sconosciuta: $c (valide: $(celle_valide | tr '\n' ' '))"
    echo "$c"
  done
}

compose() {
  local cella=$1
  shift
  docker compose --project-directory "$radice/celle/$cella" -f "$radice/celle/$cella/compose.yaml" "$@"
}

# Cartella del profilo dentro il volume: il default è la radice di HERMES_HOME.
dir_profilo() {
  if [[ $1 == default ]]; then echo /opt/data; else echo "/opt/data/profiles/$1"; fi
}

sync_cella() {
  local cella=$1 base="celle/$1" tmp p dest
  [[ -f "$base/.env" ]] || die "manca $base/.env: copia $base/.env.example e compilalo"
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN

  compose "$cella" up -d --build
  compose "$cella" exec -T hermes mkdir -p /opt/data/lavori

  for dir in "$base"/profili/*/; do
    p=$(basename "$dir")
    dest=$(dir_profilo "$p")
    if [[ $p != default ]] && ! compose "$cella" exec -T hermes test -f "$dest/SOUL.md"; then
      # Profili stretti: nessuna skill inclusa, solo i flussi del dojo.
      compose "$cella" exec -T hermes hermes profile create "$p" --no-skills
    fi
    # .env del profilo = valori comuni della cella + quelli dell'agente.
    cat "$base/.env" >"$tmp/$p.env"
    if [[ -f "$dir/.env" ]]; then
      cat "$dir/.env" >>"$tmp/$p.env"
    elif [[ $p != default ]]; then
      die "manca $dir.env: copia $dir.env.example e compilalo"
    fi
    compose "$cella" cp "$dir/config.yaml" "hermes:$dest/config.yaml"
    compose "$cella" cp "$dir/SOUL.md" "hermes:$dest/SOUL.md"
    compose "$cella" cp "$tmp/$p.env" "hermes:$dest/.env"
    compose "$cella" exec -T hermes chmod 600 "$dest/.env"
    echo "ok   $cella/$p"
  done

  compose "$cella" exec -T hermes chown -R hermes:hermes /opt/data
  compose "$cella" exec -T hermes hermes gateway restart
}

comando=${1:-}
[[ $# -gt 0 ]] && shift
case $comando in
  up)
    for c in $(scegli_celle "$@"); do compose "$c" up -d --build; done
    ;;
  down)
    for c in $(scegli_celle "$@"); do compose "$c" down; done
    ;;
  status)
    for c in $(scegli_celle "$@"); do
      echo "== $c"
      compose "$c" ps
    done
    ;;
  sync)
    [[ $# -eq 1 ]] || die "uso: dojo.sh sync <cella>"
    scegli_celle "$1" >/dev/null
    sync_cella "$1"
    ;;
  *)
    sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
    [[ -z $comando ]] || exit 1
    ;;
esac
