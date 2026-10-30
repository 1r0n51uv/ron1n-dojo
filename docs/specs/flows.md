# Flussi

Prefisso ID: `FLOW` · Label: `mod:flows`

Un flusso è una sequenza fissa di passaggi fra agenti, scritta come skill
Hermes in `flows/`. I flussi parlano di issue e stati, non di un tracker
preciso: GitHub Issues o Jira li traducono le skill del tracker
([tracker](tracker.md)). Gli agenti arrivano fino alla PR pronta; il merge è
sempre dell'utente.

## Requisiti

### FLOW-001 · Nuova feature

Stato: proposto

Da una richiesta, sulla WebUI, su Telegram o come issue nel tracker, si
arriva a una PR revisionata, pronta per il merge, seguendo il flusso di
ron1n.

Accettazione:

- [ ] Nico Robin chiarisce la richiesta con `grilling` e crea la card per
      Shikamaru, con la chiave della issue se c'è già; non tocca il tracker.
- [ ] Se la issue manca, Shikamaru la apre nel tracker del progetto.
- [ ] Shikamaru manda prima la sua revisione del piano, con le correzioni e
      da dove vengono, e chiede solo le decisioni che il repo non dice.
- [ ] Le domande a scelta multipla usano `clarify` con le opzioni in
      `choices` (bottoni su Telegram).
- [ ] Shikamaru apre la PR di specifica (label `spec`, `type:docs`,
      CHANGELOG) e manda il link; non procede prima del merge.
- [ ] Dopo il merge crea una issue per requisito nel tracker, con titolo
      `[PRE-NNN] ...`, criteri copiati e label o campi, e passa la card a
      Bulma se c'è interfaccia, altrimenti a Edward.
- [ ] Bulma lascia mockup e note UX nella issue e in `docs/design/`, poi
      passa la card a Edward.
- [ ] Edward apre una PR per issue dal branch `<chiave>-<titolo>` (per
      esempio `DOJO-42-login` o `42-login`), con il riferimento alla issue
      (`Closes #N` o la chiave Jira), test, CHANGELOG e stato del requisito
      a `fatto`, dopo `npm run check` verde; sposta la issue in Review e
      passa la card a L.
- [ ] L commenta la PR; se chiede modifiche la card torna a Edward, se è
      pronta l'utente riceve il link nella chat di L.
- [ ] Dopo il merge la issue passa a Fatto.
- [ ] Nessun agente fa merge o spinge su `main`.

### FLOW-002 · Nuovo progetto

Stato: proposto

Da nome e descrizione si arriva a un repo app pronto per il primo
requisito, con il suo tracker.

Accettazione:

- [ ] Shikamaru raccoglie nome, descrizione, stack, primo modulo e tracker
      (GitHub Issues o Jira, con la chiave del progetto Jira).
- [ ] Dopo che l'utente ha creato il repo (e il progetto Jira, se serve),
      Shikamaru apre la PR con il template di ron1n e le prime specifiche,
      e quella nel repo dojo con `projects/<nome>.yaml`.
- [ ] Apre la PR sul hub ron1n con la riga del README e lo stack
      `infra/<app>/`.

### FLOW-003 · Lavori ricorrenti

Stato: proposto

Gli agenti possono lavorare a orario e mandare il risultato su Telegram.

Accettazione:

- [ ] Digest settimanale di issue e PR aperte nei progetti.
- [ ] Avviso quando la CI di `main` di un repo app è rossa.
- [ ] Nei lavori a orario i comandi pericolosi sono negati.

### FLOW-004 · Kanban interno fra agenti

Stato: proposto

Il Kanban di Hermes dice quale agente deve partire; il tracker resta la
fonte di verità per l'utente.

Accettazione:

- [ ] Ogni passaggio fra agenti è una card del board della room, con la
      chiave della issue nel titolo (`#42` o `DOJO-42`) e il progetto.
- [ ] Il dispatcher del gateway assegna le card; le card PR si chiudono solo
      con i check richiesti verdi.
- [ ] Nessun plugin nostro sul Kanban: le notifiche sono quelle di Hermes.
      Dopo la prova sul mini PC si decide se servono avvisi in più.
- [ ] Una card bloccata o fallita lo dice nella issue, così l'utente lo
      vede anche dal tracker.

## Note

- Flussi personali e di lavoro con le rooms future.
