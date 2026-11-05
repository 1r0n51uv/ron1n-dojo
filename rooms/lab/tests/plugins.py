"""Prova dei plugin della lab dentro l'immagine (CI, .github/workflows/image.yml).

Si lancia con il Python di Hermes nel container di prova, mai sul mini PC.

- ``spec-only`` (HERMES_HOME del profile strategist): i tool di file
  rifiutano il codice e lasciano passare le specifiche (FLOW-006).
- ``kanban-archive`` (HERMES_HOME del profile concierge): ``kanban_archive``
  è registrato, archivia una card e con ``delete`` la cancella (FLOW-012).
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


def kanban_archive() -> None:
    import json

    from hermes_cli import kanban_db as kb
    from hermes_cli import kanban_db_connect as kbc
    from tools.registry import registry

    plugins.discover_plugins()
    entry = registry.get_entry("kanban_archive")
    assert entry is not None and entry.toolset == "kanban", "kanban_archive non registrato"
    with kbc.connect_closing() as conn:
        a = kb.create_task(conn, title="#3 prova archivio", assignee="builder", created_by="concierge")
        b = kb.create_task(conn, title="#4 prova cancella", assignee="builder", created_by="concierge")
    assert json.loads(entry.handler({"task_id": a}))["status"] == "archived"
    assert json.loads(entry.handler({"task_id": b, "delete": True}))["status"] == "deleted"
    with kbc.connect_closing() as conn:
        assert kb.get_task(conn, a).status == "archived", "card non archiviata"
        assert kb.get_task(conn, b) is None, "card non cancellata"
    print("ok   dojo-kanban-archive: archivia e cancella le card")


{"spec-only": spec_only, "kanban-archive": kanban_archive}[sys.argv[1]]()
