#!/usr/bin/env bash
# Valida stanze e servizi: `docker compose config` su ogni compose.yaml (i
# servizi con i valori di .env.example) e, per ogni profilo, la presenza di
# config.yaml, SOUL.md e .env.example. Non serve il demone Docker.
set -euo pipefail

cd "$(dirname "$0")/.."
status=0

for compose in stanze/*/compose.yaml; do
  dir=$(dirname "$compose")
  if docker compose --project-directory "$dir" -f "$compose" config --quiet; then
    echo "ok   $compose"
  else
    echo "FAIL $compose"
    status=1
  fi
  [[ -f "$dir/.env.example" ]] || { echo "FAIL $dir/.env.example mancante"; status=1; }
  for profilo in "$dir"/profili/*/; do
    for f in config.yaml SOUL.md .env.example; do
      if [[ ! -f "$profilo$f" ]]; then
        echo "FAIL $profilo$f mancante"
        status=1
      fi
    done
  done
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
for compose in servizi/*/compose.yaml; do
  dir=$(dirname "$compose")
  work="$tmp/$(basename "$dir")"
  cp -r "$dir" "$work"
  # env_file: .env non è versionato: al suo posto .env.example.
  cp "$work/.env.example" "$work/.env"
  if docker compose --project-directory "$work" -f "$work/compose.yaml" --env-file "$work/.env" config --quiet; then
    echo "ok   $compose"
  else
    echo "FAIL $compose"
    status=1
  fi
done

for skill in flussi/*/; do
  if ! head -1 "${skill}SKILL.md" 2>/dev/null | grep -qx -- '---'; then
    echo "FAIL ${skill}SKILL.md mancante o senza frontmatter"
    status=1
  fi
done

exit $status
