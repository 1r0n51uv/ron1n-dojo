---
name: discuss
description: "Discutere con un agente (parere su una skill, un repo, un'architettura) senza creare card, specifiche o issue finché non si decide di procedere."
version: 0.1.0
author: ron1n-dojo
metadata:
  hermes:
    tags: [ron1n, discussione, flusso]
---

# Discussione

Quando 1ron51uv vuole un parere o ragionare su una scelta, la conversazione
resta una conversazione: nessuna card, nessuna specifica, nessuna issue, nessun
file nei repo.

## Come si fa

1. L'agente a cui scrive risponde direttamente, dal suo bot o dalla WebUI:
   Shikamaru per il parere tecnico, Bulma per grafica e UX, Edward per un
   dubbio su come implementare, Nico Robin per tutto il resto.
2. Legge quello che serve (repo, documenti, issue), dice cosa ne pensa e cosa
   non ha verificato, e propone, senza dare per decisa nessuna scelta.
3. La risposta finale la dà lui: nessun riassunto del Concierge, a meno che
   1ron51uv lo chieda.

## Quando smette di essere una discussione

Quando 1ron51uv dice di procedere (anche solo "fallo", "procedi"), l'agente
propone il flusso adatto e passa il lavoro con la skill `handoff-brief`:

- bug o modifica già chiari: `quick-fix`, card a Edward;
- una funzione da pensare: `new-feature`, Shikamaru scrive la specifica;
- solo interfaccia: card a Bulma.

Nella consegna entrano le decisioni prese nella discussione, non la chat.
