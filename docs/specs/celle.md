# Celle

Prefisso ID: `CELLA` · Label: `mod:celle`

Una cella è un container Hermes con i suoi profili, il suo volume e la sua
rete. È il confine di sicurezza del dojo: quello che sta in una cella non
vede le altre né il server.

## Requisiti

### CELLA-001 · Cella confinata

Stato: proposto

Una cella gira senza poter toccare il server né raggiungere internet se
non verso i domini previsti.

Accettazione:

- [ ] Nessun `docker.sock` montato, nessuna porta pubblicata sull'host.
- [ ] Il container Hermes sta solo sulla rete `interna` (senza rotta verso
      internet); esce dal proxy `uscita`.
- [ ] Una richiesta verso un dominio fuori da `uscita/allowlist.conf`
      fallisce; verso `api.telegram.org` e `api.github.com` riesce.
- [ ] Limiti di memoria, CPU e processi; `no-new-privileges`.
- [ ] Immagine Hermes a versione fissata, mai `latest`.

### CELLA-002 · Un agente risponde solo a te

Stato: proposto

Ogni agente ha il suo bot Telegram e risponde solo all'utente autorizzato.

Accettazione:

- [ ] Un bot per profilo; lo stesso token su due profili è un errore.
- [ ] Un messaggio da un utente fuori da `TELEGRAM_ALLOWED_USERS` non
      riceve risposta.
- [ ] I comandi pericolosi chiedono conferma su Telegram; nei cron sono
      negati.

### CELLA-003 · Permessi minimi per agente

Stato: proposto

Ogni agente ha solo gli strumenti e le credenziali del suo ruolo.

Accettazione:

- [ ] I toolset di ogni profilo sono elencati in `platform_toolsets`; un
      profilo senza `file` non scrive file con i tool di Hermes.
- [ ] Token GitHub fine-grained dell'account degli agenti, uno per
      agente, limitati ai repo app: architetto con contents, pull requests
      e issues in scrittura; fabbro con contents e pull requests in
      scrittura; revisore con contents in lettura e pull requests in
      scrittura. Nessuno ha administration.
- [ ] `gh pr merge`, push forzati e push su `main` sono bloccati da
      `approvals.deny` in ogni profilo dell'officina.
- [ ] I flussi sono montati in sola lettura.

### CELLA-004 · Gestire le celle con un comando

Stato: proposto

`scripts/dojo.sh` avvia, spegne, mostra e aggiorna le celle.

Accettazione:

- [ ] `up`, `down`, `status` senza nomi agiscono su tutte le celle, con
      nomi solo su quelle; un nome sconosciuto elenca le celle valide.
- [ ] `sync <cella>` crea i profili mancanti, copia `config.yaml`,
      `SOUL.md` e il `.env` (comune più agente, permessi 600) nel volume e
      riavvia il gateway; memoria e sessioni restano.
- [ ] Senza `.env` della cella o di un agente si ferma e dice quale manca.

## Note

- Le celle `personale` e `lavoro` arrivano nella fase 2 e 3
  ([architettura](../architettura.md#fasi)).
- Da verificare al primo avvio: chiave del modello letta dal `.env` del
  profilo, identità git dei commit degli agenti, HOME dei tool per `gh`.
