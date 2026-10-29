# Skill

Skill Hermes di supporto, che non sono flussi: un agente le usa dentro il
suo lavoro. Come `flows/`, la cartella è montata in sola lettura nelle
rooms (`/opt/dojo/skills`) e ogni profile la carica con
`skills.external_dirs` solo se gli serve.

| Skill                         | Chi la usa               | Cosa fa                                                        |
| ----------------------------- | ------------------------ | -------------------------------------------------------------- |
| [grilling](grilling/SKILL.md) | Nico Robin (`concierge`) | intervista a turni finché la richiesta è chiara, poi la smista |
