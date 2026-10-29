#!/usr/bin/env bash
# Installa il dojo con un comando, su qualsiasi macchina con Docker (il mini
# PC, un portatile, WSL):
#
#   curl -fsSL https://raw.githubusercontent.com/1r0n51uv/ron1n-dojo/main/scripts/install.sh | bash
#
# Clona o aggiorna il repo, chiede i valori dei .env che mancano (invio =
# default, password casuali), accende il gateway dei modelli, crea le chiavi
# delle rooms, attiva gli agenti scelti e li avvia. Si può rilanciare: i .env
# che esistono già non si toccano. Spec: docs/specs/rooms.md (ROOM-005).
#
# Variabili: DOJO_DIR (cartella, default ~/ron1n-dojo), DOJO_BRANCH (ramo da
# installare, default main).
set -euo pipefail

REPO=https://github.com/1r0n51uv/ron1n-dojo.git
BRANCH=${DOJO_BRANCH:-main}

step() { printf '\n\033[1;31m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
die() {
  printf '\033[1;31mdojo:\033[0m %s\n' "$*" >&2
  exit 1
}

# Le domande leggono dal terminale anche con `curl | bash`.
ask() {
  local domanda=$1 default=${2:-}
  printf '    %s [%s]: ' "$domanda" "$default" >/dev/tty
  IFS= read -r REPLY </dev/tty || REPLY=
  [[ -n $REPLY ]] || REPLY=$default
}
ask_secret() {
  printf '    %s: ' "$1" >/dev/tty
  IFS= read -rs REPLY </dev/tty || REPLY=
  printf '\n' >/dev/tty
}
ask_yes() {
  ask "$1 (s/n)" "${2:-s}"
  [[ $REPLY == [sSyY]* ]]
}

rand() { od -An -N24 -tx1 /dev/urandom | tr -d ' \n'; }

# Il commento sopra una chiave nel .env.example, come help_text alla domanda.
help_text() {
  awk -v k="$2" '/^#/ { c = c "    " $0 "\n"; next } $0 ~ "^" k "=" { printf "%s", c; exit } { c = "" }' "$1" >/dev/tty
}

# Scrive un .env a partire dal suo .env.example, una domanda per chiave.
# $1 file .env.example, $2 file .env, poi coppie CHIAVE=valore già decise.
write_env() {
  local esempio=$1 dest=$2 tmp key val fisso
  shift 2
  tmp=$(mktemp)
  # Le chiavi sono nomi senza spazi: una per parola.
  # shellcheck disable=SC2013
  for key in $(sed -n 's/^\([A-Z_][A-Z0-9_]*\)=.*/\1/p' "$esempio"); do
    val=
    fisso=
    for coppia in "$@"; do
      if [[ ${coppia%%=*} == "$key" ]]; then
        val=${coppia#*=}
        fisso=1
      fi
    done
    if [[ -z $fisso ]]; then
      help_text "$esempio" "$key"
      case $key in
        *PASSWORD* | *MASTER_KEY*)
          val=$(rand)
          [[ $key != *MASTER_KEY* ]] || val=sk-$val
          info "$key generata"
          ;;
        *KEY* | *TOKEN*)
          ask_secret "$key (invio = vuoto)"
          val=$REPLY
          ;;
        *)
          ask "$key"
          val=$REPLY
          ;;
      esac
    fi
    printf '%s=%s\n' "$key" "$val" >>"$tmp"
  done
  chmod 600 "$tmp"
  mv "$tmp" "$dest"
  info "scritto $dest"
}

env_get() { sed -n "s/^$2=//p" "$1" | tail -1; }

check() {
  step "Controllo"
  command -v git >/dev/null || die "manca git"
  command -v docker >/dev/null || die "manca Docker: installalo (sul mini PC lo fa il bootstrap di ron1n)"
  docker compose version >/dev/null 2>&1 || die "manca docker compose v2"
  docker info >/dev/null 2>&1 || die "Docker non risponde: avvialo, o aggiungi l'utente al gruppo docker"
  info "git, Docker e compose ok"
}

# Se lo script gira da un checkout usa quello, altrimenti clona in DOJO_DIR.
repo() {
  step "Repo"
  local qui
  qui=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." 2>/dev/null && pwd) || qui=
  if [[ -n $qui && -f $qui/scripts/dojo.sh && -z ${DOJO_DIR:-} ]]; then
    DIR=$qui
    info "uso il checkout in $DIR"
    return
  fi
  DIR=${DOJO_DIR:-$HOME/ron1n-dojo}
  if [[ -d $DIR/.git ]]; then
    git -C "$DIR" fetch -q origin "$BRANCH"
    git -C "$DIR" checkout -q "$BRANCH"
    git -C "$DIR" pull -q --ff-only origin "$BRANCH"
    info "aggiornato $DIR ($BRANCH)"
  else
    git clone -q --branch "$BRANCH" "$REPO" "$DIR"
    info "clonato in $DIR ($BRANCH)"
  fi
}

models() {
  local base=$DIR/services/models
  step "Gateway dei modelli"
  if [[ -f $base/.env ]]; then
    info "$base/.env c'è già"
  else
    info "Basta un provider: Anthropic o OpenRouter per i modelli forti,"
    info "OpenRouter, Groq o Gemini per quelli gratis."
    write_env "$base/.env.example" "$base/.env"
  fi
  "$DIR/scripts/dojo.sh" up-models
  info "attendo che LiteLLM sia pronto (al primo avvio prepara il database)"
  local _
  for _ in $(seq 1 60); do
    if docker compose --project-directory "$base" -f "$base/compose.yaml" exec -T litellm \
      python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:4000/health/liveliness')" \
      >/dev/null 2>&1; then
      info "LiteLLM pronto"
      return
    fi
    sleep 5
  done
  die "LiteLLM non risponde dopo 5 minuti: scripts/dojo.sh status e docker compose logs in services/models"
}

room() {
  local s=$1 base=$DIR/rooms/$1 api_key budget telegram dir p attivi=0
  step "Stanza $s"
  if [[ -f $base/.env ]]; then
    info "$base/.env c'è già"
  else
    while :; do
      ask "Budget mensile della room sul gateway, in dollari (maggiore di 0)" 20
      budget=$REPLY
      awk -v b="$budget" 'BEGIN { exit !(b ~ /^[0-9]+([.][0-9]+)?$/ && b + 0 > 0) }' && break
      info "serve un numero maggiore di 0: con 0 ogni richiesta verrebbe rifiutata"
    done
    api_key=$("$DIR/scripts/dojo.sh" key "$s" "$budget" | sed -n 's/^LITELLM_API_KEY=//p')
    [[ -n $api_key ]] || die "chiave della room non creata"
    info "chiave virtuale creata"
    write_env "$base/.env.example" "$base/.env" "LITELLM_API_KEY=$api_key"
  fi
  telegram=$(env_get "$base/.env" TELEGRAM_ALLOWED_USERS)
  [[ -n $telegram ]] || info "TELEGRAM_ALLOWED_USERS è vuoto: gli agenti non risponderanno a nessuno"

  for dir in "$base"/profiles/*/; do
    p=$(basename "$dir")
    [[ $p != default ]] || continue
    if [[ -f $dir.env ]]; then
      attivi=$((attivi + 1))
      continue
    fi
    echo >/dev/tty
    info "$(sed -n '1s/^# //p' "${dir}SOUL.md")"
    if ask_yes "Attivare $p adesso?" s; then
      write_env "${dir}.env.example" "${dir}.env"
      attivi=$((attivi + 1))
    else
      info "$p resta spento: rilancia l'installazione per attivarlo"
    fi
  done
  if [[ $attivi -eq 0 ]]; then
    info "nessun agente attivo in $s: salto l'avvio"
    return
  fi
  "$DIR/scripts/dojo.sh" sync "$s"
}

# Tutto dentro main: con `curl | bash` lo script arriva da stdin, e un
# comando figlio che legge stdin (docker compose exec) ne mangerebbe il
# resto. Così bash lo legge tutto prima di eseguire, e i figli leggono da
# /dev/null; le domande vanno comunque a /dev/tty.
main() {
  exec </dev/null
  check
  repo
  models
  local c
  for c in "$DIR"/rooms/*/compose.yaml; do
    room "$(basename "$(dirname "$c")")"
  done

  step "Fatto"
  info "Stato: $DIR/scripts/dojo.sh status"
  info "Segreti: i .env in $DIR/services/models e $DIR/rooms/*/ (permessi 600)"
  info "Scrivi ai bot su Telegram: per esempio /new-feature <repo> <idea> a Shikamaru"
}

main "$@"
