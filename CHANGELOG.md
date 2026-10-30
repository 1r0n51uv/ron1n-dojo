# Changelog

Cosa cambia nel dojo (stanze, profili, flussi, script), il giorno più
recente in alto. Ogni PR aggiunge la sua riga in cima, sotto il giorno del
merge.

## 2026-10-30

- La cartella di lavoro della lab si chiama `~/dojo/lab` (prima `~/dojo/work`): una cartella per room con lo stesso nome (`lab`, e dopo `home` e `work`). Dentro il container resta `/opt/data/work`. Chi ha già dati: `mv ~/dojo/work ~/dojo/lab`, poi `scripts/dojo.sh up`; se `dojo.env` imposta `DOJO_WORK` a mano, resta quello (ROOM-011) ([#26](https://github.com/1r0n51uv/ron1n-dojo/pull/26))
- Un solo file di configurazione, `dojo.env` (modello `dojo.env.example`): agenti accesi, utente Telegram, cartella di lavoro, porte, bot e token di ogni agente; `dojo.sh up` lo applica. `dojo.sh` scende a `up`, `down`, `status` (con i controlli dell'ex `doctor`) e `claude`; via `secret` e i `.env.example` sparsi. La migrazione della memoria sarà uno script a parte (ROOM-004, 005, 013) ([#25](https://github.com/1r0n51uv/ron1n-dojo/pull/25))
- Lab nuova: immagine da GHCR aggiornata da Watchtower, cartella di lavoro `~/dojo/work` montata con il tuo UID, config e SOUL copiati dall'immagine a ogni avvio senza toccare modello e comandi approvati scelti da Hermes, tutti gli agenti su Claude, WebUI anche sulla rete `proxy` di ron1n (`dojo-webui`); la CI prova l'immagine prima di pubblicarla. `dojo.sh` diventa `up`, `down`, `status`, `secret`, `claude`, `doctor`. Tolti gateway LiteLLM, ACP e AionUi, plugin `handoff` e `kanban-telegram` (ROOM-003, 004, 005, 009, 011, 012, MODELS-006, 007) ([#24](https://github.com/1r0n51uv/ron1n-dojo/pull/24))
- Immagine della lab costruita dalla CI e pubblicata su `ghcr.io/1r0n51uv/dojo-lab` (tag `main` e `sha-<commit>`), con versioni fissate nel Dockerfile e config, SOUL, flows e skill dentro; sulle PR solo build (ROOM-010) ([#23](https://github.com/1r0n51uv/ron1n-dojo/pull/23))
- Specifiche del dojo stabile: solo mini PC, immagine da GHCR con Watchtower, WebUI principale anche fuori casa (Cloudflare Access), tutti gli agenti su Claude con modello scelto da Hermes, Kanban interno e tracker per progetto (GitHub Issues o Jira), cartella di lavoro montata; via LiteLLM, ACP e plugin Kanban (ROOM, FLOW, MODELS, TRACKER) ([#22](https://github.com/1r0n51uv/ron1n-dojo/pull/22))
- Lab: la build dell'immagine installa PyYAML per hermes-webui in `/opt/hermes-webui/deps`, fuori dalla venv di Hermes, che non lo ha (ROOM-009) ([#20](https://github.com/1r0n51uv/ron1n-dojo/pull/20))
- Lab: interfaccia web hermes-webui su `127.0.0.1:8787`, con password in `webui.env`; le chat passano dall'API del gateway (runs API), i tool girano nel container degli agenti con i loro toolset (ROOM-009) ([#19](https://github.com/1r0n51uv/ron1n-dojo/pull/19))
- `scripts/hermes-acp.cmd`: launch path di AionUi su Windows con i container in WSL (Docker Desktop o `wsl.exe -e docker`) (ROOM-008) ([#19](https://github.com/1r0n51uv/ron1n-dojo/pull/19))
- AionUi riconosce gli agenti del dojo come Hermes: `scripts/hermes-acp.sh` fa da launch path e passa a `dojo-acp` l'agente di `DOJO_AGENT`; altri comandi e flag sono rifiutati (ROOM-008) ([#18](https://github.com/1r0n51uv/ron1n-dojo/pull/18))
- Lab: gli agenti si usano anche da un client ACP sul PC come AionUi, con `docker exec -i -u hermes dojo-lab-hermes-1 dojo-acp <agente>`; stessi tool della CLI, cartella di lavoro del container, niente server MCP del client (ROOM-008) ([#17](https://github.com/1r0n51uv/ron1n-dojo/pull/17))
- Lab: Claude Code si installa in locale in `/opt/claude-code`, con postinstall e binario della piattaforma forzati; la build non si ferma più su "claude native binary not installed" `dojo.sh claude` riconosce il login riuscito e `sync` non si ferma più se un file temporaneo del gateway sparisce durante il chown ([#16](https://github.com/1r0n51uv/ron1n-dojo/pull/16))
- Abbonamento Claude (Pro o Max) come modello degli agenti, opzionale: `dojo.sh claude <room> [agente...]` fa il login con la CLI ufficiale di Claude Code e mette Claude davanti, con il gateway (GPT e free) come riserva; `off` torna indietro (MODELS-006) ([#15](https://github.com/1r0n51uv/ron1n-dojo/pull/15))

## 2026-10-29

- Lab: quando un agente prende una card la chat passa a lui; alla fine, al blocco o al crash è lui a riprendere il discorso nella sua chat, non chi ha creato la card (plugin `handoff`, ROOM-007) ([#14](https://github.com/1r0n51uv/ron1n-dojo/pull/14))
- Lab: ogni agente manda su Telegram un riepilogo quando inizia, finisce o si blocca su una card Kanban, o se il suo worker si ferma (plugin `kanban-telegram`) ([#13](https://github.com/1r0n51uv/ron1n-dojo/pull/13))
- `dojo.sh chatgpt` azzera un login lasciato a metà e mostra subito un codice nuovo, invece di aspettare 5 minuti in silenzio ([#12](https://github.com/1r0n51uv/ron1n-dojo/pull/12))
- Abbonamento ChatGPT (Plus o Pro) per `strong` e `fast` senza API key: `dojo.sh chatgpt` fa il login con codice dispositivo e passa il gateway a `config.chatgpt.yaml`; finita la quota si scende su OpenRouter e sui free (MODELS-005) ([#11](https://github.com/1r0n51uv/ron1n-dojo/pull/11))
- Lab: patch dell'immagine Hermes che rende stabile l'identità dei processi worker quando l'orologio di WSL2/Docker Desktop oscilla; le card Kanban non crashano più con `permission_denied` ("Kanban owner refused") ([#10](https://github.com/1r0n51uv/ron1n-dojo/pull/10))
- Domande a scelta multipla con i bottoni di Telegram: il grilling e gli agenti usano `clarify` con le opzioni in `choices`; nuova skill `grilling-with-docs` con cui Shikamaru rivede il piano di Nico Robin contro i documenti del repo e scrive la specifica durante il grilling ([#9](https://github.com/1r0n51uv/ron1n-dojo/pull/9))
- Gateway su LiteLLM 1.105.7: `strong` e `fast` tornano a usare Claude (Opus 5.5 e Sonnet 5.5) e il 429 di Gemini non ferma più i fallback; Gemini passa in fondo ai free, con cooldown di 5 minuti ([#8](https://github.com/1r0n51uv/ron1n-dojo/pull/8))
- SOUL degli agenti della lab con storia, modo di parlare e ruolo dei personaggi; nuova cartella `skills/` con `grilling`, che Nico Robin usa per chiarire una richiesta prima di smistarla ([#7](https://github.com/1r0n51uv/ron1n-dojo/pull/7))
- Nomi in inglese: cartelle `rooms/`, `services/`, `flows/`, comandi `dojo.sh key`/`secret`/`up-models`, servizi `egress` e `dashboard`, modelli `strong`/`fast`/`free`/`local`, ID `ROOM`/`FLOW`/`MODELS` ([#6](https://github.com/1r0n51uv/ron1n-dojo/pull/6))
- Gemini passa in testa ai modelli gratuiti del gateway: più veloce e più affidabile con i tool ([#5](https://github.com/1r0n51uv/ron1n-dojo/pull/5))
- `dojo.sh budget lab` trova anche la chiave `stanza-kajiba` della migrazione e la rinomina ([#4](https://github.com/1r0n51uv/ron1n-dojo/pull/4))
- `dojo.sh segreto` imposta token del bot e `GH_TOKEN` di un agente con input nascosto ([#3](https://github.com/1r0n51uv/ron1n-dojo/pull/3))
- Ruoli in inglese (Strategist, Builder, Reviewer, Concierge, Companion, Captain), stanza `lab` al posto di `kajiba` e nuovi agenti Designer (Bulma) e Concierge (Nico Robin) ([#2](https://github.com/1r0n51uv/ron1n-dojo/pull/2))
- `dojo.sh provider` ricollega LiteLLM alle stanze dopo il riavvio ([#1](https://github.com/1r0n51uv/ron1n-dojo/pull/1))
- Dashboard di Hermes sulla kajiba, solo su 127.0.0.1 e con password casuale (STANZA-006)
- Prima versione del dojo: stanza kajiba (Shikamaru, Edward, L), gateway dei modelli LiteLLM, installazione con un comando ([#1](https://github.com/1r0n51uv/ron1n-dojo/pull/1))
