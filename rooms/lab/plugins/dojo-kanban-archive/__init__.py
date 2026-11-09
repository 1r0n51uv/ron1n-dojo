"""Ogni agente può togliere una card dal board (FLOW-012).

Hermes archivia e cancella le card solo da CLI (``hermes kanban archive``) e
dalla dashboard; fra i tool degli agenti non c'è, e il Concierge non ha
terminale. Questo plugin aggiunge ``kanban_archive`` al toolset ``kanban``:

- di default archivia la card (``archive_task`` di Hermes): esce dal board,
  un worker che la stava lavorando si ferma, la storia resta;
- con ``delete: true`` la cancella del tutto, commenti ed eventi compresi
  (``delete_archived_task``): prima la archivia, come vuole Hermes, così la
  perdita di dati resta un passo esplicito.

Come ``kanban_list`` e ``kanban_unblock`` è nascosto ai worker: una card la
toglie chi parla con l'utente, non chi la sta lavorando.
"""

from __future__ import annotations

import json

SCHEMA = {
    "name": "kanban_archive",
    "description": (
        "Remove a task from the kanban board when 1ron51uv asks for it. "
        "By default it archives the task (it leaves the board, a running "
        "worker is stopped, history is kept). With delete=true it also "
        "deletes it permanently, with comments and events. Use kanban_list "
        "to find the id."),
    "parameters": {
        "type": "object",
        "properties": {
            "task_id": {"type": "string", "description": "Id of the task to remove."},
            "delete": {
                "type": "boolean",
                "description": "Also delete it permanently. Defaults to false (archive only).",
            },
            "board": {"type": "string", "description": "Board slug; omit for the current board."},
        },
        "required": ["task_id"],
    },
}


def remove(task_id: str, delete: bool = False, board: str | None = None) -> dict:
    """Archivia la card e, con ``delete``, la cancella."""
    from hermes_cli import kanban_db as kb
    from hermes_cli import kanban_db_connect as kbc

    with kbc.connect_closing(board=board) as conn:
        task = kb.get_task(conn, task_id)
        if task is None:
            return {"ok": False, "error": f"task {task_id} not found"}
        archived = task.status == "archived" or kb.archive_task(conn, task_id)
        if not archived:
            return {"ok": False, "error": f"task {task_id} not archived"}
        if delete and not kb.delete_archived_task(conn, task_id):
            return {"ok": False, "error": f"task {task_id} archived but not deleted"}
    return {"ok": True, "task_id": task_id, "status": "deleted" if delete else "archived"}


def handle(args: dict, **_) -> str:
    task_id = str(args.get("task_id") or "").strip()
    if not task_id:
        return json.dumps({"ok": False, "error": "kanban_archive: task_id is required"})
    try:
        result = remove(task_id, bool(args.get("delete")), args.get("board") or None)
    except Exception as e:  # noqa: BLE001 - l'errore torna all'agente, non ferma il turno
        result = {"ok": False, "error": f"kanban_archive: {e}"}
    return json.dumps(result)


def register(ctx):
    try:
        from tools.kanban_tools import _check_kanban_orchestrator_mode as visible
    except ImportError:
        visible = None
    ctx.register_tool(
        name="kanban_archive", toolset="kanban", schema=SCHEMA, handler=handle,
        check_fn=visible, emoji="🗑",
    )
