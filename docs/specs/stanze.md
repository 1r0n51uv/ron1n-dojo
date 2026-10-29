# Stanze

Prefisso ID: `STANZA` · Label: `mod:stanze`

Una stanza è un container Hermes con i suoi profili, il suo volume e la sua
rete. È il confine di sicurezza del dojo: quello che sta in una stanza non
vede le altre né il server.

## Requisiti

### STANZA-001 · Stanza confinata

Stato: proposto

Una stanza gira senza poter toccare il server né raggiungere internet se
non verso i domini previsti.

Accettazione:

- [ ] Nessun `docker.sock` montato, nessuna porta pubblicata sull'host.
- [ ] Il container Hermes sta solo sulla rete `interna` (senza rotta verso
      internet); esce dal proxy `uscita`.
- [ ] Una richiesta verso un dominio fuori da `uscita/allowlist.conf`
      fallisce; verso `api.telegram.org` e `api.github.com` riesce.
- [ ] Limiti di memoria, CPU e processi; `no-new-privileges`.
- [ ] Immagine Hermes a versione fissata, mai `latest`.

### STANZA-002 · Un agente risponde solo a te

Stato: proposto

Ogni agente ha il suo bot Telegram e risponde solo all'utente autorizzato.

Accettazione:

- [ ] Un bot per profilo; lo stesso token su due profili è un errore.
- [ ] Un messaggio da un utente fuori da `TELEGRAM_ALLOWED_USERS` non
      riceve risposta.
- [ ] I comandi pericolosi chiedono conferma su Telegram; nei cron sono
      negati.

### STANZA-003 · Permessi minimi per agente

Stato: proposto

Ogni agente ha solo gli strumenti e le credenziali del suo ruolo.

Accettazione:

- [ ] I toolset di ogni profilo sono elencati in `platform_toolsets`; un
      profilo senza `file` non scrive file con i tool di Hermes.
- [ ] Token GitHub fine-grained dell'account degli agenti, uno per
      agente, limitati ai repo app: gunshi con contents, pull requests
      e issues in scrittura; takumi con contents e pull requests in
      scrittura; shinpan con contents in lettura e pull requests in
      scrittura. Nessuno ha administration.
- [ ] `gh pr merge`, push forzati e push su `main` sono bloccati da
      `approvals.deny` in ogni profilo della kajiba.
- [ ] I flussi sono montati in sola lettura.

### STANZA-004 · Gestire le stanze con un comando

Stato: proposto

`scripts/dojo.sh` avvia, spegne, mostra e aggiorna le stanze.

Accettazione:

- [ ] `up`, `down`, `status` senza nomi agiscono su tutte le stanze, con
      nomi solo su quelle; un nome sconosciuto elenca le stanze valide.
- [ ] `sync <stanza>` crea i profili mancanti, copia `config.yaml`,
      `SOUL.md` e il `.env` (comune più agente, permessi 600) nel volume e
      riavvia il gateway; memoria e sessioni restano.
- [ ] Senza `.env` della stanza si ferma e lo dice; un agente senza `.env`
      viene saltato, così si può attivare un agente alla volta.

### STANZA-005 · Installare il dojo con un comando

Stato: proposto

Su una macchina con Docker un solo comando porta da zero agli agenti
avviati, come il bootstrap di ron1n.

Accettazione:

- [ ] `curl -fsSL .../scripts/install.sh | bash` clona o aggiorna il repo
      (`DOJO_DIR`, `DOJO_RAMO`) e funziona anche lanciato da un checkout.
- [ ] Chiede i valori dei `.env` che mancano: password e master key
      casuali, token e chiavi nascosti, invio = vuoto o default.
- [ ] Accende il gateway dei modelli, aspetta che sia pronto e crea la
      chiave virtuale di ogni stanza con il budget scelto.
- [ ] Per ogni agente chiede se attivarlo; quelli attivati partono con
      `dojo.sh sync`.
- [ ] Si può rilanciare: i `.env` esistenti non si toccano, gli agenti
      spenti si possono attivare dopo.
- [ ] Se mancano git, Docker o compose, o Docker non risponde, si ferma
      subito e dice cosa fare.

## Note

- Le stanze `personale` e `lavoro` arrivano nella fase 2 e 3
  ([architettura](../architettura.md#fasi)).
- Da verificare al primo avvio: chiave del modello letta dal `.env` del
  profilo, identità git dei commit degli agenti, HOME dei tool per `gh`.
