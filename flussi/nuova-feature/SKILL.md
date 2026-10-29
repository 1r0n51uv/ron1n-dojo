---
name: nuova-feature
description: "Da un'idea a una PR pronta per il merge: specifica, issue, implementazione, revisione (flusso ron1n)."
version: 0.1.0
author: ron1n-dojo
metadata:
  hermes:
    tags: [ron1n, sviluppo, flusso]
prerequisites:
  commands: [git, gh]
---

# Nuova feature

Flusso di sviluppo di ron1n (`docs/flusso-sviluppo.md` nel repo
`1r0n51uv/ron1n`): specifica → issue con label → PR con CI → merge di
1ron51uv → immagine GHCR → Watchtower. Gli agenti arrivano fino alla PR
pronta; il merge non è mai loro.

## Avvio

1ron51uv scrive a Shikamaru, per esempio:
`/nuova-feature ron1nOS aggiungere il grafico del peso settimanale`.
Se manca il repo o il modulo, Shikamaru li chiede.

## Passi

1. **Specifica** (gunshi)
   - Clona il repo in `/opt/data/lavori/<repo>`, legge `docs/specs/README.md`
     e il modulo interessato.
   - Scrive o aggiorna i requisiti (ID nuovo, mai riusato, stato `proposto`).
   - Branch `spec/<PRE-NNN>`, PR con label `spec` e `type:docs`, riga nel
     `CHANGELOG.md`. Manda a 1ron51uv il link e aspetta.
2. **Issue** (gunshi, dopo il merge della specifica)
   - Una issue per requisito: titolo `[PRE-NNN] Titolo`, link alla
     specifica, criteri di accettazione copiati, label `type:feature`,
     `mod:<modulo>`, `prio:*`.
   - Stato del requisito a `pianificato (#N)` (PR di sola specifica).
   - Una card Kanban per issue, assegnata a `takumi`, con contratto di
     completamento `1r0n51uv/<repo>`.
3. **Implementazione** (takumi)
   - Branch `<PRE-NNN>-<slug>`, codice e test, `CHANGELOG.md`, stato a
     `fatto`, `npm run check` verde.
   - PR con `Closes #N` secondo il template del repo. La card passa in
     revisione.
4. **Revisione** (shinpan)
   - Review su GitHub. Se servono modifiche, la card torna a Edward.
   - Se è pronta, messaggio a 1ron51uv con il link alla PR.
5. **Merge** (1ron51uv). La card si chiude quando i check richiesti sono
   verdi e la PR è mergiata.

## Quando fermarsi

- Specifica ambigua o in conflitto con un requisito esistente: blocca la
  card e chiedi.
- CI rossa per un motivo estraneo alla PR: commenta sulla PR e avvisa,
  non correggere altro.
- Servono permessi che il token non ha: dillo, non cercare scorciatoie.
