# Progetti

Un file per progetto su cui lavorano gli agenti (TRACKER-001). I flussi
(`flows/`) lo leggono da `/opt/dojo/projects/<nome>.yaml` per sapere in
quale repo lavorare e con quale tracker; le skill `tracker-github` e
`tracker-jira` (`skills/`) fanno il resto. La cartella entra nell'immagine
della lab: un progetto nuovo si aggiunge con una PR che aggiunge il suo file,
senza toccare altro.

```yaml
repo: 1r0n51uv/ron1n # repo GitHub dove vanno branch e PR
tracker: github # github oppure jira
jira_key: DOJO # solo con tracker: jira, la chiave del progetto Jira
ci_required: false # true se la card si chiude solo con i check della PR verdi
states: # come si chiamano gli stati nel tracker
  spec: 'stato:spec'
  todo: 'stato:da-fare'
  doing: 'stato:in-corso'
  review: 'stato:review'
  done: 'stato:fatto'
```

- Con `tracker: github` gli stati sono label della issue; con `tracker: jira`
  sono i nomi degli stati del workflow del progetto (per esempio `Spec`,
  `Da fare`, `In corso`, `Review`, `Fatto`).
- Tutti e cinque gli stati sono obbligatori, in ordine di avanzamento:
  `spec` (specifica da approvare), `todo`, `doing`, `review` (PR aperta),
  `done` (PR unita).
- `ci_required` è facoltativo (default `false`). Con `true` le card di
  consegna a Edward hanno un completion contract di Hermes sul repo: la card
  non si chiude se i check richiesti della PR non sono verdi. Serve che il
  token `gh` di Edward possa leggere check e regole di protezione del repo
  (permessi Checks e Administration in lettura): senza, la card resta
  bloccata. Va acceso quando il token li ha.
- Il nome del file è il nome del progetto (`ron1n.yaml`) e non cambia.
- `scripts/validate.sh` controlla ogni file; `dojo.sh up` apre l'egress verso
  Atlassian solo se almeno un progetto usa Jira.
