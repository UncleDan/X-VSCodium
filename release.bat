@echo off
setlocal

rem ============================================================
rem release.bat - Crea il pacchetto di distribuzione X-VSCodium
rem
rem Crea release\X-VSCodium_<versione>_win64.zip contenente:
rem   X-VSCodium.exe
rem   X-VSCodium.ini
rem   Bin\**  (esclusi i file *.txt placeholder)
rem
rem Requisiti: 7-Zip installato
rem ============================================================

set VERSION=1.5.4_rev1beta_win64
set ZIPNAME=X-VSCodium_%VERSION%.zip
set OUTDIR=release
set SEVENZIP="C:\Program Files\7-Zip\7z.exe"

rem --- Verifica 7-Zip ---
if not exist %SEVENZIP% set SEVENZIP="C:\Program Files (x86)\7-Zip\7z.exe"
if not exist %SEVENZIP% (
    echo ERRORE: 7-Zip non trovato.
    echo Installare 7-Zip da https://www.7-zip.org/ oppure aggiornare
    echo la variabile SEVENZIP in questo script con il percorso corretto.
    pause
    exit /b 1
)

rem --- Verifica X-VSCodium.exe ---
if not exist "X-VSCodium.exe" (
    echo ERRORE: X-VSCodium.exe non trovato.
    echo Compilare prima il launcher con build.bat.
    pause
    exit /b 1
)

rem --- Verifica Bin\VSCodium\VSCodium.exe ---
if not exist "Bin\VSCodium\VSCodium.exe" (
    echo ERRORE: Bin\VSCodium\VSCodium.exe non trovato.
    echo Estrarre i binari di VSCodium in Bin\VSCodium\ prima di creare il pacchetto.
    pause
    exit /b 1
)

rem --- Crea cartella release ---
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

rem --- Rimuovi zip precedente se esiste ---
if exist "%OUTDIR%\%ZIPNAME%" (
    echo Rimozione zip precedente: %OUTDIR%\%ZIPNAME%
    del /f /q "%OUTDIR%\%ZIPNAME%"
)

echo Creazione %OUTDIR%\%ZIPNAME% ...
echo.

rem --- Aggiungi X-VSCodium.exe ---
%SEVENZIP% a "%OUTDIR%\%ZIPNAME%" "X-VSCodium.exe" -mx=5
if errorlevel 1 goto :error

rem --- Aggiungi X-VSCodium.ini ---
%SEVENZIP% a "%OUTDIR%\%ZIPNAME%" "X-VSCodium.ini" -mx=5
if errorlevel 1 goto :error

rem --- Aggiungi Bin\ escludendo i file *.txt placeholder ---
%SEVENZIP% a "%OUTDIR%\%ZIPNAME%" "Bin\*" -r -mx=5 ^
    -xr!"*.placeholder.txt"
if errorlevel 1 goto :error

echo.
echo OK: %OUTDIR%\%ZIPNAME% creato con successo.
echo.

rem --- Mostra dimensione e contenuto ---
%SEVENZIP% l "%OUTDIR%\%ZIPNAME%"

endlocal
exit /b 0

:error
echo.
echo ERRORE: creazione zip fallita.
pause
endlocal
exit /b 1
