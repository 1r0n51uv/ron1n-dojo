# ron1n-dojo

Il dojo è il sistema di agenti di ron1n: agenti
[Hermes](https://github.com/NousResearch/hermes-agent) in Docker, ognuno
con un ruolo e permessi stretti, con cui si parla da Telegram. Lavorano su
richiesta, a orario o su evento, e seguono flows fissi che ricalcano
quello di ron1n: specifica → issue con label → PR con CI → merge → GHCR →
Watchtower. Il merge resta sempre umano.

Architettura e scelte in [`docs/architecture.md`](docs/architecture.md),
requisiti in [`docs/specs/`](docs/specs/README.md).

## Struttura

| Cartella                               | Cosa contiene                                                                |
| -------------------------------------- | ---------------------------------------------------------------------------- |
| [`rooms/`](rooms/)                     | una room = un container Hermes con i suoi profiles, rete e proxy             |
| [`rooms/lab/`](rooms/lab/)             | sviluppo: `concierge`, `strategist`, `designer`, `builder`, `reviewer`       |
| [`services/models/`](services/models/) | gateway dei modelli LiteLLM: cloud, piani free, Ollama                       |
| [`flows/`](flows/README.md)            | skill Hermes dei flows, montate in sola lettura nelle rooms                  |
| [`skills/`](skills/README.md)          | skill Hermes di supporto (`grilling`, `grilling-with-docs`), in sola lettura |
| [`scripts/`](scripts/)                 | `dojo.sh` (up, down, status, sync) e la validazione                          |

## Installazione

Su una macchina con Docker (il mini PC, un portatile, WSL), un comando:

```sh
curl -fsSL https://raw.githubusercontent.com/1r0n51uv/ron1n-dojo/main/scripts/install.sh | bash
```

Clona il repo in `~/ron1n-dojo` (o `DOJO_DIR`), chiede le chiavi dei
provider (ne basta uno, anche gratuito), il tuo user ID Telegram e, agente
per agente, se attivarlo con il suo bot e token GitHub. Poi accende tutto.
Si può rilanciare per attivare altri agenti; i `.env` esistenti restano.

Dopo: `scripts/dojo.sh status`, `up`, `down`, `sync <room>`. Con un
abbonamento Claude Pro o Max: `scripts/dojo.sh claude lab` (MODELS-006).

La dashboard di Hermes della lab è su <http://127.0.0.1:9119> (solo dal
tuo PC). Utente `dojo`, password in `rooms/lab/dashboard.env`.

Per parlare con un agente da un client ACP come
[AionUi](https://github.com/iOfficeAI/AionUi), aggiungi un agente custom
con comando `docker` e argomenti
`exec -i -u hermes dojo-lab-hermes-1 dojo-acp <agente>`, dove `<agente>` è
`concierge`, `strategist`, `designer`, `builder` o `reviewer` (ROOM-008).
Lavora in `/opt/data/work` del container, non nelle cartelle del PC.

## Sviluppo

`npm run check` prima di consegnare: Prettier, markdownlint, shellcheck e
validazione delle rooms. La CI fa lo stesso più actionlint.
