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
      nell'allowlist di `egress`.

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

## Note

- I nomi dei modelli sui provider cambiano: si verificano in
  `services/models/config.yaml` al primo avvio.
- Un modello Claude nuovo vuole una versione di LiteLLM che lo conosca:
  con una troppo vecchia LiteLLM manda `temperature` e `budget_tokens`, che
  Claude 5.x rifiuta con 400, e `strong` scivola sui modelli free.
- I modelli free sbagliano spesso le chiamate agli strumenti: vanno bene
  per riassunti e lavori a orario, non per specifiche e codice.
