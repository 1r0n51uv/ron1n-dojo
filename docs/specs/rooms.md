# Stanze

Prefisso ID: `STANZA` · Label: `mod:rooms`

Una room è un container Hermes con i suoi profiles, il suo volume e la sua
rete. È il confine di sicurezza del dojo: quello che sta in una room non
vede le altre né il server.

## Requisiti

### ROOM-001 · Stanza confinata

Stato: proposto

Una room gira senza poter toccare il server né raggiungere internet se
non verso i domini previsti.

Accettazione:

- [ ] Nessun `docker.sock` montato; le sole porte pubblicate sull'host sono
      la dashboard (ROOM-006) e l'interfaccia web (ROOM-009), solo su
      `127.0.0.1`.
- [ ] Il container Hermes sta solo sulla rete `internal` (senza rotta verso
      internet); esce dal proxy `egress`.
- [ ] Una richiesta verso un dominio fuori da `egress/allowlist.conf`
      fallisce; verso `api.telegram.org` e `api.github.com` riesce.
- [ ] Limiti di memoria, CPU e processi; `no-new-privileges`.
- [ ] Immagine Hermes a versione fissata, mai `latest`.

### ROOM-002 · Un agente risponde solo a te

Stato: proposto

Ogni agente ha il suo bot Telegram e risponde solo all'utente autorizzato.

Accettazione:

- [ ] Un bot per profile; lo stesso token su due profiles è un errore.
- [ ] Un messaggio da un utente fuori da `TELEGRAM_ALLOWED_USERS` non
      riceve risposta.
- [ ] I comandi pericolosi chiedono conferma su Telegram; nei cron sono
      negati.

### ROOM-003 · Permessi minimi per agente

Stato: proposto

Ogni agente ha solo gli strumenti e le credenziali del suo ruolo.

Accettazione:

- [ ] I toolset di ogni profile sono elencati in `platform_toolsets`; un
      profile senza `file` non scrive file con i tool di Hermes.
- [ ] Token GitHub fine-grained dell'account degli agenti, uno per
      agente, limitati ai repo app: strategist e designer con contents, pull
      requests e issues in scrittura; builder con contents e pull requests in
      scrittura; reviewer con contents in lettura e pull requests in
      scrittura. Nessuno ha administration.
- [ ] `gh pr merge`, push forzati e push su `main` sono bloccati da
      `approvals.deny` in ogni profile della lab.
- [ ] I flows e le skill di `skills/` sono montati in sola lettura.

### ROOM-004 · Gestire le rooms con un comando

Stato: proposto

`scripts/dojo.sh` avvia, spegne, mostra e aggiorna le rooms.

Accettazione:

- [ ] `up`, `down`, `status` senza nomi agiscono su tutte le rooms, con
      nomi solo su quelle; un nome sconosciuto elenca le rooms valide.
- [ ] `sync <room>` crea i profiles mancanti, copia `config.yaml`,
      `SOUL.md` e il `.env` (comune più agente, permessi 600) e i plugin di
      `rooms/<room>/plugins/` nel volume e riavvia il gateway; memoria e
      sessioni restano.
- [ ] `secret <room> <agente> <CHIAVE>` imposta un valore (token del bot,
      `GH_TOKEN`) nel `.env` dell'agente con input nascosto, senza passarlo
      dalla riga di comando, e poi fa il `sync`.
- [ ] Senza `.env` della room si ferma e lo dice; un agente senza `.env`
      viene saltato, così si può attivare un agente alla volta.

### ROOM-005 · Installare il dojo con un comando

Stato: proposto

Su una macchina con Docker un solo comando porta da zero agli agenti
avviati, come il bootstrap di ron1n.

Accettazione:

- [ ] `curl -fsSL .../scripts/install.sh | bash` clona o aggiorna il repo
      (`DOJO_DIR`, `DOJO_BRANCH`) e funziona anche lanciato da un checkout.
- [ ] Chiede i valori dei `.env` che mancano: password e master key
      casuali, token e chiavi nascosti, invio = vuoto o default.
- [ ] Accende il gateway dei modelli, aspetta che sia pronto e crea la
      chiave virtuale di ogni room con il budget scelto.
- [ ] Per ogni agente chiede se attivarlo; quelli attivati partono con
      `dojo.sh sync`.
- [ ] Si può rilanciare: i `.env` esistenti non si toccano, gli agenti
      spenti si possono attivare dopo.
- [ ] Se mancano git, Docker o compose, o Docker non risponde, si ferma
      subito e dice cosa fare.

### ROOM-006 · Dashboard di Hermes

Stato: proposto

Ogni room offre la dashboard di Hermes (sessioni, configurazione, log),
raggiungibile solo dal PC su cui gira e protetta da password.

Accettazione:

- [ ] La dashboard è sulla porta 9119 di `127.0.0.1` (`DASHBOARD_PORT` la
      cambia), mai su altre interfacce.
- [ ] Servono utente e password: `dojo.sh sync` li crea casuali in
      `dashboard.env` (permessi 600) solo se mancano.
- [ ] Le credenziali non entrano nei `.env` dei profiles, che gli agenti
      leggono.
- [ ] Senza `dashboard.env` la dashboard resta spenta e il resto funziona.
- [ ] Il container Hermes resta su una rete senza internet: l'ingresso è un
      piccolo inoltro TCP (`dashboard`) senza privilegi e a file system
      in sola lettura.
- [ ] Da un'altra macchina si usa un tunnel SSH, non una porta aperta.

### ROOM-007 · Il lavoro autonomo si racconta su Telegram

Stato: proposto

Quando un agente lavora da solo su una card Kanban, 1ron51uv lo sa dal bot
di quell'agente, e la conversazione su quel lavoro continua lì.

Accettazione:

- [ ] Quando il dispatcher assegna una card, il bot dell'agente manda un
      messaggio breve in italiano con ID e titolo; alla fine il riassunto,
      al blocco il motivo, se il worker si ferma il codice di uscita
      (plugin `kanban-telegram`).
- [ ] Dopo la fine, un blocco o un crash è l'agente assegnato a riprendere
      il discorso nella sua chat, non chi ha creato la card (per esempio
      Nico Robin): plugin `handoff`.
- [ ] Un agente senza bot Telegram viene saltato; un errore dei plugin non
      ferma il dispatcher né la card.
- [ ] I plugin non danno nuovi tool agli agenti.

### ROOM-008 · Agenti da un client ACP sul PC

Stato: proposto

Dal PC su cui gira la room si parla con un agente da un client
[ACP](https://agentclientprotocol.com) come
[AionUi](https://github.com/iOfficeAI/AionUi), senza aprire porte e senza
dare all'agente più di quello che ha su Telegram.

Accettazione:

- [ ] Il client avvia, con `docker exec -i -u hermes` nel container
      Hermes, `dojo-acp <agente>`: nessuna porta nuova, il container resta
      com'è (ROOM-001).
- [ ] `dojo-acp` accetta solo gli agenti della room che hanno un profile,
      non il `default`.
- [ ] Ogni profile ha `platform_toolsets.acp` uguale a `cli`: niente
      toolset `hermes-acp` di default, che darebbe shell e web a tutti.
- [ ] La cartella del PC che il client manda come `cwd` diventa
      `/opt/data/work`; i server MCP proposti dal client si scartano.
- [ ] Le approvazioni restano `manual`: i comandi pericolosi chiedono
      conferma nel client e `approvals.deny` vale anche qui.
- [ ] Per un client che riconosce Hermes (AionUi) `scripts/hermes-acp.sh`
      fa da `hermes`: `acp` diventa `dojo-acp` con l'agente di
      `DOJO_AGENT`; passano solo `--version`, `acp --version` e
      `acp --check`, ogni altro comando o flag (per esempio `--yolo`) è
      rifiutato. Su Windows fa lo stesso `scripts/hermes-acp.cmd`.

### ROOM-009 · Interfaccia web per gli agenti

Stato: proposto

Dal PC si parla con gli agenti della room da
[hermes-webui](https://github.com/nesquena/hermes-webui), con gli stessi
permessi che hanno su Telegram.

Accettazione:

- [ ] L'interfaccia è su `127.0.0.1:8787` (`WEBUI_PORT` la cambia), dietro
      la password casuale che `dojo.sh sync` crea in `webui.env`; senza
      `webui.env` il servizio resta fermo.
- [ ] Il servizio `webui` usa l'immagine e il volume della room, sta solo
      sulle reti `internal` e `models` ed esce da `egress`; non scarica
      niente all'avvio.
- [ ] Le chat passano dall'API del gateway (`HERMES_WEBUI_CHAT_BACKEND=gateway`
      con la runs API): i tool girano nel container `hermes`, con
      `platform_toolsets.api_server` uguale a `cli` in ogni profile.
- [ ] Ogni agente risponde dal suo indirizzo `/p/<agente>` con la chiave
      dell'API, che `dojo.sh sync` scrive nel `.env` di ogni profile; l'API
      non è raggiungibile fuori dalla rete `internal`.
- [ ] Le approvazioni restano `manual` e `approvals.deny` vale anche qui;
      la modalità YOLO della WebUI non va accesa.

### ROOM-010 · Cartelle del PC nella room

Stato: proposto

Una cartella del PC, per esempio il repo del dojo, si apre come spazio
della WebUI e gli agenti la leggono, senza che la room possa cambiarla o
vederne i segreti.

Accettazione:

- [ ] `dojo.sh folder <room> <cartella...>` monta ogni cartella in sola
      lettura in `/opt/pc/<nome>`, nei servizi `hermes` e `webui`, con un
      override di compose (`folders.yaml`) non versionato; `off` lo toglie.
- [ ] I file `.env` e `*.env` presenti nella cartella (fuori da `.git` e
      `node_modules`) sono coperti con `/dev/null`: nella room risultano
      vuoti. Un `.env` creato dopo resta visibile finché non si rilancia il
      comando.
- [ ] Le cartelle stanno fuori dal volume `/opt/data`, così `sync` non le
      tocca; `git` le accetta (`safe.directory`) anche se sono dell'utente
      del PC.
- [ ] Non c'è una modalità in scrittura: una cartella scrivibile del PC
      lascerebbe agli agenti script, `compose.yaml` e hook di git che poi
      girano sul PC, fuori dal container. Per cambiare un repo gli agenti
      lavorano sulla loro copia in `/opt/data/work` e aprono una PR.

## Note

- Le rooms `personale` e `lavoro` arrivano nella fase 2 e 3
  ([architettura](../architecture.md#fasi)).
- La WebUI ha un suo terminale: gira nel container `webui`, con lo stesso
  confinamento della room, non sul PC.
- Da verificare al primo avvio: chiave del modello letta dal `.env` del
  profile, identità git dei commit degli agenti, HOME dei tool per `gh`.
