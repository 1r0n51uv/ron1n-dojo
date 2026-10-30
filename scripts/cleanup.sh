#!/usr/bin/env bash
# Toglie il dojo dal PC, un gruppo alla volta (ROOM-014). Per ogni gruppo
# mostra cosa sparisce e chiede conferma (s/n, invio = no): non cancella
# niente senza un sì. Va lanciato da un checkout del repo:
#
#   scripts/cleanup.sh
#
# Prima di tutto chiede se fare un backup dei file importanti (configurazione
# con i token, volumi di Hermes, cartella di lavoro) in una cartella a scelta;
# se il backup fallisce, si ferma prima di cancellare. Poi i gruppi: avanzi
# delle versioni vecchie (gateway LiteLLM, inoltri per il
# telefono, dojo-kajiba), room lab accesa, dati della lab (volume e cartella
# di lavoro), configurazione (dojo.env e password), immagini. La rete `proxy`
# è di ron1n e resta. Alla fine stampa i comandi da lanciare a mano per
# quello che lo script non raggiunge (Windows, il checkout, AionUi).
set -euo pipefail

cd "$(dirname "$0")/.."
radice=$PWD

die() {
  echo "dojo: $*" >&2
  exit 1
}

command -v docker >/dev/null || die "manca Docker"
docker info >/dev/null 2>&1 || die "Docker non risponde: avvialo e rilancia"
[[ -t 0 ]] || die "serve un terminale per le conferme"

# Cartella delle rooms da dojo.env (DOJO_ROOMS_DIR, default ~/dojo).
rooms_dir=
if [[ -f $radice/dojo.env ]]; then
  rooms_dir=$(sed -n 's/^DOJO_ROOMS_DIR=//p' "$radice/dojo.env" | tail -1)
fi
rooms_dir=${rooms_dir:-$HOME/dojo}
rooms_dir=${rooms_dir/#\~/$HOME}

conferma() {
  local risposta
  read -r -p "$1 (s/n) [n]: " risposta || risposta=
  [[ $risposta == [sSyY]* ]]
}

# Container, volumi e reti di un progetto compose (anche fermi).
container_di() { docker ps -a -q --filter "label=com.docker.compose.project=$1" 2>/dev/null || true; }
volumi_di() { docker volume ls -q --filter "label=com.docker.compose.project=$1" 2>/dev/null || true; }
reti_di() { docker network ls -q --filter "label=com.docker.compose.project=$1" 2>/dev/null || true; }

# Nomi (non id) per mostrare cosa sparisce.
nomi_container() { docker ps -a --format '{{.Names}}' --filter "label=com.docker.compose.project=$1" 2>/dev/null || true; }

rimuovi_container() {
  local ids
  ids=$(container_di "$1")
  # shellcheck disable=SC2086
  [[ -z $ids ]] || docker rm -f $ids >/dev/null
}
rimuovi_volumi() {
  local v
  for v in $(volumi_di "$1"); do docker volume rm "$v" >/dev/null || true; done
}
rimuovi_reti() {
  local n
  for n in $(reti_di "$1"); do docker network rm "$n" >/dev/null 2>&1 || true; done
}

# Backup dei file importanti (config con i token, volumi di Hermes, cartella
# di lavoro) in una cartella a scelta. I volumi si leggono con un container
# usa e getta, con l'immagine della lab se c'è, altrimenti alpine.
backup() {
  local dest immagine v
  echo
  echo "== Backup"
  conferma "Vuoi fare un backup dei file importanti prima di cancellare?" || return 0
  read -r -p "Dove lo metto? [$HOME/dojo-backup-$(date +%Y%m%d)]: " dest || dest=
  dest=${dest:-$HOME/dojo-backup-$(date +%Y%m%d)}
  dest=${dest/#\~/$HOME}
  (umask 077 && mkdir -p "$dest") || die "non riesco a creare $dest"
  dest=$(cd "$dest" && pwd -P)
  # Il backup non può stare dentro quello che poi si cancella.
  case $dest/ in
    "$radice"/* | "$rooms_dir"/*) die "scegli una cartella fuori da $radice e da $rooms_dir" ;;
  esac
  echo "   I file contengono token e password: la cartella resta leggibile solo a te."

  if conferma "   Configurazione (dojo.env, password della WebUI e della dashboard)?"; then
    local f copiati=()
    for f in dojo.env rooms/lab/webui.env rooms/lab/dashboard.env; do
      [[ ! -f $radice/$f ]] || copiati+=("$f")
    done
    ((${#copiati[@]})) || echo "   nessun file di configurazione"
    ((${#copiati[@]} == 0)) || tar -czf "$dest/configurazione.tar.gz" -C "$radice" "${copiati[@]}"
  fi

  immagine=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -E '(^|/)dojo-lab:' | head -1 || true)
  immagine=${immagine:-alpine:3.20}
  for v in dojo-lab_data dojo-kajiba_dati; do
    docker volume inspect "$v" >/dev/null 2>&1 || continue
    if conferma "   Volume $v (memorie e sessioni degli agenti, login Claude)?"; then
      docker run --rm --entrypoint tar -v "$v:/dati:ro" -v "$dest:/backup" "$immagine" \
        -czf "/backup/$v.tar.gz" -C /dati . || die "backup di $v non riuscito: non cancello niente"
    fi
  done

  for v in lab work; do
    [[ -d $rooms_dir/$v ]] || continue
    ! conferma "   Cartella di lavoro $rooms_dir/$v?" ||
      tar -czf "$dest/cartella-$v.tar.gz" -C "$rooms_dir" "$v" || die "backup di $v non riuscito: non cancello niente"
  done
  chmod 600 "$dest"/*.tar.gz 2>/dev/null || true
  echo "   Backup in $dest"
}

echo "Cleanup del dojo. Ogni gruppo chiede conferma; invio vuol dire no."
backup

# 1. Avanzi delle versioni vecchie.
vecchi=()
for c in dojo-lan-webui dojo-lan-dashboard; do
  ! docker inspect "$c" >/dev/null 2>&1 || vecchi+=("container $c (inoltro per il telefono)")
done
[[ -z $(container_di dojo-models) && -z $(volumi_di dojo-models) ]] ||
  vecchi+=("gateway LiteLLM: progetto dojo-models (container $(nomi_container dojo-models | tr '\n' ' '), volumi)")
! docker network inspect dojo-lab-models >/dev/null 2>&1 || vecchi+=("rete dojo-lab-models")
[[ -z $(container_di dojo-kajiba) ]] || vecchi+=("container di dojo-kajiba")
if ((${#vecchi[@]})); then
  echo
  echo "== Avanzi delle versioni vecchie"
  printf '   - %s\n' "${vecchi[@]}"
  if conferma "Li tolgo?"; then
    for c in dojo-lan-webui dojo-lan-dashboard; do docker rm -f "$c" >/dev/null 2>&1 || true; done
    rimuovi_container dojo-models
    rimuovi_volumi dojo-models
    rimuovi_reti dojo-models
    docker network rm dojo-lab-models >/dev/null 2>&1 || true
    rimuovi_container dojo-kajiba
    echo "   fatto"
  fi
fi

# 2. Backup della prima versione: le memorie degli agenti di allora.
if docker volume inspect dojo-kajiba_dati >/dev/null 2>&1; then
  echo
  echo "== Backup della prima versione"
  echo "   - volume dojo-kajiba_dati (memorie degli agenti di allora, non si recupera)"
  ! conferma "Lo tolgo?" || { docker volume rm dojo-kajiba_dati >/dev/null && echo "   fatto"; }
fi

# 3. Room lab accesa.
if [[ -n $(container_di dojo-lab) ]]; then
  echo
  echo "== Room lab accesa"
  nomi_container dojo-lab | sed 's/^/   - container /'
  ! conferma "La spengo e tolgo i container (i dati restano)?" || {
    rimuovi_container dojo-lab
    rimuovi_reti dojo-lab
    echo "   fatto"
  }
fi

# 4. Dati della lab.
dati=()
[[ -z $(volumi_di dojo-lab) ]] || dati+=("volume Hermes: $(volumi_di dojo-lab | tr '\n' ' ')(memoria, sessioni, login Claude)")
for d in lab work; do
  [[ ! -d $rooms_dir/$d ]] || dati+=("cartella di lavoro $rooms_dir/$d")
done
if ((${#dati[@]})); then
  echo
  echo "== Dati della lab (non si recuperano)"
  printf '   - %s\n' "${dati[@]}"
  if conferma "Li tolgo?"; then
    rimuovi_container dojo-lab
    rimuovi_volumi dojo-lab
    for d in lab work; do
      # Le cartelle sono dell'utente del PC: nessun sudo.
      [[ ! -d $rooms_dir/$d ]] || rm -rf "${rooms_dir:?}/$d"
    done
    rmdir "$rooms_dir" 2>/dev/null || true
    echo "   fatto"
  fi
fi

# 5. Configurazione.
conf=()
for f in dojo.env rooms/lab/webui.env rooms/lab/dashboard.env rooms/lab/egress/10-jira.conf; do
  [[ ! -f $radice/$f ]] || conf+=("$f")
done
if ((${#conf[@]})); then
  echo
  echo "== Configurazione (token, password, egress di Jira)"
  printf '   - %s\n' "${conf[@]}"
  ! conferma "La tolgo?" || { (cd "$radice" && rm -f "${conf[@]}") && echo "   fatto"; }
fi

# 6. Immagini: quelle in uso da altri container restano.
immagini=$(docker images --format '{{.Repository}}:{{.Tag}}' |
  grep -E '(^|/)(dojo-lab|litellm|hermes-agent):|^alpine/socat:|^ubuntu/squid:' || true)
if [[ -n $immagini ]]; then
  echo
  echo "== Immagini"
  while IFS= read -r i; do echo "   - $i"; done <<<"$immagini"
  if conferma "Le tolgo?"; then
    while IFS= read -r i; do docker rmi "$i" >/dev/null 2>&1 || echo "   resta (in uso): $i"; done <<<"$immagini"
    echo "   fatto"
  fi
fi

cat <<TESTO

Resta da fare a mano, se ti serve:
- Il checkout del repo (questo): esci dalla cartella e togli $radice
    cd ~ && rm -rf "$radice"
- Su Windows, in PowerShell come amministratore, per l'accesso dal telefono:
    netsh interface portproxy reset
    Remove-NetFirewallRule -DisplayName "dojo LAN"
- In AionUi, se l'avevi collegata: togli l'agente Hermes che usa scripts/hermes-acp.cmd.
- La rete \`proxy\` è di ron1n e non si tocca.
TESTO
