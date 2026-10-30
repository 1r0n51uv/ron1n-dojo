#!/usr/bin/env bash
# Gestione della room del dojo (spec docs/specs/rooms.md, ROOM-004). Tutta la
# configurazione sta in un file, dojo.env nella radice del repo (modello in
# dojo.env.example); i comandi sono pochi:
#
#   scripts/dojo.sh up       applica dojo.env e avvia o aggiorna la room;
#                            si rilancia dopo ogni modifica al file
#   scripts/dojo.sh down     spegne la room, i dati restano
#   scripts/dojo.sh status   stato dei container e controlli, con cosa fare
#   scripts/dojo.sh claude   login all'abbonamento Claude (Pro o Max), una
#                            volta sola: non può stare in un file
set -euo pipefail

cd "$(dirname "$0")/.."
radice=$PWD
# La room da gestire: una cartella di rooms/. Oggi c'è solo la lab.
room=${DOJO_ROOM:-lab}
base=$radice/rooms/$room
conf=$radice/dojo.env

die() {
  echo "dojo: $*" >&2
  exit 1
}

[[ -f $base/compose.yaml ]] || die "room sconosciuta: $room (DOJO_ROOM)"

# dojo.env letto riga per riga, senza eseguirlo: CHIAVE=valore, il resto si
# ignora.
declare -A cfg
[[ -f $conf ]] || die "manca $conf: lancia scripts/install.sh o copia dojo.env.example"
chmod 600 "$conf"
while IFS= read -r riga || [[ -n $riga ]]; do
  [[ $riga =~ ^([A-Z][A-Z0-9_]*)=(.*)$ ]] && cfg[${BASH_REMATCH[1]}]=${BASH_REMATCH[2]}
done <"$conf"
val() { echo "${cfg[$1]:-}"; }

# Agenti della room: le cartelle in profiles/, tranne default.
tutti=()
for dir in "$base"/profiles/*/; do
  p=$(basename "$dir")
  [[ $p == default ]] || tutti+=("$p")
done
read -ra accesi <<<"$(val DOJO_AGENTS)"
for p in "${accesi[@]}"; do
  [[ " ${tutti[*]} " == *" $p "* ]] || die "DOJO_AGENTS: agente sconosciuto $p (validi: ${tutti[*]})"
done
acceso() { [[ " ${accesi[*]} " == *" $1 "* ]]; }

# Valori per compose.yaml. La cartella di lavoro è quella della room dentro
# DOJO_ROOMS_DIR (~/dojo/<room>, ROOM-011); accetta ~. DOJO_WORK in dojo.env, se
# c'è ancora, la sostituisce per intero.
dojo_dir=$(val DOJO_ROOMS_DIR)
dojo_dir=${dojo_dir:-$HOME/dojo}
dojo_dir=${dojo_dir/#\~/$HOME}
DOJO_WORK=$(val DOJO_WORK)
DOJO_WORK=${DOJO_WORK:-$dojo_dir/$room}
DOJO_WORK=${DOJO_WORK/#\~/$HOME}
DOJO_UID=$(id -u)
DOJO_GID=$(id -g)
WEBUI_PORT=$(val WEBUI_PORT)
DASHBOARD_PORT=$(val DASHBOARD_PORT)
export DOJO_WORK DOJO_UID DOJO_GID WEBUI_PORT DASHBOARD_PORT

compose() {
  docker compose --project-directory "$base" -f "$base/compose.yaml" "$@"
}

rand() { od -An -N24 -tx1 /dev/urandom | tr -d ' \n'; }

# Cartella del profile nel volume: il default è la radice di HERMES_HOME.
profile_dir() {
  if [[ $1 == default ]]; then echo /opt/data; else echo "/opt/data/profiles/$1"; fi
}

# Credenziali di dashboard (ROOM-006) e WebUI (ROOM-009): casuali, generate
# qui e mai scritte a mano, nei loro file e non nei .env dei profiles, che
# gli agenti leggono. La chiave dell'API del gateway va anche nei .env dei
# profiles: il gateway accetta su /p/<agente> solo la chiave di quel profile.
# Se un file esiste non si tocca.
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
  fi
}

# Chiavi di dojo.env che non vanno agli agenti: sono per compose e dojo.sh.
di_dojo() { [[ $1 == DOJO_* || $1 == *_PORT ]]; }

# Le chiavi di dojo.env.example di un agente, senza il prefisso
# (BUILDER_GH_TOKEN -> GH_TOKEN).
chiavi_agente() {
  local P=${1^^}_
  sed -n "s/^${P}\([A-Z0-9_]*\)=.*/\1/p" "$radice/dojo.env.example"
}

# Il .env di un profile: valori comuni di dojo.env (senza prefisso
# d'agente), quelli dell'agente senza prefisso se è acceso, e l'API del
# gateway per la WebUI. Un agente spento non ha bot né token.
env_profile() {
  local p=$1 k altro P=${1^^}_ comune
  for k in "${!cfg[@]}"; do
    di_dojo "$k" && continue
    comune=1
    for altro in "${tutti[@]}"; do
      [[ $k == "${altro^^}"_* ]] && comune=
    done
    if [[ -n $comune ]]; then
      echo "$k=${cfg[$k]}"
    elif [[ $k == "$P"* ]] && acceso "$p"; then
      echo "${k#"$P"}=${cfg[$k]}"
    fi
  done
  echo "API_SERVER_KEY=$(sed -n 's/^API_SERVER_KEY=//p' "$base/webui.env")"
  if [[ $p == default ]]; then
    echo "HERMES_WEBUI_GATEWAY_BASE_URL=http://hermes:8642"
  else
    echo "HERMES_WEBUI_GATEWAY_BASE_URL=http://hermes:8642/p/$p"
  fi
}

# Copia il .env di ogni profile nel volume e riavvia il gateway. Config e
# SOUL arrivano dall'immagine (ROOM-012).
push_env() {
  local tmp p dest
  tmp=$(mktemp -d)
  # Il trap RETURN si toglie da solo, altrimenti scatta anche al ritorno di
  # chi ha chiamato push_env, dove tmp non c'è.
  trap 'rm -rf "$tmp"; trap - RETURN' RETURN
  for p in default "${tutti[@]}"; do
    dest=$(profile_dir "$p")
    (umask 077 && env_profile "$p" >"$tmp/$p.env")
    compose exec -T hermes test -d "$dest" || die "profile $p non creato: guarda compose logs hermes"
    compose cp "$tmp/$p.env" "hermes:$dest/.env"
    # `compose cp` crea il file come root: Hermes gira come utente hermes.
    compose exec -T hermes chown hermes:hermes "$dest/.env"
    compose exec -T hermes chmod 600 "$dest/.env"
    if [[ $p == default ]]; then :; elif acceso "$p"; then echo "ok   $p"; else echo "--   $p spento"; fi
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

# Almeno un progetto in projects/ ha il tracker Jira (TRACKER-001).
usa_jira() { grep -qE '^tracker:[[:space:]]*"?jira"?' "$radice"/projects/*.yaml 2>/dev/null; }

# L'egress apre Atlassian solo se un progetto usa Jira (TRACKER-003). Esce 0
# se il file è cambiato, cioè se Squid va riavviato.
egress_jira() {
  local f=$base/egress/10-jira.conf
  if usa_jira; then
    [[ -f $f ]] && return 1
    printf '%s\n' "# Scritto da scripts/dojo.sh up: un progetto in projects/ usa Jira." \
      "acl dojo_dest dstdomain .atlassian.net api.atlassian.com" >"$f"
  else
    [[ -f $f ]] || return 1
    rm -f "$f"
  fi
}

up() {
  [[ ${#accesi[@]} -gt 0 ]] || die "DOJO_AGENTS è vuoto in $conf: accendi almeno un agente"
  # Prima della cartella nuova: chi aveva ~/dojo/work per la lab la ritrova
  # in ~/dojo/lab con i suoi dati.
  if [[ $room == lab && ! -e $DOJO_WORK && $DOJO_WORK == "$dojo_dir/lab" && -d $dojo_dir/work ]]; then
    mv "$dojo_dir/work" "$DOJO_WORK"
    echo "cartella di lavoro: $dojo_dir/work rinominata in $DOJO_WORK"
  fi
  mkdir -p "$DOJO_WORK"
  # La rete di Caddy di ron1n: se ron1n non c'è (PC di prova) la si crea
  # vuota, e la WebUI resta solo su 127.0.0.1.
  docker network inspect proxy >/dev/null 2>&1 || docker network create proxy >/dev/null
  create_credentials
  egress=0
  ! egress_jira || egress=1
  compose pull -q
  compose up -d
  # Squid legge conf.d all'avvio: un file di Jira nuovo o tolto lo riavvia.
  [[ $egress -eq 0 ]] || compose restart egress
  wait_seed
  push_env
  echo "WebUI: http://127.0.0.1:${WEBUI_PORT:-8787} (password in $base/webui.env)"
  echo "dashboard: http://127.0.0.1:${DASHBOARD_PORT:-9119} (utente dojo, password in $base/dashboard.env)"
  claude_logged_in || echo "manca il login Claude: scripts/dojo.sh claude"
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
has_value() { [[ -n $(val "$1") ]]; }
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

# Stato della room (ROOM-004): container, poi per ogni problema una riga con
# cosa fare.
status() {
  local p k
  docker info >/dev/null 2>&1 || die "Docker non risponde"
  compose ps
  echo
  verify TELEGRAM_ALLOWED_USERS "TELEGRAM_ALLOWED_USERS vuoto in $conf: gli agenti non rispondono a nessuno" \
    has_value TELEGRAM_ALLOWED_USERS
  for p in "${tutti[@]}"; do
    if ! acceso "$p"; then
      echo "--   $p spento (non è in DOJO_AGENTS)"
      continue
    fi
    while IFS= read -r k; do
      verify "$p $k" "${p^^}_$k vuoto in $conf" has_value "${p^^}_$k"
    done < <(chiavi_agente "$p")
  done
  if usa_jira; then
    verify "Jira JIRA_URL" "JIRA_URL vuoto in $conf: un progetto usa Jira" has_value JIRA_URL
    verify "Jira JIRA_USERNAME" "JIRA_USERNAME vuoto in $conf: un progetto usa Jira" has_value JIRA_USERNAME
    for p in strategist designer builder reviewer; do
      ! acceso "$p" || verify "Jira token di $p" "${p^^}_JIRA_API_TOKEN vuoto in $conf" has_value "${p^^}_JIRA_API_TOKEN"
    done
  fi
  verify "cartella di lavoro $DOJO_WORK" "$DOJO_WORK manca o non è scrivibile: scripts/dojo.sh up" test -w "$DOJO_WORK"
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

case ${1:-} in
  up) up ;;
  down) compose down ;;
  status) status ;;
  claude) claude ;;
  *)
    sed -n '2,11s/^# \{0,1\}//p' "$0"
    exit 1
    ;;
esac
