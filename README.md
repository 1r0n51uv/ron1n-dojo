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

## Avvio di una stanza

Sul server, con Docker. Prima il gateway dei modelli:

```sh
cd servizi/modelli
cp .env.example .env                      # master key, password del DB, chiavi dei provider
chmod 600 .env
cd ../..
scripts/dojo.sh up                        # crea le reti e accende il gateway
scripts/dojo.sh chiave kajiba             # stampa LITELLM_API_KEY per la stanza
```

Poi la stanza:

```sh
cd stanze/kajiba
cp .env.example .env                      # LITELLM_API_KEY e tuo user ID Telegram
for p in gunshi takumi shinpan; do
  cp profili/$p/.env.example profili/$p/.env   # bot Telegram e token GitHub dell'agente
done
chmod 600 .env profili/*/.env
cd ../..
scripts/dojo.sh sync kajiba             # avvia, crea i profili, copia config e segreti
scripts/dojo.sh status
```

Poi scrivi al bot di Shikamaru su Telegram, per esempio
`/nuova-feature ron1nOS <idea>`.

## Sviluppo

`npm run check` prima di consegnare: Prettier, markdownlint, shellcheck e
validazione delle stanze. La CI fa lo stesso più actionlint.
