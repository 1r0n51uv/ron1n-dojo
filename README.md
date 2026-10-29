# ron1n-dojo

Il dojo è il sistema di agenti di ron1n: agenti
[Hermes](https://github.com/NousResearch/hermes-agent) in Docker, ognuno
con un ruolo e permessi stretti, con cui si parla da Telegram. Lavorano su
richiesta, a orario o su evento, e seguono flussi fissi che ricalcano
quello di ron1n: specifica → issue con label → PR con CI → merge → GHCR →
Watchtower. Il merge resta sempre umano.

Architettura e scelte in [`docs/architettura.md`](docs/architettura.md),
requisiti in [`docs/specs/`](docs/specs/README.md).

## Struttura

| Cartella                               | Cosa contiene                                                     |
| -------------------------------------- | ----------------------------------------------------------------- |
| [`stanze/`](stanze/)                   | una stanza = un container Hermes con i suoi profili, rete e proxy |
| [`stanze/kajiba/`](stanze/kajiba/)     | sviluppo: `gunshi`, `takumi`, `shinpan`                           |
| [`servizi/modelli/`](servizi/modelli/) | gateway dei modelli LiteLLM: cloud, piani free, Ollama            |
| [`flussi/`](flussi/README.md)          | skill Hermes dei flussi, montate in sola lettura nelle stanze     |
| [`scripts/`](scripts/)                 | `dojo.sh` (up, down, status, sync) e la validazione               |

## Installazione

Su una macchina con Docker (il mini PC, un portatile, WSL), un comando:

```sh
curl -fsSL https://raw.githubusercontent.com/1r0n51uv/ron1n-dojo/main/scripts/install.sh | bash
```

Clona il repo in `~/ron1n-dojo` (o `DOJO_DIR`), chiede le chiavi dei
provider (ne basta uno, anche gratuito), il tuo user ID Telegram e, agente
per agente, se attivarlo con il suo bot e token GitHub. Poi accende tutto.
Si può rilanciare per attivare altri agenti; i `.env` esistenti restano.

Dopo: `scripts/dojo.sh status`, `up`, `down`, `sync <stanza>`.

La dashboard di Hermes della kajiba è su <http://127.0.0.1:9119> (solo dal
tuo PC). Utente `dojo`, password in `stanze/kajiba/pannello.env`.

## Sviluppo

`npm run check` prima di consegnare: Prettier, markdownlint, shellcheck e
validazione delle stanze. La CI fa lo stesso più actionlint.
