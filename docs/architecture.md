# Architettura

Il dojo è un insieme di agenti Hermes (Nous Research) in Docker sul mini PC
di ron1n. Ogni agente ha un ruolo, strumenti e credenziali minimi; si parla
con loro dalla WebUI o da Telegram; lavorano su richiesta, a orario (cron) o
quando un altro agente gli passa una card.

Questa è la versione stabile (riscrittura dell'ottobre 2026): un solo
ambiente, il mini PC Linux; immagine costruita dalla CI; meno codice nostro
sopra Hermes. Il PC Windows con WSL2 serve solo per le prove.

## Principi

- **Plug and play**: un comando installa tutto (`scripts/install.sh`),
  chiede solo i valori che mancano e si può rilanciare. Gli aggiornamenti
  arrivano da soli (Watchtower).
- **Modulare**: una room è una cartella in `rooms/`; un agente si accende
  in `DOJO_AGENTS` di `dojo.env`; un progetto si aggiunge con un file in
  `projects/`.
- **Un file di configurazione**: `dojo.env` contiene tutto quello che
  decidi tu (agenti, token, bot, cartelle); `dojo.sh up` lo applica. Fuori
  restano solo il login Claude, che è un OAuth, e il modello, che si sceglie
  da Hermes.
- **Zero trust**: la room è un container senza porte verso internet, esce
  solo verso i domini permessi; ogni agente ha i suoi token minimi; il merge
  è sempre tuo.
- **Poco codice nostro**: quello che Hermes fa di serie (Kanban, notifiche,
  scelta del modello, approvazioni) non si riscrive in plugin o patch.

## Cosa isola davvero

- Un **profile** Hermes è un agente con config, SOUL, memoria, skill, cron
  e bot propri, ma non è una sandbox: i profiles nello stesso container
  condividono filesystem e processi. Un agente con `terminal` può leggere i
  file e i `.env` degli altri.
- Il **container** è il confine. Senza `docker.sock` l'agente non esce dal
  suo container; vede solo il volume della room e la cartella di lavoro
  montata.
- I **toolset** (`platform_toolsets.<piattaforma>`) decidono cosa può
  fare: senza `terminal` niente shell, senza `file` niente scritture con i
  tool di Hermes.
- Le **approvazioni** (`approvals.mode: manual`) lasciano passare da soli
  i comandi sicuri (git senza push forzato, test, build, `gh` in lettura) e
  chiedono conferma, su WebUI o Telegram, per il resto. `cron_mode` e
  `unattended_mode: deny` negano quando nessuno può rispondere;
  `approvals.deny` blocca sempre merge, push forzati e push su `main`,
  anche con approvazione.
- L'**egress** passa dal proxy Squid `egress` con allowlist di domini; la
  rete `internal` non ha rotta verso internet.
- Su **Telegram** risponde solo `TELEGRAM_ALLOWED_USERS`; un bot per
  profile.
- Su **GitHub** gli agenti usano il tuo account con un token fine-grained
  per agente, limitato ai repo dei progetti. Le loro PR risultano tue,
  quindi i repo app chiedono la CI verde ma non un'approvazione: il merge
  resta tuo e la review di L arriva come commento.

Da qui due livelli: **rooms** (container) come confine di sicurezza,
**profiles** dentro la room come ruoli. Agenti nella stessa room
condividono il board Kanban e si passano il lavoro; rooms diverse non
condividono nulla.

## Stanze

Il dojo ha una room per area. Ogni agente è un personaggio di un anime, con il
nome del ruolo in inglese.

| Stanza                | Agenti (ruolo · personaggio)                                                                                                                                                 | Può                                                    | Non può                               |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ | ------------------------------------- |
| `lab`, il laboratorio | Concierge · Nico Robin (One Piece), Strategist · Shikamaru (Naruto), Designer · Bulma (Dragon Ball), Builder · Edward Elric (Fullmetal Alchemist), Reviewer · L (Death Note) | shell nel container, git, `gh`, Jira; PR sui repo app  | merge, admin dei repo, server, docker |
| `home` (dopo)         | Companion · Chopper (One Piece)                                                                                                                                              | promemoria, note, brief del mattino; MCP di ron1nOS    | shell, GitHub, file                   |
| `work` (dopo)         | Captain · Levi (L'attacco dei giganti)                                                                                                                                       | come la room `home`, con memoria e credenziali proprie | vedere le altre rooms                 |

### Lab sul mini PC

| Servizio      | Cosa fa                                                                           | Reti               |
| ------------- | --------------------------------------------------------------------------------- | ------------------ |
| `hermes`      | gateway con i cinque profile, Telegram, Kanban, API per la WebUI                  | internal           |
| `webui`       | hermes-webui, chat via API del gateway; il suo terminale resta confinato qui      | internal           |
| `webui-proxy` | inoltro TCP verso Caddy di ron1n (`dojo.ron1n.space`) e verso `127.0.0.1:8787`    | internal, proxy    |
| `dashboard`   | inoltro TCP della dashboard di Hermes su `127.0.0.1:9119`, per diagnosi           | internal           |
| `egress`      | Squid con l'allowlist: Telegram, GitHub, npm, Anthropic, Jira (`*.atlassian.net`) | internal, external |

- **Immagine**: `ghcr.io/1r0n51uv/dojo-lab`, costruita dalla CI a ogni push
  su `main` con i tag `main` e `sha-<commit>`. Contiene Hermes, Claude Code,
  il plugin Claude, hermes-webui, config, SOUL, flows e skill, tutti a
  versione fissata. Il tag mobile `main` va bene perché l'immagine è senza
  dati. Watchtower di ron1n (`infra/updates`) la aggiorna.
- **Stato di Hermes** (memoria, sessioni, board, `.env` dei profile) nel
  volume `dojo-lab_data`.
- **Cartella di lavoro**: `~/dojo/lab` del mini PC montata in
  `/opt/data/work`. Il container gira con il tuo UID, così i file sono tuoi.
  Ogni agente lavora in `/opt/data/work/<agente>/` per convenzione. Il nome
  della room e quello della sua cartella coincidono (`~/dojo/<room>`): le
  rooms future avranno `~/dojo/home` e `~/dojo/work`, e non vedono quelle
  delle altre.
- **WebUI fuori casa**: Cloudflare Tunnel e Caddy di ron1n, dietro
  Cloudflare Access, come gli altri siti.

In una room il profile `default` non ha bot: ospita il gateway che serve
tutti i profiles (multiplexing) e il dispatcher Kanban.

### Agenti della lab

| Agente                   | Ruolo                                                                                  | Toolset                                                               | Token GitHub                                |
| ------------------------ | -------------------------------------------------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------- |
| `concierge` (Nico Robin) | primo contatto, chiarisce con `grilling`, card a Shikamaru; non tocca il tracker       | kanban, clarify, skills, todo, memory                                 | nessuno                                     |
| `strategist` (Shikamaru) | specifica, PR `spec`, issue nel tracker (anche quella iniziale), card a Bulma o Edward | file, terminal, kanban, clarify, skills, todo, memory                 | contents, pull requests, issues: scrittura  |
| `designer` (Bulma)       | flows, mockup e note UI/UX in `docs/design/` e nella issue; niente codice              | file, terminal, vision, kanban, clarify, skills, todo, memory         | contents, pull requests, issues: scrittura  |
| `builder` (Edward)       | implementazione con test, `npm run check`, PR con il riferimento alla issue            | file, terminal, code_execution, kanban, clarify, skills, todo, memory | contents, pull requests: scrittura          |
| `reviewer` (L)           | review contro specifica e regole, commento sulla PR, card indietro o PR pronta         | terminal, kanban, clarify, skills, todo, memory                       | contents: lettura; pull requests: scrittura |

## Modelli

Per ora tutti gli agenti usano Claude con il tuo abbonamento, attraverso la
CLI ufficiale di Claude Code e il plugin `claude-subscription-directsdk` di
Nous Research. È una zona grigia dei termini di Anthropic, accettata. Non c'è
riserva: finita la quota gli agenti aspettano il reset.

Il modello di ogni agente si sceglie da Hermes (`hermes model`, dashboard o
WebUI) con i nomi veri del provider: niente nomi logici come `strong` o
`fast`. Da lì si aggiungono altri provider quando serviranno. Il gateway
LiteLLM esce dal dojo ([MODELS-006, MODELS-007](specs/models.md)).

## Canali

- **WebUI**: il canale principale, da casa e da fuori.
- **Telegram**: chat completa con ogni agente, un bot per agente.
- **A orario**: `hermes cron` del profile, consegna su Telegram.
- AionUi e i client ACP non fanno più parte del dojo.

## Lavoro

Il lavoro vive su due livelli ([tracker](specs/tracker.md),
[flussi](specs/flows.md)):

- il **tracker del progetto**, GitHub Issues o Jira scelto in
  `projects/<nome>.yaml`: quello che vedi tu da cliente;
- il **Kanban di Hermes**, la cucina interna: dice quale agente deve
  partire. Ogni card porta la chiave della issue (`#42` o `DOJO-42`).

I flussi sono skill Hermes in [`flows/`](../flows/README.md), neutre
rispetto al tracker: dicono «sposta la issue in Review», e le skill
`tracker-github` e `tracker-jira` lo traducono in comandi. Accanto,
[`skills/`](../skills/README.md) ha le skill di supporto: Nico Robin usa
`grilling` per chiarire una richiesta, Shikamaru `grilling-with-docs` per
rivederla contro i documenti del repo. Le domande a scelta multipla passano
dal tool `clarify`, che su Telegram mostra le opzioni come bottoni.

1. **Nuova feature**: Nico Robin → Shikamaru (specifica, issue) → Bulma
   (mockup, se c'è interfaccia) → Edward (PR) → L (review) → merge tuo.
2. **Nuovo progetto**: Shikamaru prepara specifica, template e
   `projects/<nome>.yaml`; repo e branch protection li crei tu.
3. **Personale** (room `home`), **lavoro** (room `work`), **ricorrenti**: con le rooms future.

Le notifiche del Kanban sono quelle di Hermes. I plugin `handoff` e
`kanban-telegram` della prima versione escono; se le notifiche di serie non
bastano si decide dopo la prova sul mini PC.

## Fasi della riscrittura

1. **Specifiche**: questo documento e `docs/specs/`.
2. **Immagine in CI**: Dockerfile ripulito, pubblicazione su GHCR.
3. **Room lab nuova**: compose con l'immagine GHCR, cartella montata,
   approvazioni con comandi sicuri; via ACP, patch e plugin.
4. **Tracker e flows**: `projects/`, skill `tracker-github` e
   `tracker-jira`, flows riscritti.
5. **Install e migrazione sul mini PC**: `install.sh` con `dojo.env`,
   `migrate-memory.sh`, WebUI su `dojo.ron1n.space` (PR in ron1n), pulizia del
   PC Windows.

Dopo: room `home`, cron, webhook GitHub via Tunnel, room `work`, server
MCP per ron1n.

## Riferimenti

Documentazione di Hermes nel repo
[NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent),
cartella `website/docs/user-guide/`: `docker.md`, `profiles.md`,
`security.md`, `features/kanban.md`, `features/cron.md`,
`egress/network-isolation.md`, `messaging/telegram.md`.
