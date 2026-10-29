# Flussi

Prefisso ID: `FLUSSO` · Label: `mod:flows`

Un flusso è una sequenza fissa di passaggi fra agenti, scritta come skill
Hermes in `flows/`. Gli agenti arrivano fino alla PR pronta; il merge è
sempre dell'utente.

## Requisiti

### FLOW-001 · Nuova feature

Stato: proposto

Da un messaggio su Telegram con un'idea si arriva a una PR revisionata,
pronta per il merge, seguendo il flusso di ron1n.

Accettazione:

- [ ] Se la richiesta arriva da una card di Nico Robin, Shikamaru manda
      prima la sua revisione del piano, con le correzioni e da dove
      vengono, e chiede solo le decisioni che il repo non dice.
- [ ] Le domande a scelta multipla arrivano su Telegram con le opzioni
      come bottoni.
- [ ] Shikamaru apre la PR di specifica (label `spec`, `type:docs`,
      CHANGELOG) e manda il link; non procede prima del merge.
- [ ] Dopo il merge crea una issue per requisito, con titolo
      `[PRE-NNN] ...`, criteri copiati e label, e una card Kanban per il
      builder.
- [ ] Edward apre una PR per issue con `Closes #N`, test, CHANGELOG e
      stato del requisito a `fatto`, dopo `npm run check` verde.
- [ ] L lascia una review; se chiede modifiche la card torna a Edward,
      se è pronta l'utente riceve il link su Telegram.
- [ ] Nessun agente fa merge o spinge su `main`.

### FLOW-002 · Nuovo progetto

Stato: proposto

Da nome e descrizione si arriva a un repo app pronto per il primo
requisito.

Accettazione:

- [ ] Shikamaru raccoglie nome, descrizione, stack e primo modulo.
- [ ] Dopo che l'utente ha creato il repo, Shikamaru apre la PR con il
      template di ron1n e le prime specifiche.
- [ ] Apre la PR sul hub ron1n con la riga del README e lo stack
      `infra/<app>/`.

### FLOW-003 · Lavori ricorrenti

Stato: proposto

Gli agenti possono lavorare a orario e mandare il risultato su Telegram.

Accettazione:

- [ ] Digest settimanale di issue e PR aperte nei repo app.
- [ ] Avviso quando la CI di `main` di un repo app è rossa.
- [ ] Nei lavori a orario i comandi pericolosi sono negati.

## Note

- Flussi personali e di lavoro con le rooms della fase 2 e 3.
