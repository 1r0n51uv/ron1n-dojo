# Stanze

Prefisso ID: `ROOM` · Label: `mod:rooms`

Una room è un container Hermes con i suoi profiles, il suo volume e la sua
rete. È il confine di sicurezza del dojo: quello che sta in una room non
vede le altre né il server. Gira sul mini PC Linux; il PC Windows con WSL2
serve solo per le prove.

## Requisiti

### ROOM-001 · Stanza confinata

Stato: proposto

Una room gira senza poter toccare il server né raggiungere internet se
non verso i domini previsti.

Accettazione:

- [ ] Nessun `docker.sock` montato; le sole porte pubblicate sull'host sono
      la dashboard (ROOM-006) e la WebUI (ROOM-009), solo su `127.0.0.1`.
- [ ] Il container Hermes sta solo sulla rete `internal` (senza rotta verso
      internet); esce dal proxy `egress`.
- [ ] Una richiesta verso un dominio fuori da `egress/allowlist.conf`
      fallisce; verso `api.telegram.org`, `api.github.com` e
      `api.anthropic.com` riesce; `*.atlassian.net` solo se un progetto usa
      Jira.
- [ ] Limiti di memoria, CPU e processi; `no-new-privileges`.
- [ ] Hermes, Claude Code, plugin e WebUI a versione fissata nell'immagine.

### ROOM-002 · Un agente risponde solo a te

Stato: proposto

Ogni agente ha il suo bot Telegram con la chat completa e risponde solo
all'utente autorizzato, su Telegram come sulla WebUI.

Accettazione:

- [ ] Un bot per profile; lo stesso token su due profiles è un errore.
- [ ] Un messaggio da un utente fuori da `TELEGRAM_ALLOWED_USERS` non
      riceve risposta.
- [ ] Toolset, memoria e approvazioni di un agente sono gli stessi su
      Telegram e sulla WebUI.

### ROOM-003 · Permessi minimi per agente

Stato: proposto

Ogni agente ha solo gli strumenti e le credenziali del suo ruolo.

Accettazione:

- [ ] I toolset di ogni profile sono elencati in `platform_toolsets` per
      `telegram`, `cli` e `api_server`, uguali fra loro; nessun toolset
      `acp`.
- [ ] Token GitHub fine-grained del tuo account, uno per agente, limitati ai
      repo dei progetti: strategist e designer con contents, pull requests e
      issues in scrittura; builder con contents, pull requests e issues in
      scrittura (sposta la issue in Review); reviewer con contents in lettura,
      pull requests e issues in scrittura (la porta a Fatto); concierge
      nessuno. Nessuno ha administration.
- [ ] I commit degli agenti hanno come autore il nome dell'agente (per
      esempio `Edward Elric (dojo)`).
- [ ] `gh pr merge`, push forzati, push su `main` e cancellazioni di repo
      sono bloccati da `approvals.deny` in ogni profile, anche con
      approvazione.
- [ ] Passano senza conferma solo i comandi sicuri: `git` senza push
      forzato, test e build (`npm`, `pytest`, `make`), `gh` in lettura,
      lettura di file. Il resto chiede conferma su WebUI o Telegram;
      `cron_mode` e `unattended_mode` sono `deny`.
- [ ] Flows e skill sono nell'immagine, fuori dalla portata degli agenti.

### ROOM-004 · Un file di configurazione, pochi comandi

Stato: proposto

Tutta la configurazione del dojo sta in un solo file, `dojo.env` nella
radice del repo; `scripts/dojo.sh` ha solo i comandi che servono.

Accettazione:

- [ ] `dojo.env` (modello versionato in `dojo.env.example`, con un commento
      per valore) contiene agenti accesi (`DOJO_AGENTS`), utente Telegram,
      cartella di lavoro, porte e, con il prefisso dell'agente, bot e token
      di ognuno (`BUILDER_GH_TOKEN`). Non è versionato e `dojo.sh` lo porta
      a permessi 600.
- [ ] `dojo.sh` legge il file senza eseguirlo.
- [ ] `up` applica il file: avvia o aggiorna la room e scrive il `.env` di
      ogni profile (valori comuni più quelli dell'agente senza prefisso),
      poi riavvia il gateway. Si rilancia dopo ogni modifica.
- [ ] Un agente fuori da `DOJO_AGENTS` resta senza bot né token.
- [ ] `down` spegne la room, i dati restano.
- [ ] `status` mostra i container e controlla valori mancanti, login
      Claude, egress, WebUI e cartella di lavoro; per ogni problema dice
      cosa fare.
- [ ] `claude` fa il login dell'abbonamento Claude nel container
      (MODELS-006): è l'unica cosa che non può stare nel file.
- [ ] Il modello di ogni agente non sta nel file: si sceglie da Hermes
      (MODELS-007).

### ROOM-005 · Installare il dojo con un comando

Stato: proposto

Sul mini PC con Docker un solo comando porta da zero agli agenti avviati,
come il bootstrap di ron1n.

Accettazione:

- [ ] `curl -fsSL .../scripts/install.sh | bash` clona o aggiorna il repo
      (`DOJO_DIR`, `DOJO_BRANCH`) e funziona anche lanciato da un checkout.
- [ ] Se manca `dojo.env` lo scrive da `dojo.env.example` con le risposte:
      utente Telegram, cartella di lavoro e, per ogni agente, se accenderlo
      e i suoi token, con input nascosto. Password casuali per dashboard e
      WebUI.
- [ ] Crea `~/dojo/lab`, scarica l'immagine da GHCR, avvia la room e fa il
      login Claude.
- [ ] Se manca `dojo.env` e trova un backup di `cleanup.sh`
      (`configurazione.tar.gz` nella cartella da cui lanci, in una
      `dojo-backup-*` lì dentro o nella home), chiede se importare
      `dojo.env` e le password di WebUI e dashboard, e in quel caso non rifà
      le domande.
- [ ] Si può rilanciare: un `dojo.env` esistente non si tocca; da lì in poi
      si modifica il file e si lancia `dojo.sh up`.
- [ ] Se mancano git, Docker o compose, o Docker non risponde, si ferma
      subito e dice cosa fare.
- [ ] Alla fine lancia `dojo.sh status`.

### ROOM-006 · Dashboard di Hermes

Stato: proposto

Ogni room offre la dashboard di Hermes (sessioni, configurazione, log),
raggiungibile solo dal mini PC e protetta da password.

Accettazione:

- [ ] La dashboard è sulla porta 9119 di `127.0.0.1` (`DASHBOARD_PORT` la
      cambia); solo `DASHBOARD_BIND=0.0.0.0` in `dojo.env` la apre alla rete
      locale, e `dojo.sh up` avverte che è aperta.
- [ ] Servono utente e password, casuali in `dashboard.env` (permessi 600),
      create solo se mancano.
- [ ] Le credenziali non entrano nei `.env` dei profiles, che gli agenti
      leggono.
- [ ] Il container Hermes resta su una rete senza internet: l'ingresso è un
      piccolo inoltro TCP senza privilegi e a file system in sola lettura.
- [ ] Da un'altra macchina si usa un tunnel SSH, non una porta aperta.

### ROOM-007 · Il lavoro autonomo si racconta su Telegram

Stato: rimosso

Sostituito dalle notifiche di serie del Kanban di Hermes (FLOW-004). I
plugin `handoff` e `kanban-telegram` escono; se dopo la prova sul mini PC
non bastano, un requisito nuovo dice cosa aggiungere.

### ROOM-008 · Agenti da un client ACP sul PC

Stato: rimosso

AionUi e i client ACP non fanno più parte del dojo: i canali sono la WebUI e
Telegram.

### ROOM-009 · Interfaccia web per gli agenti

Stato: proposto

La WebUI ([hermes-webui](https://github.com/nesquena/hermes-webui)) è il
canale principale: da casa e da fuori, con gli stessi permessi che gli
agenti hanno su Telegram.

Accettazione:

- [ ] In casa è su `127.0.0.1:8787` (`WEBUI_PORT` la cambia); fuori casa su
      `https://dojo.ron1n.space` via Cloudflare Tunnel e Caddy di ron1n,
      dietro Cloudflare Access. Nessuna porta aperta verso internet.
- [ ] `WEBUI_BIND=0.0.0.0` in `dojo.env` apre la WebUI alla rete
      locale, per il telefono in casa; un valore che non è un indirizzo IPv4
      è un errore e `dojo.sh up` avverte che è aperta. Sul PC Windows servono
      anche la rete WSL2 `mirrored` e una regola del firewall (README).
- [ ] Oltre ad Access serve la password casuale di `webui.env`; senza
      `webui.env` il servizio resta fermo.
- [ ] Il servizio `webui` sta solo sulla rete `internal`; verso Caddy passa
      un inoltro TCP (`webui-proxy`) sulle reti `internal` e `proxy`.
- [ ] Le chat passano dall'API del gateway (runs API): i tool girano nel
      container `hermes` con `platform_toolsets.api_server` del profile.
- [ ] La modalità YOLO non va accesa. Il terminale della WebUI resta:
      hermes-webui non ha un interruttore per spegnerlo; gira nel container
      `webui`, confinato come la room, dietro password e Cloudflare Access.
- [ ] Ogni agente risponde dal suo indirizzo `/p/<agente>`; l'API del
      gateway non è raggiungibile fuori dalla rete `internal`.

### ROOM-010 · Immagine dalla CI e aggiornamenti automatici

Stato: proposto

Sul mini PC non si costruisce niente: l'immagine della room arriva da GHCR
e si aggiorna da sola, come le app di ron1n.

Accettazione:

- [ ] Un workflow costruisce `ghcr.io/1r0n51uv/dojo-lab` a ogni push su
      `main` e pubblica i tag `main` e `sha-<commit>`, solo `linux/amd64`.
- [ ] Le PR costruiscono l'immagine senza pubblicarla.
- [ ] I servizi della room hanno l'etichetta
      `com.centurylinklabs.watchtower.enable: "true"`: Watchtower di ron1n li
      aggiorna quando `main` cambia.
- [ ] Rollback: `image: ...:sha-<commit>` nel compose, poi `dojo.sh up`.
- [ ] Hermes cambia versione solo con una PR che passa dalla CI.

### ROOM-011 · Cartella di lavoro sul mini PC

Stato: proposto

Gli agenti lavorano in una cartella del mini PC che apri anche da fuori,
senza poter uscire da lì.

Accettazione:

- [ ] `~/dojo/<room>` (`DOJO_ROOMS_DIR` cambia `~/dojo`) è montata in `/opt/data/work`,
      la `cwd` del terminale di ogni agente.
- [ ] `dojo.sh up` rinomina `~/dojo/work` (la cartella di prima) in
      `~/dojo/lab` se questa non esiste, senza perdere dati. Il volume di
      Hermes si chiama `dojo-<room>_data`.
- [ ] Il container gira con UID e GID dell'utente del mini PC: i file
      creati dagli agenti sono suoi, senza `sudo`.
- [ ] Ogni agente lavora in `/opt/data/work/<agente>/` per convenzione (non
      è un blocco).
- [ ] Il nome di una room e quello della sua cartella coincidono:
      `~/dojo/<room>`, cioè `lab` oggi e `home` e `work` per le rooms future.
- [ ] Nessun'altra cartella del mini PC è montata in scrittura.

### ROOM-012 · Configurazione dall'immagine, modello da Hermes

Stato: proposto

Un aggiornamento dell'immagine porta config, SOUL e skill nuovi senza
comandi a mano, e non cancella le scelte fatte da Hermes.

Accettazione:

- [ ] All'avvio il gateway copia `config.yaml`, `SOUL.md` e skill
      dall'immagine nei profiles e crea quelli mancanti.
- [ ] Modello e provider scelti da Hermes (`hermes model`, dashboard,
      WebUI) restano: la copia non tocca `model` e `providers` di un profile
      che li ha già.
- [ ] `dojo.env` e i `.env` dei profiles restano sul mini PC e non sono
      nell'immagine.
- [ ] Memoria e sessioni restano.

### ROOM-013 · Migrare la memoria degli agenti

Stato: proposto

Dalla prima versione si portano solo le memorie degli agenti; sessioni,
board e config ripartono da zero.

Accettazione:

- [ ] Uno script da usare una volta, `scripts/migrate-memory.sh`, fuori da
      `dojo.sh`: `export` sul PC di prova crea un archivio con le
      `memories/` di ogni profile del volume, `import <archivio>` sul mini
      PC le rimette nei profiles con lo stesso nome, senza toccare il resto.
- [ ] Il volume vecchio non si cancella: resta come backup.

### ROOM-014 · Togliere il dojo dal PC

Stato: proposto

Un solo script toglie il dojo dal PC, anche le versioni vecchie, senza
cancellare niente che l'utente non abbia confermato.

Accettazione:

- [ ] `scripts/cleanup.sh` chiede prima se fare un backup dei file importanti
      (configurazione con i token, volumi `dojo-lab_data` e
      `dojo-kajiba_dati`, cartella di lavoro) in una cartella a scelta,
      fuori dal checkout e dalle cartelle delle rooms; se il backup non
      riesce, non cancella niente.
- [ ] Poi, un gruppo alla volta, mostra cosa toglie e chiede conferma (invio
      = no): avanzi delle versioni vecchie (gateway LiteLLM, inoltri per il
      telefono), room lab accesa, dati della lab, configurazione, immagini.
- [ ] La rete `proxy` di ron1n non si tocca; un'immagine in uso resta.
- [ ] Alla fine stampa cosa fare a mano: togliere il checkout, il portproxy
      e la regola del firewall su Windows, l'agente in AionUi.

## Note

- Le rooms `home` (personale) e `work` (lavoro) arrivano dopo
  ([architettura](../architecture.md#fasi-della-riscrittura)).
- Se Hermes v0.22.5 non sa approvare da solo i comandi sicuri di ROOM-003,
  si passa alla versione che lo fa, provandola prima.
- Una room per tutti gli agenti: chi ha `terminal` può leggere `.env` e file
  degli altri. Il confine vero sono container, egress e token limitati.
