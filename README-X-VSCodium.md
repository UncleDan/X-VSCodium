# X-VSCodium per winPenPack

**VSCodium** è la distribuzione FOSS (Free and Open Source Software) dei binari
di Visual Studio Code, senza telemetria Microsoft, senza branding proprietario e
senza licenze restrittive.

Questo pacchetto include uno script AutoIt che al **primo avvio** scarica
automaticamente l'ultima versione di VSCodium da GitHub, la installa e configura
la portable mode — esattamente come fa X-Firefox nel progetto winPenPack.

---

## Indice

1. [File inclusi in questo pacchetto](#1-file-inclusi-in-questo-pacchetto)
2. [Prerequisiti](#2-prerequisiti)
3. [Compilare lo script AutoIt in .exe](#3-compilare-lo-script-autoit-in-exe)
4. [Struttura delle cartelle](#4-struttura-delle-cartelle)
5. [Installazione](#5-installazione)
6. [Primo avvio — download automatico](#6-primo-avvio--download-automatico)
7. [Avvii successivi](#7-avvii-successivi)
8. [Aggiornare VSCodium](#8-aggiornare-vscodium)
9. [Estensioni e Marketplace](#9-estensioni-e-marketplace)
10. [Come funziona lo script AutoIt](#10-come-funziona-lo-script-autoit)
11. [Differenze rispetto a VS Code](#11-differenze-rispetto-a-vs-code)
12. [Risoluzione problemi](#12-risoluzione-problemi)

---

## 1. File inclusi in questo pacchetto

| File | Descrizione |
|---|---|
| `X-VSCodium.au3` | Script AutoIt sorgente — da compilare in `.exe` |
| `X-VSCodium.ini` | Configurazione per X-Launcher (backup impostazioni, menu) |
| `README-X-VSCodium.md` | Questa guida |

**Non sono inclusi** `X-VSCodium.exe` (devi compilarlo da `.au3`, vedi sezione 3)
né VSCodium stesso (viene scaricato automaticamente al primo avvio).

---

## 2. Prerequisiti

- **winPenPack** già installato (Flash Edition, X-PenDrive o Full)
- **AutoIt v3.3.14.5** o superiore per compilare lo script
  → https://www.autoitscript.com/site/autoit/downloads/
- **SciTE4AutoIt3** (consigliato, include Aut2Exe)
  → https://www.autoitscript.com/site/autoit-script-editor/downloads/
- Sistema operativo: **Windows 10 / 11 (64-bit)**
- Connessione a Internet (necessaria solo al primo avvio per il download)
- (Opzionale) **7-Zip** in `winPenPack\App\7-Zip\7z.exe` per estrazione più rapida

---

## 3. Compilare lo script AutoIt in .exe

Questo è il passo fondamentale. Lo script `.au3` deve essere compilato in un
eseguibile `.exe` prima di poter essere usato. AutoIt e SciTE4AutoIt3 devono
essere installati sul tuo PC (non serve averli sulla USB).

### Metodo A — SciTE4AutoIt3 (consigliato)

1. Installa **SciTE4AutoIt3** sul tuo PC
2. Apri `X-VSCodium.au3` con SciTE4AutoIt3
3. Dal menu **Tools** → **Compile** (oppure premi `F7`)
4. Nella finestra di Aut2Exe:
   - **Source:** percorso di `X-VSCodium.au3`
   - **Destination:** `X-VSCodium.exe` (stessa cartella del sorgente)
   - **Architettura:** seleziona **x64** (consigliato per Windows 10/11)
   - **Compression:** UPX (opzionale, riduce le dimensioni del file)
5. Clicca **Convert** e attendi il messaggio di successo

### Metodo B — Aut2Exe da riga di comando

```cmd
"C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2exe.exe" ^
  /in "X-VSCodium.au3" ^
  /out "X-VSCodium.exe" ^
  /x64
```

### Nota sugli antivirus

Alcuni antivirus segnalano i compilati AutoIt come falsi positivi. Questo è un
comportamento noto e documentato — non indica la presenza di malware. Il codice
sorgente `X-VSCodium.au3` è completamente leggibile e verificabile. Se necessario,
aggiungi un'eccezione per `X-VSCodium.exe` nel tuo antivirus.

---

## 4. Struttura delle cartelle

Dopo l'installazione e il primo avvio, la struttura sarà questa:

```
winPenPack\
├── Bin\
│   └── X-VSCodium\
│       ├── X-VSCodium.exe          ← compilato da te al passo 3
│       ├── X-VSCodium.ini          ← configurazione X-Launcher
│       ├── X-VSCodium.au3          ← sorgente (puoi rimuoverlo dopo la compilazione)
│       └── VSCodium-win32-x64\     ← creato automaticamente al primo avvio
│           ├── codium.exe          ← eseguibile principale
│           ├── data\               ← portable mode (creata dallo script)
│           │   ├── user-data\      ← impostazioni, temi, keybindings
│           │   ├── extensions\     ← estensioni installate
│           │   └── tmp\
│           └── ... (altri file VSCodium)
│
├── User\
│   └── X-VSCodium\                 ← backup impostazioni (gestito da X-Launcher)
│
└── Temp\
    └── X-VSCodium\                 ← download temporaneo (gestito dallo script)
```

---

## 5. Installazione

### Passo 1 — Compilare l'exe

Segui la [sezione 3](#3-compilare-lo-script-autoit-in-exe) per ottenere
`X-VSCodium.exe` dal sorgente `X-VSCodium.au3`.

### Passo 2 — Copiare i file nella cartella winPenPack

Crea la cartella `winPenPack\Bin\X-VSCodium\` e copia al suo interno:

```
X-VSCodium.exe
X-VSCodium.ini
```

Il file `.au3` sorgente è opzionale: puoi tenerlo come riferimento o rimuoverlo.

### Passo 3 — Aggiungere al menu winPenPack (opzionale)

Modifica il file di configurazione del menu winPenPack aggiungendo:

```ini
[X-VSCodium]
Name=VSCodium
Exec=Bin\X-VSCodium\X-VSCodium.exe
Icon=Bin\X-VSCodium\VSCodium-win32-x64\codium.exe,0
Category=Development
```

L'icona sarà disponibile solo dopo il primo avvio, quando VSCodium è stato scaricato.

---

## 6. Primo avvio — download automatico

Al primo avvio `X-VSCodium.exe` rileva che `codium.exe` non esiste ancora e
avvia il processo di setup automatico, esattamente come X-Firefox:

**A) Dialogo di conferma**

Appare una finestra che chiede conferma per il download. Clicca **Sì** per
procedere o **No** per annullare (potrai riavviare in qualsiasi momento).

**B) Interroga le API GitHub**

Lo script contatta `https://api.github.com/repos/VSCodium/vscodium/releases/latest`
e legge il campo `tag_name` per trovare l'ultima versione disponibile
(es. `1.110.11631`).

**C) Download con progress bar**

Scarica automaticamente `VSCodium-win32-x64-{versione}.zip` (~100 MB) nella
cartella `winPenPack\Temp\X-VSCodium\`, mostrando percentuale e dimensioni.

**D) Estrazione**

Estrae il ZIP in `Bin\X-VSCodium\VSCodium-win32-x64\`.
Usa 7-Zip se disponibile in `App\7-Zip\7z.exe`, altrimenti usa Shell.Application
(nativo Windows, nessuna dipendenza aggiuntiva).

**E) Setup portable mode**

Crea la struttura di cartelle per la portable mode:
```
data\user-data\
data\extensions\
data\tmp\
```

**F) Aggiornamento versione**

Aggiorna automaticamente il campo `Version` in `X-VSCodium.ini`.

**G) Avvio**

Imposta le variabili d'ambiente portable e avvia `codium.exe`.

> Il primo avvio richiede 2–5 minuti a seconda della velocità della connessione.

---

## 7. Avvii successivi

Dagli avvii successivi, lo script rileva `codium.exe` e lo avvia direttamente,
impostando le variabili d'ambiente per la portable mode:

| Variabile | Valore |
|---|---|
| `VSCODE_APPDATA` | `...\VSCodium-win32-x64\data\user-data` |
| `VSCODE_LOGS` | `...\VSCodium-win32-x64\data\logs` |
| `VSCODE_EXTENSIONS` | `...\VSCodium-win32-x64\data\extensions` |
| `DISABLE_TELEMETRY` | `1` |

Al termine della sessione le variabili vengono pulite, senza lasciare tracce
sul PC host. X-Launcher sincronizza inoltre `data\` con `User\X-VSCodium\`
prima e dopo ogni avvio.

---

## 8. Aggiornare VSCodium

> Le impostazioni e le estensioni vengono **conservate** perché risiedono
> nella cartella `data\`, separata dai file dell'applicazione.

1. Scarica il nuovo ZIP da: https://github.com/VSCodium/vscodium/releases/latest
   Scegli il file `VSCodium-win32-x64-{versione}.zip`
2. Estrai il contenuto **sopra** la cartella esistente:
   ```
   winPenPack\Bin\X-VSCodium\VSCodium-win32-x64\
   ```
   Conferma la sovrascrittura dei file quando richiesto.
   La cartella `data\` non è presente nello ZIP e non verrà toccata.
3. Aggiorna il campo `Version` in `X-VSCodium.ini`:
   ```ini
   [Software]
   Version=1.110.11631
   ```

---

## 9. Estensioni e Marketplace

VSCodium usa per default il marketplace **Open VSX Registry** (https://open-vsx.org).
La maggior parte delle estensioni popolari è disponibile, ma alcune estensioni
proprietarie Microsoft (Pylance, C# DevKit, GitHub Copilot) non sono presenti
per ragioni di licenza.

Per installare un'estensione non disponibile su Open VSX, scarica il file `.vsix`
dalla pagina GitHub dell'estensione e installala manualmente:
`Ctrl+Shift+P` → **Install from VSIX...**

### Abilitare il Microsoft Marketplace (opzionale)

Modifica `winPenPack\Bin\X-VSCodium\VSCodium-win32-x64\resources\app\product.json`:

```json
"extensionsGallery": {
  "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
  "itemUrl": "https://marketplace.visualstudio.com/items"
}
```

> Questa modifica va ripetuta ad ogni aggiornamento di VSCodium.

---

## 10. Come funziona lo script AutoIt

```
Avvio X-VSCodium.exe
        │
        ▼
 codium.exe esiste?
   NO ──────────── SÌ
   │                │
   ▼                ▼
Dialogo          Imposta variabili
conferma         d'ambiente portable
   │                │
   ▼                ▼
API GitHub       Avvia codium.exe
ultima versione       │
   │             Attende chiusura
   ▼                  │
Download ZIP      Pulisce variabili
con progress bar       │
   │                   ▼
   ▼                 Fine
Estrazione
(7-Zip o COM)
   │
   ▼
Crea data\
user-data\
extensions\
   │
   ▼
Aggiorna ini
   │
   ▼
Avvia codium.exe
```

---

## 11. Differenze rispetto a VS Code

| Caratteristica | VS Code (Microsoft) | VSCodium (FOSS) |
|---|---|---|
| Licenza binari | Proprietaria Microsoft | MIT |
| Telemetria | Attiva per default | Disabilitata per default |
| Marketplace | Microsoft Marketplace | Open VSX Registry |
| Eseguibile | `Code.exe` | `codium.exe` |
| Download automatico (questo script) | — | ✓ |
| Tracce nel registro di sistema | Nessuna (portable) | Nessuna (portable) |

---

## 12. Risoluzione problemi

**"Impossibile ottenere la versione più recente da GitHub"**
→ Controlla la connessione a Internet e riprova. Se GitHub è irraggiungibile
dalla rete, scarica manualmente il ZIP e segui le istruzioni nella sezione 8.

**Il download si blocca o non completa**
→ Verifica che ci sia spazio libero sufficiente (almeno 600 MB) e che la cartella
`Temp\X-VSCodium\` sia scrivibile. Controlla anche che nessun proxy blocchi
le connessioni a `github.com`.

**Errore di estrazione**
→ Installa 7-Zip e copialo in `winPenPack\App\7-Zip\7z.exe` per un metodo
di estrazione più affidabile. In alternativa, estrai manualmente il file
`Temp\X-VSCodium\VSCodium-win32-x64-latest.zip` nella cartella di destinazione.

**VSCodium salva le impostazioni in `%APPDATA%` invece di `data\`**
→ Verifica che la cartella `data\` esista nella stessa directory di `codium.exe`.
Se lo script ha incontrato un errore durante il setup, creala manualmente.

**Le estensioni scompaiono dopo il riavvio su un altro PC**
→ Controlla che `SyncBinToUser=true` e `SyncUserToBin=true` siano impostati
in `X-VSCodium.ini` e che la cartella `User\X-VSCodium\` sia scrivibile.

---

## Riferimenti

- Sito ufficiale VSCodium: https://vscodium.com/
- Repository GitHub VSCodium: https://github.com/VSCodium/vscodium
- Open VSX Registry: https://open-vsx.org
- AutoIt (download e documentazione): https://www.autoitscript.com
- SciTE4AutoIt3: https://www.autoitscript.com/site/autoit-script-editor/downloads/
- winPenPack: https://www.winpenpack.com
- Portable mode VSCode/VSCodium: https://code.visualstudio.com/docs/editor/portable

---

*Realizzato per winPenPack — The Portable Software Collection*
