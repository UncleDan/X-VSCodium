; ==============================================================================
;  X-VSCodium.au3 - winPenPack launcher per VSCodium con download automatico
;  Versione: 1.0
;
;  Al primo avvio scarica automaticamente l'ultima versione di VSCodium
;  da GitHub, la estrae e configura la portable mode.
;  Dagli avvii successivi avvia direttamente codium.exe.
;
;  === COMPILAZIONE ===
;  Usa il file COMPILA.bat incluso nel pacchetto, oppure manualmente:
;    Aut2exe /in X-VSCodium.au3 /out X-VSCodium.exe /icon vscodium.ico /x64
;  L'icona vscodium.ico deve trovarsi nella stessa cartella di questo file.
; ==============================================================================

; --- Direttive compilatore (incorporate icona e metadati nel .exe) -----------
#pragma compile(Icon,        vscodium.ico)
#pragma compile(Out,         X-VSCodium.exe)
#pragma compile(x64,         true)
#pragma compile(UPX,         false)
#pragma compile(FileVersion, 1.0.0.0)
#pragma compile(ProductName, X-VSCodium)
#pragma compile(CompanyName, winPenPack)
#pragma compile(LegalCopyright, MIT - VSCodium Community)
#pragma compile(FileDescription, winPenPack X-Launcher per VSCodium)

#NoTrayIcon
#RequireAdmin

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ProgressConstants.au3>
#include <StaticConstants.au3>
#include <InetConstants.au3>
#include <MsgBoxConstants.au3>

; --- Costanti -----------------------------------------------------------------
Global Const $APP_NAME       = "VSCodium"
Global Const $APP_EXE        = "codium.exe"
Global Const $APP_SUBDIR     = "VSCodium-win32-x64"
Global Const $GITHUB_API_URL = "https://api.github.com/repos/VSCodium/vscodium/releases/latest"
Global Const $DOWNLOAD_MASK  = "https://github.com/VSCodium/vscodium/releases/download/%s/VSCodium-win32-x64-%s.zip"
Global Const $ZIP_NAME       = "VSCodium-win32-x64-latest.zip"
Global Const $INI_FILE       = "X-VSCodium.ini"

; --- Percorsi derivati --------------------------------------------------------
Global $sLauncherDir = @ScriptDir
Global $sWppRoot     = _GetWppRoot($sLauncherDir)
Global $sBinDir      = $sLauncherDir & "\" & $APP_SUBDIR & "\"
Global $sAppExe      = $sBinDir & $APP_EXE
Global $sDataDir     = $sBinDir & "data\"
Global $sTempDir     = $sWppRoot & "Temp\X-VSCodium\"
Global $s7zExe       = $sWppRoot & "App\7-Zip\7z.exe"
Global $sZipPath     = $sTempDir & $ZIP_NAME

; ==============================================================================
_Main()

Func _Main()
    If Not FileExists($sAppExe) Then
        _FirstRunSetup()
    EndIf
    _LaunchVSCodium()
EndFunc

; ==============================================================================
;  PRIMO AVVIO
; ==============================================================================
Func _FirstRunSetup()
    Local $iAnswer = MsgBox( _
        $MB_YESNO + $MB_ICONQUESTION + $MB_TOPMOST, _
        $APP_NAME & " - winPenPack", _
        $APP_NAME & " non e' ancora installato." & @CRLF & @CRLF & _
        "Vuoi scaricarlo adesso da GitHub?" & @CRLF & @CRLF & _
        "Verra' scaricata l'ultima versione disponibile" & @CRLF & _
        "e installata automaticamente in:" & @CRLF & _
        $sBinDir & @CRLF & @CRLF & _
        "E' richiesta una connessione a Internet." _
    )
    If $iAnswer <> $IDYES Then
        MsgBox($MB_ICONINFORMATION + $MB_TOPMOST, $APP_NAME & " - winPenPack", _
            "Installazione annullata." & @CRLF & _
            "Esegui nuovamente X-VSCodium.exe quando sei pronto.")
        Exit 0
    EndIf

    Local $sVersion = _GetLatestVersion()
    If $sVersion = "" Then
        MsgBox($MB_ICONERROR + $MB_TOPMOST, $APP_NAME & " - Errore", _
            "Impossibile ottenere la versione piu' recente da GitHub." & @CRLF & @CRLF & _
            "Controlla la connessione a Internet e riprova.")
        Exit 1
    EndIf

    Local $sDownloadURL = StringFormat($DOWNLOAD_MASK, $sVersion, $sVersion)

    DirCreate($sBinDir)
    DirCreate($sTempDir)

    _DownloadWithProgress($sDownloadURL, $sZipPath, $sVersion)
    _ExtractZip($sZipPath, $sBinDir)
    _CreatePortableStructure()
    _UpdateIniVersion($sVersion)

    FileDelete($sZipPath)

    MsgBox($MB_ICONINFORMATION + $MB_TOPMOST, $APP_NAME & " - winPenPack", _
        $APP_NAME & " " & $sVersion & " installato con successo!" & @CRLF & @CRLF & _
        "Modalita' portable attiva: le impostazioni" & @CRLF & _
        "saranno salvate nella cartella data\." & @CRLF & @CRLF & _
        "Avvio in corso...")
EndFunc

; ==============================================================================
;  RECUPERO VERSIONE DA GITHUB API
; ==============================================================================
Func _GetLatestVersion()
    Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
    If Not IsObj($oHTTP) Then Return ""
    $oHTTP.Open("GET", $GITHUB_API_URL, False)
    $oHTTP.SetRequestHeader("User-Agent", "winPenPack-X-VSCodium/1.0")
    $oHTTP.SetRequestHeader("Accept", "application/vnd.github.v3+json")
    $oHTTP.Send()
    If $oHTTP.Status <> 200 Then Return ""
    Local $aMatch = StringRegExp($oHTTP.ResponseText, '"tag_name"\s*:\s*"([^"]+)"', 3)
    If @error Or Not IsArray($aMatch) Or UBound($aMatch) < 1 Then Return ""
    Return $aMatch[0]
EndFunc

; ==============================================================================
;  DOWNLOAD CON PROGRESS BAR
; ==============================================================================
Func _DownloadWithProgress($sURL, $sDestFile, $sVersion)
    Local $hGUI = GUICreate($APP_NAME & " - Download in corso...", 480, 130, -1, -1, _
        $WS_CAPTION + $WS_SYSMENU, $WS_EX_TOPMOST)
    GUISetBkColor(0xFFFFFF)

    Local $hLblTitle = GUICtrlCreateLabel("Download " & $APP_NAME & " " & $sVersion, 15, 12, 450, 22)
    GUICtrlSetFont($hLblTitle, 10, 700)

    Local $hLblStatus = GUICtrlCreateLabel("Connessione in corso...", 15, 38, 450, 18)
    Local $hProgress  = GUICtrlCreateProgress(15, 62, 450, 20, $PBS_SMOOTH)
    Local $hLblSize   = GUICtrlCreateLabel("", 15, 88, 450, 18)
    GUICtrlSetFont($hLblSize, 8)

    ; Icona nella finestra (usa l'icona incorporata nel .exe stesso)
    GUISetIcon(@ScriptFullPath, 0)
    GUISetState(@SW_SHOW, $hGUI)

    Local $hDownload = InetGet($sURL, $sDestFile, $INET_FORCERELOAD, 1)
    If @error Then
        GUIDelete($hGUI)
        MsgBox($MB_ICONERROR + $MB_TOPMOST, $APP_NAME & " - Errore download", _
            "Impossibile avviare il download." & @CRLF & "URL: " & $sURL)
        Exit 1
    EndIf

    Local $iBytesTotal, $iBytesRecv, $iPct
    Do
        $iBytesRecv  = InetGetInfo($hDownload, $INET_DOWNLOADREAD)
        $iBytesTotal = InetGetInfo($hDownload, $INET_DOWNLOADSIZE)
        If $iBytesTotal > 0 Then
            $iPct = Int(($iBytesRecv / $iBytesTotal) * 100)
            GUICtrlSetData($hProgress, $iPct)
            GUICtrlSetData($hLblStatus, "Download: " & $iPct & "%")
            GUICtrlSetData($hLblSize, _FormatBytes($iBytesRecv) & " / " & _FormatBytes($iBytesTotal))
        Else
            GUICtrlSetData($hLblStatus, "Download in corso... (" & _FormatBytes($iBytesRecv) & ")")
        EndIf
        Sleep(300)
        GUIGetMsg()
    Until InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)

    InetClose($hDownload)
    GUICtrlSetData($hProgress, 100)
    GUICtrlSetData($hLblStatus, "Download completato.")
    Sleep(400)
    GUIDelete($hGUI)

    If Not FileExists($sDestFile) Or FileGetSize($sDestFile) < 1024 Then
        MsgBox($MB_ICONERROR + $MB_TOPMOST, $APP_NAME & " - Errore", _
            "Il file scaricato non e' valido." & @CRLF & $sDestFile)
        Exit 1
    EndIf
EndFunc

; ==============================================================================
;  ESTRAZIONE ZIP
; ==============================================================================
Func _ExtractZip($sZipFile, $sDestDir)
    DirCreate($sDestDir)

    Local $hGUI = GUICreate($APP_NAME & " - Estrazione...", 480, 90, -1, -1, $WS_CAPTION, $WS_EX_TOPMOST)
    GUISetBkColor(0xFFFFFF)
    GUISetIcon(@ScriptFullPath, 0)
    GUICtrlCreateLabel("Estrazione dell'archivio in corso...", 15, 15, 450, 20)
    Local $hProgress = GUICtrlCreateProgress(15, 45, 450, 20, $PBS_MARQUEE)
    GUICtrlSetState($hProgress, $GUI_DISABLE)
    GUISetState(@SW_SHOW, $hGUI)

    Local $bOK = False

    ; Tentativo 1: 7-Zip (veloce e affidabile)
    If FileExists($s7zExe) Then
        Local $iPID = Run('"' & $s7zExe & '" x "' & $sZipFile & '" -o"' & $sDestDir & '" -y', _
            $sTempDir, @SW_HIDE)
        ProcessWaitClose($iPID, 180)
        If FileExists($sDestDir & $APP_EXE) Then $bOK = True
    EndIf

    ; Tentativo 2: Shell.Application (nativo Windows, nessuna dipendenza)
    If Not $bOK Then
        Local $oShell = ObjCreate("Shell.Application")
        If IsObj($oShell) Then
            Local $oZip  = $oShell.NameSpace($sZipFile)
            Local $oDest = $oShell.NameSpace($sDestDir)
            If IsObj($oZip) And IsObj($oDest) Then
                $oDest.CopyHere($oZip.Items(), 4 + 16 + 1024)
                Local $iWait = 0
                Do
                    Sleep(2000)
                    $iWait += 2
                Until FileExists($sDestDir & $APP_EXE) Or $iWait >= 300
                If FileExists($sDestDir & $APP_EXE) Then $bOK = True
            EndIf
        EndIf
    EndIf

    GUIDelete($hGUI)

    If Not $bOK Then
        MsgBox($MB_ICONERROR + $MB_TOPMOST, $APP_NAME & " - Errore estrazione", _
            "Impossibile estrarre l'archivio ZIP." & @CRLF & @CRLF & _
            "Prova manualmente:" & @CRLF & $sZipFile & @CRLF & _
            "in: " & $sDestDir & @CRLF & @CRLF & _
            "Per 7-Zip, copiare 7z.exe in:" & @CRLF & $sWppRoot & "App\7-Zip\7z.exe")
        Exit 1
    EndIf
EndFunc

; ==============================================================================
;  STRUTTURA PORTABLE MODE
; ==============================================================================
Func _CreatePortableStructure()
    DirCreate($sDataDir)
    DirCreate($sDataDir & "user-data\")
    DirCreate($sDataDir & "user-data\User\")
    DirCreate($sDataDir & "extensions\")
    DirCreate($sDataDir & "tmp\")
    DirCreate($sWppRoot & "User\X-VSCodium\")
    DirCreate($sWppRoot & "Temp\X-VSCodium\")
EndFunc

; ==============================================================================
;  AGGIORNA VERSIONE NEL FILE INI
; ==============================================================================
Func _UpdateIniVersion($sVersion)
    Local $sIniPath = $sLauncherDir & "\" & $INI_FILE
    If FileExists($sIniPath) Then IniWrite($sIniPath, "Software", "Version", $sVersion)
EndFunc

; ==============================================================================
;  AVVIO VSCODIUM
; ==============================================================================
Func _LaunchVSCodium()
    If Not FileExists($sAppExe) Then
        MsgBox($MB_ICONERROR + $MB_TOPMOST, $APP_NAME & " - Errore", _
            "Impossibile trovare:" & @CRLF & $sAppExe & @CRLF & @CRLF & _
            "Rimuovi la cartella " & $APP_SUBDIR & "\" & @CRLF & _
            "e avvia nuovamente X-VSCodium.exe per riscaricare.")
        Exit 1
    EndIf

    EnvSet("VSCODE_APPDATA",    $sDataDir & "user-data")
    EnvSet("VSCODE_LOGS",       $sDataDir & "logs")
    EnvSet("VSCODE_EXTENSIONS", $sDataDir & "extensions")
    EnvSet("DISABLE_TELEMETRY", "1")

    Local $sCmdArgs = ""
    If $CmdLineRaw <> "" Then $sCmdArgs = " " & $CmdLineRaw

    Local $iPID = Run('"' & $sAppExe & '"' & $sCmdArgs, $sBinDir, @SW_SHOW)
    If $iPID = 0 Then
        MsgBox($MB_ICONERROR + $MB_TOPMOST, $APP_NAME & " - Errore avvio", _
            "Impossibile avviare " & $APP_EXE & ".")
        Exit 1
    EndIf

    ProcessWaitClose($iPID)

    EnvSet("VSCODE_APPDATA",    "")
    EnvSet("VSCODE_LOGS",       "")
    EnvSet("VSCODE_EXTENSIONS", "")
    EnvSet("DISABLE_TELEMETRY", "")
EndFunc

; ==============================================================================
;  UTILITY
; ==============================================================================
Func _GetWppRoot($sDir)
    Local $s = StringRegExpReplace($sDir, "\\[^\\]+$", "")
    Return StringRegExpReplace($s, "\\[^\\]+$", "") & "\"
EndFunc

Func _FormatBytes($iBytes)
    If $iBytes >= 1048576 Then Return StringFormat("%.1f MB", $iBytes / 1048576)
    If $iBytes >= 1024    Then Return StringFormat("%.0f KB", $iBytes / 1024)
    Return $iBytes & " B"
EndFunc
