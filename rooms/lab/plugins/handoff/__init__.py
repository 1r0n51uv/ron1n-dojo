"""Handoff delle card Kanban sulla chat Telegram dell'agente assegnato.

Chi crea una card da Telegram (per esempio Nico Robin) viene iscritto da
Hermes agli esiti della card in modalità ``notify+wake``: alla fine o al
blocco è lui a rispondere, non l'agente che ha lavorato. Questo plugin, nel
gateway del profile default dove il dispatcher prende le card (hook
``kanban_task_claimed``), intesta quella subscription all'agente assegnato
(``notifier_profile``) in modalità ``wake``: fine, blocco o crash svegliano
l'agente nella sua chat con 1ron51uv, che riprende il discorso con il
riepilogo o le domande. I messaggi di inizio, fine e blocco li manda già il
plugin kanban-telegram, per questo qui niente ping passivo.

Chat dell'utente dal .env del profile assegnato. Un agente senza bot viene
saltato. Tutto è best effort: un errore finisce nel log e non ferma mai il
dispatcher.
"""

from __future__ import annotations

import logging
import threading

logger = logging.getLogger(__name__)

PLATFORM = "telegram"


def _read_env(profile: str) -> dict[str, str]:
    from hermes_cli.profiles import get_profile_dir

    values: dict[str, str] = {}
    path = get_profile_dir(profile) / ".env"
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip("'\"")
    return values


def _owner_chat(env: dict[str, str]) -> str:
    # In un DM di Telegram la chat ha lo stesso ID dell'utente.
    home = env.get("TELEGRAM_HOME_CHANNEL", "")
    if home:
        return home
    users = [u.strip() for u in env.get("TELEGRAM_ALLOWED_USERS", "").split(",")]
    return next((u for u in users if u), "")


def _move_subscription(task_id: str, board: str | None, assignee: str, chat: str) -> None:
    """Intesta all'agente assegnato la subscription della chat dell'utente."""
    from hermes_cli import kanban_db_connect as kbc
    from hermes_cli import kanban_db_notify as kbn

    with kbc.connect_closing(board=board) as conn:
        for sub in kbn.list_notify_subs(conn, task_id):
            # notifier_profile non si sovrascrive su una riga esistente: la
            # subscription di un altro agente sulla stessa chat va tolta.
            if (
                sub["platform"] == PLATFORM
                and str(sub["chat_id"]) == chat
                and sub.get("notifier_profile") != assignee
            ):
                kbn.remove_notify_sub(
                    conn,
                    task_id=task_id,
                    platform=PLATFORM,
                    chat_id=sub["chat_id"],
                    thread_id=sub.get("thread_id") or None,
                )
        kbn.add_notify_sub(
            conn,
            task_id=task_id,
            platform=PLATFORM,
            chat_id=chat,
            chat_type="dm",
            user_id=chat,
            notifier_profile=assignee,
            delivery_mode="wake",
        )


def _handoff(task_id: str, board: str | None, assignee: str) -> None:
    try:
        env = _read_env(assignee)
        chat = _owner_chat(env)
        if not env.get("TELEGRAM_BOT_TOKEN") or not chat:
            logger.info("handoff: %s senza bot Telegram, salto %s", assignee, task_id)
            return
        _move_subscription(task_id, board, assignee, chat)
    except Exception:
        logger.warning("handoff: card %s di %s non passata", task_id, assignee, exc_info=True)


def register(ctx):
    def on_claimed(task_id=None, assignee=None, board=None, **_):
        if not task_id or not assignee or assignee == "default":
            return
        # Il dispatcher chiama l'hook con il suo lock: il lavoro va in un
        # thread, così non lo rallenta.
        threading.Thread(
            target=_handoff, args=(task_id, board, assignee), name="handoff", daemon=True
        ).start()

    ctx.register_hook("kanban_task_claimed", on_claimed)
