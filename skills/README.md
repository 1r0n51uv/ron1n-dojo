# Skill

Skill Hermes di supporto, che non sono flussi: un agente le usa dentro il
suo lavoro. Come `flows/`, la cartella è montata in sola lettura nelle
rooms (`/opt/dojo/skills`) e ogni profile la carica con
`skills.external_dirs` solo se gli serve.

| Skill                                             | Chi la usa                              | Cosa fa                                                                                             |
| ------------------------------------------------- | --------------------------------------- | --------------------------------------------------------------------------------------------------- |
| [grilling](grilling/SKILL.md)                     | Nico Robin (`concierge`)                | intervista a turni finché la richiesta è chiara, poi la smista                                      |
| [grilling-with-docs](grilling-with-docs/SKILL.md) | Shikamaru (`strategist`)                | rivede il piano di Nico Robin contro i documenti del repo, poi grilling e specifica scritta durante |
| [tracker-github](tracker-github/SKILL.md)         | strategist, designer, builder, reviewer | issue di un progetto con tracker GitHub: leggere, creare, commentare, stato, assegnatario           |
| [tracker-jira](tracker-jira/SKILL.md)             | strategist, designer, builder, reviewer | le stesse operazioni su Jira Cloud, con il server MCP `atlassian`                                   |

Le domande a scelta multipla passano sempre dal tool `clarify`, con le
opzioni in `choices`: su Telegram Hermes le mostra come bottoni sotto il
messaggio, più un bottone "Altro" per rispondere a parole.
