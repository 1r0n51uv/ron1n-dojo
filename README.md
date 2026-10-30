# ron1n-dojo

Il dojo è il sistema di agenti di ron1n: agenti
[Hermes](https://github.com/NousResearch/hermes-agent) in Docker sul mini PC,
ognuno con un ruolo e permessi stretti, con cui si parla dalla WebUI o da
Telegram. Lavorano su richiesta o a orario e seguono flows fissi che
ricalcano quello di ron1n: specifica → issue → PR con CI → merge → GHCR →
Watchtower. Il merge resta sempre umano.

Architettura e scelte in [`docs/architecture.md`](docs/architecture.md),
requisiti in [`docs/specs/`](docs/specs/README.md).

## Struttura

| Cartella                      | Cosa contiene                                                         |
| ----------------------------- | --------------------------------------------------------------------- |
| [`rooms/lab/`](rooms/lab/)    | la room: `concierge`, `strategist`, `designer`, `builder`, `reviewer` |
| [`flows/`](flows/README.md)   | skill Hermes dei flows, dentro l'immagine                             |
| [`skills/`](skills/README.md) | skill Hermes di supporto (`grilling`, `grilling-with-docs`)           |
| [`scripts/`](scripts/)        | `install.sh`, `dojo.sh` (up, down, status, claude), checks            |

## Installazione

Sul mini PC, con Docker, un comando:

```sh
curl -fsSL https://raw.githubusercontent.com/1r0n51uv/ron1n-dojo/main/scripts/install.sh | bash
```

Clona il repo in `~/ron1n-dojo` (o `DOJO_DIR`), chiede il tuo user ID
Telegram e, agente per agente, se accenderlo con il suo bot e token GitHub,
e scrive le risposte in `dojo.env`. Poi scarica l'immagine da GHCR, avvia
la room, fa il login all'abbonamento Claude e controlla tutto con
`scripts/dojo.sh status`.

## Configurazione

Tutto sta in un file, `dojo.env` nella radice del repo (permessi 600, non
versionato; ogni valore è spiegato in [`dojo.env.example`](dojo.env.example)):
agenti accesi, utente Telegram, cartella di lavoro, bot e token di ogni
agente. Dopo una modifica:

```sh
scripts/dojo.sh up       # applica dojo.env e avvia o aggiorna la room
scripts/dojo.sh status   # cosa gira e cosa manca
scripts/dojo.sh down     # spegne, i dati restano
scripts/dojo.sh claude   # login Claude, una volta sola
```

Ogni progetto su cui lavorano gli agenti ha un file in
[`projects/`](projects/README.md) (repo, tracker GitHub o Jira, stati). Con
un progetto Jira, `dojo.env` ha anche `JIRA_URL`, `JIRA_USERNAME` e un token
per agente (commentati in `dojo.env.example`) e `scripts/dojo.sh up` apre
l'egress verso Atlassian.

Per togliere il dojo dal PC, anche le versioni vecchie: `scripts/cleanup.sh`
(chiede prima se fare un backup, poi conferma ogni gruppo; ROOM-014).

Il modello di ogni agente si sceglie da Hermes (WebUI, dashboard o
`hermes model`), non dal file.

Gli agenti lavorano in `~/dojo/lab` (la cartella `~/dojo` è `DOJO_ROOMS_DIR` in
`dojo.env`; ogni room ha la sua, con il suo nome), con i
tuoi permessi.
L'immagine si aggiorna da sola con Watchtower di ron1n; config e SOUL nuovi
arrivano con lei, mentre il modello scelto da Hermes resta.

- WebUI: <http://127.0.0.1:8787>, password in `rooms/lab/webui.env`; fuori
  casa `https://dojo.ron1n.space` dietro Cloudflare Access. Scegli l'agente
  dal selettore dei profili.
- Dashboard di Hermes: <http://127.0.0.1:9119>, utente `dojo`, password in
  `rooms/lab/dashboard.env`.

### WebUI e dashboard dal telefono, in rete locale o hotspot (Windows con WSL2)

Solo per le prove su Windows; sul mini PC si usa il Cloudflare Tunnel. La
WebUI ha la sua password e un terminale: aprila solo su una rete tua.

1. In `dojo.env` metti `WEBUI_BIND=0.0.0.0` (e `DASHBOARD_BIND=0.0.0.0` per la
   dashboard) e lancia `scripts/dojo.sh up`.
2. Con Docker Desktop basta il punto 3. Con Docker dentro WSL2 (Windows 11
   22H2 o più recente) metti in `%UserProfile%\.wslconfig`
   `[wsl2]` e `networkingMode=mirrored`, poi `wsl --shutdown` e riapri WSL.
3. In PowerShell come amministratore, una regola per le porte, solo sulle
   reti private (la rete di un hotspot Windows la tratta spesso come
   pubblica: in quel caso mettila privata da Impostazioni › Rete, oppure
   usa `-Profile Private,Public`):

   ```powershell
   New-NetFirewallRule -DisplayName "dojo LAN" -Direction Inbound -Protocol TCP -LocalPort 8787,9119 -Action Allow -Profile Private
   ```

   Con il networking `mirrored` serve anche, una volta:
   `Set-NetFirewallHyperVVMSetting -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -DefaultInboundAction Allow`.

4. Dal telefono: `http://<indirizzo IP del PC>:8787` (WebUI) o `:9119`
   (dashboard). L'IP si legge con `ipconfig` sulla rete a cui il PC è
   collegato, anche quella dell'hotspot del telefono.

Per chiudere: togli `WEBUI_BIND` e rilancia `up`, poi
`Remove-NetFirewallRule -DisplayName "dojo LAN"` (`cleanup.sh` te lo ricorda).

- Telegram: un bot per agente.

## Sviluppo

`npm run check` prima di consegnare: Prettier, markdownlint, shellcheck e
validazione delle rooms. La CI fa lo stesso più actionlint, e costruisce e
prova l'immagine della lab.
