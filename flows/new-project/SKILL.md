---
name: new-project
description: 'Prepara un nuovo repo app ron1n dal template: specifica iniziale, label, stack in infra.'
version: 0.1.0
author: ron1n-dojo
metadata:
  hermes:
    tags: [ron1n, progetto, flusso]
prerequisites:
  commands: [git, gh]
---

# Nuovo progetto

Segue la sezione "Nuovo repo app" di `docs/flusso-sviluppo.md` nel repo
`1r0n51uv/ron1n`. Bozza: i passi che richiedono permessi da
amministratore li fa 1ron51uv.

## Passi

1. **Idea** (strategist): chiede nome, descrizione, stack e primo modulo.
   Se l'idea arriva da una card di Nico Robin, la rivede prima con la skill
   `grilling-with-docs` e chiede solo quello che manca.
2. **Repo** (1ron51uv): crea il repo su GitHub e lo rende visibile al
   token degli agenti. Shikamaru non crea repo.
3. **Template** (strategist): copia `templates/app/` di ron1n nel repo,
   compila `docs/specs/README.md` e il primo `docs/specs/<modulo>.md`, apre
   la PR.
4. **Branch protection** (1ron51uv): PR obbligatoria, check `ci`, solo
   squash.
5. **Hub** (strategist): PR su `1r0n51uv/ron1n` con la riga nella tabella
   del README e lo stack `infra/<app>/` dal template.
6. Da qui ogni requisito segue il flusso `new-feature`.
