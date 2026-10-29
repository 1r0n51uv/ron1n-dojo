"""Riepilogo su Telegram dei lavori autonomi degli agenti della lab.

Quando una card Kanban parte, finisce, si blocca o il suo worker si ferma,
l'agente assegnatario scrive all'utente dal proprio bot: titolo della card e,
a seconda del caso, il riassunto o il motivo. Token del bot e chat vengono dal
.env del profile assegnatario (TELEGRAM_BOT_TOKEN, TELEGRAM_ALLOWED_USERS),
quello che `scripts/dojo.sh sync` copia nel volume. Il messaggio esce dal
proxy egress (HTTPS_PROXY), dove api.telegram.org è già permesso.

Gli hook partono in processi diversi: la presa in carico e l'uscita del worker
nel dispatcher (profile default), fine e blocco nel worker. Per questo il
plugin è abilitato in tutti i profiles della lab.
"""

import json
import logging
import sqlite3
import threading
import urllib.parse
import urllib.request
from contextlib import closing
from pathlib import Path

logger = logging.getLogger(__name__)

DATA = Path("/opt/data")
# Il bot che scrive se l'assegnatario non ne ha uno (per esempio il default).
FALLBACK_PROFILE = "concierge"
# Telegram accetta fino a 4096 caratteri: si resta larghi.
MAX_TEXT = 3500
TIMEOUT_S = 8


def _env(profile):
    home = DATA if not profile or profile == "default" else DATA / "profiles" / profile
    values = {}
    try:
        for line in (home / ".env").read_text(encoding="utf-8").splitlines():
            key, sep, value = line.partition("=")
            if sep and not key.lstrip().startswith("#"):
                values[key.strip()] = value.strip().strip("\"'")
    except OSError:
        pass
    return values


def _credentials(profile):
    env = _env(profile)
    if not env.get("TELEGRAM_BOT_TOKEN"):
        env = {**env, "TELEGRAM_BOT_TOKEN": _env(FALLBACK_PROFILE).get("TELEGRAM_BOT_TOKEN", "")}
    chats = [c.strip() for c in env.get("TELEGRAM_ALLOWED_USERS", "").split(",") if c.strip()]
    return env.get("TELEGRAM_BOT_TOKEN", ""), chats


def _title(task_id, board):
    """Titolo della card, letto in sola lettura per non contendere il lock del board."""
    try:
        from hermes_cli import kanban_db as kb

        path = kb.kanban_db_path(board=board).resolve()
        with closing(sqlite3.connect(path.as_uri() + "?mode=ro", uri=True)) as conn:
            conn.row_factory = sqlite3.Row
            task = kb.get_task(conn, task_id)
            return task.title if task else ""
    except Exception:  # il titolo è un di più: senza si manda lo stesso
        return ""


def _send(profile, text):
    token, chats = _credentials(profile)
    if not token or not chats:
        logger.warning("kanban-telegram: manca TELEGRAM_BOT_TOKEN o TELEGRAM_ALLOWED_USERS per %s", profile)
        return
    if len(text) > MAX_TEXT:
        text = text[: MAX_TEXT - 1] + "…"
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    for chat in chats:
        data = urllib.parse.urlencode({"chat_id": chat, "text": text, "disable_web_page_preview": "true"}).encode()
        try:
            with urllib.request.urlopen(url, data=data, timeout=TIMEOUT_S) as resp:
                json.load(resp)
        except Exception as exc:
            # Mai il token nei log: solo il tipo di errore.
            logger.warning("kanban-telegram: invio fallito per %s: %s", profile, type(exc).__name__)


def _notify(task_id, board, assignee, head, body="", background=False):
    def run():
        title = _title(task_id, board)
        text = f"{head} {task_id}" + (f": {title}" if title else "")
        if body:
            text += f"\n\n{body.strip()}"
        _send(assignee, text)

    if background:
        # Dispatcher: l'hook gira dentro il lock del board, non si aspetta la rete.
        threading.Thread(target=run, name="kanban-telegram", daemon=True).start()
    else:
        # Worker: il processo può uscire subito dopo, si manda prima di tornare.
        run()


def register(ctx):
    def on_claimed(task_id=None, board=None, assignee=None, **kw):
        _notify(task_id, board, assignee, "▶️ Inizio la card", background=True)

    def on_completed(task_id=None, board=None, assignee=None, summary=None, **kw):
        _notify(task_id, board, assignee, "✅ Ho finito la card", summary or "")

    def on_blocked(task_id=None, board=None, assignee=None, reason=None, **kw):
        _notify(task_id, board, assignee, "⛔ Mi sono bloccato sulla card",
                f"Motivo: {reason}" if reason else "")

    def on_exited(task_id=None, board=None, assignee=None, exit_code=None, retry_status=None, **kw):
        detail = f"Codice di uscita {exit_code}." if exit_code is not None else ""
        if retry_status:
            detail += f" Stato: {retry_status}."
        _notify(task_id, board, assignee, "⚠️ Il mio worker si è fermato sulla card", detail, background=True)

    ctx.register_hook("kanban_task_claimed", on_claimed)
    ctx.register_hook("kanban_task_completed", on_completed)
    ctx.register_hook("kanban_task_blocked", on_blocked)
    ctx.register_hook("on_kanban_worker_exited", on_exited)
