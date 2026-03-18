; ============================================================
; X-VSCodium.au3 - Portable VSCodium Launcher
; Version: 1.5.4 rev1beta
; Based on X-Notepad++ launcher 1.5.4 rev18beta (winPenPack)
; Adapted for VSCodium 1.110.11631 (win64)
;
; MECCANISMO DI PORTABILITÀ:
; VSCodium supporta la portable mode nativa tramite la cartella
; Bin\data\ nella stessa directory dell'eseguibile.
; Se data\ esiste, VSCodium usa:
;   data\user-data\  → configurazione, settings, temi, keybindings
;   data\extensions\ → estensioni installate
;   data\tmp\        → file temporanei (opzionale)
; Non sono necessari parametri --user-data-dir o --extensions-dir.
;
; Il launcher si occupa di:
;   - verificare/creare le sottocartelle di data\ al primo avvio
;   - gestione PID-file per operazioni post-run multi-istanza
;   - PathNormalize di settings.json e workspace state
;
; ISTANZE MULTIPLE:
; VSCodium supporta istanze multiple native (ogni finestra è
; indipendente). Con un solo data\ condiviso, tutte le istanze
; usano la stessa configurazione — comportamento corretto e atteso.
;
; winPenPack License: http://www.winpenpack.com/en/page.php?5
; ============================================================
;
; #AutoIt3Wrapper_Compression=4
; #AutoIt3Wrapper_UseX64=Y
; #AutoIt3Wrapper_Icon=icons\code.ico
; #AutoIt3Wrapper_Res_Description=X-VSCodium - Portable VSCodium
; #AutoIt3Wrapper_Res_Fileversion=1.5.4.0
; #AutoIt3Wrapper_Res_ProductVersion=1.5.4 rev1beta
; #AutoIt3Wrapper_Res_LegalCopyright=winPenPack License
; #AutoIt3Wrapper_Language=1033
; #AutoIt3Wrapper_Res_Language=1033

#include <File.au3>
#include <String.au3>
#include <WinAPI.au3>
#include <Constants.au3>

; -------------------------------------------------------
; Risolve il .ini con lo stesso nome base del .exe corrente
; -------------------------------------------------------
Global $sScriptBase = StringTrimRight(@ScriptFullPath, StringLen(@ScriptExt) + 1)
Global $sIniFile    = $sScriptBase & ".ini"

If Not FileExists($sIniFile) Then
    MsgBox(16, "X-VSCodium Error", "INI file not found:" & @CRLF & $sIniFile)
    Exit 1
EndIf

; -------------------------------------------------------
; Percorsi di sistema
; -------------------------------------------------------
Global $sProgramDir   = @ScriptDir
Global $sLocalAppData = @LocalAppDataDir
Global $sAppData      = @AppDataDir
Global $sTempDir      = @TempDir

; -------------------------------------------------------
; Lettura INI
; -------------------------------------------------------
Global $sProgramExe    = IniRead($sIniFile, "Launch", "ProgramExecutable", "Bin\VSCodium\VSCodium.exe")
Global $sProgramParams = IniRead($sIniFile, "Launch", "ProgramParameters", "")
Global $sWorkingDir    = IniRead($sIniFile, "Launch", "WorkingDirectory",  $sProgramDir & "\Bin\VSCodium")

; -------------------------------------------------------
; Espansione placeholder
; -------------------------------------------------------
$sWorkingDir    = StringReplace($sWorkingDir,    "%ProgramDir%", $sProgramDir)
$sProgramParams = StringReplace($sProgramParams, "%ProgramDir%", $sProgramDir)
$sProgramParams = StringReplace($sProgramParams, "%LocalAppData%", $sLocalAppData)
$sProgramParams = StringReplace($sProgramParams, "%AppData%",    $sAppData)
$sProgramParams = StringReplace($sProgramParams, "%Temp%",       $sTempDir)

; -------------------------------------------------------
; Percorsi cartelle data\ portabili
; data\ si trova nella stessa cartella di VSCodium.exe
; -------------------------------------------------------
Global $sDataDir       = $sProgramDir & "\Bin\VSCodium\data"
Global $sUserDataDir   = $sDataDir & "\user-data"
Global $sExtensionsDir = $sDataDir & "\extensions"
Global $sTmpDir        = $sDataDir & "\tmp"

; -------------------------------------------------------
; Percorso completo eseguibile
; -------------------------------------------------------
Global $sExeFullPath = $sProgramDir & "\" & $sProgramExe

If Not FileExists($sExeFullPath) Then
    MsgBox(16, "X-VSCodium Error", _
        "VSCodium.exe non trovato." & @CRLF & @CRLF & _
        "Percorso atteso:" & @CRLF & $sExeFullPath & @CRLF & @CRLF & _
        "Copiare i binari di VSCodium in:" & @CRLF & _
        $sProgramDir & "\Bin\VSCodium\")
    Exit 1
EndIf

; -------------------------------------------------------
; Pre-avvio: crea struttura data\ se mancante
;
; La presenza di data\ attiva la portable mode di VSCodium.
; Le sottocartelle vengono create se non esistono.
; -------------------------------------------------------
If Not FileExists($sDataDir)       Then DirCreate($sDataDir)
If Not FileExists($sUserDataDir)   Then DirCreate($sUserDataDir)
If Not FileExists($sExtensionsDir) Then DirCreate($sExtensionsDir)
If Not FileExists($sTmpDir)        Then DirCreate($sTmpDir)

; -------------------------------------------------------
; Pre-avvio: PID-file — registra questa istanza del launcher
;
; VSCodium non ha risorse condivise tra istanze che richiedano
; protezione (nessun singleton, nessun updater da gestire).
; Il PID-file è mantenuto per coerenza architetturale con gli
; altri launcher della serie e per eventuali estensioni future.
; -------------------------------------------------------
Global $sPidDir  = $sProgramDir & "\Bin\VSCodium\data"
Global $sPidFile = $sPidDir & "\.launcher." & @ProcessID & ".pid"

Local $hPid = FileOpen($sPidFile, 2)
FileWrite($hPid, @ProcessID)
FileClose($hPid)

; -------------------------------------------------------
; Funzione: verifica se altri launcher del pacchetto sono attivi
; -------------------------------------------------------
Func _OtherLaunchersActive()
    Local $aFiles = _FileListToArray($sPidDir, ".launcher.*.pid", 1)
    If @error Then Return False
    Return ($aFiles[0] > 0)
EndFunc

; -------------------------------------------------------
; Avvio VSCodium
; -------------------------------------------------------
Global $iPID = Run('"' & $sExeFullPath & '" ' & $sProgramParams, $sWorkingDir)

If $iPID = 0 Then
    FileDelete($sPidFile)
    MsgBox(16, "X-VSCodium Error", _
        "Impossibile avviare VSCodium." & @CRLF & @CRLF & _
        "Comando: " & $sExeFullPath & @CRLF & _
        "Parametri: " & $sProgramParams)
    Exit 1
EndIf

; -------------------------------------------------------
; Attesa chiusura VSCodium — usa PID specifico
;
; VSCodium (basato su Electron) lancia processi figlio multipli
; (renderer, extension host, ecc.). ProcessWaitClose($iPID) attende
; solo il processo padre — i figli terminano autonomamente.
; L'attesa aggiuntiva copre il flush dei file di configurazione
; (settings.json, keybindings.json, workspace storage).
; -------------------------------------------------------
If $iPID > 0 Then
    ProcessWaitClose($iPID)
    Local $iWait = TimerInit()
    While TimerDiff($iWait) < 2000
        Sleep(200)
    WEnd
EndIf

; -------------------------------------------------------
; Post-chiusura: rimuovi PID-file di questo launcher
; DEVE avvenire prima di _OtherLaunchersActive()
; -------------------------------------------------------
FileDelete($sPidFile)

; -------------------------------------------------------
; Post-chiusura: pulizia file lock di VSCodium
;
; VSCodium/Electron crea file di lock in data\user-data\.
; Vengono rimossi solo all'ultima istanza chiusa per non
; interferire con altre istanze ancora aperte.
; -------------------------------------------------------
If Not _OtherLaunchersActive() Then
    FileDelete($sUserDataDir & "\User\globalStorage\state.vscdb.backup")
    ; Rimuovi eventuali file .lock residui da crash
    Local $aLocks = _FileListToArray($sUserDataDir, "*.lock", 1)
    If Not @error Then
        For $i = 1 To $aLocks[0]
            FileDelete($sUserDataDir & "\" & $aLocks[$i])
        Next
    EndIf
EndIf

Exit 0
