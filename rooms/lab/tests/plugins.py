"""Prova dei plugin della lab dentro l'immagine (CI, .github/workflows/image.yml).

Si lancia con il Python di Hermes nel container di prova, mai sul mini PC:
scrive un .env finto nel profile strategist e crea card sul board.

- ``handoff`` (HERMES_HOME=/opt/data, il default con il dispatcher): una card
  creata da Nico Robin e presa da Shikamaru passa la subscription della chat
  dell'utente al bot di Shikamaru, e il blocco successivo la raggiunge; a
  card finita la subscription passa a ``notify`` (FLOW-005).
- ``spec-only`` (HERMES_HOME del profile strategist): i tool di file
  rifiutano il codice e lasciano passare le specifiche (FLOW-006).
"""

import sys
import time

from hermes_cli import kanban_db as kb
from hermes_cli import kanban_db_connect as kbc
from hermes_cli import kanban_db_notify as kbn
from hermes_cli import plugins

CHAT = "123456789"


def handoff() -> None:
    from hermes_cli.profiles import get_profile_dir

    (get_profile_dir("strategist") / ".env").write_text(
        f"TELEGRAM_BOT_TOKEN=123:finto\nTELEGRAM_ALLOWED_USERS={CHAT}\n", encoding="utf-8"
    )
    plugins.discover_plugins()
    assert plugins.has_hook("kanban_task_claimed"), "dojo-handoff non caricato nel default"

    with kbc.connect_closing() as conn:
        tid = kb.create_task(conn, title="#1 prova avvisi", assignee="strategist", created_by="concierge")
        # La subscription che Hermes crea per chi fa la card da Telegram.
        kbn.add_notify_sub(
            conn, task_id=tid, platform="telegram", chat_id=CHAT, chat_type="dm",
            user_id=CHAT, notifier_profile="concierge", delivery_mode="notify+wake",
        )
        assert kb.claim_task(conn, tid), "card non presa"

        for _ in range(50):
            subs = kbn.list_notify_subs(conn, tid)
            if [s.get("notifier_profile") for s in subs] == ["strategist"]:
                break
            time.sleep(0.1)
        else:
            raise AssertionError(f"subscription non passata a strategist: {subs}")
        sub = subs[0]
        assert sub["platform"] == "telegram" and str(sub["chat_id"]) == CHAT, sub
        assert sub["delivery_mode"] == "notify+wake", sub

        assert kb.block_task(conn, tid, reason="Quale tracker usiamo?"), "card non bloccata"
        _, events = kbn.unseen_events_for_sub(conn, task_id=tid, platform="telegram", chat_id=CHAT)
        assert "blocked" in {e.kind for e in events}, [e.kind for e in events]
    print("ok   dojo-handoff: il blocco arriva dal bot di strategist")

    # Card finita: l'esito arriva passivo, senza turno dell'agente.
    assert plugins.has_hook("kanban_task_completed"), "dojo-handoff senza hook di fine card"
    with kbc.connect_closing() as conn:
        tid = kb.create_task(conn, title="#2 prova fine card", assignee="strategist", created_by="concierge")
        kbn.add_notify_sub(
            conn, task_id=tid, platform="telegram", chat_id=CHAT, chat_type="dm",
            user_id=CHAT, notifier_profile="concierge", delivery_mode="notify+wake",
        )
        assert kb.claim_task(conn, tid), "card non presa"
        for _ in range(50):
            subs = kbn.list_notify_subs(conn, tid)
            if [s.get("notifier_profile") for s in subs] == ["strategist"]:
                break
            time.sleep(0.1)
        else:
            raise AssertionError(f"subscription non passata a strategist: {subs}")
        assert subs[0]["delivery_mode"] == "notify+wake", subs[0]

        assert kb.complete_task(conn, tid, result="fatto", force=True), "card non completata"
        sub = kbn.list_notify_subs(conn, tid)[0]
        assert sub["delivery_mode"] == "notify", sub
        _, events = kbn.unseen_events_for_sub(conn, task_id=tid, platform="telegram", chat_id=CHAT)
        assert "completed" in {e.kind for e in events}, [e.kind for e in events]
    print("ok   dojo-handoff: la card finita non sveglia l'agente")


def spec_only() -> None:
    plugins.discover_plugins()
    block = plugins.get_pre_tool_call_block_message
    assert block("write_file", {"path": "src/app.py", "content": ""}), "codice non rifiutato"
    assert block("patch", {"mode": "patch", "patch": "*** Begin Patch\n*** Add File: skills/x/SKILL.md\n*** End Patch"})
    assert block("write_file", {"path": "docs/specs/app.md", "content": ""}) is None, "specifica rifiutata"
    assert block("patch", {"path": "CHANGELOG.md", "old_string": "a", "new_string": "b"}) is None
    print("ok   dojo-spec-only: lo strategist scrive solo specifiche")


{"handoff": handoff, "spec-only": spec_only}[sys.argv[1]]()
