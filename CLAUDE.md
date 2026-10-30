# CLAUDE.md

Contesto per le sessioni di Claude che lavorano su questo repo.

- Il dojo è il sistema di agenti Hermes di ron1n. Architettura in
  `docs/architecture.md`, requisiti in `docs/specs/` (ID `ROOM-NNN`,
  `FLOW-NNN`, stati come in ron1n).
- Documentazione e commenti in italiano.
- Una room è `rooms/<nome>/`: `compose.yaml`, `Dockerfile` se serve,
  `egress/allowlist.conf` (domini raggiungibili) e `profiles/<agente>/` con
  `config.yaml` e `SOUL.md`. Il container è il confine di
  sicurezza: niente `docker.sock`, niente porte pubblicate, rete `internal`
  senza internet più il proxy `egress`.
- I profiles Hermes separano ruoli e memoria ma non isolano: due agenti che
  non devono vedersi stanno in rooms diverse.
- Permessi minimi: toolset espliciti in `platform_toolsets`, approvazioni
  `manual` con `cron_mode: deny`, `approvals.deny` per merge e push forzati,
  token GitHub fine-grained per agente.
- I flows sono skill in `flows/<nome>/SKILL.md`, montate in sola lettura.
- Tutta la configurazione dell'utente sta in un solo file, `dojo.env` (non
  versionato, modello in `dojo.env.example`), applicato da `dojo.sh up`.
  Comandi di `dojo.sh` pochi: up, down, status, claude. Un valore nuovo va
  in `dojo.env.example`, non in un comando o in un altro file.
- Immagini sempre con tag esplicito (Hermes a versione fissata, mai
  `latest`).
- Ogni PR aggiunge in cima a `CHANGELOG.md` una riga con il link alla PR,
  sotto la sezione del giorno (`## AAAA-MM-GG`), come in ron1n.
- Prima di consegnare: `npm run check` pulito.
- Il flusso di sviluppo delle app che gli agenti seguono è quello di ron1n:
  `docs/flusso-sviluppo.md` nel repo `1r0n51uv/ron1n`.
