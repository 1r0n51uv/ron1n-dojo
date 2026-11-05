---
name: kanban-card
description: 'Come lavora un agente su una card Kanban: fare domande da un worker, rispondere a un blocco, esito di una card fallita, tentativi massimi e quando una card è finita.'
version: 0.1.0
author: ron1n-dojo
metadata:
  hermes:
    tags: [ron1n, kanban, protocollo]
---

# Protocollo delle card

Vale per ogni agente che lavora una card (worker) o che viene svegliato per
una. La consegna da creare, per chi apre card, è in `handoff-brief`.

## Fare una domanda dal worker

In una card `clarify` non c'è: nessuno risponde mentre lavori. Se ti manca
una decisione di 1ron51uv, non inventarla e non aspettare:

1. `kanban_block` con la domanda e le opzioni nel motivo, la tua consigliata
   per prima. Una domanda sola, la più utile.
2. 1ron51uv la vede bloccata nella WebUI: risponde con un commento e la
   sblocca, e il dispatcher te la ridà con il commento.

## Quando ti sveglia un blocco

Succede quando 1ron51uv ti scrive nella WebUI su una tua card bloccata.

1. Leggi la card con `kanban_show`.
2. Se serve, fai la domanda nella chat con `clarify` e le opzioni in
   `choices` (mai le opzioni nel testo).
3. Scrivi la risposta di 1ron51uv come commento sulla card
   (`kanban_comment`) e sblocca (`kanban_unblock`). Il lavoro riprende
   nella card, non nella chat.

## Quando ti arriva una card fallita

Una riga a 1ron51uv: cosa è successo e chi ha il lavoro adesso. Non rifai la
card e non ne crei di doppie.

## Tentativi massimi

- Lo stesso comando non si ripete più di due volte con lo stesso errore: la
  terza volta cambi approccio o blocchi la card con quello che hai provato.
- Dopo due correzioni della CI con la stessa causa, blocca la card: serve
  una decisione, non un terzo tentativo.
- Un errore di permessi o di credenziali non si aggira: blocca e dillo.
- Una issue o una PR non si ricreano se non sei sicuro che la prima non sia
  stata creata: controlla prima nel tracker.

## Una card è finita quando

- i criteri di accettazione della consegna sono tutti verificati, uno per
  uno, e dici quali e come;
- quello che non hai potuto verificare lo scrivi nel riassunto, non lo
  taci;
- il risultato è consultabile da 1ron51uv (link alla PR, alla issue o al
  file) e sta nel riassunto di `kanban_complete`.

## Contesto piccolo

Leggi solo quello che serve alla card: la consegna, i riferimenti indicati e
i file che tocchi. Un log lungo o una chat intera si aprono solo dal
riferimento e si riassumono in una riga nel commento.
