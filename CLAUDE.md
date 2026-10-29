# CLAUDE.md

Contesto per le sessioni di Claude che lavorano su questo repo.

- Il dojo è il sistema di agenti Hermes di ron1n. Architettura in
  `docs/architettura.md`, requisiti in `docs/specs/` (ID `CELLA-NNN`,
  `FLUSSO-NNN`, stati come in ron1n).
- Documentazione e commenti in italiano.
- Una cella è `celle/<nome>/`: `compose.yaml`, `Dockerfile` se serve,
  `uscita/allowlist.conf` (domini raggiungibili) e `profili/<agente>/` con
  `config.yaml`, `SOUL.md`, `.env.example`. Il container è il confine di
  sicurezza: niente `docker.sock`, niente porte pubblicate, rete `interna`
  senza internet più il proxy `uscita`.
- I profili Hermes separano ruoli e memoria ma non isolano: due agenti che
  non devono vedersi stanno in celle diverse.
- Permessi minimi: toolset espliciti in `platform_toolsets`, approvazioni
  `manual` con `cron_mode: deny`, `approvals.deny` per merge e push forzati,
  token GitHub fine-grained per agente.
- I flussi sono skill in `flussi/<nome>/SKILL.md`, montate in sola lettura.
- Segreti solo in file `.env` non versionati; versiona un `.env.example`.
- Immagini sempre con tag esplicito (Hermes a versione fissata, mai
  `latest`).
- Ogni PR aggiunge in cima a `CHANGELOG.md` una riga con il link alla PR,
  sotto la sezione del giorno (`## AAAA-MM-GG`), come in ron1n.
- Prima di consegnare: `npm run check` pulito.
- Il flusso di sviluppo delle app che gli agenti seguono è quello di ron1n:
  `docs/flusso-sviluppo.md` nel repo `1r0n51uv/ron1n`.
