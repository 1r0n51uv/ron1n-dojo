---
name: tracker-jira
description: 'Issue di un progetto con tracker Jira Cloud: leggere, creare, commentare, cambiare stato e assegnatario con il server MCP atlassian.'
version: 0.1.0
author: ron1n-dojo
metadata:
  hermes:
    tags: [tracker, jira, issue]
---

# Tracker: Jira

Le operazioni sulle issue di un progetto il cui file `projects/<nome>.yaml`
(`/opt/dojo/projects/`) dice `tracker: jira`. Sono le stesse di
`tracker-github`, così i flussi non cambiano col tracker. `<chiave>` è il
campo `jira_key` del file (per esempio `DOJO`), gli stati sono i nomi del
workflow in `states`.

Si usano i tool del server MCP `atlassian` (`mcp_atlassian_*`), che parla con
il Jira Cloud di 1ron51uv con l'account e il token dell'agente. L'agente a cui
è affidata la issue è la label `agente:<nome>`.

## Operazioni

- **Leggere**: `mcp_atlassian_get_issue` con la chiave della issue; per
  cercare, `mcp_atlassian_search` con una JQL, per esempio
  `project = DOJO AND status = "Da fare" ORDER BY created`.
- **Creare**: `mcp_atlassian_create_issue` con progetto `<chiave>`, tipo,
  titolo `[PRE-NNN] Titolo` e descrizione con il link alla specifica e i
  criteri di accettazione copiati; label `mod:<modulo>` e `agente:<nome>`.
- **Commentare**: `mcp_atlassian_add_comment`.
- **Cambiare stato**: `mcp_atlassian_get_transitions` per vedere le
  transizioni possibili, poi `mcp_atlassian_transition_issue` con quella che
  porta allo stato voluto. Se non c'è una transizione verso quello stato,
  dillo a 1ron51uv: non cercare giri più lunghi.
- **Assegnare**: cambia la label con `mcp_atlassian_update_issue`
  (`agente:<vecchio>` fuori, `agente:<nuovo>` dentro).

## Branch e PR

La chiave della issue sta nel nome del branch (`DOJO-42-login`) e nel titolo
della PR, così l'app GitHub for Jira collega la PR alla issue. La PR su GitHub
non usa `Closes #N`: la issue passa a Fatto con il cambio di stato.

## Quando fermarsi

Se i tool `mcp_atlassian_*` non ci sono, o rispondono con un errore di
autenticazione o di permessi (manca `JIRA_URL`, `JIRA_USERNAME` o il token in
`dojo.env`), dillo a 1ron51uv e fermati: non passare a GitHub Issues né
cercare scorciatoie.
