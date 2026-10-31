"""Chi si blocca su una card Kanban te lo dice dal suo bot (FLOW-005).

Hermes iscrive agli esiti di una card solo la chat di chi l'ha creata (per
esempio Nico Robin, ``auto_subscribe_on_create``): un blocco di Shikamaru
arrivava quindi, se arrivava, dal bot di Robin, e Shikamaru restava zitto.

Quando il dispatcher prende una card (hook ``kanban_task_claimed``, nel
gateway del profile default), questo plugin iscrive la chat Telegram
dell'utente agli esiti della card a nome dell'agente assegnato
(``notifier_profile``), in modalità ``notify+wake``. Così il notifier di
Hermes, quando la card si blocca, finisce o fallisce:

- manda il messaggio di serie dal bot dell'assegnatario;
- sveglia l'assegnatario nella sua chat con l'utente, dove può fare la
  domanda (anche con ``clarify``, che nel worker non c'è) e poi commentare e
  sbloccare la card.

La subscription va creata alla presa in carico e non al blocco: Hermes fa
partire una subscription nuova dopo l'ultimo evento della card, quindi una
creata da ``kanban_task_blocked`` non vedrebbe il blocco che l'ha creata.

In un DM di Telegram la chat ha l'ID dell'utente per ogni bot, e Hermes tiene
una sola subscription per card e chat: quella di chi ha creato la card sulla
stessa chat si toglie, così l'avviso arriva da un bot solo. Le subscription
su altre piattaforme (la WebUI) restano.

Chat dal .env del profile assegnato (TELEGRAM_HOME_CHANNEL, altrimenti il
primo di TELEGRAM_ALLOWED_USERS). Un agente senza bot viene saltato e resta
la subscription di chi ha creato la card. Tutto è best effort: un errore
finisce nel log e non ferma mai il dispatcher.
"""

from __future__ import annotations

import logging
import threading

logger = logging.getLogger(__name__)

PLATFORM = "telegram"
MODE = "notify+wake"


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


def owner_chat(env: dict[str, str]) -> str:
    """La chat dell'utente con il bot dell'agente: in un DM ha l'ID dell'utente."""
    home = env.get("TELEGRAM_HOME_CHANNEL", "")
    if home:
        return home
    users = [u.strip() for u in env.get("TELEGRAM_ALLOWED_USERS", "").split(",")]
    return next((u for u in users if u), "")


def subscribe(task_id: str, board: str | None, assignee: str, chat: str) -> None:
    """Intesta all'assegnatario la subscription della chat dell'utente."""
    from hermes_cli import kanban_db_connect as kbc
    from hermes_cli import kanban_db_notify as kbn

    with kbc.connect_closing(board=board) as conn:
        for sub in kbn.list_notify_subs(conn, task_id):
            # notifier_profile non si sovrascrive su una riga esistente: quella
            # di un altro agente sulla stessa chat va tolta e rifatta.
            if (
                sub["platform"] == PLATFORM
                and str(sub["chat_id"]) == chat
                and (sub.get("notifier_profile") != assignee or sub.get("delivery_mode") != MODE)
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
            delivery_mode=MODE,
        )


def handoff(task_id: str, board: str | None, assignee: str) -> None:
    try:
        env = _read_env(assignee)
        chat = owner_chat(env)
        if not env.get("TELEGRAM_BOT_TOKEN") or not chat:
            logger.info("dojo-handoff: %s senza bot Telegram, salto %s", assignee, task_id)
            return
        subscribe(task_id, board, assignee, chat)
        logger.info("dojo-handoff: avvisi di %s dal bot di %s", task_id, assignee)
    except Exception:
        logger.warning("dojo-handoff: card %s di %s non passata", task_id, assignee, exc_info=True)


def register(ctx):
    def on_claimed(task_id=None, assignee=None, board=None, **_):
        if not task_id or not assignee or assignee == "default":
            return
        # Il dispatcher chiama l'hook con il suo lock: il lavoro va in un
        # thread, così non lo rallenta. Il worker parte dopo, e un blocco
        # arriva quando la subscription c'è già.
        threading.Thread(
            target=handoff, args=(task_id, board, assignee), name="dojo-handoff", daemon=True
        ).start()

    ctx.register_hook("kanban_task_claimed", on_claimed)
