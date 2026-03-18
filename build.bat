@echo off
setlocal

set AUT2EXE="C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2exe_x64.exe"
set SRC=X-VSCodium.au3
set OUT=X-VSCodium.exe
set ICON=icons\vscodium.ico

echo Compilazione %SRC% ...

if not exist %AUT2EXE% (
    echo ERRORE: Aut2exe_x64.exe non trovato in:
    echo   %AUT2EXE%
    echo Installare AutoIt3 64-bit da https://www.autoitscript.com/site/autoit/downloads/
    pause
    exit /b 1
)

if not exist "%ICON%" (
    echo ERRORE: icona non trovata: %ICON%
    echo Copiare il file .ico nella cartella icons\ prima di compilare.
    pause
    exit /b 1
)

%AUT2EXE% /in "%SRC%" /out "%OUT%" /icon "%ICON%" /x64

if errorlevel 1 (
    echo.
    echo ERRORE: compilazione fallita.
    pause
    exit /b 1
)

echo.
echo OK: %OUT% creato con successo.
pause
endlocal
