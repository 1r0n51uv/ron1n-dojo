# Changelog

Cosa cambia nel dojo (stanze, profili, flussi, script), il giorno più
recente in alto. Ogni PR aggiunge la sua riga in cima, sotto il giorno del
merge.

## 2026-10-30

- Lab: Claude Code si installa in locale in `/opt/claude-code`, con postinstall e binario della piattaforma forzati; la build non si ferma più su "claude native binary not installed" ([#16](https://github.com/1r0n51uv/ron1n-dojo/pull/16))
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
