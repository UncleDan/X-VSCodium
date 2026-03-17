# X-VSCodium — Guida alla compilazione e distribuzione

Questa guida è destinata a chi vuole **compilare e distribuire** il pacchetto
X-VSCodium. Se sei un utente finale che ha già ricevuto lo ZIP, leggi
`README-X-VSCodium.md`.

---

## Indice

1. [File del progetto](#1-file-del-progetto)
2. [Prerequisiti di sviluppo](#2-prerequisiti-di-sviluppo)
3. [Come funziona `#pragma compile`](#3-come-funziona-pragma-compile)
4. [Compilazione con COMPILA.bat (metodo consigliato)](#4-compilazione-con-compilabat)
5. [Compilazione manuale](#5-compilazione-manuale)
6. [Struttura del pacchetto distribuito](#6-struttura-del-pacchetto-distribuito)
7. [Come testare prima di distribuire](#7-come-testare-prima-di-distribuire)
8. [Aggiornare la versione nel sorgente](#8-aggiornare-la-versione-nel-sorgente)
9. [Note sull'icona](#9-note-sullicona)
10. [Falsi positivi antivirus](#10-falsi-positivi-antivirus)

---

## 1. File del progetto

| File | Ruolo |
|---|---|
| `X-VSCodium.au3` | Sorgente AutoIt del launcher |
| `X-VSCodium.ini` | Configurazione X-Launcher winPenPack |
| `vscodium.ico` | Icona incorporata nel .exe durante la compilazione |
| `COMPILA.bat` | Script di build automatico (compila + pacchettizza) |
| `README-X-VSCodium.md` | Guida utente finale (inclusa nel pacchetto ZIP) |
| `README-COMPILAZIONE.md` | Questa guida (NON inclusa nel pacchetto ZIP) |

**File generati dal processo di build:**

| File | Descrizione |
|---|---|
| `X-VSCodium.exe` | Launcher compilato, standalone, con icona incorporata |
| `X-VSCodium_winpenpack.zip` | Pacchetto finale pronto per la distribuzione |

---

## 2. Prerequisiti di sviluppo

### AutoIt + Aut2Exe (obbligatorio)

Aut2Exe è il compilatore incluso con AutoIt. Scarica e installa il pacchetto completo:

→ https://www.autoitscript.com/site/autoit/downloads/

Installa **AutoIt Full Installation** (non solo il runtime). Dopo l'installazione,
Aut2Exe si troverà in:
```
C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2exe_x64.exe
```

### SciTE4AutoIt3 (opzionale ma consigliato)

Editor con syntax highlighting, debugger e compilazione integrata (F7):

→ https://www.autoitscript.com/site/autoit-script-editor/downloads/

### 7-Zip (per il packaging)

Necessario solo per la creazione automatica del pacchetto ZIP finale:

→ https://www.7-zip.org/

Se 7-Zip non è installato, `COMPILA.bat` compila comunque l'exe ma salta
la creazione dello ZIP.

---

## 3. Come funziona `#pragma compile`

Lo script `.au3` usa le direttive `#pragma compile` per incorporare metadati
e l'icona direttamente nell'eseguibile finale **senza passare parametri a
Aut2Exe dalla riga di comando**:

```autoit
#pragma compile(Icon,        vscodium.ico)
#pragma compile(Out,         X-VSCodium.exe)
#pragma compile(x64,         true)
#pragma compile(UPX,         false)
#pragma compile(FileVersion, 1.0.0.0)
#pragma compile(ProductName, X-VSCodium)
#pragma compile(CompanyName, winPenPack)
#pragma compile(FileDescription, winPenPack X-Launcher per VSCodium)
```

Il percorso dell'icona in `#pragma compile(Icon, vscodium.ico)` è **relativo**
alla posizione del file `.au3`. Quindi `vscodium.ico` deve stare nella stessa
cartella di `X-VSCodium.au3`.

Se preferisci passare l'icona da riga di comando invece di usare `#pragma`,
il parametro è `/icon`:
```
Aut2exe /in X-VSCodium.au3 /out X-VSCodium.exe /icon vscodium.ico /x64
```
In questo caso il parametro `/icon` **sovrascrive** quello in `#pragma compile`.

---

## 4. Compilazione con COMPILA.bat

Il metodo più semplice. Esegui `COMPILA.bat` con doppio click oppure da
prompt dei comandi nella cartella del progetto:

```cmd
cd percorso\del\progetto
COMPILA.bat
```

Il batch esegue automaticamente questi passaggi:

**[1/4] Verifica prerequisiti**
Controlla che `X-VSCodium.au3`, `vscodium.ico` e `Aut2Exe` esistano.
Cerca `Aut2exe_x64.exe` e `7z.exe` nei percorsi standard di installazione.

**[2/4] Compilazione**
Esegue Aut2Exe e genera `X-VSCodium.exe` con icona incorporata.
Usa il flag `/nopack` (niente UPX) per massima compatibilità antivirus.

**[3/4] Verifica exe**
Controlla che il file sia un eseguibile PE valido (header `MZ`).

**[4/4] Packaging ZIP**
Crea la struttura di cartelle corretta per winPenPack e la comprime in
`X-VSCodium_winpenpack.zip` pronto per la distribuzione.

### Personalizzare i percorsi

Se AutoIt o 7-Zip non sono nei percorsi standard, modifica le variabili
nella sezione `CONFIGURAZIONE` in cima a `COMPILA.bat`:

```batch
:: Imposta manualmente se la ricerca automatica fallisce
set "AUT2EXE=C:\Tools\AutoIt3\Aut2Exe\Aut2exe_x64.exe"
set "SEVENZIP=C:\Tools\7-Zip\7z.exe"
```

---

## 5. Compilazione manuale

Se preferisci non usare `COMPILA.bat`, puoi compilare direttamente da:

### SciTE4AutoIt3

1. Apri `X-VSCodium.au3` con SciTE4AutoIt3
2. **Tools → Compile** (F7)
3. Aut2Exe legge automaticamente le direttive `#pragma compile` dal sorgente
4. L'output sarà `X-VSCodium.exe` nella stessa cartella

### Riga di comando

```cmd
"C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2exe_x64.exe" ^
  /in  "X-VSCodium.au3"  ^
  /out "X-VSCodium.exe"  ^
  /icon "vscodium.ico"   ^
  /x64                   ^
  /nopack
```

### Packaging manuale con 7-Zip

Dopo la compilazione, crea la struttura:

```
_pacchetto\
  Bin\
    X-VSCodium\
      X-VSCodium.exe
      X-VSCodium.ini
      README-X-VSCodium.md
  User\
    X-VSCodium\
  Temp\
    X-VSCodium\
```

Poi comprimi la cartella `_pacchetto\` in ZIP:

```cmd
"C:\Program Files\7-Zip\7z.exe" a -tzip -mx=9 ^
  X-VSCodium_winpenpack.zip ^
  _pacchetto\*
```

---

## 6. Struttura del pacchetto distribuito

Il file `X-VSCodium_winpenpack.zip` deve contenere esattamente:

```
Bin\
  X-VSCodium\
    X-VSCodium.exe          ← launcher compilato (~1.5 MB)
    X-VSCodium.ini          ← configurazione X-Launcher
    README-X-VSCodium.md    ← guida utente
User\
  X-VSCodium\
    .placeholder            ← mantiene la cartella nello ZIP
Temp\
  X-VSCodium\
    .placeholder
```

L'utente estrae lo ZIP nella **root di winPenPack** (non dentro `Bin\`),
in modo che la struttura si sovrapponga correttamente a quella esistente:

```
winPenPack\             ← radice winPenPack esistente
├── Bin\
│   └── X-VSCodium\    ← estratto dallo ZIP
├── User\
│   └── X-VSCodium\    ← estratto dallo ZIP
└── Temp\
    └── X-VSCodium\    ← estratto dallo ZIP
```

---

## 7. Come testare prima di distribuire

### Test rapido in locale

1. Crea una cartella di test che simuli winPenPack:
   ```
   C:\test-wpp\
     Bin\
       X-VSCodium\
         X-VSCodium.exe
         X-VSCodium.ini
   ```
2. Avvia `X-VSCodium.exe`
3. Verifica che appaia il dialogo di conferma download
4. Conferma e attendi il download completo
5. Verifica che VSCodium si avvii correttamente
6. Chiudi VSCodium
7. Verifica che la struttura `data\` sia stata creata

### Checklist pre-distribuzione

- [ ] `X-VSCodium.exe` ha l'icona VSCodium visibile (click destro → Proprietà → scheda generale)
- [ ] Il dialogo di conferma mostra il percorso corretto di installazione
- [ ] Il download completa senza errori
- [ ] L'estrazione crea `VSCodium-win32-x64\codium.exe`
- [ ] La cartella `data\` viene creata con le sottocartelle
- [ ] VSCodium si avvia e la barra del titolo mostra "VSCodium"
- [ ] Il campo `Version` in `X-VSCodium.ini` viene aggiornato automaticamente
- [ ] Chiudendo VSCodium, l'exe termina senza errori
- [ ] Al secondo avvio, VSCodium parte direttamente senza riscaricare

---

## 8. Aggiornare la versione nel sorgente

Quando vuoi rilasciare una nuova versione del **launcher** (non di VSCodium,
che si aggiorna da solo), aggiorna la direttiva in `X-VSCodium.au3`:

```autoit
#pragma compile(FileVersion, 1.1.0.0)   ; aggiorna qui
```

Non è necessario aggiornare il numero di versione di VSCodium in `X-VSCodium.ini`
poiché viene sovrascritto automaticamente dallo script al primo avvio.

---

## 9. Note sull'icona

L'icona `vscodium.ico` è inclusa nel pacchetto sorgente e contiene
le dimensioni standard Windows: **256×256, 64×64, 48×48, 32×32, 16×16** pixel,
tutte in formato RGBA a 32-bit.

Il formato 256×256 è salvato come **PNG compresso** dentro l'ICO (standard
Windows Vista+), le altre dimensioni come bitmap DIB.

Se vuoi sostituire l'icona con quella ufficiale dal repository VSCodium,
scaricala da:
```
https://raw.githubusercontent.com/VSCodium/icons/main/icons/win32/nobg/blue/paulo22s.ico
```
e salvala come `vscodium.ico` nella cartella del progetto prima di compilare.

---

## 10. Falsi positivi antivirus

I compilati AutoIt sono spesso segnalati come falsi positivi da vari antivirus
(in particolare Windows Defender, Avast, AVG). Questo è un problema noto e
documentato, non indica la presenza di malware.

Il codice sorgente `X-VSCodium.au3` è completamente leggibile e verificabile.

Per ridurre i falsi positivi:
- Usa `/nopack` in Aut2Exe (niente compressione UPX) — già impostato in `COMPILA.bat`
- Non usare `#RequireAdmin` se non necessario — in questo caso è necessario
  per poter scrivere nella struttura di winPenPack
- Considera la firma code signing del .exe se hai un certificato disponibile

Se VirusTotal segnala il file, puoi inviarlo come falso positivo ai vendor
direttamente dalla pagina dei risultati.

---

*Guida per sviluppatori — X-VSCodium per winPenPack*
