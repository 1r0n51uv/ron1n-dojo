#!/usr/bin/env bash
# Valida le rooms: `docker compose config` su ogni compose.yaml e, per ogni
# profile, la presenza di config.yaml e SOUL.md e del suo bot in
# dojo.env.example; ogni skill di flows/ e skills/ ha il frontmatter. Non
# serve il demone Docker.
set -euo pipefail

cd "$(dirname "$0")/.."
status=0
# La cartella di lavoro la imposta dojo.sh; qui basta un valore qualsiasi.
export DOJO_WORK=${DOJO_WORK:-/tmp/dojo-work}

for compose in rooms/*/compose.yaml; do
  dir=$(dirname "$compose")
  if docker compose --project-directory "$dir" -f "$compose" config --quiet; then
    echo "ok   $compose"
  else
    echo "FAIL $compose"
    status=1
  fi
  for profile in "$dir"/profiles/*/; do
    for f in config.yaml SOUL.md; do
      if [[ ! -f "$profile$f" ]]; then
        echo "FAIL $profile$f mancante"
        status=1
      fi
    done
    p=$(basename "$profile")
    if [[ $p != default ]] && ! grep -q "^${p^^}_TELEGRAM_BOT_TOKEN=" dojo.env.example; then
      echo "FAIL ${p^^}_TELEGRAM_BOT_TOKEN mancante in dojo.env.example"
      status=1
    fi
  done
done

for skill in flows/*/ skills/*/; do
  if ! head -1 "${skill}SKILL.md" 2>/dev/null | grep -qx -- '---'; then
    echo "FAIL ${skill}SKILL.md mancante o senza frontmatter"
    status=1
  fi
done

exit $status
