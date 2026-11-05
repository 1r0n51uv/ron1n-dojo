"""Prova dei plugin della lab dentro l'immagine (CI, .github/workflows/image.yml).

Si lancia con il Python di Hermes nel container di prova, mai sul mini PC.

- ``spec-only`` (HERMES_HOME del profile strategist): i tool di file
  rifiutano il codice e lasciano passare le specifiche (FLOW-006).
"""

import sys

from hermes_cli import plugins


def spec_only() -> None:
    plugins.discover_plugins()
    block = plugins.get_pre_tool_call_block_message
    assert block("write_file", {"path": "src/app.py", "content": ""}), "codice non rifiutato"
    assert block("patch", {"mode": "patch", "patch": "*** Begin Patch\n*** Add File: skills/x/SKILL.md\n*** End Patch"})
    assert block("write_file", {"path": "docs/specs/app.md", "content": ""}) is None, "specifica rifiutata"
    assert block("patch", {"path": "CHANGELOG.md", "old_string": "a", "new_string": "b"}) is None
    print("ok   dojo-spec-only: lo strategist scrive solo specifiche")


{"spec-only": spec_only}[sys.argv[1]]()
