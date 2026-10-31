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
- [ ] Shikamaru non implementa (FLOW-006): codice, skill e config li fa
      Edward.
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
      Shikamaru apre la PR con le prime specifiche e quella nel repo dojo con
      `projects/<nome>.yaml`, e passa a Edward una card per il template di
      ron1n (FLOW-006).
- [ ] La PR sul hub ron1n con la riga del README e lo stack `infra/<app>/`
      la apre Edward, da una card di Shikamaru.

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
- [ ] Le notifiche sono quelle di Hermes; l'unico plugin nostro sul Kanban
      dice solo da quale bot arrivano (FLOW-005).
- [ ] Una card bloccata o fallita lo dice nella issue, così l'utente lo
      vede anche dal tracker.

### FLOW-005 · Chi si blocca te lo dice dal suo bot

Stato: fatto (#PR)

Quando una card si blocca, l'avviso arriva all'utente dal bot Telegram
dell'agente che la stava lavorando, e la risposta si dà nella chat con lui.
Hermes iscrive agli esiti solo chi ha creato la card (di solito Nico Robin) e
un worker Kanban non ha un canale verso l'utente (`clarify` lì non c'è): senza
questo, una domanda di Shikamaru restava ferma in silenzio.

Accettazione:

- [ ] Quando il dispatcher prende una card, la chat Telegram dell'utente è
      iscritta ai suoi esiti a nome dell'agente assegnato, in modalità
      `notify+wake`: blocco, fine e fallimenti arrivano dal suo bot e lo
      svegliano nella sua chat. Lo fa il plugin `dojo-handoff`, acceso nel
      profile `default` dove gira il dispatcher.
- [ ] L'avviso arriva da un bot solo: la subscription di chi ha creato la card
      sulla stessa chat Telegram passa all'assegnatario. Quelle su altre
      piattaforme (WebUI) restano.
- [ ] Un agente senza bot non cambia niente: resta la subscription di chi ha
      creato la card.
- [ ] Nel worker, un agente a cui manca una decisione dell'utente fa
      `kanban_block` con la domanda e le opzioni nel motivo, invece di
      aspettare o inventare.
- [ ] Svegliato da un blocco, l'agente legge la card, fa la domanda nella
      chat (`clarify` con `choices` se è una scelta), poi scrive la risposta
      come commento sulla card e la sblocca: il dispatcher la riprende con il
      commento. Anche una risposta scritta di getto nella chat dell'agente
      sblocca la card allo stesso modo.
- [ ] Si può sempre rispondere anche dal board: commento e `unblock` da
      dashboard o CLI.
- [ ] Un errore del plugin finisce nel log e non ferma il dispatcher.
- [ ] La CI dell'immagine prova che la subscription passa all'assegnatario e
      che il blocco successivo la raggiunge.

### FLOW-006 · Lo Strategist non implementa

Stato: fatto (#PR)

Shikamaru pianifica, chiarisce con il grilling, scrive specifiche e issue e
passa il lavoro con le card; implementare spetta a Edward, sempre.

Accettazione:

- [ ] Shikamaru non scrive né cambia codice, skill, config, script, template
      o qualunque file del repo che non sia una specifica o un documento
      (`docs/**/*.md`), il `CHANGELOG.md` o `projects/<nome>.yaml`. Le sue PR
      sono solo di specifica.
- [ ] Una richiesta da implementare (anche "aggiungi una skill al repo")
      diventa una specifica o una issue e una card per Edward (`builder`),
      con la chiave della issue e cosa fare.
- [ ] Il SOUL di Shikamaru lo dice in chiaro.
- [ ] Rinforzo in configurazione: nel profile strategist il plugin
      `dojo-spec-only` rifiuta le scritture dei tool di file (`write_file`,
      `patch`) fuori da quei percorsi, con l'invito a passare la card a
      Edward. Il terminale resta per git e `gh`, quindi non è un confine:
      una PR di Shikamaru con file fuori dalle specifiche non si fonde.
- [ ] La CI dell'immagine prova che il codice è rifiutato e la specifica
      passa.

## Note

- Flussi personali e di lavoro con le rooms future.
