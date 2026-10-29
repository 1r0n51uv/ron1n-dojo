---
name: grilling
description: 'Intervista 1ron51uv con domande mirate, a turni, finché la richiesta è chiara e si sa a chi passarla. Da usare prima di creare una card Kanban.'
version: 0.1.0
author: ron1n-dojo
license: MIT
metadata:
  hermes:
    tags: [ron1n, concierge, chiarimento, smistamento]
---

# Grilling

Adattata da `grilling` di Matt Pocock
([mattpocock/skills](https://github.com/mattpocock/skills), licenza MIT)
per il Concierge del dojo: si parla su Telegram, non ci sono sub-agent e
alla fine non si scrive codice ma si crea una card Kanban.

## Quando usarla

- Sempre, prima di creare una card per una richiesta nuova.
- Non serve per le domande sullo stato ("a che punto siamo?"): lì guardi il
  board e rispondi.
- Se la richiesta è già chiara (cosa, dove, perché, per chi), fai un solo
  turno di conferma con il riepilogo e passi alla card.

## L'albero delle decisioni

Tratta la richiesta come un **albero**: ogni decisione apre quelle che
dipendono da lei. La **frontiera** sono le decisioni i cui prerequisiti sono
già risolti: le domande che puoi fare _adesso_ senza indovinare risposte che
non hai ancora sentito.

I rami che contano per il dojo, più o meno in quest'ordine:

1. **Cosa**: nuova feature, nuovo progetto, bug, revisione di un design,
   altro. Senza questo non si smista niente.
2. **Dove**: repo e modulo (`ron1nOS`, un'app, il dojo stesso). Se il repo
   non esiste ancora, è un nuovo progetto.
3. **Perché e per chi**: il problema da risolvere, chi userà la cosa. È la
   materia della specifica di Shikamaru.
4. **Come si vede**: c'è un'interfaccia? Serve un mockup prima del codice?
   Decide se passa da Bulma.
5. **Quando è finita**: due o tre criteri verificabili.
6. **Vincoli**: urgenza, priorità, cose da non toccare, dipendenze da altre
   richieste sul board.

Non tutti i rami servono sempre: un bug ha bisogno di "cosa succede, cosa
dovrebbe succedere, come si riproduce", non di un mockup.

## I turni

Lavori a **turni**. In ogni turno fai le domande della frontiera, ognuna
con la tua risposta consigliata. Poi aspetti le risposte.

- Al massimo tre domande per turno: su Telegram un muro di domande non si
  legge. Se la frontiera è più larga, tieni le più importanti.
- Ogni turno è **una sola chiamata** al tool `clarify`, con le domande del
  turno in `questions`. Su Telegram ogni domanda arriva come un messaggio
  con i bottoni delle opzioni, una dopo l'altra, come le conferme di
  `/new`.
- Le opzioni vanno solo in `choices`, mai scritte nel testo della domanda:
  scritte nel testo non si possono toccare. Al massimo quattro, la tua
  consigliata per **prima**; Hermes aggiunge da solo il bottone "Altro"
  per una risposta libera.
- Se si può scegliere più di un'opzione (per esempio i moduli toccati),
  metti `multi_select: true`: si risponde con i numeri separati da virgole.
- Una domanda senza opzioni possibili (un nome, una descrizione) va senza
  `choices`: si risponde scrivendo. Mettila comunque nella stessa chiamata
  del turno.
- Il testo della domanda è breve: un titolo e la domanda, niente elenchi.
  Per esempio:

```json
{
  "questions": [
    {
      "question": "D1 · Dove: in che repo va?",
      "choices": ["ron1nOS", "un'app nuova", "il dojo"]
    },
    {
      "question": "D2 · Interfaccia: serve un mockup di Bulma prima del codice?",
      "choices": ["Sì, prima il mockup", "No, basta la specifica"]
    }
  ]
}
```

Ogni risposta cambia l'albero: le decisioni prese spostano la frontiera e
sbloccano le domande che dipendevano da loro. Ricalcola e fai il turno
successivo. Una domanda che dipende da un'altra ancora aperta in questo
turno va al turno dopo, non a questo.

Se `clarify` torna con `outcome` diverso da `submitted` (1ron51uv non ha
risposto in tempo o ha annullato), non decidere al suo posto: scrivi in
una riga dove ti sei fermata e rifai le domande rimaste quando torna. Una
domanda saltata (`skipped`) diventa una domanda aperta nella card.

## Fatti e decisioni

Trovare i _fatti_ è compito tuo, non di 1ron51uv. Prima di chiedere guarda
quello che puoi vedere: il board Kanban (card simili o già aperte), la tua
memoria (repo, moduli, preferenze già dette). Non chiedere quello che sai
già. Quello che non puoi vedere (codice, issue su GitHub) non lo cerchi:
lo scrivi nella card come domanda aperta per l'agente che la riceve.

Le _decisioni_ sono di 1ron51uv: gliele proponi e aspetti la risposta.

## Quando fermarsi

Il grilling finisce quando la frontiera è vuota: ogni ramo che serve è
stato visitato, niente è dato per scontato in silenzio. Oppure quando
1ron51uv dice "basta, vai": allora le domande rimaste diventano domande
aperte nella card.

A quel punto mandi un riepilogo di poche righe:

- cosa, dove, perché;
- criteri di "finito";
- a chi passi la card e perché (Shikamaru, Bulma, o "non è roba del Lab");
- domande aperte, se ce ne sono.

Poi chiedi la conferma con `clarify`, scelte "Confermo, crea la card" e
"Correggo qualcosa". Crei la card solo dopo la conferma. Nella card
copi il riepilogo così com'è: chi la riceve non deve rifare le domande.

Una card per Shikamaru non è l'ultima parola: lui la rivede contro la
documentazione del repo con la skill `grilling-with-docs` e chiede a
1ron51uv solo quello che il riepilogo non ha chiuso.
