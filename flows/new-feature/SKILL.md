---
name: new-feature
description: "Da un'idea a una PR pronta per il merge: specifica, issue nel tracker del progetto, implementazione, revisione (flusso ron1n)."
version: 0.2.0
author: ron1n-dojo
metadata:
  hermes:
    tags: [ron1n, sviluppo, flusso]
prerequisites:
  commands: [git, gh]
---

# Nuova feature

Flusso di sviluppo di ron1n (`docs/flusso-sviluppo.md` nel repo
`1r0n51uv/ron1n`): specifica → issue → PR con CI → merge di 1ron51uv →
immagine GHCR → Watchtower. Gli agenti arrivano fino alla PR pronta; il merge
non è mai loro.

## Tracker del progetto

Le issue stanno nel tracker del progetto, GitHub Issues o Jira. Il file
`/opt/dojo/projects/<progetto>.yaml` dice repo, tracker e come si chiamano
gli stati (`spec`, `todo`, `doing`, `review`, `done`). Per ogni operazione
sulle issue usa la skill del suo tracker, `tracker-github` o `tracker-jira`:
leggere, creare, commentare, cambiare stato, assegnare. Questo flusso
parla solo di quelle operazioni, mai di `gh issue` o di Jira. Se il file del
progetto non c'è, o il tracker non risponde per permessi o credenziali,
dillo a 1ron51uv e fermati: non ripiegare sull'altro tracker.

## Avvio

1ron51uv scrive a Shikamaru, per esempio:
`/new-feature ron1nOS aggiungere il grafico del peso settimanale`.
Se manca il progetto o il modulo, Shikamaru li chiede. Se esiste già una
issue (con la sua chiave o il suo numero), la legge e riparte da lì.

## Passi

1. **Specifica** (strategist)
   - Se la richiesta arriva da una card di Nico Robin, la rivede con la
     skill `grilling-with-docs` (`skills/`): revisione del piano con le
     correzioni, poi grilling e specifica scritta durante.
   - Clona il repo in `/opt/data/work/<repo>`, legge `docs/specs/README.md`
     e il modulo interessato.
   - Scrive o aggiorna i requisiti (ID nuovo, mai riusato, stato `proposto`).
   - Se la issue della richiesta manca, la apre nel tracker, nello stato
     `spec`.
   - Branch `spec/<PRE-NNN>`, PR con label `spec` e `type:docs`, riga nel
     `CHANGELOG.md`. Manda a 1ron51uv il link e aspetta.
2. **Issue** (strategist, dopo il merge della specifica)
   - Una issue per requisito, nello stato `todo`: titolo `[PRE-NNN] Titolo`,
     link alla specifica, criteri di accettazione copiati, tipo `feature`,
     modulo `mod:<modulo>` e priorità, nel modo della skill del tracker.
   - Stato del requisito a `pianificato (<chiave o #N>)` (PR di sola
     specifica).
   - Una card Kanban per issue, con la chiave o il numero nel titolo: a
     `designer` se c'è un'interfaccia da disegnare, altrimenti a `builder`.
3. **Design** (designer, solo se serve)
   - Mockup e note UX nella issue e in `docs/design/`, poi passa la card a
     `builder`.
4. **Implementazione** (builder)
   - Porta la issue a `doing`. Branch `<chiave>-<titolo>`: `DOJO-42-login` con
     Jira, `42-login` con GitHub. Codice e test, `CHANGELOG.md`, stato del
     requisito a `fatto`, `npm run check` verde.
   - PR secondo il template del repo, con `Closes #N` (GitHub) o la chiave
     Jira nel titolo. Porta la issue a `review` e la card passa in
     revisione.
5. **Revisione** (reviewer)
   - Review su GitHub. Se servono modifiche, la issue torna a `doing` e la
     card a Edward.
   - Se è pronta, messaggio a 1ron51uv con il link alla PR.
6. **Merge** (1ron51uv). Con GitHub la issue si chiude alla merge; con Jira
   il reviewer la porta a `done`. La card si chiude quando i check richiesti
   sono verdi e la PR è mergiata.

## Quando fermarsi

- Specifica ambigua o in conflitto con un requisito esistente: blocca la
  card e chiedi.
- CI rossa per un motivo estraneo alla PR: commenta sulla PR e avvisa,
  non correggere altro.
- Servono permessi che il token non ha: dillo, non cercare scorciatoie.
