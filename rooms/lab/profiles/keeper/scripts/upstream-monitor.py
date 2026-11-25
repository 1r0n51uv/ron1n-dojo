#!/usr/bin/env python3
"""Quali fork hanno una release upstream non ancora allineata (ROOM-017).

È il monitor del cron `fork-sync` (`hermes cron --monitor-script`): gira prima
dell'agente e, se l'output non cambia, l'agente non parte. Per ogni
`/opt/dojo/forks/*.yaml` (repo, upstream) stampa una riga solo se l'ultima
release stabile di upstream:

- non è già nella `main` del fork (compare upstream-commit...main);
- non ha già una PR `sync/<tag>` sul fork (`upstream/<tag>` se il fork è in
  `mode: review`), aperta, unita o chiusa: una PR chiusa senza unire è un
  rifiuto, non si rifà da sola.

Parte quindi solo quando upstream pubblica una release nuova.

L'output è stabile (niente orari): `<fork> <- <upstream> <tag> <commit>`.
Vuoto vuol dire niente da fare. Un fork che non risponde non si stampa: meglio
saltarlo che far partire l'agente su un dato incerto.
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

FORKS = Path(os.environ.get("DOJO_FORKS_DIR", "/opt/dojo/forks"))


def token() -> str | None:
    """GH_TOKEN dell'ambiente o, se il cron non lo passa, dal .env del profile."""
    if os.environ.get("GH_TOKEN"):
        return os.environ["GH_TOKEN"]
    env = Path(os.environ.get("HERMES_HOME", "/opt/data")) / ".env"
    if env.is_file():
        m = re.search(r"^GH_TOKEN=(.+)$", env.read_text(encoding="utf-8"), re.M)
        if m:
            return m[1].strip().strip("\"'")
    return None


def gh(*args: str) -> str | None:
    """Output di `gh`, o None se la chiamata fallisce (404, rete, token)."""
    env = dict(os.environ)
    t = token()
    if t:
        env["GH_TOKEN"] = t
    r = subprocess.run(["gh", *args], capture_output=True, text=True, env=env, timeout=60)
    return r.stdout.strip() if r.returncode == 0 else None


def leggi(path: Path) -> dict[str, str]:
    campi = {}
    for riga in path.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^([a-z_]+):\s*(.*?)\s*(?:#.*)?$", riga)
        if m:
            campi[m[1]] = m[2].strip("\"'")
    return campi


def da_sincronizzare(repo: str, upstream: str, mode: str = "merge") -> str | None:
    tag = gh("api", f"repos/{upstream}/releases/latest", "--jq", ".tag_name")
    if not tag:
        return None
    sha = gh("api", f"repos/{upstream}/commits/{tag}", "--jq", ".sha")
    if not sha:
        return None
    # `sha...main`: "ahead" o "identical" = il commit è già antenato della main del fork.
    stato = gh("api", f"repos/{repo}/compare/{sha}...main", "--jq", ".status")
    if stato in ("ahead", "identical"):
        return None
    prefisso = "upstream" if mode == "review" else "sync"
    prs = gh("pr", "list", "--repo", repo, "--head", f"{prefisso}/{tag}", "--state", "all", "--json", "number")
    if prs is None or json.loads(prs or "[]"):
        return None
    return f"{repo} <- {upstream} {tag} {sha[:12]}"


def main() -> int:
    for f in sorted(FORKS.glob("*.yaml")):
        c = leggi(f)
        if "repo" not in c or "upstream" not in c:
            print(f"# {f.name}: mancano repo o upstream", file=sys.stderr)
            continue
        riga = da_sincronizzare(c["repo"], c["upstream"], c.get("mode", "merge"))
        if riga:
            print(riga)
    return 0


if __name__ == "__main__":
    sys.exit(main())
