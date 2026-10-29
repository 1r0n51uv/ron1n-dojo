# Specifiche del dojo

Le specifiche descrivono cosa fa il dojo, non come. Stesse regole di ron1n
(`docs/flusso-sviluppo.md` nel repo `1r0n51uv/ron1n`): ID stabili, criteri
di accettazione, stato.

## Moduli

| Modulo | File                   | Prefisso ID | Label        |
| ------ | ---------------------- | ----------- | ------------ |
| Stanze | [stanze.md](stanze.md) | `STANZA`    | `mod:stanze` |
| Flussi | [flussi.md](flussi.md) | `FLUSSO`    | `mod:flussi` |

## Stati dei requisiti

`proposto` → `pianificato (#issue)` → `in corso (#issue)` → `fatto (#PR)`,
oppure `rimosso`. Gli ID non si riusano.
