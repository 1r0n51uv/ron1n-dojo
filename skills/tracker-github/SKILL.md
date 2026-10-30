---
name: tracker-github
description: 'Issue di un progetto con tracker GitHub: leggere, creare, commentare, cambiare stato e assegnatario con gh.'
version: 0.1.0
author: ron1n-dojo
metadata:
  hermes:
    tags: [tracker, github, issue]
prerequisites:
  commands: [gh]
---

# Tracker: GitHub Issues

Le operazioni sulle issue di un progetto il cui file `projects/<nome>.yaml`
(`/opt/dojo/projects/`) dice `tracker: github`. Sono le stesse di
`tracker-jira`, così i flussi non cambiano col tracker. `<repo>` è il campo
`repo` del file, `<stato>` il nome dello stato in `states`.

Gli stati sono label della issue (di solito `stato:spec`, `stato:da-fare`,
`stato:in-corso`, `stato:review`, `stato:fatto`): una sola alla volta. L'agente
a cui è affidata la issue è la label `agente:<nome>` (per esempio
`agente:builder`). Se una label manca nel repo, creala:
`gh label create "<label>" --repo <repo> --force`.

## Operazioni

- **Leggere**: `gh issue view <N> --repo <repo> --comments`; per cercare,
  `gh issue list --repo <repo> --state open --label "<label>"`.
- **Creare**: titolo `[PRE-NNN] Titolo`, corpo con il link alla specifica e i
  criteri di accettazione copiati, label `type:*`, `mod:*` e `prio:*` come
  nel repo più lo stato `todo`:

  ```sh
  gh issue create --repo <repo> --title "[PRE-NNN] Titolo" \
    --body-file <file> --label "type:feature,mod:<modulo>,prio:media,<stato todo>"
  ```

- **Commentare**: `gh issue comment <N> --repo <repo> --body "..."`.
- **Cambiare stato**: togli la label dello stato attuale e metti la nuova,
  in un solo comando. Con `done` la issue si chiude da sola alla merge della
  PR con `Closes #N`; non chiuderla a mano.

  ```sh
  gh issue edit <N> --repo <repo> --remove-label "<stato vecchio>" --add-label "<stato nuovo>"
  ```

- **Assegnare**: stesso comando con la label dell'agente.

  ```sh
  gh issue edit <N> --repo <repo> --remove-label "agente:<vecchio>" --add-label "agente:<nuovo>"
  ```

## Branch e PR

Il branch si chiama `<N>-<titolo-breve>` (per esempio `42-login`) e la PR ha
`Closes #N` nel corpo.

## Quando fermarsi

Se `gh` risponde con un errore di permessi o di autenticazione, dillo a
1ron51uv e fermati: non passare a Jira né a un altro repo.
