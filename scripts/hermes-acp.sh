#!/usr/bin/env bash
# Al posto di `hermes` per un client ACP sul PC che riconosce Hermes, come
# AionUi (ROOM-008): nel client è il "launch path" dell'agente Hermes.
# `hermes acp` diventa `dojo-acp <agente>` nel container della room;
# l'agente si sceglie con DOJO_AGENT (default concierge), il container con
# DOJO_CONTAINER. Passano solo i controlli di versione e di salute, niente
# altri comandi o flag (per esempio --yolo).
set -euo pipefail

container=${DOJO_CONTAINER:-dojo-lab-hermes-1}
agente=${DOJO_AGENT:-concierge}

case "$*" in
  acp)
    exec docker exec -i -u hermes "$container" dojo-acp "$agente"
    ;;
  --version | acp\ --version | acp\ --check)
    exec docker exec -i -u hermes "$container" hermes -p "$agente" "$@"
    ;;
  *)
    echo "hermes-acp.sh: comando non permesso: hermes $*" >&2
    exit 2
    ;;
esac
