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

Il modello di ogni agente si sceglie da Hermes (WebUI, dashboard o
`hermes model`), non dal file.

Gli agenti lavorano in `~/dojo/work` (o `DOJO_WORK` in `dojo.env`), con i
tuoi permessi.
L'immagine si aggiorna da sola con Watchtower di ron1n; config e SOUL nuovi
arrivano con lei, mentre il modello scelto da Hermes resta.

- WebUI: <http://127.0.0.1:8787>, password in `rooms/lab/webui.env`; fuori
  casa `https://dojo.ron1n.space` dietro Cloudflare Access. Scegli l'agente
  dal selettore dei profili.
- Dashboard di Hermes: <http://127.0.0.1:9119>, utente `dojo`, password in
  `rooms/lab/dashboard.env`.
- Telegram: un bot per agente.

## Sviluppo

`npm run check` prima di consegnare: Prettier, markdownlint, shellcheck e
validazione delle rooms. La CI fa lo stesso più actionlint, e costruisce e
prova l'immagine della lab.
