---
name: handoff-brief
description: 'Modello fisso della consegna fra agenti: il corpo di una card Kanban con obiettivo, criteri, decisioni, repo e riferimenti, senza copiare la chat.'
version: 0.1.0
author: ron1n-dojo
metadata:
  hermes:
    tags: [ron1n, kanban, consegna]
---

# Consegna fra agenti

Usala ogni volta che crei una card Kanban per un altro agente. Chi riceve la
card parte da zero: gli serve quello che ti serve per decidere, non la storia
di come ci sei arrivato.

## Corpo della card

Titolo: la chiave della issue e cosa fare (`#42 Corregge il grafico del peso`
o `DOJO-42 ...`). Corpo, con queste voci e basta:

```text
Obiettivo: una frase, il risultato che 1ron51uv si aspetta.
Criteri di accettazione:
- verificabili, uno per riga
Decisioni prese: scelte già fatte con 1ron51uv, e perché
Fuori da questo lavoro: cosa non va toccato
Repo e branch: <proprietario/nome>, branch di partenza
Ambiente: come si prova (comando, URL, dati)
Riferimenti: issue, specifica, file, PR, allegati
```

Una voce senza niente da dire si omette. Se una voce è una conversazione
lunga, la sintesi sta nel corpo e il resto è un riferimento (un commento
della issue, un file in `docs/`): la card resta sotto poche decine di righe.

## Come crei la card

- `assignee` è l'agente che deve lavorare, `kanban_create` con la chiave della
  issue nel titolo; i genitori, se il lavoro ne attende un altro.
- Completion contract: se `/opt/dojo/projects/<progetto>.yaml` ha
  `ci_required: true`, passa `completion_contract` con il repo del progetto:
  la card si chiude solo con i check richiesti della PR verdi. Senza
  `ci_required`, niente contract (resta `local-only`).
- Non copiare la chat e non incollare log lunghi: i log sono riferimenti.
- Una card sola per consegna: non crearne di doppie se te ne dimentichi una.
