---
name: new-project
description: 'Prepara un nuovo repo app ron1n dal template: specifica iniziale, label, stack in infra.'
version: 0.3.0
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

1. **Idea** (strategist): chiede nome, descrizione, stack, primo modulo e
   tracker: GitHub Issues oppure Jira (con la chiave del progetto Jira, che
   1ron51uv crea prima).
   Se l'idea arriva da una card di Nico Robin, la rivede prima con la skill
   `grilling-with-docs` e chiede solo quello che manca.
2. **Repo** (1ron51uv): crea il repo su GitHub e lo rende visibile al
   token degli agenti. Shikamaru non crea repo.
3. **Specifiche** (strategist): compila `docs/specs/README.md` e il primo
   `docs/specs/<modulo>.md` e apre la PR di sola specifica. Non implementa
   (FLOW-006): per il resto crea card per Edward (`builder`).
4. **Template** (builder, card di Shikamaru): copia `templates/app/` di
   ron1n nel repo e apre la PR.
5. **Branch protection** (1ron51uv): PR obbligatoria, check `ci`, solo
   squash.
6. **Hub** (builder, card di Shikamaru): PR su `1r0n51uv/ron1n` con la riga
   nella tabella del README e lo stack `infra/<app>/` dal template.
7. **Progetto nel dojo** (strategist): PR su `1r0n51uv/ron1n-dojo` con
   `projects/<nome>.yaml` (repo, tracker, `jira_key` se Jira, i cinque stati;
   formato in `projects/README.md`). Se il suo token non arriva a quel repo,
   passa il file a 1ron51uv. Gli agenti lo usano dopo il merge e
   l'aggiornamento dell'immagine; con un progetto Jira, `dojo.sh up` apre
   l'egress verso Atlassian.
8. Da qui ogni requisito segue il flusso `new-feature`.
