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

- [ ] Nessun `docker.sock` montato; l'unica porta pubblicata sull'host è la
      dashboard (ROOM-006), solo su `127.0.0.1`.
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

## Note

- Le rooms `personale` e `lavoro` arrivano nella fase 2 e 3
  ([architettura](../architecture.md#fasi)).
- Da verificare al primo avvio: chiave del modello letta dal `.env` del
  profile, identità git dei commit degli agenti, HOME dei tool per `gh`.
