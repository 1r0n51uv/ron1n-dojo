# Flussi

Ogni flusso è una skill Hermes (`<flusso>/SKILL.md`). La cartella è montata
in sola lettura nelle rooms (`/opt/dojo/flows`) e caricata con
`skills.external_dirs`: gli agenti la usano ma non possono cambiarla. Un
flusso si modifica con una PR su questo repo.

I flussi parlano di issue e di stati, non di un tracker: per ogni progetto
(`projects/<nome>.yaml`) le skill `tracker-github` e `tracker-jira`
(`skills/`) fanno le operazioni sulle issue.

| Flusso                              | Chi lo avvia | Agenti                 | Stato |
| ----------------------------------- | ------------ | ---------------------- | ----- |
| [new-feature](new-feature/SKILL.md) | tu, Telegram | Shikamaru → Edward → L | bozza |
| [new-project](new-project/SKILL.md) | tu, Telegram | strategist             | bozza |
