---
name: grilling-with-docs
description: 'Prende il piano di Nico Robin da una card Kanban, lo rivede contro la documentazione del repo con le sue correzioni, poi chiude i dubbi con un grilling e scrive le decisioni nella specifica mentre si prendono.'
version: 0.1.0
author: ron1n-dojo
license: MIT
metadata:
  hermes:
    tags: [ron1n, strategist, specifica, revisione, chiarimento]
prerequisites:
  commands: [git, gh]
---

# Grilling with docs

Adattata da `grill-with-docs` di Matt Pocock
([mattpocock/skills](https://github.com/mattpocock/skills), licenza MIT)
per lo Strategist del dojo. L'originale intervista l'utente e intanto
scrive glossario e ADR nel repo; qui il punto di partenza è il piano che
Nico Robin ha già raccolto con la skill `grilling`, e la documentazione
che si scrive è quella del flusso ron1n: la specifica del modulo.

Due passaggi, sempre in quest'ordine:

1. **Revisione**: leggi il piano e la documentazione, e scrivi la tua
   versione del piano con le correzioni.
2. **Grill e documentazione**: chiudi con 1ron51uv i dubbi rimasti e scrivi
   ogni decisione nella specifica appena è presa.

## Quando usarla

- Ogni volta che prendi una card di Nico Robin (`concierge`) con una
  richiesta da trasformare in specifica: nuova feature o nuovo progetto.
- Non serve per le card che non chiedono una specifica (per esempio una
  domanda di Edward su un requisito già scritto): lì rispondi e basta.

## Passaggio 1 · Revisione

Il piano di Nico Robin è un buon inizio, non un contratto: lei non vede il
codice né i documenti del repo. Il tuo compito è confrontarlo con quello
che c'è.

1. Leggi la card: riepilogo, criteri di "finito", domande aperte.
2. Clona il repo in `/opt/data/work/<repo>` (o aggiornalo) e leggi, in
   quest'ordine:
   - `README.md` e `CHANGELOG.md`, per sapere cos'è l'app e cosa è
     cambiato di recente;
   - `docs/specs/README.md` e il file del modulo interessato
     (`docs/specs/<modulo>.md`): requisiti esistenti, ID, stati;
   - `docs/flusso-sviluppo.md` del repo `1r0n51uv/ron1n`, se il piano
     tocca il modo di lavorare;
   - il codice, solo quanto serve a verificare un'affermazione del piano.
3. Per ogni punto del piano decidi se **regge**, va **corretto** o
   **manca**. Cerca soprattutto:
   - requisiti che esistono già o che il piano contraddice (un ID
     esistente, uno stato `fatto`, un requisito `rimosso`);
   - un modulo sbagliato o mancante: se nessun file di specifica va bene,
     serve un modulo nuovo, con prefisso e label;
   - criteri di "finito" non verificabili ("funziona bene", "è veloce");
   - un "come" travestito da "cosa": la specifica dice cosa fa l'app, non
     come;
   - dipendenze: richieste aperte sul board, issue aperte su GitHub,
     permessi che il tuo token non ha;
   - un piano troppo grande per una sola PR di specifica: proponi come
     dividerlo.
4. Manda a 1ron51uv la tua revisione, breve:

```
📜 Revisione del piano · <titolo della card>
✅ Regge: <i punti che restano come sono, in una riga>
✏️ Correzioni:
- <cosa cambi> · perché: <il documento o il fatto che lo dice>
➕ Manca:
- <cosa aggiungi>
❓ Da decidere: <quante domande restano per il passaggio 2>
```

Ogni correzione cita da dove viene (il file, l'ID del requisito, la issue):
è quello che la distingue da un'opinione. Se il piano regge tutto, dillo
in una riga e passa al passaggio 2.

Poi chiedi con `clarify` se la revisione va bene, scelte "Sì, procedi" e
"No, correggo qualcosa". Una correzione rifiutata da 1ron51uv si toglie, non
si ridiscute.

## Passaggio 2 · Grill e documentazione

### Grill

Le domande seguono le regole della skill `grilling`: albero delle
decisioni, frontiera, turni di al massimo tre domande, **una chiamata
`clarify` per turno con le opzioni in `choices`** (su Telegram diventano
bottoni), la tua risposta consigliata per prima, mai le opzioni scritte nel
testo della domanda.

In più, rispetto a Nico Robin, tu vedi il repo:

- I **fatti** li trovi nei documenti e nel codice, non li chiedi. Chiedi
  solo le **decisioni**.
- Se 1ron51uv usa una parola che la specifica usa in un altro senso,
  diglielo subito: "nella specifica 'pasto' è X, tu intendi Y?".
- Metti alla prova i confini con un caso concreto: "se il peso di lunedì
  manca, il grafico salta il giorno o lo interpola?". Un caso limite
  scoperto adesso è un bug in meno per Edward e un dubbio in meno per L.
- Se quello che dice 1ron51uv contraddice il codice, mostralo e chiedi
  quale dei due va cambiato.

Il grill finisce quando ogni requisito ha criteri verificabili e nessuna
decisione è data per scontata in silenzio, oppure quando 1ron51uv dice
"basta, vai": allora le domande rimaste vanno nella PR come domande aperte.

### Documentazione

La documentazione si scrive **durante** il grill, non alla fine: ogni
decisione presa va subito nel file, così niente si perde fra una risposta e
l'altra.

- Lavori sul branch `spec/<PRE-NNN>` nel clone, come nel flusso
  `new-feature`.
- Ogni requisito nuovo o cambiato va in `docs/specs/<modulo>.md`: ID nuovo,
  mai riusato, stato `proposto`, cosa fa l'app e non come, criteri di
  accettazione verificabili.
- Le parole del dominio e le scelte con un perché (difficili da cambiare
  dopo, sorprendenti senza contesto, frutto di un compromesso vero) vanno
  nel testo introduttivo del modulo, prima dei requisiti, come fanno le
  specifiche di ron1n. Le altre decisioni stanno nei requisiti e basta.
- Se serve un modulo nuovo, aggiungi il file e la riga nella tabella di
  `docs/specs/README.md`, e segnala la label `mod:<nome>` da creare.
- Non scrivi glossari, ADR o note sparse: la specifica è l'unico documento.

Quando il grill è chiuso apri la PR della specifica come dice
`new-feature` (label `spec` e `type:docs`, riga nel `CHANGELOG.md`). Nella
descrizione della PR metti:

- la revisione del passaggio 1, con le correzioni accettate;
- le decisioni del grill, una riga ciascuna;
- le domande aperte, se ce ne sono.

Manda a 1ron51uv il link alla PR e aspetta il merge. Sulla card scrivi
cosa hai fatto e il link, poi segui `new-feature` dal passo 2.
