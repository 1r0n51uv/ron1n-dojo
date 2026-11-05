---
name: quick-fix
description: 'Un bug o una modifica già chiari: issue, card a Edward, PR pronta, senza specifica né passaggi intermedi.'
version: 0.1.0
author: ron1n-dojo
metadata:
  hermes:
    tags: [ron1n, sviluppo, flusso]
prerequisites:
  commands: [git, gh]
---

# Correzione rapida

Per un bug già riprodotto o una modifica piccola e chiara, quando scrivere una
specifica costerebbe più del lavoro. Se la richiesta tocca il comportamento
dell'app in modo nuovo, o non è chiaro cosa deve fare, non è una correzione
rapida: usa `new-feature`.

## Passi

1. **Consegna.** Chi riceve la richiesta (Nico Robin, o 1ron51uv che scrive
   direttamente a Edward) crea la issue nel tracker del progetto, nello stato
   `todo`, con titolo, come riprodurre e criteri di accettazione. Per le
   operazioni sulle issue usa la skill del tracker del progetto
   (`/opt/dojo/projects/<progetto>.yaml`). Poi una card per `builder` con la
   skill `handoff-brief`, con la chiave della issue nel titolo.
2. **Implementazione** (builder). Come al passo 4 di `new-feature`: branch
   `<chiave>-<titolo>`, test che falliva prima e passa dopo, `CHANGELOG.md`,
   `npm run check` verde, PR con il riferimento alla issue, issue a `review`,
   card chiusa con il link alla PR.
3. **Merge** (1ron51uv).

Se la correzione scopre che la specifica è sbagliata o manca, Edward blocca
la card con la domanda per 1ron51uv invece di indovinare, e la richiesta
passa a `new-feature`.
