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

| Cartella                             | Cosa contiene                                                    |
| ------------------------------------ | ---------------------------------------------------------------- |
| [`celle/`](celle/)                   | una cella = un container Hermes con i suoi profili, rete e proxy |
| [`celle/officina/`](celle/officina/) | sviluppo: `architetto`, `fabbro`, `revisore`                     |
| [`flussi/`](flussi/README.md)        | skill Hermes dei flussi, montate in sola lettura nelle celle     |
| [`scripts/`](scripts/)               | `dojo.sh` (up, down, status, sync) e la validazione              |

## Avvio di una cella

Sul server, con Docker:

```sh
cd celle/officina
cp .env.example .env                      # chiave del modello e tuo user ID Telegram
for p in architetto fabbro revisore; do
  cp profili/$p/.env.example profili/$p/.env   # bot Telegram e token GitHub dell'agente
done
chmod 600 .env profili/*/.env
cd ../..
scripts/dojo.sh sync officina             # avvia, crea i profili, copia config e segreti
scripts/dojo.sh status
```

Poi scrivi al bot dell'architetto su Telegram, per esempio
`/nuova-feature ron1nOS <idea>`.

## Sviluppo

`npm run check` prima di consegnare: Prettier, markdownlint, shellcheck e
validazione delle celle. La CI fa lo stesso più actionlint.
