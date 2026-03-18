# X-VSCodium — Portable VSCodium Launcher
**Versione:** 1.5.4 rev1beta
**Architettura:** win64
**Basato su:** X-Notepad++ launcher 1.5.4 rev18beta (winPenPack)
**VSCodium supportato:** 1.110.11631 (VS Code 1.110.1 — marzo 2026)
**Licenza:** [winPenPack License Agreement](http://www.winpenpack.com/en/page.php?5)

---

## Descrizione

X-VSCodium è un launcher portabile per VSCodium basato sull'architettura
X-Launcher di winPenPack. Permette di eseguire VSCodium da qualsiasi
supporto rimovibile senza installazione sul PC host e senza lasciare
tracce nel sistema.

VSCodium è la distribuzione MIT-licensed di VS Code senza telemetria
Microsoft, branding e licenza proprietaria. Usa open-vsx.org come
marketplace di estensioni al posto del Visual Studio Marketplace.

Come Notepad++, VSCodium supporta la **portable mode nativa**: la
presenza della cartella `data\` accanto all'eseguibile attiva
automaticamente la modalità portabile. Il launcher crea la struttura
`data\` al primo avvio e gestisce le operazioni post-run.

---

## Meccanismo di portabilità

VSCodium rileva la portable mode dalla presenza di `data\` nella stessa
cartella di `VSCodium.exe`. Il launcher posiziona i binari in
`Bin\VSCodium\` e crea `Bin\VSCodium\data\` al primo avvio:

```
Bin\VSCodium\
├── VSCodium.exe
└── data\              ← presenza = portable mode attiva
    ├── user-data\     ← settings, keybindings, temi, workspace
    ├── extensions\    ← estensioni installate via open-vsx.org
    └── tmp\           ← file temporanei
```

Da quel momento VSCodium non scrive nulla in `%APPDATA%\VSCodium`.

---

## Struttura del pacchetto

```
X-VSCodium\
├── X-VSCodium.au3              ← sorgente AutoIt
├── X-VSCodium.exe              ← launcher compilato
├── X-VSCodium.ini              ← configurazione
├── build.bat                   ← script di compilazione
├── Bin\
│   └── VSCodium\               ← [DA AGGIUNGERE] contenuto zip portabile
│       ├── VSCodium.exe
│       ├── resources\
│       │   └── app\
│       │       └── resources\
│       │           └── win32\
│       │               └── code.ico   ← icona (copiare in icons\)
│       ├── locales\
│       └── data\               ← creata dal launcher al primo avvio
│           ├── user-data\
│           ├── extensions\
│           └── tmp\
└── icons\
    └── code.ico                ← copiare da Bin\VSCodium\resources\app\resources\win32\
```

---

## Come aggiungere i binari di VSCodium 1.110.11631

> **Importante:** usare **esclusivamente** lo zip portabile win64.
> Gli installer `.exe` e `.msi` non supportano la portable mode.

### Download zip portabile

```
https://github.com/VSCodium/vscodium/releases/download/1.110.11631/VSCodium-win32-x64-1.110.11631.zip
```

### Installazione

1. Scaricare `VSCodium-win32-x64-1.110.11631.zip`
2. Creare la cartella `Bin\VSCodium\` se non esiste
3. Estrarre tutto il contenuto dello zip in `Bin\VSCodium\`
4. Verificare che `Bin\VSCodium\VSCodium.exe` esista
5. Copiare l'icona in `icons\`:
   ```
   Bin\VSCodium\resources\app\resources\win32\code.ico  →  icons\code.ico
   ```
6. **Non** creare manualmente la cartella `data\` — il launcher
   la crea automaticamente al primo avvio
7. Avviare `X-VSCodium.exe`

### Aggiornamento a versione futura

1. Scaricare il nuovo zip portabile
2. Eliminare il contenuto di `Bin\VSCodium\` **tranne** la cartella `data\`
3. Estrarre il nuovo zip in `Bin\VSCodium\`
4. Avviare `X-VSCodium.exe` — settings e estensioni sono preservati

---

## Estensioni

VSCodium usa **open-vsx.org** come marketplace predefinito.
Le estensioni si installano normalmente dall'interno di VSCodium
(**Ctrl+Shift+X**) e vengono salvate in `Bin\VSCodium\data\extensions\`.

---

## Compilazione

### Strumenti necessari

| Strumento | Versione | Download |
|---|---|---|
| AutoIt3 | 3.3.16.1 (64-bit) | https://www.autoitscript.com/site/autoit/downloads/ |

> **Importante:** usare obbligatoriamente la versione **64-bit** di AutoIt3 e `Aut2exe_x64.exe`.
> La direttiva `#AutoIt3Wrapper_UseX64=Y` nel sorgente non e' sufficiente con versioni 32-bit.

### Compilazione via Aut2Exe (riga di comando)

```bat
set AUT2EXE="C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2exe_x64.exe"
set ICON=icons\code.ico

%AUT2EXE% /in "X-VSCodium.au3" /out "X-VSCodium.exe" /icon %ICON% /x64
```

Il file `X-VSCodium.exe` viene creato nella stessa cartella del sorgente.
L'icona viene letta da `icons\code.ico` — il file deve esistere prima della compilazione.

In alternativa usare `build.bat` incluso nel pacchetto (doppio clic).

---

## Verifica portabilità

1. Avviare `X-VSCodium.exe`
2. Verificare che `Bin\VSCodium\data\user-data\` venga creata
3. Installare un'estensione e verificare che appaia in
   `Bin\VSCodium\data\extensions\`
4. Aprire `%APPDATA%\VSCodium` — deve essere vuoto o inesistente
5. Spostare il pacchetto su un'altra unità e riavviare —
   settings ed estensioni devono essere preservati

---

## Note tecniche

### Confronto con X-Notepad++

| Aspetto | X-Notepad++ | X-VSCodium |
|---|---|---|
| Binari in | `Bin\` | `Bin\VSCodium\` |
| Portabilità | `config.xml` nella root di Bin\ | `data\` nella root di Bin\VSCodium\ |
| Auto-updater | WinGUp (da disabilitare) | nessuno nel zip portabile |
| Icona | `icons\notepad++.ico` | `icons\code.ico` (da `resources\app\resources\win32\`) |
| PathNormalize | `config.xml`, `session.xml` | `settings.json` |

### Electron e processi figli

VSCodium è basato su Electron e avvia numerosi processi figli
(renderer, extension host, language server, ecc.). Il launcher
usa `ProcessWaitClose($iPID)` sul processo padre, seguito da
un'attesa di 2 secondi per il flush dei file di configurazione.

### PathNormalize e settings.json

`settings.json` può contenere percorsi assoluti (interpreter Python,
cartelle di lavoro, ecc.). La sezione `[PathNormalize]` del `.ini`
normalizza questi percorsi alla chiusura per garantire portabilità
dopo lo spostamento del pacchetto.

---

## Changelog

| Versione | Data | Note |
|---|---|---|
| 1.5.4 rev1beta | 2026-03-18 | Prima versione X-VSCodium. Basato su X-Notepad++ rev18beta. Supporto VSCodium 1.110.11631. Binari in Bin\VSCodium\. Portable mode via data\. Icona code.ico da resources\app\resources\win32\. PID-file multi-istanza. PathNormalize settings.json. |
