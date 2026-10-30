# Specifiche del dojo

Le specifiche descrivono cosa fa il dojo, non come. Stesse regole di ron1n
(`docs/flusso-sviluppo.md` nel repo `1r0n51uv/ron1n`): ID stabili, criteri
di accettazione, stato.

## Moduli

| Modulo  | File                     | Prefisso ID | Label         |
| ------- | ------------------------ | ----------- | ------------- |
| Stanze  | [rooms.md](rooms.md)     | `ROOM`      | `mod:rooms`   |
| Flussi  | [flows.md](flows.md)     | `FLOW`      | `mod:flows`   |
| Modelli | [models.md](models.md)   | `MODELS`    | `mod:models`  |
| Tracker | [tracker.md](tracker.md) | `TRACKER`   | `mod:tracker` |

## Stati dei requisiti

`proposto` → `pianificato (#issue)` → `in corso (#issue)` → `fatto (#PR)`,
oppure `rimosso`. Gli ID non si riusano.
