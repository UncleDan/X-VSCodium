@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1
title X-VSCodium - Compilazione e packaging

echo.
echo  ╔══════════════════════════════════════════════════════╗
echo  ║   X-VSCodium - Build Script per winPenPack          ║
echo  ║   Compila X-VSCodium.au3 e crea il pacchetto ZIP    ║
echo  ╚══════════════════════════════════════════════════════╝
echo.

:: ===========================================================================
:: CONFIGURAZIONE — modifica questi percorsi se necessario
:: ===========================================================================

:: Percorso di Aut2Exe (compilatore AutoIt)
:: Prova le posizioni standard di installazione
set "AUT2EXE="
if exist "%ProgramFiles(x86)%\AutoIt3\Aut2Exe\Aut2exe_x64.exe" (
    set "AUT2EXE=%ProgramFiles(x86)%\AutoIt3\Aut2Exe\Aut2exe_x64.exe"
) else if exist "%ProgramFiles(x86)%\AutoIt3\Aut2Exe\Aut2exe.exe" (
    set "AUT2EXE=%ProgramFiles(x86)%\AutoIt3\Aut2Exe\Aut2exe.exe"
) else if exist "%ProgramFiles%\AutoIt3\Aut2Exe\Aut2exe_x64.exe" (
    set "AUT2EXE=%ProgramFiles%\AutoIt3\Aut2Exe\Aut2exe_x64.exe"
) else if exist "%ProgramFiles%\AutoIt3\Aut2Exe\Aut2exe.exe" (
    set "AUT2EXE=%ProgramFiles%\AutoIt3\Aut2Exe\Aut2exe.exe"
)

:: Percorso di 7-Zip per il packaging finale
set "SEVENZIP="
if exist "%ProgramFiles%\7-Zip\7z.exe"        set "SEVENZIP=%ProgramFiles%\7-Zip\7z.exe"
if exist "%ProgramFiles(x86)%\7-Zip\7z.exe"   set "SEVENZIP=%ProgramFiles(x86)%\7-Zip\7z.exe"

:: File sorgente e output
set "SCRIPT_DIR=%~dp0"
set "SOURCE=%SCRIPT_DIR%X-VSCodium.au3"
set "ICON=%SCRIPT_DIR%vscodium.ico"
set "OUTPUT_EXE=%SCRIPT_DIR%X-VSCodium.exe"
set "OUTPUT_ZIP=%SCRIPT_DIR%X-VSCodium_winpenpack.zip"

:: ===========================================================================
:: VERIFICA PREREQUISITI
:: ===========================================================================

echo [1/4] Verifica prerequisiti...
echo.

:: Verifica sorgente .au3
if not exist "%SOURCE%" (
    echo  [ERRORE] File sorgente non trovato:
    echo           %SOURCE%
    goto :error
)
echo  [OK] Sorgente: %SOURCE%

:: Verifica icona
if not exist "%ICON%" (
    echo  [ERRORE] File icona non trovato:
    echo           %ICON%
    echo.
    echo  Assicurati che vscodium.ico sia nella stessa cartella
    echo  di questo file .bat
    goto :error
)
echo  [OK] Icona:    %ICON%

:: Verifica Aut2Exe
if "%AUT2EXE%"=="" (
    echo  [ERRORE] Aut2Exe non trovato.
    echo.
    echo  Installa AutoIt da: https://www.autoitscript.com/site/autoit/downloads/
    echo  oppure imposta manualmente il percorso nella variabile AUT2EXE
    echo  nella sezione CONFIGURAZIONE di questo file .bat
    goto :error
)
echo  [OK] Aut2Exe:  %AUT2EXE%

:: Verifica 7-Zip (solo per il packaging, non blocca la compilazione)
if "%SEVENZIP%"=="" (
    echo  [WARN] 7-Zip non trovato - il pacchetto ZIP non verra' creato.
    echo         Installa 7-Zip da: https://www.7-zip.org/
) else (
    echo  [OK] 7-Zip:    %SEVENZIP%
)
echo.

:: ===========================================================================
:: COMPILAZIONE
:: ===========================================================================

echo [2/4] Compilazione X-VSCodium.au3 ...
echo.

:: Rimuovi exe precedente se esiste
if exist "%OUTPUT_EXE%" (
    echo  Rimozione exe precedente...
    del /f /q "%OUTPUT_EXE%"
)

:: Compila con Aut2Exe
:: /in  = sorgente
:: /out = destinazione
:: /icon = icona (sovrascrive quella in #pragma compile se specificata)
:: /x64 = target 64-bit
:: /nopack = non usare UPX (più compatibile con antivirus)
echo  Esecuzione: Aut2exe ...
"%AUT2EXE%" /in "%SOURCE%" /out "%OUTPUT_EXE%" /icon "%ICON%" /x64 /nopack

if errorlevel 1 (
    echo.
    echo  [ERRORE] Compilazione fallita. Controlla il sorgente .au3
    goto :error
)

if not exist "%OUTPUT_EXE%" (
    echo.
    echo  [ERRORE] Il file .exe non e' stato generato.
    goto :error
)

:: Mostra dimensione exe
for %%F in ("%OUTPUT_EXE%") do (
    set /a "SIZE_KB=%%~zF/1024"
    echo  [OK] Compilazione completata: X-VSCodium.exe (!SIZE_KB! KB^)
)
echo.

:: ===========================================================================
:: VERIFICA EXE
:: ===========================================================================

echo [3/4] Verifica dell'eseguibile...
echo.

:: Controlla che l'exe sia un PE valido (legge i primi 2 byte: "MZ")
for /f "tokens=*" %%i in ('powershell -NoProfile -Command ^
    "[System.IO.File]::ReadAllBytes('%OUTPUT_EXE%')[0..1] -join ','"') do (
    set "MAGIC=%%i"
)

if "!MAGIC!"=="77,90" (
    echo  [OK] Eseguibile valido ^(header MZ confermato^)
) else (
    echo  [WARN] Impossibile verificare l'header dell'exe.
    echo         Controlla manualmente che X-VSCodium.exe funzioni.
)
echo.

:: ===========================================================================
:: CREAZIONE PACCHETTO ZIP
:: ===========================================================================

echo [4/4] Creazione pacchetto ZIP...
echo.

if "%SEVENZIP%"=="" (
    echo  [SKIP] 7-Zip non disponibile - pacchetto ZIP non creato.
    echo         Puoi creare manualmente un archivio con:
    echo           X-VSCodium.exe
    echo           X-VSCodium.ini
    echo           README-X-VSCodium.md
    goto :done
)

:: Rimuovi zip precedente
if exist "%OUTPUT_ZIP%" del /f /q "%OUTPUT_ZIP%"

:: Verifica che i file necessari esistano
set "FILES_OK=1"
for %%F in ("X-VSCodium.exe" "X-VSCodium.ini" "README-X-VSCodium.md") do (
    if not exist "%SCRIPT_DIR%%%F" (
        echo  [WARN] File mancante: %%F
        set "FILES_OK=0"
    )
)

:: Crea la struttura del pacchetto in una cartella temporanea
set "PKG_DIR=%SCRIPT_DIR%_pkg_temp\"
if exist "%PKG_DIR%" rmdir /s /q "%PKG_DIR%"
mkdir "%PKG_DIR%Bin\X-VSCodium\"

:: Copia i file nel pacchetto
copy /y "%SCRIPT_DIR%X-VSCodium.exe"          "%PKG_DIR%Bin\X-VSCodium\" >nul
copy /y "%SCRIPT_DIR%X-VSCodium.ini"          "%PKG_DIR%Bin\X-VSCodium\" >nul
if exist "%SCRIPT_DIR%README-X-VSCodium.md" (
    copy /y "%SCRIPT_DIR%README-X-VSCodium.md" "%PKG_DIR%Bin\X-VSCodium\" >nul
)

:: Crea le cartelle User e Temp (vuote, servono a winPenPack)
mkdir "%PKG_DIR%User\X-VSCodium\"
mkdir "%PKG_DIR%Temp\X-VSCodium\"

:: Crea un placeholder nelle cartelle vuote (7-Zip ignora le cartelle vuote)
echo. > "%PKG_DIR%User\X-VSCodium\.placeholder"
echo. > "%PKG_DIR%Temp\X-VSCodium\.placeholder"

echo  Struttura del pacchetto:
echo    Bin\X-VSCodium\X-VSCodium.exe
echo    Bin\X-VSCodium\X-VSCodium.ini
echo    Bin\X-VSCodium\README-X-VSCodium.md
echo    User\X-VSCodium\
echo    Temp\X-VSCodium\
echo.

:: Comprimi con 7-Zip
echo  Compressione in corso...
"%SEVENZIP%" a -tzip -mx=9 "%OUTPUT_ZIP%" "%PKG_DIR%*" >nul 2>&1

:: Pulizia cartella temporanea
rmdir /s /q "%PKG_DIR%"

if not exist "%OUTPUT_ZIP%" (
    echo  [ERRORE] Creazione ZIP fallita.
    goto :error
)

for %%F in ("%OUTPUT_ZIP%") do (
    set /a "ZIP_KB=%%~zF/1024"
    echo  [OK] Pacchetto creato: X-VSCodium_winpenpack.zip (!ZIP_KB! KB^)
)

:: ===========================================================================
:: DONE
:: ===========================================================================

:done
echo.
echo  ╔══════════════════════════════════════════════════════╗
echo  ║   Build completato con successo!                    ║
echo  ╠══════════════════════════════════════════════════════╣
echo  ║                                                      ║
echo  ║   File generati:                                     ║
echo  ║     X-VSCodium.exe       <- copia in Bin\X-VSCodium\║
echo  ║     X-VSCodium_winpenpack.zip  <- distribuisci questo║
echo  ║                                                      ║
echo  ║   L'utente finale deve solo:                        ║
echo  ║     1. Estrarre lo ZIP nella root di winPenPack     ║
echo  ║     2. Avviare Bin\X-VSCodium\X-VSCodium.exe       ║
echo  ║     3. VSCodium si scarica automaticamente          ║
echo  ╚══════════════════════════════════════════════════════╝
echo.
pause
exit /b 0

:error
echo.
echo  ╔══════════════════════════════════════════════════════╗
echo  ║   [ERRORE] Build interrotto.                        ║
echo  ╚══════════════════════════════════════════════════════╝
echo.
pause
exit /b 1
