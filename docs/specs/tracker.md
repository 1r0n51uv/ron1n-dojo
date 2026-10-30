# Tracker

Prefisso ID: `TRACKER` · Label: `mod:tracker`

Il tracker del progetto è dove l'utente, da cliente, chiede e segue il
lavoro: GitHub Issues o Jira, scelto per progetto. Gli agenti lo usano
attraverso due skill con le stesse operazioni, così i flussi non cambiano
col tracker.

## Requisiti

### TRACKER-001 · Un file per progetto

Stato: proposto

Ogni progetto su cui lavorano gli agenti è descritto da un file nel repo
dojo.

Accettazione:

- [ ] `projects/<nome>.yaml` dice repo GitHub, tracker (`github` o `jira`),
      chiave del progetto Jira se serve, e come si chiamano gli stati
      (Spec, Da fare, In corso, Review, Fatto).
- [ ] `scripts/validate.sh` controlla ogni file: campi obbligatori, tracker
      valido, chiave Jira presente se il tracker è `jira`.
- [ ] Un progetto si aggiunge con un file, senza toccare altro.

### TRACKER-002 · Stesse operazioni su GitHub e Jira

Stato: proposto

Le skill `skills/tracker-github` e `skills/tracker-jira` offrono le stesse
operazioni: leggere, creare, commentare una issue, cambiarne stato e
assegnatario.

Accettazione:

- [ ] `tracker-github` usa `gh issue` con il token dell'agente; gli stati
      sono label (`stato:review` ...), l'agente una label `agente:<nome>`.
- [ ] `tracker-jira` usa il server MCP `mcp-atlassian`, nell'immagine a
      versione fissata, con email e token API di Jira Cloud in `dojo.env`
      per gli agenti che ne hanno bisogno; l'agente è un campo o una label
      `agente:<nome>`.
- [ ] I flussi scelgono la skill dal `tracker` del progetto.
- [ ] Con un tracker senza credenziali l'agente lo dice e si ferma, non
      ripiega sull'altro.

### TRACKER-003 · Jira personale nella lab

Stato: proposto

Il Jira Cloud personale dell'utente è collegato alla room `lab`. Un Jira di
lavoro non entra nella lab: arriverà con la room `work`.

Accettazione:

- [ ] L'egress apre `*.atlassian.net` e `api.atlassian.com` solo se almeno
      un progetto usa Jira.
- [ ] Il token Jira ha solo i progetti del dojo; sta in `dojo.env`.
- [ ] Branch e PR portano la chiave della issue (`DOJO-42-login`), così
      l'app GitHub for Jira li mostra nella issue.

## Note

- Il token Jira, come quelli GitHub, finisce nel `.env` del profile: gli agenti
  con `terminal` della stessa room possono leggerlo.
