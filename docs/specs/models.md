# Modelli

Prefisso ID: `MODELS` · Label: `mod:models`

Il gateway dei modelli (`services/models/`) è l'unico punto da cui il dojo
parla con i modelli: LiteLLM davanti a provider cloud, piani free e Ollama
sul mini PC. Gli agenti chiedono un nome logico, non un provider.

## Requisiti

### MODELS-001 · Nomi logici con riserve

Stato: proposto

Un agente chiede `strong`, `fast`, `free` o `local`; il gateway sceglie
il provider e, se fallisce o finisce la quota, passa alla riserva.

Accettazione:

- [ ] `strong` e `fast` usano Anthropic, con riserva su OpenRouter.
- [ ] `free` usa i modelli `:free` di OpenRouter, poi Groq, Gemini e
      Ollama.
- [ ] Un provider senza chiave non blocca gli altri: si passa al successivo.
- [ ] Un 429 di quota finita (anche a stream già aperto, come fa Gemini)
      passa al modello successivo, e il modello resta in cooldown 5 minuti.
- [ ] Ollama è spento di default e si accende con il profile `local`.

### MODELS-002 · Chiavi vere solo nel gateway

Stato: proposto

Le rooms non vedono le chiavi dei provider: ognuna ha una chiave virtuale
con un budget.

Accettazione:

- [ ] Le chiavi dei provider stanno solo in `services/models/.env`.
- [ ] `scripts/dojo.sh key <room> [budget]` crea una chiave limitata ai
      nomi logici, con budget mensile (20 dollari di default).
- [ ] Oltre il budget la room riceve un errore, non spende altro.
- [ ] Un budget a 0, negativo o non numerico è rifiutato da `dojo.sh key` e
      dall'installazione, che lo richiede finché è valido.
- [ ] `scripts/dojo.sh budget <room> <dollari>` cambia il budget della
      chiave esistente, senza toccare i `.env` né riavviare nulla.
- [ ] Le rooms non hanno `api.anthropic.com` né altri provider
      nell'allowlist di `egress`; l'unica eccezione è l'abbonamento Claude
      acceso con `dojo.sh claude` (MODELS-006).

### MODELS-003 · Stanze separate anche verso il gateway

Stato: proposto

Ogni room raggiunge il gateway su una rete sua, senza internet, e non
vede le altre rooms.

Accettazione:

- [ ] `dojo.sh up` e `sync` creano `dojo-<room>-models` (`--internal`)
      se manca.
- [ ] Da una room `litellm:4000` risponde, il container di un'altra
      room no.
- [ ] Il gateway non pubblica porte sull'host.

### MODELS-004 · Chiavi dei provider senza toccare i file

Stato: proposto

Una chiave si aggiunge o si cambia con un comando, senza aprire il `.env` e
senza riavviare le rooms.

Accettazione:

- [ ] `scripts/dojo.sh provider <anthropic|openrouter|groq|gemini>` chiede la
      chiave con input nascosto: non passa dalla riga di comando.
- [ ] Aggiorna la riga in `services/models/.env` (permessi 600) e riavvia solo
      LiteLLM.
- [ ] Un valore vuoto non cambia nulla.

### MODELS-005 · Abbonamento ChatGPT al posto delle API key

Stato: proposto

Con un abbonamento ChatGPT (Plus o Pro) `strong` e `fast` usano GPT
attraverso il provider `chatgpt/` di LiteLLM, senza API key e senza
toccare le rooms. Finita la quota dell'abbonamento si scende sulle riserve.

Accettazione:

- [ ] `scripts/dojo.sh chatgpt` fa il login con codice dispositivo in un
      container usa e getta del gateway, poi passa LiteLLM a
      `config.chatgpt.yaml` (`LITELLM_CONFIG` nel `.env`) e lo riavvia.
- [ ] Il token sta solo nel volume `chatgpt` del gateway; le rooms non lo
      vedono e non hanno domini OpenAI nell'allowlist.
- [ ] Senza login il gateway resta su `config.yaml`: nessuna richiesta
      aspetta un codice dispositivo.
- [ ] Un 429 di quota finita passa a `strong-backup` e poi ai free, come
      per gli altri provider.
- [ ] `scripts/dojo.sh chatgpt off` torna a `config.yaml`.
- [ ] L'installazione chiede se collegare l'abbonamento (default no) e
      non lo richiede se è già collegato.
- [ ] `config.chatgpt.yaml` è uguale a `config.yaml` dai piani free in
      giù: lo controlla `scripts/validate.sh`.

### MODELS-006 · Abbonamento Claude come modello degli agenti

Stato: proposto

Con un abbonamento Claude (Pro o Max) un agente usa Claude come modello
principale, attraverso la CLI ufficiale di Claude Code non modificata e il
plugin `claude-subscription-directsdk` di Nous Research. Il gateway resta la
riserva: finita la quota di Claude si passa a `strong` o `fast`, quindi a GPT
se l'abbonamento ChatGPT è collegato, e poi ai free.

Accettazione:

- [ ] L'immagine della room ha Claude Code e il plugin a versione fissata
      (`CLAUDE_CODE_VERSION` e `CLAUDE_PLUGIN_COMMIT` in `compose.yaml`); il
      plugin sta in `/opt/hermes`, che gli agenti non possono modificare.
- [ ] Senza `dojo.sh claude` nulla cambia: gli agenti usano il gateway e
      l'egress non ha domini di Anthropic.
- [ ] `scripts/dojo.sh claude <room> [agente...]` apre all'egress
      `api.anthropic.com`, `claude.ai` e `platform.claude.com`
      (`egress/00-claude.conf`), fa il login con `claude auth login` nel
      container se manca e scrive `claude.env` con gli agenti (tutti quelli
      attivi senza nomi) e il modello (`sonnet` di default).
- [ ] `dojo.sh sync` passa il `config.yaml` di quegli agenti a Claude con
      `scripts/claude_profile.py`: il modello del repo diventa la prima voce di
      `fallback_providers`, il contesto resta quello del repo.
- [ ] Un 429 di quota finita passa alla riserva per il resto della
      sessione; le sessioni nuove tornano su Claude
      quando la quota si azzera.
- [ ] `scripts/dojo.sh claude <room> off` toglie `claude.env` e
      `00-claude.conf` e riporta gli agenti al gateway.
- [ ] Telemetria e aggiornamenti automatici di Claude Code spenti.

## Note

- I nomi dei modelli sui provider cambiano: si verificano in
  `services/models/config.yaml` al primo avvio.
- Un modello Claude nuovo vuole una versione di LiteLLM che lo conosca:
  con una troppo vecchia LiteLLM manda `temperature` e `budget_tokens`, che
  Claude 5.x rifiuta con 400, e `strong` scivola sui modelli free.
- I nomi dei modelli GPT dell'abbonamento (`chatgpt/gpt-6.1-sol` per
  `strong`, `chatgpt/gpt-6-luna` per `fast`) cambiano con i piani di
  OpenAI: si verificano dopo il login.
- Il token dell'abbonamento Claude sta nel volume della room
  (`/opt/data/claude`), non nel gateway: gli agenti con `terminal` girano
  con lo stesso utente e potrebbero leggerlo. È il prezzo del plugin, che
  deve chiamare la CLI dal processo di Hermes.
- La quota di Claude è quella del tuo account, condivisa con Claude Code,
  claude.ai e l'app. Il plugin consuma come `claude -p`, più in fretta della
  CLI interattiva. Su Pro i modelli con contesto da 1M di Opus e Fable usano
  i crediti extra: si resta su `sonnet`.
- I modelli free sbagliano spesso le chiamate agli strumenti: vanno bene
  per riassunti e lavori a orario, non per specifiche e codice.
