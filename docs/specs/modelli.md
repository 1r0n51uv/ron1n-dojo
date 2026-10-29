# Modelli

Prefisso ID: `MODELLI` · Label: `mod:modelli`

Il gateway dei modelli (`servizi/modelli/`) è l'unico punto da cui il dojo
parla con i modelli: LiteLLM davanti a provider cloud, piani free e Ollama
sul mini PC. Gli agenti chiedono un nome logico, non un provider.

## Requisiti

### MODELLI-001 · Nomi logici con riserve

Stato: proposto

Un agente chiede `forte`, `veloce`, `gratis` o `locale`; il gateway sceglie
il provider e, se fallisce o finisce la quota, passa alla riserva.

Accettazione:

- [ ] `forte` e `veloce` usano Anthropic, con riserva su OpenRouter.
- [ ] `gratis` usa i modelli `:free` di OpenRouter, poi Groq, Gemini e
      Ollama.
- [ ] Un provider senza chiave non blocca gli altri: si passa al successivo.
- [ ] Ollama è spento di default e si accende con il profilo `locale`.

### MODELLI-002 · Chiavi vere solo nel gateway

Stato: proposto

Le stanze non vedono le chiavi dei provider: ognuna ha una chiave virtuale
con un budget.

Accettazione:

- [ ] Le chiavi dei provider stanno solo in `servizi/modelli/.env`.
- [ ] `scripts/dojo.sh chiave <stanza> [budget]` crea una chiave limitata ai
      nomi logici, con budget mensile (20 dollari di default).
- [ ] Oltre il budget la stanza riceve un errore, non spende altro.
- [ ] Un budget a 0, negativo o non numerico è rifiutato da `dojo.sh chiave` e
      dall'installazione, che lo richiede finché è valido.
- [ ] `scripts/dojo.sh budget <stanza> <dollari>` cambia il budget della
      chiave esistente, senza toccare i `.env` né riavviare nulla.
- [ ] Le stanze non hanno `api.anthropic.com` né altri provider
      nell'allowlist di `uscita`.

### MODELLI-003 · Stanze separate anche verso il gateway

Stato: proposto

Ogni stanza raggiunge il gateway su una rete sua, senza internet, e non
vede le altre stanze.

Accettazione:

- [ ] `dojo.sh up` e `sync` creano `dojo-<stanza>-modelli` (`--internal`)
      se manca.
- [ ] Da una stanza `litellm:4000` risponde, il container di un'altra
      stanza no.
- [ ] Il gateway non pubblica porte sull'host.

## Note

- I nomi dei modelli sui provider cambiano: si verificano in
  `servizi/modelli/config.yaml` al primo avvio.
- I modelli free sbagliano spesso le chiamate agli strumenti: vanno bene
  per riassunti e lavori a orario, non per specifiche e codice.
