#!/usr/bin/env bash
# Gestione delle rooms del dojo (spec docs/specs/rooms.md).
#
#   scripts/dojo.sh up [room...]      avvia le rooms (tutte senza nomi)
#   scripts/dojo.sh down [room...]    spegne le rooms, i dati restano
#   scripts/dojo.sh status [room...]  stato dei container
#   scripts/dojo.sh sync <room>       copia config, SOUL e .env dei profiles
#                                      nel volume della room e riavvia il gateway
#   scripts/dojo.sh up-models         avvia solo il gateway dei modelli
#   scripts/dojo.sh provider <nome>    imposta la chiave di un provider (anthropic,
#                                      openrouter, groq, gemini), input nascosto
#   scripts/dojo.sh chatgpt [off]     login all'abbonamento ChatGPT (Plus o Pro)
#                                      e strong/fast su ChatGPT; off torna indietro
#   scripts/dojo.sh claude <room> [agente...|off]
#                                      login all'abbonamento Claude (Pro o Max) e
#                                      Claude come modello degli agenti (tutti
#                                      senza nomi), con il gateway come riserva
#   scripts/dojo.sh secret <room> <agente> <CHIAVE>
#                                      imposta un valore (per esempio GH_TOKEN o
#                                      TELEGRAM_BOT_TOKEN) nel .env di un agente,
#                                      input nascosto, poi sync della room
#   scripts/dojo.sh budget <room> <dollari>
#                                      cambia il budget mensile della chiave
#   scripts/dojo.sh key <room> [budget]
#                                      crea la chiave virtuale della room sul
#                                      gateway dei modelli (budget in dollari, 20)
#   scripts/dojo.sh folder <room> <cartella...|off>
#                                      cartelle del PC in sola lettura in
#                                      /opt/pc/<nome>, senza i file .env;
#                                      off le toglie
#
# Senza nomi, up e down includono il gateway dei modelli (services/models):
# acceso per primo, spento per ultimo.
set -euo pipefail

cd "$(dirname "$0")/.."
radice=$PWD

die() {
  echo "dojo: $*" >&2
  exit 1
}

valid_rooms() {
  for c in rooms/*/compose.yaml; do basename "$(dirname "$c")"; done
}

pick_rooms() {
  if [[ $# -eq 0 ]]; then
    valid_rooms
    return
  fi
  for c in "$@"; do
    [[ -f "rooms/$c/compose.yaml" ]] || die "room sconosciuta: $c (valide: $(valid_rooms | tr '\n' ' '))"
    echo "$c"
  done
}

compose() {
  local room=$1 base="$radice/rooms/$1" files
  shift
  files=(-f "$base/compose.yaml")
  # Cartelle del PC montate con `dojo.sh folder` (ROOM-010), non versionato.
  [[ ! -f "$base/folders.yaml" ]] || files+=(-f "$base/folders.yaml")
  docker compose --project-directory "$base" "${files[@]}" "$@"
}

models() {
  docker compose --project-directory "$radice/services/models" -f "$radice/services/models/compose.yaml" "$@"
}

# Ogni room ha una rete sua verso il gateway dei modelli, senza internet:
# così le rooms non si vedono fra loro. Le reti nascono dalle cartelle in
# rooms/ e il gateway, se è acceso, si collega a ognuna.
create_networks() {
  local s id
  for s in $(valid_rooms); do
    docker network inspect "dojo-$s-models" >/dev/null 2>&1 ||
      docker network create --internal "dojo-$s-models" >/dev/null
  done
  id=$(models ps -q litellm 2>/dev/null) || id=
  [[ -n $id ]] || return 0
  for s in $(valid_rooms); do
    docker network connect --alias litellm "dojo-$s-models" "$id" 2>/dev/null || true
  done
}

up_models() {
  models up -d
  create_networks
}

# Chiave virtuale LiteLLM per una room, con un budget che si azzera ogni
# mese. Vale per tutti i modelli del gateway, riserve comprese. La stampa: va nel .env della room.
key() {
  local room=$1 budget=${2:-20}
  # Un budget a 0 o non numerico blocca ogni richiesta della room.
  awk -v b="$budget" 'BEGIN { exit !(b ~ /^[0-9]+([.][0-9]+)?$/ && b + 0 > 0) }' ||
    die "budget non valido: $budget (serve un numero maggiore di 0, in dollari)"
  models exec -T litellm python3 - "$room" "$budget" <<'PY'
import json, os, sys, urllib.request
room, budget = sys.argv[1], float(sys.argv[2])
corpo = {
    "key_alias": f"room-{room}",
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

# Cambia il budget mensile della chiave di una room. Non cambia la chiave:
# i .env e i container restano come sono.
budget() {
  local room=$1 importo=$2
  awk -v b="$importo" 'BEGIN { exit !(b ~ /^[0-9]+([.][0-9]+)?$/ && b + 0 > 0) }' ||
    die "budget non valido: $importo (serve un numero maggiore di 0, in dollari)"
  models exec -T litellm python3 - "$room" "$importo" <<'PY'
import json, os, sys, urllib.parse, urllib.request
room, importo = sys.argv[1], float(sys.argv[2])
base = "http://localhost:4000"
testa = {
    "Authorization": "Bearer " + os.environ["LITELLM_MASTER_KEY"],
    "Content-Type": "application/json",
}


def chiama(percorso, corpo=None):
    req = urllib.request.Request(
        base + percorso,
        data=None if corpo is None else json.dumps(corpo).encode(),
        headers=testa,
    )
    return json.load(urllib.request.urlopen(req))


def cerca(alias):
    q = urllib.parse.urlencode({"key_alias": alias, "return_full_object": "true"})
    return chiama("/key/list?" + q).get("keys", [])


chiavi = cerca(f"room-{room}")
# La room lab si chiamava kajiba e le room stanze: la sua chiave può avere
# ancora un nome vecchio, che qui viene rinominato.
if not chiavi:
    for vecchio in (f"stanza-{room}", "stanza-kajiba"):
        chiavi = cerca(vecchio)
        if chiavi:
            break
if not chiavi:
    sys.exit(f"nessuna chiave room-{room}: usa dojo.sh key {room}")
for k in chiavi:
    token = k["token"] if isinstance(k, dict) else k
    chiama("/key/update", {"key": token, "max_budget": importo, "key_alias": f"room-{room}"})
    info = chiama("/key/info?" + urllib.parse.urlencode({"key": token}))["info"]
    print(f"room-{room}: max_budget {info.get('max_budget')}, spesa {info.get('spend')}")
PY
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

# Chiave di un provider nel .env del gateway, chiesta con input nascosto e
# senza passare dalla riga di comando né dalla cronologia. Poi riavvia solo
# LiteLLM: le rooms non si accorgono di nulla.
provider() {
  local nome=$1 var f="$radice/services/models/.env" valore tmp
  case $nome in
    anthropic) var=ANTHROPIC_API_KEY ;;
    openrouter) var=OPENROUTER_API_KEY ;;
    groq) var=GROQ_API_KEY ;;
    gemini) var=GEMINI_API_KEY ;;
    *) die "provider sconosciuto: $nome (validi: anthropic openrouter groq gemini)" ;;
  esac
  [[ -f $f ]] || die "manca $f: lancia prima scripts/install.sh"
  printf '%s: ' "$var" >/dev/tty
  IFS= read -rs valore </dev/tty
  printf '\n' >/dev/tty
  [[ -n $valore ]] || die "valore vuoto, non cambio nulla"
  env_set "$f" "$var" "$valore"
  up_models
  echo "$var aggiornata, LiteLLM riavviato e ricollegato alle rooms"
}

# Abbonamento ChatGPT davanti a strong e fast (config.chatgpt.yaml). Il
# login con codice dispositivo gira in un container usa e getta del gateway:
# il token resta nel volume chatgpt, che le rooms non vedono. Rilanciarlo con
# il login già fatto non chiede nulla. `off` torna a config.yaml.
chatgpt() {
  local f="$radice/services/models/.env"
  [[ -f $f ]] || die "manca $f: lancia prima scripts/install.sh"
  if [[ ${1:-} == off ]]; then
    env_set "$f" LITELLM_CONFIG config.yaml
    up_models
    echo "strong e fast tornano ai provider di config.yaml"
    return
  fi
  echo "Apri il link, accedi con l'account ChatGPT e inserisci il codice."
  # Un tentativo lasciato a metà (senza token) farebbe aspettare a LiteLLM 5
  # minuti in silenzio prima di chiedere un codice nuovo: si azzera.
  models run --rm --no-deps --entrypoint python3 litellm -c '
import os
from litellm.llms.chatgpt.authenticator import Authenticator
a = Authenticator()
dati = a._read_auth_file() or {}
if not dati.get("access_token") and os.path.exists(a.auth_file):
    os.remove(a.auth_file)
    print("tentativo di login precedente azzerato")
a.get_access_token()
print("login ChatGPT ok, account", a.get_account_id())
'
  env_set "$f" LITELLM_CONFIG config.chatgpt.yaml
  up_models
  echo "strong e fast usano ChatGPT; finita la quota si scende sui provider di riserva"
}

# Abbonamento Claude come modello degli agenti di una room (MODELS-006). La
# CLI ufficiale di Claude Code, nell'immagine della room, fa il login: il token
# sta nel volume della room (/opt/data/claude), non nel gateway. claude.env
# dice quali agenti lo usano e con che modello; egress/00-claude.conf apre i
# domini di Anthropic. `off` toglie i due file e gli agenti tornano al gateway;
# il login resta, finché non lo togli da claude.ai o con `claude auth logout`.
claude_cli() {
  local room=$1
  shift
  compose "$room" exec -u hermes -e USER=hermes -e LOGNAME=hermes \
    -e CLAUDE_CONFIG_DIR=/opt/data/claude -e DISABLE_AUTOUPDATER=1 \
    -e CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 "$@"
}

# L'uscita si legge tutta prima di cercarci dentro: con `grep -q` in pipe e
# pipefail, grep chiude presto e il comando a monte fallisce anche col login.
claude_logged_in() {
  local stato
  stato=$(claude_cli "$1" -T hermes claude auth status 2>&1) || true
  [[ $stato =~ \"loggedIn\":[[:space:]]*true ]] && return 0
  [[ ${2:-} != verbose ]] || echo "$stato" >&2
  return 1
}

claude_sub() {
  local room=$1 base="rooms/$1" agenti=() modello p
  shift
  if [[ ${1:-} == off ]]; then
    rm -f "$base/claude.env" "$base/egress/00-claude.conf"
    compose "$room" restart egress
    sync_room "$room"
    echo "gli agenti di $room tornano al gateway dei modelli"
    return
  fi
  [[ -f "$base/.env" ]] || die "manca $base/.env: lancia prima scripts/install.sh"
  if [[ $# -eq 0 ]]; then
    for p in "$base"/profiles/*/; do
      p=$(basename "$p")
      [[ $p == default || ! -f "$base/profiles/$p/.env" ]] || agenti+=("$p")
    done
  else
    for p in "$@"; do
      [[ $p != default && -d "$base/profiles/$p" ]] || die "agente sconosciuto: $p"
      agenti+=("$p")
    done
  fi
  [[ ${#agenti[@]} -gt 0 ]] || die "nessun agente attivo in $room"
  # Il modello scelto la volta prima resta (CLAUDE_MODEL in claude.env).
  modello=$(sed -n 's/^CLAUDE_MODEL=//p' "$base/claude.env" 2>/dev/null) || modello=
  modello=${modello:-sonnet}

  # Il nome comincia con 00: Squid include i file in ordine alfabetico.
  cat >"$base/egress/00-claude.conf" <<'EOF'
# Scritto da `scripts/dojo.sh claude`: abbonamento Claude acceso (MODELS-006).
# API, login dell'account e scambio del token OAuth della CLI di Claude Code.
acl dojo_dest dstdomain api.anthropic.com claude.ai platform.claude.com
EOF
  create_networks
  compose "$room" up -d --build
  compose "$room" restart egress
  compose "$room" exec -T hermes install -d -m 700 -o hermes -g hermes /opt/data/claude
  if claude_logged_in "$room"; then
    echo "login Claude già fatto"
  else
    echo "Apri il link, accedi con l'account Claude (Pro o Max) e incolla qui il codice."
    claude_cli "$room" hermes claude auth login --claudeai
    claude_logged_in "$room" verbose || die "login Claude non riuscito (stato qui sopra)"
  fi
  {
    echo "CLAUDE_AGENTS=${agenti[*]}"
    echo "CLAUDE_MODEL=$modello"
  } >"$base/claude.env"
  sync_room "$room"
  echo "${agenti[*]}: Claude ($modello) con l'abbonamento; finita la quota si passa al gateway"
}

# Un valore nel .env di un agente (token del bot, GH_TOKEN), chiesto con input
# nascosto: non passa dalla riga di comando né dalla cronologia. Se il .env
# non c'è lo crea dal .env.example. Poi allinea la room.
secret() {
  local room=$1 agente=$2 var=$3 dir="$radice/rooms/$1/profiles/$2" f valore tmp
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
  sync_room "$room"
}

# Cartella del profile dentro il volume: il default è la radice di HERMES_HOME.
profile_dir() {
  if [[ $1 == default ]]; then echo /opt/data; else echo "/opt/data/profiles/$1"; fi
}

rand() { od -An -N24 -tx1 /dev/urandom | tr -d ' \n'; }

# Credenziali della dashboard di Hermes: casuali, solo in dashboard.env (non
# nei .env dei profiles, che gli agenti leggono). Se il file esiste non si tocca.
create_dashboard() {
  local f="rooms/$1/dashboard.env"
  [[ ! -f $f ]] || return 0
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
}

# Interfaccia web (hermes-webui, ROOM-009): password casuale e chiave dell'API
# del gateway, in webui.env. La chiave va anche nel .env di ogni profile,
# perché il gateway accetta su /p/<agente> solo la chiave di quel profile.
create_webui() {
  local f="rooms/$1/webui.env" chiave
  [[ ! -f $f ]] || return 0
  chiave=$(rand)
  (
    umask 077
    {
      echo "HERMES_WEBUI_PASSWORD=$(rand)"
      echo "API_SERVER_KEY=$chiave"
      echo "HERMES_WEBUI_GATEWAY_API_KEY=$chiave"
    } >"$f"
  )
  echo "creato $f: password dell'interfaccia web lì dentro"
}

sync_room() {
  local room=$1 base="rooms/$1" tmp p dest api_key claude_agenti='' claude_modello=''
  [[ -f "$base/.env" ]] || die "manca $base/.env: copia $base/.env.example e compilalo"
  if [[ -f "$base/claude.env" ]]; then
    claude_agenti=$(sed -n 's/^CLAUDE_AGENTS=//p' "$base/claude.env")
    claude_modello=$(sed -n 's/^CLAUDE_MODEL=//p' "$base/claude.env")
  fi
  create_dashboard "$room"
  create_webui "$room"
  api_key=$(sed -n 's/^API_SERVER_KEY=//p' "$base/webui.env")
  tmp=$(mktemp -d)
  # Il trap RETURN resta attivo anche dopo: si toglie da solo, altrimenti
  # scatta al ritorno di chi ha chiamato sync_room, dove tmp non c'è.
  trap 'rm -rf "$tmp"; trap - RETURN' RETURN

  create_networks
  compose "$room" up -d --build
  compose "$room" exec -T hermes mkdir -p /opt/data/work

  for dir in "$base"/profiles/*/; do
    p=$(basename "$dir")
    dest=$(profile_dir "$p")
    # Un agente senza .env non si attiva ancora: si può partire da uno solo.
    if [[ $p != default && ! -f "$dir/.env" ]]; then
      echo "salto $room/$p: manca ${dir}.env"
      continue
    fi
    if [[ $p != default ]] && ! compose "$room" exec -T hermes test -f "$dest/SOUL.md"; then
      # Profili stretti: nessuna skill inclusa, solo i flows del dojo.
      compose "$room" exec -T hermes hermes profile create "$p" --no-skills
    fi
    # .env del profile = valori comuni della room + quelli dell'agente.
    cat "$base/.env" >"$tmp/$p.env"
    [[ ! -f "$dir/.env" ]] || cat "$dir/.env" >>"$tmp/$p.env"
    # API del gateway per l'interfaccia web: la chiave e l'indirizzo del
    # profile (/p/<agente> sul gateway che serve tutti i profiles).
    {
      echo "API_SERVER_KEY=$api_key"
      if [[ $p == default ]]; then
        echo "HERMES_WEBUI_GATEWAY_BASE_URL=http://hermes:8642"
      else
        echo "HERMES_WEBUI_GATEWAY_BASE_URL=http://hermes:8642/p/$p"
      fi
    } >>"$tmp/$p.env"
    compose "$room" cp "$dir/config.yaml" "hermes:$dest/config.yaml"
    # Abbonamento Claude acceso per questo agente: Claude davanti, il modello
    # del repo diventa la riserva (scripts/claude_profile.py).
    if [[ " ${claude_agenti:-} " == *" $p "* ]]; then
      compose "$room" exec -T hermes /opt/hermes/.venv/bin/python - \
        "$dest/config.yaml" "$claude_modello" <scripts/claude_profile.py
      echo "     $p usa Claude ($claude_modello), riserva il gateway"
    fi
    compose "$room" cp "$dir/SOUL.md" "hermes:$dest/SOUL.md"
    compose "$room" cp "$tmp/$p.env" "hermes:$dest/.env"
    # Plugin della room (rooms/<room>/plugins/), uguali per tutti i profiles:
    # ognuno li abilita in plugins.enabled del suo config.yaml.
    if [[ -d "$base/plugins" ]]; then
      compose "$room" exec -T hermes mkdir -p "$dest/plugins"
      compose "$room" cp "$base/plugins/." "hermes:$dest/plugins/"
    fi
    # `compose cp` crea i file come root: Hermes gira come utente hermes e
    # senza questo non riesce a leggere il .env (né quello del default, che
    # serve già al comando successivo).
    compose "$room" exec -T hermes chown hermes:hermes \
      "$dest/config.yaml" "$dest/SOUL.md" "$dest/.env"
    compose "$room" exec -T hermes chmod 600 "$dest/.env"
    echo "ok   $room/$p"
  done

  # Il gateway acceso scrive e rinomina file temporanei mentre chown -R li
  # attraversa: se uno sparisce a metà, un secondo giro basta.
  compose "$room" exec -T hermes chown -R hermes:hermes /opt/data 2>/dev/null ||
    compose "$room" exec -T hermes chown -R hermes:hermes /opt/data
  compose "$room" exec -T hermes hermes gateway restart
  echo "dashboard: http://127.0.0.1:${DASHBOARD_PORT:-9119} (utente e password in $base/dashboard.env)"
}

# Cartelle del PC nella room (ROOM-010), per esempio il repo del dojo da
# aprire come spazio della WebUI. Ognuna va in sola lettura in
# /opt/pc/<nome>, sia in hermes (dove girano i tool) sia in webui; i
# file .env e *.env che ci sono adesso vengono coperti con /dev/null, così i
# segreti non entrano nella room. folders.yaml (non versionato) è l'override
# di compose che le monta; `off` lo toglie.
folders() {
  local room=$1 base="rooms/$1" dir nome dest f s i mounts='' env='' dests=()
  shift
  if [[ $1 == off ]]; then
    [[ $# -eq 1 ]] || die "uso: dojo.sh folder <room> <cartella...|off>"
    rm -f "$base/folders.yaml"
    compose "$room" up -d
    echo "nessuna cartella del PC in $room"
    return
  fi
  for dir in "$@"; do
    [[ -d $dir ]] || die "cartella inesistente: $dir"
    dir=$(cd "$dir" && pwd -P)
    # Virgolette, backslash e $ romperebbero lo YAML o l'interpolazione di
    # compose; i due punti la sintassi dei volumi.
    [[ $dir != *[\"\\\$:$'\n']* ]] || die "percorso con caratteri non ammessi: $dir"
    nome=$(basename "$dir")
    [[ $nome =~ ^[A-Za-z0-9._-]+$ ]] || die "nome di cartella non ammesso: $nome"
    # Fuori dal volume /opt/data: `sync` fa chown -R lì dentro e su una
    # cartella in sola lettura fallirebbe.
    dest=/opt/pc/$nome
    [[ " ${dests[*]} " != *" $dest "* ]] || die "due cartelle con lo stesso nome: $nome"
    dests+=("$dest")
    mounts+="      - \"$dir:$dest:ro\"\n"
    # I file devono esistere già: sopra una cartella in sola lettura Docker
    # non crea il punto di montaggio. Per quelli nuovi si rilancia il comando.
    while IFS= read -r -d '' f; do
      [[ $f != *[\"\\\$:$'\n']* ]] || die "percorso con caratteri non ammessi: $f"
      mounts+="      - \"/dev/null:$dest/${f#"$dir"/}:ro\"\n"
    done < <(find "$dir" -path "$dir/node_modules" -prune -o -path "$dir/.git" -prune -o \
      -type f \( -name .env -o -name '*.env' \) -print0)
  done
  # I file sono dell'utente del PC, non di hermes: senza safe.directory git
  # rifiuta i repo ("dubious ownership"). Variabili d'ambiente e non
  # ~/.gitconfig, perché Hermes cambia HOME per ogni profile.
  env+="      GIT_CONFIG_COUNT: \"${#dests[@]}\"\n"
  for i in "${!dests[@]}"; do
    env+="      GIT_CONFIG_KEY_$i: safe.directory\n"
    env+="      GIT_CONFIG_VALUE_$i: \"${dests[$i]}\"\n"
  done
  {
    echo "# Scritto da \`scripts/dojo.sh folder\` (ROOM-010): cartelle del PC in sola"
    echo "# lettura, con i file .env coperti. Non versionato."
    echo "services:"
    for s in hermes webui; do
      echo "  $s:"
      echo "    environment:"
      printf '%b' "$env"
      echo "    volumes:"
      printf '%b' "$mounts"
    done
  } >"$base/folders.yaml"
  create_networks
  compose "$room" up -d --build
  for dest in "${dests[@]}"; do echo "ok   $dest (sola lettura)"; done
  echo "WebUI: aggiungi la cartella fra gli spazi con il percorso qui sopra"
}

comando=${1:-}
[[ $# -gt 0 ]] && shift
case $comando in
  up)
    if [[ $# -eq 0 ]]; then up_models; else create_networks; fi
    for c in $(pick_rooms "$@"); do compose "$c" up -d --build; done
    ;;
  down)
    for c in $(pick_rooms "$@"); do compose "$c" down; done
    [[ $# -gt 0 ]] || models down
    ;;
  status)
    echo "== models"
    models ps
    for c in $(pick_rooms "$@"); do
      echo "== $c"
      compose "$c" ps
    done
    ;;
  sync)
    [[ $# -eq 1 ]] || die "uso: dojo.sh sync <room>"
    pick_rooms "$1" >/dev/null
    sync_room "$1"
    ;;
  up-models)
    up_models
    ;;
  provider)
    [[ $# -eq 1 ]] || die "uso: dojo.sh provider <anthropic|openrouter|groq|gemini>"
    provider "$1"
    ;;
  chatgpt)
    [[ $# -le 1 && ${1:-on} =~ ^(on|off)$ ]] || die "uso: dojo.sh chatgpt [off]"
    chatgpt "${1:-}"
    ;;
  claude)
    [[ $# -ge 1 ]] || die "uso: dojo.sh claude <room> [agente...|off]"
    pick_rooms "$1" >/dev/null
    claude_sub "$@"
    ;;
  secret)
    [[ $# -eq 3 ]] || die "uso: dojo.sh secret <room> <agente> <CHIAVE>"
    pick_rooms "$1" >/dev/null
    secret "$@"
    ;;
  budget)
    [[ $# -eq 2 ]] || die "uso: dojo.sh budget <room> <dollari>"
    pick_rooms "$1" >/dev/null
    budget "$1" "$2"
    ;;
  key)
    [[ $# -ge 1 && $# -le 2 ]] || die "uso: dojo.sh key <room> [budget]"
    pick_rooms "$1" >/dev/null
    key "$@"
    ;;
  folder)
    [[ $# -ge 2 ]] || die "uso: dojo.sh folder <room> <cartella...|off>"
    pick_rooms "$1" >/dev/null
    folders "$@"
    ;;
  *)
    sed -n '2,33p' "$0" | sed 's/^# \{0,1\}//'
    [[ -z $comando ]] || exit 1
    ;;
esac
