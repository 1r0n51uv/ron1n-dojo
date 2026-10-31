"""Lo Strategist non implementa (FLOW-006).

Abilitato solo nel profile strategist (Shikamaru). Prima di ogni scrittura con
i tool di file di Hermes (``write_file`` e ``patch``, anche in formato V4A)
controlla il percorso: nella cartella di lavoro passano solo specifiche e
documenti (``docs/**/*.md``), ``CHANGELOG.md`` e ``projects/*.yaml``; il resto
(codice, skill, config, script) viene rifiutato con l'invito a passare il
lavoro a Edward con una card. Fuori dalla cartella di lavoro (per esempio
``/tmp``) non c'è niente da implementare e si scrive.

Il terminale resta, perché Shikamaru ne ha bisogno per git e ``gh``, quindi
questo è un rinforzo e non un confine: la regola vera è nel SOUL, e una PR
di Shikamaru con file fuori dalle specifiche va rifiutata in review.
"""

from __future__ import annotations

import posixpath
import re
from typing import Any, Optional

WORK = "/opt/data/work"
WRITE_TOOLS = ("write_file", "patch")
# Intestazioni V4A: *** Update File: p, *** Add File: p, *** Delete File: p,
# *** Move File: p, *** Move to: p.
_V4A_PATH = re.compile(r"^\*\*\* (?:(?:Update|Add|Delete|Move) File|Move to):\s*(.+?)\s*$", re.M)


def allowed(path: str) -> bool:
    """Vero se Shikamaru può scrivere ``path``."""
    norm = posixpath.normpath(path.strip())
    if norm.startswith("/") and not (norm == WORK or norm.startswith(WORK + "/")):
        return True
    parts = norm.split("/")
    name = parts[-1]
    if name == "CHANGELOG.md":
        return True
    if name.endswith(".md") and "docs" in parts[:-1]:
        return True
    return len(parts) >= 2 and parts[-2] == "projects" and name.endswith((".yaml", ".yml"))


def paths(tool_name: str, args: dict[str, Any]) -> list[str]:
    found = [args["path"]] if isinstance(args.get("path"), str) and args["path"] else []
    if tool_name == "patch" and isinstance(args.get("patch"), str):
        found += _V4A_PATH.findall(args["patch"])
    return found


def check(tool_name: str = "", args: Optional[dict[str, Any]] = None, **_: Any) -> Optional[dict]:
    if tool_name not in WRITE_TOOLS or not isinstance(args, dict):
        return None
    refused = [p for p in paths(tool_name, args) if not allowed(p)]
    if not refused:
        return None
    return {
        "action": "block",
        "message": (
            f"Rifiutato: {', '.join(refused)}. Lo Strategist non implementa (FLOW-006): "
            "scrivi solo specifiche e documenti (docs/**/*.md), CHANGELOG.md e "
            "projects/*.yaml. Codice, skill, config e script li fa Edward: crea una "
            "card per `builder` con kanban_create, con la chiave della issue e cosa fare."
        ),
    }


def register(ctx):
    ctx.register_hook("pre_tool_call", check)
