#!/usr/bin/env bash
# Installa il dojo con un comando sul mini PC (va anche su un'altra macchina
# Linux con Docker, per le prove):
#
#   curl -fsSL https://raw.githubusercontent.com/1r0n51uv/ron1n-dojo/main/scripts/install.sh | bash
#
# Clona o aggiorna il repo, scrive dojo.env con le tue risposte (invio =
# vuoto, token nascosti), scarica l'immagine da GHCR, avvia la room, fa il
# login Claude e lancia `dojo.sh status`. Si può rilanciare: un dojo.env che
# esiste già non si tocca. Spec: docs/specs/rooms.md (ROOM-005).
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

# Imposta CHIAVE=valore in dojo.env, dove c'è già la riga del modello. Il
# valore passa dall'ambiente di awk, non dalla riga di comando.
set_value() {
  local f=$1 tmp
  tmp=$(mktemp)
  chmod 600 "$tmp"
  VALORE=$3 awk -v k="$2" 'index($0, k "=") == 1 { print k "=" ENVIRON["VALORE"]; next } { print }' "$f" >"$tmp"
  mv "$tmp" "$f"
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

# dojo.env: un solo file con tutta la configurazione (ROOM-004), copiato da
# dojo.env.example con le risposte al posto dei valori vuoti.
config() {
  local f=$DIR/dojo.env esempio=$DIR/dojo.env.example p P k accesi=
  step "Configurazione"
  if [[ -f $f ]]; then
    info "$f c'è già: per cambiare qualcosa modificalo e lancia scripts/dojo.sh up"
    return
  fi
  install -m 600 "$esempio" "$f.tmp"
  info "Il tuo user ID Telegram numerico (da @userinfobot): l'unico a cui gli agenti rispondono."
  ask TELEGRAM_ALLOWED_USERS
  set_value "$f.tmp" TELEGRAM_ALLOWED_USERS "$REPLY"
  info "Cartella che contiene quelle delle rooms (la lab lavora in <cartella>/lab), con i tuoi permessi."
  ask DOJO_DIR "$(env_get "$esempio" DOJO_DIR)"
  set_value "$f.tmp" DOJO_DIR "$REPLY"
  for p in concierge strategist designer builder reviewer; do
    P=${p^^}
    echo >/dev/tty
    info "$(sed -n '1s/^# //p' "$DIR/rooms/lab/profiles/$p/SOUL.md")"
    if ! ask_yes "Accendere $p?" s; then
      info "$p resta spento: aggiungilo a DOJO_AGENTS in $f quando vuoi"
      continue
    fi
    accesi+=" $p"
    while IFS= read -r k <&3; do
      ask_secret "$k (invio = vuoto, lo metti dopo in dojo.env)"
      set_value "$f.tmp" "$k" "$REPLY"
    done 3< <(sed -n "s/^\(${P}_[A-Z0-9_]*\)=.*/\1/p" "$esempio")
  done
  [[ -n $accesi ]] || die "nessun agente acceso: rilancia e accendine almeno uno"
  set_value "$f.tmp" DOJO_AGENTS "${accesi# }"
  mv "$f.tmp" "$f"
  info "scritto $f (permessi 600)"
}

start() {
  step "Avvio"
  "$DIR/scripts/dojo.sh" up
  step "Abbonamento Claude"
  info "Tutti gli agenti usano Claude con il tuo abbonamento (Pro o Max)."
  "$DIR/scripts/dojo.sh" claude </dev/tty
}

# Tutto dentro main: con `curl | bash` lo script arriva da stdin, e un
# comando figlio che legge stdin (docker compose exec) ne mangerebbe il
# resto. Così bash lo legge tutto prima di eseguire, e i figli leggono da
# /dev/null; le domande vanno comunque a /dev/tty.
main() {
  exec </dev/null
  check
  repo
  config
  start

  step "Controllo finale"
  "$DIR/scripts/dojo.sh" status || info "sistema le righe NO qui sopra, poi $DIR/scripts/dojo.sh status"

  step "Fatto"
  info "Configurazione: $DIR/dojo.env; dopo una modifica, $DIR/scripts/dojo.sh up"
  info "WebUI: http://127.0.0.1:8787, password in $DIR/rooms/lab/webui.env"
  info "Oppure scrivi ai bot su Telegram, per esempio a Nico Robin"
}

main "$@"
