# Modelli

Prefisso ID: `MODELS` · Label: `mod:models`

Per ora il dojo usa solo Claude, con l'abbonamento dell'utente. Il modello
di ogni agente si sceglie da Hermes con i nomi veri del provider; il gateway
LiteLLM e i nomi logici (`strong`, `fast`, `free`, `local`) della prima
versione escono.

## Requisiti

### MODELS-001 · Nomi logici con riserve

Stato: rimosso

Niente più nomi logici: il modello si sceglie da Hermes (MODELS-007).

### MODELS-002 · Chiavi vere solo nel gateway

Stato: rimosso

Il gateway LiteLLM esce dal dojo insieme alle chiavi virtuali e ai budget.

### MODELS-003 · Stanze separate anche verso il gateway

Stato: rimosso

Senza gateway non servono le reti `dojo-<room>-models`.

### MODELS-004 · Chiavi dei provider senza toccare i file

Stato: rimosso

Le chiavi di eventuali provider nuovi si aggiungono da Hermes (MODELS-007).

### MODELS-005 · Abbonamento ChatGPT al posto delle API key

Stato: rimosso

Per ora solo Claude, senza riserva ChatGPT.

### MODELS-006 · Abbonamento Claude per tutti gli agenti

Stato: proposto

Tutti gli agenti usano Claude con l'abbonamento dell'utente (Pro o Max),
attraverso la CLI ufficiale di Claude Code non modificata e il plugin
`claude-subscription-directsdk` di Nous Research. È una zona grigia dei
termini di Anthropic, accettata dall'utente.

Accettazione:

- [ ] L'immagine ha Claude Code e il plugin a versione fissata; il plugin
      sta in `/opt/hermes`, che gli agenti non possono modificare.
- [ ] L'egress apre sempre `api.anthropic.com`, `claude.ai` e
      `platform.claude.com`.
- [ ] `scripts/dojo.sh claude` fa il login con `claude auth login` nel
      container se manca; il token sta nel volume della room
      (`/opt/data/claude`).
- [ ] Ogni profile parte con il provider Claude e il modello `sonnet`.
- [ ] Nessuna riserva: finita la quota l'agente lo dice in chat e aspetta
      il reset; `dojo.sh doctor` mostra lo stato del login.
- [ ] Telemetria e aggiornamenti automatici di Claude Code spenti.

### MODELS-007 · Modello scelto da Hermes

Stato: proposto

Il modello di ogni agente si sceglie e si cambia da Hermes, e da lì si
aggiungono altri provider quando serviranno.

Accettazione:

- [ ] Nei `config.yaml` del repo provider e modello hanno i nomi veri (per
      esempio `claude-subscription` e `sonnet`), nessun alias.
- [ ] Un cambio fatto con `hermes model`, dalla dashboard o dalla WebUI
      resta dopo un riavvio e dopo un aggiornamento dell'immagine
      (ROOM-012).
- [ ] Un provider nuovo con API key si aggiunge da Hermes; il suo dominio
      entra nell'allowlist di `egress` con una PR che dice perché serve.

## Note

- La quota di Claude è quella dell'account dell'utente, condivisa con Claude
  Code, claude.ai e l'app. Il plugin consuma come `claude -p`, più in fretta
  della CLI interattiva; con cinque agenti su Pro finisce presto. Su Pro i
  modelli con contesto da 1M di Opus e Fable usano i crediti extra: si resta
  su `sonnet`.
- Il token dell'abbonamento sta nel volume della room: gli agenti con
  `terminal` girano con lo stesso utente e potrebbero leggerlo. È il prezzo
  del plugin, che deve chiamare la CLI dal processo di Hermes.
