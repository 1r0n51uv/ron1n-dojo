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

Da una richiesta, sulla WebUI o come issue nel tracker, si
arriva a una PR pronta per il merge, seguendo il flusso di
ron1n.

Accettazione:

- [ ] Quando 1ron51uv decide di procedere, Nico Robin (se chiarire serve,
      con `grilling`) crea la card per Shikamaru con la consegna di FLOW-010,
      con la chiave della issue se c'è già; non tocca il tracker (FLOW-007).
- [ ] Se la issue manca, Shikamaru la apre nel tracker del progetto.
- [ ] Shikamaru non implementa (FLOW-006): codice, skill e config li fa
      Edward.
- [ ] Shikamaru manda prima la sua revisione del piano, con le correzioni e
      da dove vengono, e chiede solo le decisioni che il repo non dice.
- [ ] Le domande a scelta multipla usano `clarify` con le opzioni in
      `choices`.
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

Gli agenti possono lavorare a orario; come arriva il risultato si decide
con il primo lavoro a orario, senza Telegram.

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
- [ ] Le notifiche sono quelle di Hermes, nessun plugin nostro sul Kanban.
- [ ] Una card bloccata o fallita lo dice nella issue, così l'utente lo
      vede anche dal tracker.

### FLOW-005 · Chi si blocca te lo dice dal suo bot

Stato: rimosso

Fatto con la #32, esce con Telegram (ROOM-002): non ci sono più bot da cui
far arrivare gli avvisi, e il plugin `dojo-handoff` è stato tolto. Una card
bloccata si vede nella WebUI, sul board o nella sessione dell'agente, e si
sblocca da lì (commento e `unblock`, anche da dashboard o CLI). Resta la
regola dei SOUL: nel worker, un agente a cui manca una tua decisione fa
`kanban_block` con la domanda e le opzioni nel motivo, invece di aspettare o
inventare.

### FLOW-006 · Lo Strategist non implementa

Stato: fatto (#32)

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

### FLOW-007 · Concierge: tre strade

Stato: proposto

Nico Robin sceglie la strada più leggera che basta, invece di far passare ogni
richiesta dal grilling e da una card.

Accettazione:

- [ ] Un consiglio, una domanda o un "a che punto siamo" ricevono risposta
      diretta: niente grilling, niente card.
- [ ] Una richiesta di lavoro vaga passa dal `grilling` e da una conferma
      prima di diventare una card.
- [ ] Una card nasce solo quando l'utente ha deciso di procedere o lo chiede
      con una richiesta già chiara; la consegna segue FLOW-010 e va a Edward
      (bug o modifica chiari), a Shikamaru (idea da pensare) o a Bulma
      (interfaccia).
- [ ] Nico Robin non fa da intermediario con gli specialisti: se l'utente
      vuole discutere gli dice di scrivergli dalla WebUI e non riassume le
      sue risposte, salvo richiesta.

### FLOW-008 · Correzione rapida

Stato: proposto

Un bug o una modifica già chiari arrivano a una PR pronta senza specifica.

Accettazione:

- [ ] La issue nel tracker ha come riprodurre e i criteri di accettazione;
      la card per Edward segue FLOW-010.
- [ ] Edward lavora come al passo di implementazione di FLOW-001 (branch,
      test, CHANGELOG, `npm run check`, PR con il riferimento alla issue) e
      chiude la card con il link alla PR.
- [ ] Se manca o è sbagliata la specifica, Edward blocca la card con la
      domanda e la richiesta passa a FLOW-001.

### FLOW-009 · Discussione senza card

Stato: proposto

Un parere o una scelta si discutono con l'agente giusto e restano una
conversazione.

Accettazione:

- [ ] Con Shikamaru (o con l'agente scelto) la discussione non crea card,
      specifiche, issue né file nei repo.
- [ ] La risposta finale è dell'agente con cui si parla.
- [ ] Quando l'utente decide di procedere, l'agente propone il flusso
      (FLOW-001 o FLOW-008) e passa il lavoro con FLOW-010, con le decisioni
      prese e non la chat.

### FLOW-010 · Consegna fra agenti

Stato: proposto

Ogni card per un altro agente ha lo stesso modello: obiettivo, criteri di
accettazione, decisioni prese, repo e branch, ambiente, riferimenti. Lo fissa
la skill `handoff-brief`.

Accettazione:

- [ ] La skill `handoff-brief` descrive il modello e l'agente che crea una
      card la usa; la chat non si copia.
- [ ] Un progetto con `ci_required: true` in `projects/<nome>.yaml` ha card
      con completion contract di Hermes sul suo repo: non si chiudono se i
      check richiesti della PR non sono verdi. Senza il campo, niente
      contract.
- [ ] `scripts/validate.sh` accetta `ci_required` solo con `true` o `false`.

### FLOW-011 · Protocollo delle card e SOUL snelli

Stato: proposto

Il protocollo comune delle card sta in una skill e non copiato in ogni SOUL, e
i SOUL dicono per prime le regole operative.

Accettazione:

- [ ] La skill `kanban-card` descrive come fare una domanda da un worker
      (`kanban_block`), come rispondere a un blocco, cosa fare con una card
      fallita, i tentativi massimi, quando una card è finita e come tenere
      piccolo il contesto; ogni SOUL la richiama in una riga.
- [ ] Nessuna regola delle card è duplicata nei SOUL: cambia in un posto solo.
- [ ] Ogni SOUL ha, in quest'ordine, cosa fa l'agente, le regole e il
      personaggio, compresso; la prima riga resta `# Nome · Ruolo` (la legge
      `install.sh`).
- [ ] Il Concierge risponde breve: 1ron51uv lo legge dal telefono.

### FLOW-012 · Ogni agente toglie le card

Stato: proposto

Ogni agente può togliere una card dal board quando 1ron51uv lo chiede. Hermes
lo fa solo da CLI e dashboard; il plugin `dojo-kanban-archive` aggiunge il
tool `kanban_archive` al toolset `kanban`.

Accettazione:

- [ ] `kanban_archive` archivia la card (esce dal board, un worker che la
      lavora si ferma, la storia resta); con `delete: true` la cancella del
      tutto, commenti ed eventi compresi.
- [ ] Il plugin è acceso in tutti i profiles; come `kanban_list` il tool è
      nascosto ai worker.
- [ ] Un agente toglie una card solo su richiesta di 1ron51uv (skill
      `kanban-card`).
- [ ] La CI dell'immagine prova che il tool è registrato, archivia e
      cancella.

## Note

- Flussi personali e di lavoro con le rooms future.
