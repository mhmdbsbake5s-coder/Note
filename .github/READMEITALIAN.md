# Note

[![Version](https://img.shields.io/github/v/release/mhmdbsbake5s-coder/note?color=%230567ff&label=Latest%20Release&style=for-the-badge)](https://github.com/mhmdbsbake5s-coder/note/releases/latest)
![GitHub Downloads (specific asset, all releases)](https://img.shields.io/github/downloads/mhmdbsbake5s-coder/note/Note.ps1?label=Total%20Downloads&style=for-the-badge)
[![](https://dcbadge.limes.pink/api/server/https://discord.gg/RUbZUZyByQ?theme=default-inverted&style=for-the-badge)](https://discord.gg/RUbZUZyByQ)
[![Static Badge](https://img.shields.io/badge/Documentation-_?style=for-the-badge&logo=bookstack&color=grey)](https://noteshopp.mysellauth.com/)

Questa utility Ã¨ una raccolta di attivitÃ  Windows che eseguo personalmente su ogni sistema che utilizzo. Ãˆ progettata per snellire le *installazioni*, rimuovere i componenti superflui tramite *ottimizzazioni*, risolvere problemi tramite la *configurazione*, e riparare *aggiornamenti* di Windows. Sono estremamente selettivo riguardo ai contributi per mantenere questo progetto pulito ed efficiente.

![screen-install](/docs/src/assets/branding/title-screen.png)

## ðŸ’¡ Come usarlo

Note deve essere eseguito con privilegi di amministratore, poichÃ© apporta modifiche all'intero sistema. Per farlo, avvia PowerShell come amministratore. Ecco alcuni modi per procedere:

1. **Metodo del menu di Start:**
   - Fai clic con il tasto destro sul menu Start.
   - Scegli "Windows PowerShell (esegui come Amministratore)" (per Windows 10) o "Terminale (esegui come Amministratore)" (per Windows 11).

2. **Metodo tramite ricerca:**
   - Premi il tasto Windows.
   - Digita "PowerShell" o "Terminal" (per Windows 11).
   - Premi `Ctrl + Shift + Invio` oppure fai clic con il tasto destro e seleziona "Esegui come amministratore" per avviarlo con privilegi elevati.

### Comando di avvio

#### Branch stabile (Consigliato)

```ps1
irm "https://yourdomain.example/note" | iex
```
#### Branch Sviluppatore

```ps1
irm "https://yourdomain.example/notedev" | iex
```

### Automazione

Note supporta anche preset predefiniti che applicano automaticamente configurazioni comuni:

- `Standard`
- `Minimal`
- `Advanced`

Esempio:

```powershell
& ([ScriptBlock]::Create((irm "https://yourdomain.example/note"))) -Preset Standard
```

Per vedere esattamente cosa fa ogni preset, consulta:
https://github.com/mhmdbsbake5s-coder/note/blob/main/config/preset.json

In caso di problemi, consulta i [Problemi noti](https://noteshopp.mysellauth.com/knownissues/) o [Apri una segnalazione](https://github.com/mhmdbsbake5s-coder/note/issues)

## ðŸŽ“ Documentazione

### [Documentazione ufficiale di Note](https://noteshopp.mysellauth.com/)

### [Tutorial su YouTube](https://www.youtube.com/watch?v=6UQZ5oQg8XA)

### [Articolo su ChrisTitus.com](https://yourdomain.example/notedows-tool/)

## ðŸ› ï¸ Build & Sviluppo

> [!NOTE]
> Note Ã¨ uno script piuttosto esteso, per questo Ã¨ suddiviso in piÃ¹ file che vengono combinati in un unico file `.ps1` tramite un compilatore personalizzato. Questo rende la manutenzione del progetto molto piÃ¹ semplice.

Ottieni una copia del codice sorgente. Puoi farlo tramite l'interfaccia di GitHub (**Code** > **Download ZIP**), oppure clonando (scaricando) la repo tramite git.

Se git Ã¨ installato, esegui i seguenti comandi in una finestra PowerShell per clonare e accedere alla directory del progetto:
```ps1
git clone --depth 1 "https://github.com/mhmdbsbake5s-coder/note.git"
cd Note
```

Per compilare il progetto, esegui lo script di compilazione in una finestra PowerShell (i permessi di amministratore NON sono richiesti):
```ps1
.\Compile.ps1
```

Troverai un nuovo file chiamato `Note.ps1`, creato dallo script `Compile.ps1`. Ora puoi eseguirlo come amministratore e apparirÃ  una nuova finestra. Goditi la tua versione compilata di Note :)

> [!TIP]
> Per ulteriori informazioni sull'utilizzo di Note e su come contribuire allo sviluppo, ti invitiamo a leggere le [Linee guida per i contributi](https://noteshopp.mysellauth.com/contributing/). Se non sai da dove iniziare o hai domande, puoi chiedere sul nostro [Server Discord della community](https://discord.gg/RUbZUZyByQ); i membri attivi del progetto risponderanno appena possibile.

## ðŸ’– Supporto
- Per sostenere il progetto moralmente e mentalmente, non dimenticare di lasciare una â­ï¸!
- Wrapper EXE a 10$ su https://noteshopp.mysellauth.com

## ðŸ’– Sponsor

Questi sono gli sponsor che aiutano a mantenere vivo il progetto con contributi mensili.

<!-- sponsors --><a href="https://github.com/dwelfusius"><img src="https:&#x2F;&#x2F;github.com&#x2F;dwelfusius.png" width="60px" alt="Avatar utente: " /></a><a href="https://github.com/mews-se"><img src="https:&#x2F;&#x2F;github.com&#x2F;mews-se.png" width="60px" alt="Avatar utente: Martin Stockzell" /></a><a href="https://github.com/jdiegmueller"><img src="https:&#x2F;&#x2F;github.com&#x2F;jdiegmueller.png" width="60px" alt="Avatar utente: Jason A. Diegmueller" /></a><a href="https://github.com/robertsandrock"><img src="https:&#x2F;&#x2F;github.com&#x2F;robertsandrock.png" width="60px" alt="Avatar utente: RMS" /></a><a href="https://github.com/paulsheets"><img src="https:&#x2F;&#x2F;github.com&#x2F;paulsheets.png" width="60px" alt="Avatar utente: Paul" /></a><a href="https://github.com/djones369"><img src="https:&#x2F;&#x2F;github.com&#x2F;djones369.png" width="60px" alt="Avatar utente: Dave J  (WhamGeek)" /></a><a href="https://github.com/anthonymendez"><img src="https:&#x2F;&#x2F;github.com&#x2F;anthonymendez.png" width="60px" alt="Avatar utente: Anthony Mendez" /></a><a href="https://github.com/FatBastard0"><img src="https:&#x2F;&#x2F;github.com&#x2F;FatBastard0.png" width="60px" alt="Avatar utente: " /></a><a href="https://github.com/DursleyGuy"><img src="https:&#x2F;&#x2F;github.com&#x2F;DursleyGuy.png" width="60px" alt="Avatar utente: DursleyGuy" /></a><a href="https://github.com/DwayneTheRockLobster1"><img src="https:&#x2F;&#x2F;github.com&#x2F;DwayneTheRockLobster1.png" width="60px" alt="Avatar utente: " /></a><a href="https://github.com/KieraKujisawa"><img src="https:&#x2F;&#x2F;github.com&#x2F;KieraKujisawa.png" width="60px" alt="Avatar utente: Kiera Meredith" /></a><a href="https://github.com/andrewpayne68"><img src="https:&#x2F;&#x2F;github.com&#x2F;andrewpayne68.png" width="60px" alt="Avatar utente: Andrew P" /></a><!-- sponsors -->

## ðŸ… Grazie a tutti i collaboratori
Un ringraziamento speciale per aver dedicato il vostro tempo ad aiutare Note a crescere. Grazie mille! Continuate cosÃ¬ ðŸ».

[![Contributori](https://contrib.rocks/image?repo=mhmdbsbake5s-coder/note)](https://github.com/mhmdbsbake5s-coder/note/graphs/contributors)

## ðŸ“Š Statistiche GitHub

![Alt](https://repobeats.axiom.co/api/embed/aad37eec9114c507f109d34ff8d38a59adc9503f.svg "Immagine analisi Repobeats")
