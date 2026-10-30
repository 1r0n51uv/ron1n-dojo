#!/usr/bin/env bash
# Valida le rooms: `docker compose config` su ogni compose.yaml e, per ogni
# profile, la presenza di config.yaml e SOUL.md e del suo bot in
# dojo.env.example; ogni progetto di projects/ ha i campi giusti; ogni skill
# di flows/ e skills/ ha il frontmatter. Non serve il demone Docker.
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

# projects/*.yaml (TRACKER-001): repo, tracker, stati e, per Jira, la chiave.
# Il formato è fisso e semplice, si legge senza una libreria YAML.
for f in projects/*.yaml; do
  if python3 - "$f" <<'PY'
import re, sys

errori = []
campi, stati, in_stati = {}, {}, False
for riga in open(sys.argv[1], encoding="utf-8"):
    riga = riga.split(" #")[0].rstrip() if not riga.lstrip().startswith("#") else ""
    if not riga.strip():
        continue
    m = re.match(r"^(\s*)([a-z_]+):\s*(.*)$", riga)
    if not m:
        errori.append(f"riga non valida: {riga!r}")
        continue
    rientro, chiave, valore = len(m[1]), m[2], m[3].strip().strip("\"'")
    if rientro == 0:
        in_stati = chiave == "states"
        campi[chiave] = valore
    elif in_stati:
        stati[chiave] = valore
    else:
        errori.append(f"rientro inatteso: {riga!r}")

if not re.fullmatch(r"[\w.-]+/[\w.-]+", campi.get("repo", "")):
    errori.append("repo mancante o non nella forma proprietario/nome")
if campi.get("tracker") not in ("github", "jira"):
    errori.append("tracker deve essere github o jira")
if campi.get("tracker") == "jira" and not re.fullmatch(r"[A-Z][A-Z0-9]+", campi.get("jira_key", "")):
    errori.append("jira_key mancante o non valida (per esempio DOJO)")
for stato in ("spec", "todo", "doing", "review", "done"):
    if not stati.get(stato):
        errori.append(f"states.{stato} mancante")
for chiave in set(campi) - {"repo", "tracker", "jira_key", "states"}:
    errori.append(f"campo sconosciuto: {chiave}")
for chiave in set(stati) - {"spec", "todo", "doing", "review", "done"}:
    errori.append(f"stato sconosciuto: {chiave}")
for e in errori:
    print(f"  {e}", file=sys.stderr)
sys.exit(1 if errori else 0)
PY
  then
    echo "ok   $f"
  else
    echo "FAIL $f"
    status=1
  fi
done

for skill in flows/*/ skills/*/; do
  if ! head -1 "${skill}SKILL.md" 2>/dev/null | grep -qx -- '---'; then
    echo "FAIL ${skill}SKILL.md mancante o senza frontmatter"
    status=1
  fi
done

exit $status
