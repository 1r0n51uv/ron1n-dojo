# Architettura

Il dojo è un insieme di agenti Hermes (Nous Research) in Docker. Ognuno ha
un ruolo, strumenti e credenziali minimi; si parla con loro da Telegram;
lavorano su richiesta, a orario (cron) o su evento (webhook). Gira sul
mini PC di ron1n accanto agli altri stack.

## Cosa isola davvero

- Un **profilo** Hermes è un agente con config, SOUL, memoria, skill, cron
  e bot propri, ma non è una sandbox: i profili nello stesso container
  condividono filesystem e processi.
- Il **container** è il confine. Senza `docker.sock` l'agente non esce dal
  suo container; il volume dati è solo suo.
- I **toolset** (`platform_toolsets.<piattaforma>`) decidono cosa può
  fare: senza `terminal` niente shell, senza `file` niente scritture.
- Le **approvazioni** (`approvals.mode: manual`) chiedono conferma su
  Telegram per i comandi pericolosi; `cron_mode` e `unattended_mode: deny`
  li negano quando nessuno può rispondere; `approvals.deny` blocca sempre
  alcuni comandi (merge, push forzati), anche con approvazione.
- L'**uscita** passa dal proxy Squid `uscita` con allowlist di domini; la
  rete `interna` non ha rotta verso internet.
- Su **Telegram** risponde solo `TELEGRAM_ALLOWED_USERS`; un bot per
  profilo.
- Su **GitHub** ogni agente ha un token fine-grained dell'account bot,
  limitato ai repo app; la branch protection impedisce merge senza
  approvazione.

Da qui due livelli: **stanze** (container) come confine di sicurezza,
**profili** dentro la stanza come ruoli. Agenti nella stessa stanza
condividono il board Kanban e si passano il lavoro; stanze diverse non
condividono nulla.

## Stanze

Il dojo ha una stanza per area. Ogni agente è un personaggio, uno per
anime, con il nome del ruolo in giapponese.

| Stanza              | Agenti (ruolo · personaggio)                                                                       | Può                                                         | Non può                               |
| ------------------- | -------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- | ------------------------------------- |
| `kajiba`, la forgia | Gunshi · Shikamaru (Naruto), Takumi · Edward Elric (Fullmetal Alchemist), Shinpan · L (Death Note) | shell nel container, git, `gh`, npm; PR sui repo app        | merge, admin dei repo, server, docker |
| personale (dopo)    | Nakama · Chopper (One Piece)                                                                       | promemoria, note, brief del mattino; MCP di ron1nOS         | shell, GitHub, file                   |
| lavoro (dopo)       | Taichō · Levi (L'attacco dei giganti)                                                              | come la stanza personale, con memoria e credenziali proprie | vedere le altre stanze                |
| ingresso (forse)    | Shihan · da scegliere (Gojo, Netero, ...)                                                          | smistare le richieste alle stanze, creare cron              | lavorare da sé                        |

I nomi delle stanze personale, lavoro e ingresso si decidono quando
arrivano. Shinpan potrebbe diventare Aizawa (My Hero Academia).

Ogni stanza: immagine Hermes a versione fissata, volume dati suo, limiti di
CPU e memoria, rete `interna` più proxy `uscita`, nessuna porta pubblicata
(Telegram in polling), dashboard spenta o solo su `127.0.0.1`.

In una stanza il profilo `default` non ha bot: ospita il gateway che serve
tutti i profili (multiplexing) e il dispatcher Kanban.

### Kajiba

| Agente               | Ruolo                                                         | Toolset                                         | Token GitHub                                |
| -------------------- | ------------------------------------------------------------- | ----------------------------------------------- | ------------------------------------------- |
| `gunshi` (Shikamaru) | specifica, PR `spec`, issue con label, card per Edward        | file, terminal, kanban, clarify, skills         | contents, pull requests, issues: scrittura  |
| `takumi` (Edward)    | implementazione con test, `npm run check`, PR con `Closes #N` | file, terminal, code_execution, kanban, clarify | contents, pull requests: scrittura          |
| `shinpan` (L)        | review contro specifica e regole, segnala la PR pronta        | terminal, kanban, clarify, skills               | contents: lettura; pull requests: scrittura |

## Canali

- **Telegram** per iniziare: un bot per agente. WhatsApp è supportato da
  Hermes ma vuole un secondo numero e un pairing da rifare: più avanti.
- **Su richiesta**: messaggio al bot (`/nuova-feature ...` o testo libero).
- **A orario**: `hermes cron` del profilo, consegna su Telegram.
- **Su evento**: webhook GitHub verso il gateway. Serve una porta
  raggiungibile, quindi Caddy più Cloudflare Tunnel come gli altri stack:
  fase 2.

## Flussi

Skill Hermes in [`flussi/`](../flussi/README.md), montate in sola lettura.
Ogni passaggio fra agenti è una card Kanban; le card PR hanno un contratto
di completamento, quindi si chiudono solo con i check richiesti verdi.

1. **Nuova feature**: gunshi (specifica, issue) → takumi (PR) →
   shinpan (review) → merge tuo.
2. **Nuovo progetto**: gunshi prepara specifica e template; repo e
   branch protection li crei tu; PR sul hub per README e `infra/<app>/`.
3. **Personale**, **lavoro**, **ricorrenti** (digest di PR e issue, CI
   rossa su `main`, dipendenze): con le stanze della fase 2.

## Fasi

1. **Fase 0**: questo repo, specifiche, stanza `kajiba`, flussi in bozza.
2. **Fase 1**: `kajiba` sul mini PC con Telegram, prova di
   `nuova-feature` su un repo vero; stack `infra/dojo-kajiba/` in ron1n.
3. **Fase 2**: stanza `personale`, cron, webhook GitHub via Tunnel.
4. **Fase 3**: stanza `lavoro`, server MCP per ron1n (stato degli stack,
   log, API di ron1nOS) con filtri per server nelle stanze.

## Riferimenti

Documentazione di Hermes nel repo
[NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent),
cartella `website/docs/user-guide/`: `docker.md`, `profiles.md`,
`security.md`, `features/kanban.md`, `features/cron.md`,
`egress/network-isolation.md`, `messaging/telegram.md`.
