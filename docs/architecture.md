# Architettura

Il dojo è un insieme di agenti Hermes (Nous Research) in Docker. Ognuno ha
un ruolo, strumenti e credenziali minimi; si parla con loro da Telegram;
lavorano su richiesta, a orario (cron) o su evento (webhook). Gira sul
mini PC di ron1n accanto agli altri stack.

## Principi

- **Plug and play**: un comando installa tutto
  (`scripts/install.sh`), chiede solo i valori che mancano e si può
  rilanciare.
- **Modulare**: una room è una cartella in `rooms/`; reti, chiavi e
  avvio la trovano da sola. Un agente si attiva quando gli dai un `.env`.
- **Zero trust**: nessun agente si fida degli altri né della rete. Ogni
  room è un container senza porte e senza internet, esce solo verso i
  domini permessi; ogni agente ha i suoi token minimi; le chiavi dei
  provider stanno solo nel gateway; il merge è sempre tuo.
- **Free**: tutto è open source e gira anche solo con modelli gratuiti
  (OpenRouter `:free`, Groq, Gemini) o locali (Ollama); trascrizione e voci
  hanno opzioni gratuite e locali. I modelli a pagamento sono un'aggiunta.

## Cosa isola davvero

- Un **profile** Hermes è un agente con config, SOUL, memoria, skill, cron
  e bot propri, ma non è una sandbox: i profiles nello stesso container
  condividono filesystem e processi.
- Il **container** è il confine. Senza `docker.sock` l'agente non esce dal
  suo container; il volume dati è solo suo.
- I **toolset** (`platform_toolsets.<piattaforma>`) decidono cosa può
  fare: senza `terminal` niente shell, senza `file` niente scritture.
- Le **approvazioni** (`approvals.mode: manual`) chiedono conferma su
  Telegram per i comandi pericolosi; `cron_mode` e `unattended_mode: deny`
  li negano quando nessuno può rispondere; `approvals.deny` blocca sempre
  alcuni comandi (merge, push forzati), anche con approvazione.
- L'**egress** passa dal proxy Squid `egress` con allowlist di domini; la
  rete `internal` non ha rotta verso internet.
- Su **Telegram** risponde solo `TELEGRAM_ALLOWED_USERS`; un bot per
  profile.
- Su **GitHub** ogni agente ha un token fine-grained dell'account bot,
  limitato ai repo app; la branch protection impedisce merge senza
  approvazione.

Da qui due livelli: **rooms** (container) come confine di sicurezza,
**profiles** dentro la room come ruoli. Agenti nella stessa room
condividono il board Kanban e si passano il lavoro; rooms diverse non
condividono nulla.

## Stanze

Il dojo ha una room per area. Ogni agente è un personaggio di un anime, con il
nome del ruolo in inglese.

| Stanza                | Agenti (ruolo · personaggio)                                                                                                                                                 | Può                                                       | Non può                               |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- | ------------------------------------- |
| `lab`, il laboratorio | Strategist · Shikamaru (Naruto), Designer · Bulma (Dragon Ball), Concierge · Nico Robin (One Piece), Builder · Edward Elric (Fullmetal Alchemist), Reviewer · L (Death Note) | shell nel container, git, `gh`, npm; PR sui repo app      | merge, admin dei repo, server, docker |
| personale (dopo)      | Companion · Chopper (One Piece)                                                                                                                                              | promemoria, note, brief del mattino; MCP di ron1nOS       | shell, GitHub, file                   |
| lavoro (dopo)         | Captain · Levi (L'attacco dei giganti)                                                                                                                                       | come la room personale, con memoria e credenziali proprie | vedere le altre rooms                 |

I nomi delle rooms personale e lavoro si decidono quando
arrivano.

Ogni room: immagine Hermes a versione fissata, volume dati suo, limiti di
CPU e memoria, rete `internal` più proxy `egress`, nessuna porta pubblicata
(Telegram in polling), dashboard spenta o solo su `127.0.0.1`.

In una room il profile `default` non ha bot: ospita il gateway che serve
tutti i profiles (multiplexing) e il dispatcher Kanban.

### Lab

| Agente                   | Ruolo                                                                                                   | Toolset                                         | Token GitHub                                |
| ------------------------ | ------------------------------------------------------------------------------------------------------- | ----------------------------------------------- | ------------------------------------------- |
| `strategist` (Shikamaru) | specifica, PR `spec`, issue con label, card per Edward                                                  | file, terminal, kanban, clarify, skills         | contents, pull requests, issues: scrittura  |
| `designer` (Bulma)       | flows, mockup e specifiche UI/UX in `docs/design/`, review di progetti, issue per Edward; niente codice | file, terminal, vision, kanban, clarify, skills | contents, pull requests, issues: scrittura  |
| `builder` (Edward)       | implementazione con test, `npm run check`, PR con `Closes #N`                                           | file, terminal, code_execution, kanban, clarify | contents, pull requests: scrittura          |
| `reviewer` (L)           | review contro specifica e regole, segnala la PR pronta                                                  | terminal, kanban, clarify, skills               | contents: lettura; pull requests: scrittura |

## Modelli

Le rooms non parlano direttamente con i provider: passano dal gateway
[`services/models/`](../services/models/compose.yaml), un LiteLLM con le
chiavi vere. Ogni room ha una chiave virtuale con budget mensile e una
rete sua verso il gateway. Gli agenti chiedono un nome logico:

| Nome     | Provider, in ordine                           | Per                        |
| -------- | --------------------------------------------- | -------------------------- |
| `strong` | Anthropic Opus, OpenRouter, poi `fast`        | specifiche, codice, review |
| `fast`   | Anthropic Sonnet, OpenRouter, poi `free`      | lavoro di tutti i giorni   |
| `free`   | OpenRouter `:free`, Groq, Gemini, poi `local` | digest, riassunti, cron    |
| `local`  | Ollama sul mini PC (spento di default)        | lavori leggeri e privati   |

## Canali

- **Telegram** per iniziare: un bot per agente. WhatsApp è supportato da
  Hermes ma vuole un secondo numero e un pairing da rifare: più avanti.
- **Su richiesta**: messaggio al bot (`/new-feature ...` o testo libero).
- **A orario**: `hermes cron` del profile, consegna su Telegram.
- **Su evento**: webhook GitHub verso il gateway. Serve una porta
  raggiungibile, quindi Caddy più Cloudflare Tunnel come gli altri stack:
  fase 2.

## Flussi

Skill Hermes in [`flows/`](../flows/README.md), montate in sola lettura.
Ogni passaggio fra agenti è una card Kanban; le card PR hanno un contratto
di completamento, quindi si chiudono solo con i check richiesti verdi.

1. **Nuova feature**: strategist (specifica, issue) → designer (mockup,
   se c'è interfaccia) → builder (PR) → reviewer (review) → merge tuo.
2. **Nuovo progetto**: strategist prepara specifica e template; repo e
   branch protection li crei tu; PR sul hub per README e `infra/<app>/`.
3. **Personale**, **lavoro**, **ricorrenti** (digest di PR e issue, CI
   rossa su `main`, dipendenze): con le rooms della fase 2.

## Fasi

1. **Fase 0**: questo repo, specifiche, room `lab`, flows in bozza.
2. **Fase 1**: `lab` sul mini PC con Telegram, prova di
   `new-feature` su un repo vero; stack `infra/dojo-lab/` in ron1n.
3. **Fase 2**: room `personale`, cron, webhook GitHub via Tunnel.
4. **Fase 3**: room `lavoro`, server MCP per ron1n (stato degli stack,
   log, API di ron1nOS) con filtri per server nelle rooms.

## Riferimenti

Documentazione di Hermes nel repo
[NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent),
cartella `website/docs/user-guide/`: `docker.md`, `profiles.md`,
`security.md`, `features/kanban.md`, `features/cron.md`,
`egress/network-isolation.md`, `messaging/telegram.md`.
