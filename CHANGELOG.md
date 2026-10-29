# Changelog

Cosa cambia nel dojo (stanze, profili, flussi, script), il giorno più
recente in alto. Ogni PR aggiunge la sua riga in cima, sotto il giorno del
merge.

## 2026-10-29

- SOUL degli agenti della lab con storia, modo di parlare e ruolo dei personaggi; nuova cartella `skills/` con `grilling`, che Nico Robin usa per chiarire una richiesta prima di smistarla ([#7](https://github.com/1r0n51uv/ron1n-dojo/pull/7))
- Nomi in inglese: cartelle `rooms/`, `services/`, `flows/`, comandi `dojo.sh key`/`secret`/`up-models`, servizi `egress` e `dashboard`, modelli `strong`/`fast`/`free`/`local`, ID `ROOM`/`FLOW`/`MODELS` ([#6](https://github.com/1r0n51uv/ron1n-dojo/pull/6))
- Gemini passa in testa ai modelli gratuiti del gateway: più veloce e più affidabile con i tool ([#5](https://github.com/1r0n51uv/ron1n-dojo/pull/5))
- `dojo.sh budget lab` trova anche la chiave `stanza-kajiba` della migrazione e la rinomina ([#4](https://github.com/1r0n51uv/ron1n-dojo/pull/4))
- `dojo.sh segreto` imposta token del bot e `GH_TOKEN` di un agente con input nascosto ([#3](https://github.com/1r0n51uv/ron1n-dojo/pull/3))
- Ruoli in inglese (Strategist, Builder, Reviewer, Concierge, Companion, Captain), stanza `lab` al posto di `kajiba` e nuovi agenti Designer (Bulma) e Concierge (Nico Robin) ([#2](https://github.com/1r0n51uv/ron1n-dojo/pull/2))
- `dojo.sh provider` ricollega LiteLLM alle stanze dopo il riavvio ([#1](https://github.com/1r0n51uv/ron1n-dojo/pull/1))
- Dashboard di Hermes sulla kajiba, solo su 127.0.0.1 e con password casuale (STANZA-006)
- Prima versione del dojo: stanza kajiba (Shikamaru, Edward, L), gateway dei modelli LiteLLM, installazione con un comando ([#1](https://github.com/1r0n51uv/ron1n-dojo/pull/1))
