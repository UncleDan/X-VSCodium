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
semplice presenza della cartella `Bin\data\` accanto all'eseguibile
attiva automaticamente la modalità portabile. Il launcher non deve
passare parametri speciali — si occupa di creare la struttura `data\`
al primo avvio e di gestire le operazioni post-run.

---

## Meccanismo di portabilità

VSCodium supporta la portable mode nativa: creando una cartella `data`
nella stessa directory dell'eseguibile, questa viene usata per contenere
tutta la configurazione di VSCodium, inclusi session state, preferenze
ed estensioni.

```
Bin\
├── VSCodium.exe
└── data\              ← presenza = portable mode attiva
    ├── user-data\     ← settings, keybindings, temi, workspace
    ├── extensions\    ← estensioni installate via open-vsx.org
    └── tmp\           ← file temporanei
```

La cartella `data\` viene creata dal launcher al primo avvio se non
esiste. Da quel momento VSCodium non scrive nulla in `%APPDATA%\VSCodium`.

---

## Struttura del pacchetto

```
X-VSCodium\
├── X-VSCodium.au3              ← sorgente AutoIt
├── X-VSCodium.exe              ← launcher compilato
├── X-VSCodium.ini              ← configurazione
├── Bin\
│   ├── VSCodium.exe            ← [DA AGGIUNGERE] binari VSCodium 1.110.11631
│   ├── resources\
│   ├── locales\
│   └── data\                   ← creata dal launcher al primo avvio
│       ├── user-data\
│       │   └── User\
│       │       ├── settings.json
│       │       └── keybindings.json
│       ├── extensions\
│       └── tmp\
├── icons\
│   └── vscodium.ico
└── README.md
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
2. Estrarre tutto il contenuto dello zip in `Bin\`
3. Verificare che `Bin\VSCodium.exe` esista
4. **Non** creare manualmente la cartella `data\` — viene creata
   automaticamente dal launcher al primo avvio
5. Avviare `X-VSCodium.exe`

### Aggiornamento a versione futura

La cartella `data` può essere spostata su altre installazioni di
VS Code, utile per aggiornare la versione portabile.

Procedura:
1. Scaricare il nuovo zip portabile
2. Eliminare il contenuto di `Bin\` **tranne** la cartella `data\`
3. Estrarre il nuovo zip in `Bin\`
4. Avviare `X-VSCodium.exe` — settings e estensioni sono preservati

---

## Estensioni

VSCodium usa **open-vsx.org** come marketplace predefinito.
Le estensioni si installano normalmente da dentro VSCodium
(**Ctrl+Shift+X**) e vengono salvate in `Bin\data\extensions\`.

> **Nota:** alcune estensioni del Visual Studio Marketplace hanno
> licenze che ne vietano l'uso fuori da VS Code ufficiale e non
> sono disponibili su open-vsx.org. Per usare il Marketplace MS
> è possibile configurare `product.json` — vedere la documentazione
> ufficiale di VSCodium.

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
set ICON=icons\vscodium.ico

%AUT2EXE% /in "X-VSCodium.au3" /out "X-VSCodium.exe" /icon %ICON% /x64
```

Il file `X-VSCodium.exe` viene creato nella stessa cartella del sorgente.
L'icona viene letta da `icons\\vscodium.ico` — il file deve esistere prima della compilazione.

## Verifica portabilità

1. Avviare `X-VSCodium.exe`
2. Verificare che `Bin\data\user-data\` venga creata
3. Installare un'estensione e verificare che appaia in
   `Bin\data\extensions\`
4. Aprire `%APPDATA%\VSCodium` — deve essere vuoto o inesistente
5. Spostare il pacchetto su un'altra unità e riavviare —
   settings ed estensioni devono essere preservati

---

## Note tecniche

### Confronto con X-Notepad++

| Aspetto | X-Notepad++ | X-VSCodium |
|---|---|---|
| Portabilità | `config.xml` nella root | `data\` nella root di Bin\ |
| Auto-updater | WinGUp (da disabilitare) | nessuno nel zip portabile |
| Istanze multiple | native, condividono config | native, condividono `data\` |
| PathNormalize | `config.xml`, `session.xml` | `settings.json` |
| PID-file | per WinGUp condizionale | per lock cleanup condizionale |

### Electron e processi figli

VSCodium è basato su Electron e avvia numerosi processi figli
(renderer, extension host, language server, ecc.). Il launcher
usa `ProcessWaitClose($iPID)` sul processo padre, seguito da
un'attesa di 2 secondi per il flush dei file di configurazione
prima di eseguire le operazioni post-run.

### PathNormalize e settings.json

`settings.json` può contenere percorsi assoluti (interpreter Python,
cartelle di lavoro, ecc.). La sezione `[PathNormalize]` normalizza
questi percorsi alla chiusura per garantire portabilità dopo lo
spostamento del pacchetto.

`workspaceStorage` contiene lo stato degli workspace aperti con
percorsi assoluti alle cartelle di progetto. Questi non vengono
normalizzati (sono percorsi al codice sorgente dell'utente, non
al pacchetto VSCodium) — semplicemente diventeranno workspace
"non trovati" se il codice sorgente non è accessibile.

---

## Changelog

| Versione | Data | Note |
|---|---|---|
| 1.5.4 rev1beta | 2026-03-18 | Prima versione X-VSCodium. Basato su X-Notepad++ rev18beta. Supporto VSCodium 1.110.11631. Portable mode via data\. PID-file multi-istanza. PathNormalize settings.json. |
