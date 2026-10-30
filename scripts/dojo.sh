#!/usr/bin/env bash
# Gestione della room del dojo (spec docs/specs/rooms.md, ROOM-004).
#
#   scripts/dojo.sh up                 scarica l'immagine, avvia la room e
#                                      copia i .env nei profiles
#   scripts/dojo.sh down               spegne la room, i dati restano
#   scripts/dojo.sh status             stato dei container
#   scripts/dojo.sh secret <agente> <CHIAVE>
#                                      imposta un valore (TELEGRAM_BOT_TOKEN,
#                                      GH_TOKEN) nel .env di un agente, input
#                                      nascosto, poi lo copia nella room
#   scripts/dojo.sh claude             login all'abbonamento Claude (Pro o Max)
#   scripts/dojo.sh doctor             controlla la room e dice cosa manca
#
# La room è `lab` (DOJO_ROOM la cambia). La cartella di lavoro degli agenti è
# ~/dojo/work (DOJO_WORK la cambia, ROOM-011).
set -euo pipefail

cd "$(dirname "$0")/.."
radice=$PWD
room=${DOJO_ROOM:-lab}
base=$radice/rooms/$room

export DOJO_UID=${DOJO_UID:-$(id -u)}
export DOJO_GID=${DOJO_GID:-$(id -g)}
export DOJO_WORK=${DOJO_WORK:-$HOME/dojo/work}

die() {
  echo "dojo: $*" >&2
  exit 1
}

[[ -f $base/compose.yaml ]] || die "room sconosciuta: $room"

compose() {
  docker compose --project-directory "$base" -f "$base/compose.yaml" "$@"
}

rand() { od -An -N24 -tx1 /dev/urandom | tr -d ' \n'; }

# Cartella del profile nel volume: il default è la radice di HERMES_HOME.
profile_dir() {
  if [[ $1 == default ]]; then echo /opt/data; else echo "/opt/data/profiles/$1"; fi
}

# Imposta VAR=valore in un .env: sostituisce la riga se c'è, altrimenti la
# aggiunge. Il valore passa dall'ambiente di awk, non dalla riga di comando.
env_set() {
  local f=$1 var=$2 tmp
  tmp=$(mktemp)
  chmod 600 "$tmp"
  VALORE=$3 awk -v var="$var" 'BEGIN { FS = OFS = "="; fatto = 0 }
    $1 == var { print var "=" ENVIRON["VALORE"]; fatto = 1; next }
    { print }
    END { if (!fatto) print var "=" ENVIRON["VALORE"] }' "$f" >"$tmp"
  mv "$tmp" "$f"
}

# Credenziali di dashboard (ROOM-006) e WebUI (ROOM-009): casuali, nei loro
# file e non nei .env dei profiles, che gli agenti leggono. La chiave dell'API
# del gateway va anche nei .env dei profiles: il gateway accetta su
# /p/<agente> solo la chiave di quel profile. Se un file esiste non si tocca.
create_credentials() {
  local f=$base/dashboard.env chiave
  if [[ ! -f $f ]]; then
    (
      umask 077
      {
        echo "HERMES_DASHBOARD=1"
        echo "HERMES_DASHBOARD_BASIC_AUTH_USERNAME=dojo"
        echo "HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=$(rand)"
        echo "HERMES_DASHBOARD_BASIC_AUTH_SECRET=$(rand)"
      } >"$f"
    )
    echo "creato $f: utente dojo, password casuale lì dentro"
  fi
  f=$base/webui.env
  if [[ ! -f $f ]]; then
    chiave=$(rand)
    (
      umask 077
      {
        echo "HERMES_WEBUI_PASSWORD=$(rand)"
        echo "API_SERVER_KEY=$chiave"
        echo "HERMES_WEBUI_GATEWAY_API_KEY=$chiave"
      } >"$f"
    )
    echo "creato $f: password della WebUI lì dentro"
  fi
}

# .env di ogni profile = valori comuni della room + quelli dell'agente + API
# del gateway per la WebUI. Config e SOUL arrivano dall'immagine (ROOM-012).
push_env() {
  local tmp p dir dest api_key
  api_key=$(sed -n 's/^API_SERVER_KEY=//p' "$base/webui.env")
  tmp=$(mktemp -d)
  # Il trap RETURN si toglie da solo, altrimenti scatta anche al ritorno di
  # chi ha chiamato push_env, dove tmp non c'è.
  trap 'rm -rf "$tmp"; trap - RETURN' RETURN
  for dir in "$base"/profiles/*/; do
    p=$(basename "$dir")
    # Un agente senza .env non si attiva: si può partire da uno solo.
    if [[ $p != default && ! -f "$dir/.env" ]]; then
      echo "salto $p: manca ${dir}.env"
      continue
    fi
    dest=$(profile_dir "$p")
    cat "$base/.env" >"$tmp/$p.env"
    [[ ! -f "$dir/.env" ]] || cat "$dir/.env" >>"$tmp/$p.env"
    {
      echo "API_SERVER_KEY=$api_key"
      if [[ $p == default ]]; then
        echo "HERMES_WEBUI_GATEWAY_BASE_URL=http://hermes:8642"
      else
        echo "HERMES_WEBUI_GATEWAY_BASE_URL=http://hermes:8642/p/$p"
      fi
    } >>"$tmp/$p.env"
    compose exec -T hermes test -d "$dest" || die "profile $p non creato: guarda compose logs hermes"
    compose cp "$tmp/$p.env" "hermes:$dest/.env"
    # `compose cp` crea il file come root: Hermes gira come utente hermes.
    compose exec -T hermes chown hermes:hermes "$dest/.env"
    compose exec -T hermes chmod 600 "$dest/.env"
    echo "ok   $p"
  done
  compose exec -T hermes hermes gateway restart
}

# Il profile default e gli agenti nascono all'avvio del container
# (dojo-seed): si aspetta che ci siano prima di copiare i .env.
wait_seed() {
  local _
  for _ in $(seq 1 60); do
    compose exec -T hermes test -f /opt/data/profiles/strategist/config.yaml 2>/dev/null && return 0
    sleep 2
  done
  die "i profiles non compaiono dopo 2 minuti: compose logs hermes"
}

up() {
  [[ -f $base/.env ]] || die "manca $base/.env: lancia scripts/install.sh"
  mkdir -p "$DOJO_WORK"
  # La rete di Caddy di ron1n: se ron1n non c'è (PC di prova) la si crea
  # vuota, e la WebUI resta solo su 127.0.0.1.
  docker network inspect proxy >/dev/null 2>&1 || docker network create proxy >/dev/null
  create_credentials
  compose pull -q
  compose up -d
  wait_seed
  push_env
  echo "WebUI: http://127.0.0.1:${WEBUI_PORT:-8787} (password in $base/webui.env)"
  echo "dashboard: http://127.0.0.1:${DASHBOARD_PORT:-9119} (utente e password in $base/dashboard.env)"
}

# Un valore nel .env di un agente, chiesto con input nascosto: non passa
# dalla riga di comando né dalla cronologia. Se il .env non c'è lo crea dal
# .env.example. Poi lo copia nella room, se è accesa.
secret() {
  local agente=$1 var=$2 dir="$base/profiles/$1" f valore
  [[ -d $dir && $agente != default ]] || die "agente sconosciuto: $agente"
  [[ $var =~ ^[A-Z][A-Z0-9_]*$ ]] || die "nome non valido: $var"
  grep -q "^$var=" "$dir/.env.example" 2>/dev/null ||
    die "$var non è nel .env.example di $agente"
  f=$dir/.env
  [[ -f $f ]] || install -m 600 "$dir/.env.example" "$f"
  printf '%s di %s: ' "$var" "$agente" >/dev/tty
  IFS= read -rs valore </dev/tty
  printf '\n' >/dev/tty
  [[ -n $valore ]] || die "valore vuoto, non cambio nulla"
  env_set "$f" "$var" "$valore"
  echo "$var di $agente aggiornato"
  if [[ -n $(compose ps -q hermes 2>/dev/null) ]]; then push_env; fi
}

# CLI di Claude Code nel container, con il login nel volume della room.
claude_cli() {
  compose exec -u hermes -e USER=hermes -e LOGNAME=hermes \
    -e CLAUDE_CONFIG_DIR=/opt/data/claude "$@"
}

# L'uscita si legge tutta prima di cercarci dentro: con `grep -q` in pipe e
# pipefail, grep chiude presto e il comando a monte fallisce anche col login.
claude_logged_in() {
  local stato
  stato=$(claude_cli -T hermes claude auth status 2>&1) || true
  [[ $stato =~ \"loggedIn\":[[:space:]]*true ]] && return 0
  [[ ${1:-} != verbose ]] || echo "$stato" >&2
  return 1
}

# Abbonamento Claude di tutti gli agenti (MODELS-006): login con la CLI
# ufficiale. Rilanciarlo con il login già fatto non chiede nulla.
claude() {
  [[ -n $(compose ps -q hermes 2>/dev/null) ]] || die "la room è spenta: scripts/dojo.sh up"
  if claude_logged_in; then
    echo "login Claude già fatto"
    return
  fi
  echo "Apri il link, accedi con l'account Claude (Pro o Max) e incolla qui il codice."
  claude_cli hermes claude auth login --claudeai
  claude_logged_in verbose || die "login Claude non riuscito (stato qui sopra)"
  echo "login Claude ok"
}

# Una riga per controllo: ok, oppure NO con cosa fare.
male=0
verify() {
  local bene=$1 rimedio=$2
  shift 2
  if "$@" >/dev/null 2>&1; then
    echo "ok   $bene"
  else
    echo "NO   $rimedio"
    male=1
  fi
}
not() { ! "$@"; }
has_value() { [[ -n $(sed -n "s/^$2=//p" "$1" 2>/dev/null) ]]; }
running() { [[ -n $(compose ps -q --status running "$1" 2>/dev/null) ]]; }

# Python dentro hermes: esce 0 se l'URL risponde (anche con un errore HTTP).
reach() {
  compose exec -T hermes /opt/hermes/.venv/bin/python -c 'import sys, urllib.request
try:
    urllib.request.urlopen(sys.argv[1], timeout=10)
except urllib.error.HTTPError:
    pass
except Exception:
    sys.exit(1)' "$1"
}

# Controlli della room (ROOM-004): per ogni problema una riga con cosa fare.
doctor() {
  local p dir v
  docker info >/dev/null 2>&1 || die "Docker non risponde"
  verify "$base/.env" "manca $base/.env: scripts/install.sh" test -f "$base/.env"
  verify TELEGRAM_ALLOWED_USERS "TELEGRAM_ALLOWED_USERS vuoto: gli agenti non rispondono a nessuno" \
    has_value "$base/.env" TELEGRAM_ALLOWED_USERS
  for dir in "$base"/profiles/*/; do
    p=$(basename "$dir")
    [[ $p != default ]] || continue
    if [[ ! -f $dir/.env ]]; then
      echo "--   $p spento (manca ${dir}.env)"
      continue
    fi
    while IFS= read -r v; do
      verify "$p $v" "$p: $v vuoto, scripts/dojo.sh secret $p $v" has_value "$dir/.env" "$v"
    done < <(sed -n 's/^\([A-Z_][A-Z0-9_]*\)=.*/\1/p' "$dir/.env.example")
  done
  verify "cartella di lavoro $DOJO_WORK" "$DOJO_WORK manca o non è scrivibile" test -w "$DOJO_WORK"
  if ! running hermes; then
    echo "NO   la room è spenta: scripts/dojo.sh up"
    return 1
  fi
  for p in webui webui-proxy dashboard egress; do
    verify "servizio $p" "servizio $p fermo: docker compose logs $p in rooms/$room" running "$p"
  done
  verify "login Claude" "login Claude mancante: scripts/dojo.sh claude" claude_logged_in
  # Egress: Telegram sì, un dominio fuori dall'allowlist no (ROOM-001).
  verify "egress verso Telegram" "Telegram non raggiungibile: docker compose logs egress" reach https://api.telegram.org
  verify "egress chiuso fuori dall'allowlist" "example.com raggiungibile: l'allowlist non funziona" \
    not reach https://example.com
  return $male
}

comando=${1:-}
[[ $# -gt 0 ]] && shift
case $comando in
  up) up ;;
  down) compose down ;;
  status) compose ps ;;
  secret)
    [[ $# -eq 2 ]] || die "uso: dojo.sh secret <agente> <CHIAVE>"
    secret "$@"
    ;;
  claude) claude ;;
  doctor) doctor ;;
  *)
    sed -n '2,15s/^# \{0,1\}//p' "$0"
    exit 1
    ;;
esac
