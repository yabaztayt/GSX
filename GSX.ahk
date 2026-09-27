#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Current version and GitHub repo, used by the auto-updater.
; IMPORTANT: change GITHUB_REPO to your actual user/repo before publishing,
; and bump APP_VERSION with every release you make.
APP_VERSION := "0.3.2"
GITHUB_REPO := "yabaztayt/GSX"

RUN_KEY := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
RUN_VALUE_NAME := "GSX"

; How long to wait (in seconds) after the "polite" Alt+F4 before force-killing
; the process if the window is still open. Adjustable.
FORCE_KILL_GRACE_SEC := 2.0

; ==================== Localization ====================
; Minimal localization: defaults to English everywhere, and only switches
; to Spanish when Windows' own UI language is Spanish (any regional
; variant - Spain, Mexico, Argentina, etc. all share the same primary
; language ID). To add another language later, add a new inner Map to
; STRINGS and extend the UI_LANG check below.
; A_Language isn't reliable here: on many Windows installs it reflects
; the legacy "language for non-Unicode programs" (system locale), which
; can be English even when the actual Windows display language is
; Spanish. GetUserDefaultUILanguage() asks Windows directly for the UI
; language it's actually using for its own menus, so it matches what
; the user sees everywhere else. The low byte of a LANGID is the primary
; language ID; 0x0A is Spanish across every regional variant (Spain,
; Mexico, Argentina, etc.).
IsWindowsSpanishUI() {
    langId := DllCall("kernel32\GetUserDefaultUILanguage", "UShort")
    return (langId & 0xFF) = 0x0A
}
UI_LANG := IsWindowsSpanishUI() ? "es" : "en"

STRINGS := Map(
    "en", Map(
        "tray_about", "About",
        "tray_check_updates", "Check for updates",
        "tray_donations", "Donations",
        "tray_run_startup", "Run at startup",
        "tray_exit", "Exit",

        "about_title", "About",
        "about_body", "GSX v{v}`n`n"
            . "GLOBAL (any mode)`n"
            . "Guide + Start  ->  Close active window (Alt+F4, force-kill if it doesn't respond)`n"
            . "Guide + Back   ->  Toggle mouse mode`n`n"
            . "MOUSE MODE`n"
            . "Left stick        ->  Move cursor`n"
            . "RT / LT           ->  Left / right click (hold)`n"
            . "X                    ->  Middle click (hold)`n"
            . "A / B              ->  Enter / Escape (hold)`n"
            . "D-Pad            ->  Arrow keys (hold)`n"
            . "LB / RB          ->  Scroll up / down`n"
            . "L3 (stick click)  ->  Alt+Tab`n"
            . "R3 (stick click)  ->  Play / Pause`n"
            . "Right stick ↕     ->  Volume`n"
            . "Right stick ↔     ->  Next / previous track`n"
            . "Start (alone)     ->  Windows key`n"
            . "Back (alone)     ->  Tab`n"
            . "Y                    ->  Show/hide on-screen keyboard`n"
            . "   (drag it by its top bar, ?123 for symbols,`n"
            . "   Shift stays locked until you tap it again,`n"
            . "   hold a vowel for á/é/í/ó/ú)`n`n"
            . "Made by Yabazta with Claude AI. 🤖✨",

        "update_check_failed", "Couldn't reach GitHub right now (code {v}). Try again later.",
        "update_up_to_date", "You already have the latest version ({v}).",
        "update_available_title", "GSX - Update available",
        "update_available_body", "A new version is available: {v}`nYou have installed: {v2}",
        "update_open_page_question", "`n`nOpen the downloads page?",
        "update_self_question", "`n`nUpdate now? GSX will close for a moment,`ndownload the new version, and reopen on its own.",
        "update_download_failed", "Couldn't download the update (code {v}).",
        "update_install_failed", "Couldn't install the update: {v}",
        "update_check_error", "Couldn't check for updates: {v}",
        "update_done_title", "Update complete",
        "update_done_body", "GSX was updated to version {v}.",

        "firstrun_title", "Before you continue",
        "firstrun_body", "GSX doesn't need any external program to work: "
            . "it sends Alt+F4 to the active window and, if it doesn't close within a few seconds, "
            . "force-kills the process automatically.`n`n"
            . "It also includes a mouse mode (Guide+Back to toggle it) "
            . "that lets you control the cursor and keyboard with the controller.",
        "firstrun_uncompiled_note", "`n`nSince you're running the .ahk uncompiled, you need AutoHotkey v2 installed.",
        "firstrun_compiled_note", "`n`n(AutoHotkey is already bundled into this .exe, no need to install it separately.)",

        "osk_drag_hint", "  ⠿  GSX Keyboard   ·   drag here to move",
        "osk_space", "Space",
    ),
    "es", Map(
        "tray_about", "Acerca de",
        "tray_check_updates", "Buscar actualizaciones",
        "tray_donations", "Donaciones",
        "tray_run_startup", "Ejecutar al iniciar",
        "tray_exit", "Salir",

        "about_title", "Acerca de",
        "about_body", "GSX v{v}`n`n"
            . "GLOBAL (en cualquier modo)`n"
            . "Guide + Start  ->  Cerrar ventana activa (Alt+F4, force-kill si no responde)`n"
            . "Guide + Back   ->  Activar/desactivar modo mouse`n`n"
            . "MODO MOUSE`n"
            . "Stick izquierdo   ->  Mover el cursor`n"
            . "RT / LT              ->  Clic izquierdo / derecho (mantenido)`n"
            . "X                       ->  Clic central (mantenido)`n"
            . "A / B                 ->  Enter / Escape (mantenido)`n"
            . "D-Pad               ->  Flechas (mantenido)`n"
            . "LB / RB             ->  Scroll arriba / abajo`n"
            . "L3 (clic stick)      ->  Alt+Tab`n"
            . "R3 (clic stick)      ->  Play / Pause`n"
            . "Stick derecho ↕     ->  Volumen`n"
            . "Stick derecho ↔     ->  Pista siguiente / anterior`n"
            . "Start (solo)         ->  Tecla Windows`n"
            . "Back (solo)         ->  Tab`n"
            . "Y                       ->  Mostrar/ocultar teclado en pantalla`n"
            . "   (arrástralo desde su barra superior, ?123 para símbolos,`n"
            . "   Shift queda fijo hasta que lo vuelvas a tocar,`n"
            . "   mantén presionada una vocal para á/é/í/ó/ú)`n`n"
            . "Hecho por Yabazta con Claude AI. 🤖✨",

        "update_check_failed", "No se pudo consultar GitHub ahorita (código {v}). Intenta más tarde.",
        "update_up_to_date", "Ya tienes la última versión ({v}).",
        "update_available_title", "GSX - Actualización disponible",
        "update_available_body", "Hay una nueva versión disponible: {v}`nTienes instalada: {v2}",
        "update_open_page_question", "`n`n¿Abrir la página de descargas?",
        "update_self_question", "`n`n¿Actualizar ahora? GSX se va a cerrar un momento,`ndescargar la nueva versión y volver a abrirse solo.",
        "update_download_failed", "No se pudo descargar la actualización (código {v}).",
        "update_install_failed", "No se pudo instalar la actualización: {v}",
        "update_check_error", "No se pudo revisar actualizaciones: {v}",
        "update_done_title", "Actualización completada",
        "update_done_body", "GSX se actualizó a la versión {v}.",

        "firstrun_title", "Antes de continuar",
        "firstrun_body", "GSX no necesita ningún programa externo para funcionar: "
            . "manda Alt+F4 a la ventana activa y, si no cierra en unos segundos, "
            . "mata el proceso a la fuerza automáticamente.`n`n"
            . "También incluye un modo mouse (Guide+Back para activarlo/desactivarlo) "
            . "que te deja controlar el cursor y el teclado con el control.",
        "firstrun_uncompiled_note", "`n`nComo estás corriendo el .ahk sin compilar, necesitas AutoHotkey v2 instalado.",
        "firstrun_compiled_note", "`n`n(AutoHotkey ya viene incluido en este .exe, no necesitas instalarlo aparte.)",

        "osk_drag_hint", "  ⠿  Teclado GSX   ·   arrástralo desde aquí para moverlo",
        "osk_space", "Espacio",
    ),
)

; Looks up STRINGS[UI_LANG][key], falling back to English if a key is
; ever missing from a non-English table. {v} / {v2} placeholders are
; filled in by TrFmt below when a string needs interpolation.
Tr(key) {
    global STRINGS, UI_LANG
    if STRINGS[UI_LANG].Has(key)
        return STRINGS[UI_LANG][key]
    return STRINGS["en"][key]
}

TrFmt(key, v := "", v2 := "") {
    s := Tr(key)
    s := StrReplace(s, "{v}", v)
    s := StrReplace(s, "{v2}", v2)
    return s
}

; --- Tray menu ---
A_TrayMenu.Delete()
A_TrayMenu.Add(Tr("tray_about"), ShowAbout)
A_TrayMenu.Add(Tr("tray_check_updates"), (*) => CheckForUpdates(true))
A_TrayMenu.Add(Tr("tray_donations"), (*) => Run("https://www.patreon.com/cw/Yabazta"))
A_TrayMenu.Add()
A_TrayMenu.Add(Tr("tray_run_startup"), ToggleStartup)
A_TrayMenu.Add()
A_TrayMenu.Add(Tr("tray_exit"), (*) => ExitApp())
A_TrayMenu.Default := Tr("tray_about")

; Checks for updates ~3 seconds after startup (so it doesn't delay
; launch if GitHub is slow to respond), and silently: if there's no
; internet or GitHub doesn't respond, it just says nothing.
SetTimer(() => CheckForUpdates(false), -3000)

if IsStartupEnabled()
    A_TrayMenu.Check(Tr("tray_run_startup"))

IsStartupEnabled() {
    global RUN_KEY, RUN_VALUE_NAME
    try {
        RegRead(RUN_KEY, RUN_VALUE_NAME)
        return true
    } catch {
        return false
    }
}

ToggleStartup(*) {
    global RUN_KEY, RUN_VALUE_NAME
    if IsStartupEnabled() {
        try RegDelete(RUN_KEY, RUN_VALUE_NAME)
        A_TrayMenu.Uncheck(Tr("tray_run_startup"))
    } else {
        RegWrite('"' . A_ScriptFullPath . '"', "REG_SZ", RUN_KEY, RUN_VALUE_NAME)
        A_TrayMenu.Check(Tr("tray_run_startup"))
    }
}

OnMessage(0x404, TrayIconClick)
TrayIconClick(wParam, lParam, msg, hwnd) {
    static WM_LBUTTONUP := 0x202
    if (lParam = WM_LBUTTONUP)
        A_TrayMenu.Show()
}

ShowAbout(*) {
    global APP_VERSION
    MsgBox(
        TrFmt("about_body", APP_VERSION),
        Tr("about_title"),
        "Iconi"
    )
}

; Compares two versions like "1.2.3" field by field, numerically (not as
; text: "0.3.10" > "0.3.2" even though "10" < "2" as a string). Returns 1
; if a > b, -1 if a < b, 0 if equal. Missing fields are treated as 0 (so
; "1.2" = "1.2.0").
CompareVersions(a, b) {
    partsA := StrSplit(a, ".")
    partsB := StrSplit(b, ".")
    maxLen := Max(partsA.Length, partsB.Length)
    Loop maxLen {
        na := (A_Index <= partsA.Length) ? Integer(partsA[A_Index]) : 0
        nb := (A_Index <= partsB.Length) ? Integer(partsB[A_Index]) : 0
        if (na > nb)
            return 1
        if (na < nb)
            return -1
    }
    return 0
}

; Checks the latest published GitHub release and warns if there's a
; newer version than the current one. manual=true means the user asked
; for this from the tray menu, so we also tell them when they're ALREADY
; on the latest version (the silent background check doesn't bother with
; that). Any network error is silently ignored, so as not to be annoying
; when there's no internet.
;
; If the release has a downloadable asset of the same type we're
; currently running (.exe if compiled, .ahk if running the loose
; script), a self-update is offered. If that asset isn't found (for
; example, only a source-code zip is attached), it falls back to opening
; the downloads page like before.
CheckForUpdates(manual) {
    global APP_VERSION, GITHUB_REPO
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", "https://api.github.com/repos/" . GITHUB_REPO . "/releases/latest", true)
        whr.SetRequestHeader("User-Agent", "GSX-Updater")
        whr.Send()
        whr.WaitForResponse(10)  ; up to 10 seconds, never hangs

        if (whr.Status != 200) {
            if manual
                MsgBox(TrFmt("update_check_failed", whr.Status), "GSX", "Iconi")
            return
        }

        json := whr.ResponseText

        if !RegExMatch(json, '"tag_name"\s*:\s*"v?([^"]+)"', &m)
            return

        latest := m[1]
        cmp := CompareVersions(latest, APP_VERSION)
        if (cmp <= 0) {
            ; latest = APP_VERSION, or even older (e.g. you're testing a
            ; dev build that's newer than the latest published release):
            ; nothing to offer.
            if manual
                MsgBox(TrFmt("update_up_to_date", APP_VERSION), "GSX", "Iconi")
            return
        }

        wantedExt := A_IsCompiled ? ".exe" : ".ahk"
        downloadUrl := ""
        pos := 1
        while RegExMatch(json, '"browser_download_url"\s*:\s*"([^"]+)"', &am, pos) {
            url := StrReplace(am[1], "\/", "/")
            if (SubStr(url, -StrLen(wantedExt)) = wantedExt) {
                downloadUrl := url
                break
            }
            pos := am.Pos + am.Len
        }

        msg := TrFmt("update_available_body", latest, APP_VERSION)

        if (downloadUrl = "") {
            result := MsgBox(msg . Tr("update_open_page_question"),
                Tr("update_available_title"), "YesNo Iconi")
            if (result = "Yes")
                Run("https://github.com/" . GITHUB_REPO . "/releases/latest")
            return
        }

        result := MsgBox(
            msg . Tr("update_self_question"),
            Tr("update_available_title"),
            "YesNo Iconi"
        )
        if (result = "Yes")
            DoSelfUpdate(downloadUrl, latest)

    } catch as e {
        if manual
            MsgBox(TrFmt("update_check_error", e.Message), "GSX", "Iconi")
    }
}

; Downloads the new file into a temp folder and launches a helper .bat
; that:
;   1) waits (retrying) for this process to release the current file,
;   2) moves the new file on top of the old one (same name and folder,
;      so shortcuts / the startup registry entry keep pointing to the
;      right place),
;   3) relaunches GSX, passing it an "/updated:<version>" argument so
;      the new instance knows to show a "update complete" notice,
;   4) deletes itself.
; All of this trouble is because Windows won't let you overwrite an
; .exe (or, often, an .ahk in use) while the process still has it open;
; that's why a separate process is needed to wait until this one has
; actually closed.
;
; Note: if GSX lives in a protected folder (e.g. Program Files),
; replacing the file may require administrator permissions; if the .bat
; keeps retrying forever, that's the most likely cause.
DoSelfUpdate(url, newVersion) {
    try {
        currentFile := A_ScriptFullPath
        tempFile := A_Temp . "\GSX_update_" . A_TickCount . (A_IsCompiled ? ".exe" : ".ahk")

        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, false)
        whr.SetRequestHeader("User-Agent", "GSX-Updater")
        whr.Send()
        if (whr.Status != 200) {
            MsgBox(TrFmt("update_download_failed", whr.Status), "GSX", "Iconi")
            return
        }

        stream := ComObject("ADODB.Stream")
        stream.Type := 1  ; binary
        stream.Open()
        stream.Write(whr.ResponseBody)
        stream.SaveToFile(tempFile, 2)  ; 2 = overwrite if it already exists
        stream.Close()

        launchCmd := A_IsCompiled
            ? '"' . currentFile . '" /updated:' . newVersion
            : '"' . A_AhkPath . '" "' . currentFile . '" /updated:' . newVersion

        batLines := [
            "@echo off",
            ":wait",
            "timeout /t 1 /nobreak >nul",
            'move /y "' . tempFile . '" "' . currentFile . '" >nul 2>&1',
            "if errorlevel 1 goto wait",
            'start "" ' . launchCmd,
            'del "%~f0"'
        ]
        batContent := ""
        for line in batLines
            batContent .= line . "`r`n"

        batFile := A_Temp . "\GSX_update_" . A_TickCount . ".bat"
        FileAppend(batContent, batFile)

        Run('"' . batFile . '"', , "Hide")
        ExitApp()

    } catch as e {
        MsgBox(TrFmt("update_install_failed", e.Message), "GSX", "Iconi")
    }
}

; If this instance was launched by the self-update .bat above, it will
; carry an "/updated:<version>" argument on the command line — show a
; one-time confirmation that the update actually landed.
CheckPostUpdateNotice() {
    for arg in A_Args {
        if (InStr(arg, "/updated:") = 1) {
            newVersion := SubStr(arg, StrLen("/updated:") + 1)
            MsgBox(TrFmt("update_done_body", newVersion), Tr("update_done_title"), "Iconi")
            return
        }
    }
}
CheckPostUpdateNotice()

ShowFirstRunWarning()

ShowFirstRunWarning() {
    markerDir := A_AppData . "\GSX"
    markerFile := markerDir . "\.firstrun"

    if FileExist(markerFile)
        return

    msg := Tr("firstrun_body")
    msg .= A_IsCompiled ? Tr("firstrun_compiled_note") : Tr("firstrun_uncompiled_note")

    MsgBox(msg, Tr("firstrun_title"), "Iconi")

    try {
        if !DirExist(markerDir)
            DirCreate(markerDir)
        FileAppend("1", markerFile)
    }
}

; ==================== XInput setup ====================

; Button bitmask bits from XInputGetStateEx (undocumented, ordinal 100)
XI_DPAD_UP    := 0x0001
XI_DPAD_DOWN  := 0x0002
XI_DPAD_LEFT  := 0x0004
XI_DPAD_RIGHT := 0x0008
XI_START      := 0x0010
XI_BACK       := 0x0020
XI_L3         := 0x0040  ; left stick click
XI_R3         := 0x0080  ; right stick click
XI_LB         := 0x0100
XI_RB         := 0x0200
XI_GUIDE      := 0x0400  ; only visible via GetStateEx, not in the public API
XI_A          := 0x1000
XI_B          := 0x2000
XI_X          := 0x4000
XI_Y          := 0x8000

COMBO_CLOSE_WINDOW := XI_GUIDE | XI_START
COMBO_TOGGLE_MOUSE := XI_GUIDE | XI_BACK

XINPUT_DLL := "xinput1_4.dll"

hModule := DllCall("GetModuleHandle", "Str", XINPUT_DLL, "Ptr")
if !hModule
    hModule := DllCall("LoadLibrary", "Str", XINPUT_DLL, "Ptr")
if !hModule
    throw Error("Couldn't load " . XINPUT_DLL)

pGetStateEx := DllCall("GetProcAddress", "Ptr", hModule, "Ptr", 100, "Ptr")
if !pGetStateEx
    throw Error("Couldn't find XInputGetStateEx (ordinal 100) in " . XINPUT_DLL)

; ==================== Polling state ====================

comboCloseWasPressed := false
comboToggleWasPressed := false

lastScan := 0
ScanIntervalMs := 3000

bufs := [Buffer(16, 0), Buffer(16, 0), Buffer(16, 0), Buffer(16, 0)]
connected := [false, false, false, false]

; Polling intervals: fast while mouse mode is active (smooth cursor),
; slow the rest of the time (saves CPU).
POLL_INTERVAL_IDLE_MS  := 100
POLL_INTERVAL_MOUSE_MS := 16

mouseModeActive := false

SetTimer(CheckCombo, POLL_INTERVAL_IDLE_MS)

CheckCombo() {
    global comboCloseWasPressed, comboToggleWasPressed, pGetStateEx, bufs, connected
    global lastScan, ScanIntervalMs, mouseModeActive

    combinedButtons := 0
    primaryIndex := 0
    anyConnected := false

    doFullScan := (A_TickCount - lastScan) >= ScanIntervalMs
    if doFullScan
        lastScan := A_TickCount

    Loop 4 {
        i := A_Index
        userIndex := i - 1
        if (!connected[i] && !doFullScan)
            continue

        result := DllCall(pGetStateEx, "UInt", userIndex, "Ptr", bufs[i], "UInt")
        connected[i] := (result = 0)

        if (connected[i]) {
            wB := NumGet(bufs[i], 4, "UShort")
            combinedButtons |= wB
            if !anyConnected {
                primaryIndex := i
                anyConnected := true
            }
        }
    }

    guideHeld := (combinedButtons & XI_GUIDE) != 0

    ; --- Guide+Start: close/kill the active window (works in any mode) ---
    comboCloseNow := (combinedButtons & COMBO_CLOSE_WINDOW) = COMBO_CLOSE_WINDOW
    if (comboCloseNow && !comboCloseWasPressed)
        CloseOrKillActiveWindow()
    comboCloseWasPressed := comboCloseNow

    ; --- Guide+Back: toggle mouse mode ---
    comboToggleNow := (combinedButtons & COMBO_TOGGLE_MOUSE) = COMBO_TOGGLE_MOUSE
    if (comboToggleNow && !comboToggleWasPressed)
        ToggleMouseMode()
    comboToggleWasPressed := comboToggleNow

    ; --- Mouse mode logic (only using the first detected controller) ---
    if (mouseModeActive && anyConnected)
        HandleMouseMode(bufs[primaryIndex], guideHeld)
}

; Tries to politely close the active window (Alt+F4). If it doesn't
; respond within FORCE_KILL_GRACE_SEC, force-kills the process.
CloseOrKillActiveWindow() {
    global FORCE_KILL_GRACE_SEC
    hwnd := WinExist("A")
    if !hwnd
        return
    target := "ahk_id " . hwnd

    try WinClose(target)

    if !WinWaitClose(target, , FORCE_KILL_GRACE_SEC)
        try WinKill(target)
}

; ==================== Mouse mode ====================

ToggleMouseMode() {
    global mouseModeActive, POLL_INTERVAL_IDLE_MS, POLL_INTERVAL_MOUSE_MS

    mouseModeActive := !mouseModeActive

    if mouseModeActive {
        SetTimer(CheckCombo, POLL_INTERVAL_MOUSE_MS)
    } else {
        ReleaseAllMouseModeState()
        SetTimer(CheckCombo, POLL_INTERVAL_IDLE_MS)
    }

    ShowMouseModeIndicator(mouseModeActive)
}

; --- Mouse Mode visual indicator ---
; TrayTip depends on the app having Windows notifications enabled
; (Settings > Notifications), on Focus Assist, and on the .exe having a
; registered AppUserModelID — none of that is guaranteed for an
; AutoHotkey script/exe, so in practice it can easily never show up.
; This little window of our own (same as the on-screen keyboard) doesn't
; depend on anything from Windows: it always shows.
mouseModeIndicatorGui := ""
MOUSE_INDICATOR_DURATION_MS := 2500

ShowMouseModeIndicator(isOn) {
    global mouseModeIndicatorGui, MOUSE_INDICATOR_DURATION_MS

    ; Cancels any pending auto-hide from a previous activation, and
    ; destroys the previous indicator if it somehow was still alive
    ; (avoids an old timer wiping out a new one if you toggle very fast).
    SetTimer(HideMouseModeIndicator, 0)
    if (mouseModeIndicatorGui != "") {
        mouseModeIndicatorGui.Destroy()
        mouseModeIndicatorGui := ""
    }

    ; Font size proportional to screen height, so it's easy to make out
    ; both on a small monitor and on a big 4K TV from the couch. Clamped
    ; so it never looks ridiculous at either extreme.
    fontSize := Round(A_ScreenHeight / 18)
    if (fontSize < 28)
        fontSize := 28
    if (fontSize > 90)
        fontSize := 90

    ; Same style for both states, only the text and color change (lime
    ; green = on, soft red = off) so they're distinguishable at a glance
    ; without having to read carefully.
    text := isOn ? "🖱  Mouse Mode ON" : "🖱  Mouse Mode OFF"
    color := isOn ? "cLime" : "cFF6B6B"

    g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000", "GSX Indicator")
    g.BackColor := "1E1E1E"
    g.MarginX := Round(fontSize * 1.1)
    g.MarginY := Round(fontSize * 0.55)
    g.SetFont("s" . fontSize . " " . color . " Bold", "Segoe UI")
    g.Add("Text", , text)

    ; First shown far off-screen (instead of hidden) to measure its real
    ; size without the user seeing it, then it's centered.
    g.Show("NoActivate AutoSize x-4000 y-4000")
    WinGetPos(, , &w, &h, "ahk_id " . g.Hwnd)

    x := (A_ScreenWidth - w) / 2
    y := (A_ScreenHeight - h) / 2
    WinMove(x, y, , , "ahk_id " . g.Hwnd)
    WinSetTransparent(235, "ahk_id " . g.Hwnd)

    mouseModeIndicatorGui := g
    SetTimer(HideMouseModeIndicator, -MOUSE_INDICATOR_DURATION_MS)
}

HideMouseModeIndicator() {
    global mouseModeIndicatorGui
    SetTimer(HideMouseModeIndicator, 0)
    if (mouseModeIndicatorGui != "") {
        mouseModeIndicatorGui.Destroy()
        mouseModeIndicatorGui := ""
    }
}



; Standard XInput deadzones.
LEFT_STICK_DEADZONE  := 7849
RIGHT_STICK_DEADZONE := 8689

; Cursor speed (pixels per tick at full stick tilt, with the timer
; running at POLL_INTERVAL_MOUSE_MS = 16ms). Adjust to taste.
CURSOR_MAX_SPEED := 32

; Exponent of the stick's response curve:
;   1.0 = linear (proportional and predictable — recommended to start).
;   >1.0 (e.g. 1.5, 2.0) = slow/medium movements feel slower than the
;        tilt would suggest, but you keep the same max speed at full
;        tilt. More "imprecise" in the middle range.
;   <1.0 (e.g. 0.7) = the cursor feels more sensitive near the center.
CURSOR_CURVE_EXPONENT := 1.0

TRIGGER_THRESHOLD := 100  ; 0-255. RT/LT pass this threshold to count as a "click".

; "Key/button held" states so down/up can be sent instead of just taps,
; and to do edge detection for the toggles.
rtDown := false        ; RT -> left click
ltDown := false        ; LT -> right click
xDown  := false        ; X  -> middle click
aDown  := false        ; A  -> Enter
bDown  := false        ; B  -> Escape
dpadUpDown := false
dpadDownDown := false
dpadLeftDown := false
dpadRightDown := false

yWasPressed := false      ; Y -> toggle on-screen keyboard (tap)
lbWasPressed := false     ; LB -> scroll up (tap, one step)
rbWasPressed := false     ; RB -> scroll down (tap, one step)
l3WasPressed := false     ; L3 -> Alt+Tab (tap)
r3WasPressed := false     ; R3 -> Play/Pause (tap)
startAloneWasPressed := false  ; Start alone -> Windows key (tap)
backAloneWasPressed := false   ; Back alone -> Tab (tap)

; Volume (right stick up/down): repeats while held tilted.
lastVolumeRepeat := 0
VOLUME_REPEAT_MS := 120

; Next/previous track (right stick left/right): fires once per tilt, has
; to return to center before it can fire again.
mediaHorizArmed := true
MEDIA_TRACK_DEADZONE := 20000  ; higher than the normal deadzone, to avoid accidental triggers

HandleMouseMode(buf, guideHeld) {
    global rtDown, ltDown, xDown, aDown, bDown
    global dpadUpDown, dpadDownDown, dpadLeftDown, dpadRightDown
    global yWasPressed, lbWasPressed, rbWasPressed, l3WasPressed, r3WasPressed
    global startAloneWasPressed, backAloneWasPressed
    global LEFT_STICK_DEADZONE, RIGHT_STICK_DEADZONE, CURSOR_MAX_SPEED, CURSOR_CURVE_EXPONENT
    global TRIGGER_THRESHOLD
    global lastVolumeRepeat, VOLUME_REPEAT_MS, mediaHorizArmed, MEDIA_TRACK_DEADZONE

    wButtons := NumGet(buf, 4, "UShort")
    lTrigger := NumGet(buf, 6, "UChar")
    rTrigger := NumGet(buf, 7, "UChar")
    lx := NumGet(buf, 8, "Short")
    ly := NumGet(buf, 10, "Short")
    rx := NumGet(buf, 12, "Short")
    ry := NumGet(buf, 14, "Short")

    ; --- Move cursor (left stick) ---
    normX := ApplyDeadzone(lx, LEFT_STICK_DEADZONE)
    normY := ApplyDeadzone(ly, LEFT_STICK_DEADZONE)
    if (normX != 0 || normY != 0) {
        curvedX := ApplyCurve(normX, CURSOR_CURVE_EXPONENT)
        curvedY := ApplyCurve(normY, CURSOR_CURVE_EXPONENT)
        dx := Round(curvedX * CURSOR_MAX_SPEED)
        dy := Round(-curvedY * CURSOR_MAX_SPEED)  ; stick up (Y+) = cursor up (screen Y-)
        if (dx != 0 || dy != 0)
            MouseMove(dx, dy, 0, "R")
    }

    ; --- RT: left click (held, based on the analog trigger) ---
    rtNow := rTrigger >= TRIGGER_THRESHOLD
    if (rtNow && !rtDown)
        Click("left down")
    else if (!rtNow && rtDown)
        Click("left up")
    rtDown := rtNow

    ; --- LT: right click ---
    ltNow := lTrigger >= TRIGGER_THRESHOLD
    if (ltNow && !ltDown)
        Click("right down")
    else if (!ltNow && ltDown)
        Click("right up")
    ltDown := ltNow

    ; --- RB: scroll down / LB: scroll up (one step per press) ---
    rbNow := (wButtons & XI_RB) != 0
    if (rbNow && !rbWasPressed)
        Click("WheelDown")
    rbWasPressed := rbNow

    lbNow := (wButtons & XI_LB) != 0
    if (lbNow && !lbWasPressed)
        Click("WheelUp")
    lbWasPressed := lbNow

    ; --- A: Enter (held) / B: Escape (held) ---
    aNow := (wButtons & XI_A) != 0
    if (aNow && !aDown)
        Send("{Enter down}")
    else if (!aNow && aDown)
        Send("{Enter up}")
    aDown := aNow

    bNow := (wButtons & XI_B) != 0
    if (bNow && !bDown)
        Send("{Escape down}")
    else if (!bNow && bDown)
        Send("{Escape up}")
    bDown := bNow

    ; --- X: middle click (held) ---
    xNow := (wButtons & XI_X) != 0
    if (xNow && !xDown)
        Click("middle down")
    else if (!xNow && xDown)
        Click("middle up")
    xDown := xNow

    ; --- Y: toggle on-screen keyboard (tap) ---
    yNow := (wButtons & XI_Y) != 0
    if (yNow && !yWasPressed)
        ToggleOnScreenKeyboard()
    yWasPressed := yNow

    ; --- D-Pad: arrow keys (held, allows the system's own auto-repeat) ---
    dU := (wButtons & XI_DPAD_UP) != 0
    if (dU && !dpadUpDown)
        Send("{Up down}")
    else if (!dU && dpadUpDown)
        Send("{Up up}")
    dpadUpDown := dU

    dD := (wButtons & XI_DPAD_DOWN) != 0
    if (dD && !dpadDownDown)
        Send("{Down down}")
    else if (!dD && dpadDownDown)
        Send("{Down up}")
    dpadDownDown := dD

    dL := (wButtons & XI_DPAD_LEFT) != 0
    if (dL && !dpadLeftDown)
        Send("{Left down}")
    else if (!dL && dpadLeftDown)
        Send("{Left up}")
    dpadLeftDown := dL

    dR := (wButtons & XI_DPAD_RIGHT) != 0
    if (dR && !dpadRightDown)
        Send("{Right down}")
    else if (!dR && dpadRightDown)
        Send("{Right up}")
    dpadRightDown := dR

    ; --- L3: Alt+Tab (tap) ---
    l3Now := (wButtons & XI_L3) != 0
    if (l3Now && !l3WasPressed)
        Send("!{Tab}")
    l3WasPressed := l3Now

    ; --- R3: Play/Pause (tap) ---
    r3Now := (wButtons & XI_R3) != 0
    if (r3Now && !r3WasPressed)
        Send("{Media_Play_Pause}")
    r3WasPressed := r3Now

    ; --- Start alone (without Guide): Windows key (tap) ---
    startBitNow := (wButtons & XI_START) != 0
    startAloneNow := startBitNow && !guideHeld
    if (startAloneNow && !startAloneWasPressed)
        Send("{LWin}")
    startAloneWasPressed := startAloneNow

    ; --- Back alone (without Guide): Tab (tap) ---
    backBitNow := (wButtons & XI_BACK) != 0
    backAloneNow := backBitNow && !guideHeld
    if (backAloneNow && !backAloneWasPressed)
        Send("{Tab}")
    backAloneWasPressed := backAloneNow

    ; --- Right stick: volume (up/down, repeatable) and next/prev track (left/right, one-shot) ---
    rNormY := ApplyDeadzone(ry, RIGHT_STICK_DEADZONE)
    if (rNormY != 0) {
        if (A_TickCount - lastVolumeRepeat >= VOLUME_REPEAT_MS) {
            Send(rNormY > 0 ? "{Volume_Up}" : "{Volume_Down}")
            lastVolumeRepeat := A_TickCount
        }
    }

    if (Abs(rx) < RIGHT_STICK_DEADZONE) {
        mediaHorizArmed := true
    } else if (mediaHorizArmed && Abs(rx) >= MEDIA_TRACK_DEADZONE) {
        Send(rx > 0 ? "{Media_Next}" : "{Media_Prev}")
        mediaHorizArmed := false
    }
}

; Converts a raw stick value (-32768..32767) into a normalized -1.0..1.0
; value, applying the deadzone. Returns 0 if inside the deadzone.
ApplyDeadzone(rawValue, deadzone) {
    if (Abs(rawValue) < deadzone)
        return 0.0
    sign := rawValue > 0 ? 1 : -1
    magnitude := (Abs(rawValue) - deadzone) / (32767.0 - deadzone)
    if (magnitude > 1.0)
        magnitude := 1.0
    return sign * magnitude
}

; Applies the curve exponent to a normalized value (-1.0..1.0),
; preserving its sign. With exponent=1.0 this is an identity (linear).
ApplyCurve(normValue, exponent) {
    if (normValue = 0)
        return 0.0
    sign := normValue > 0 ? 1 : -1
    return sign * (Abs(normValue) ** exponent)
}

ReleaseAllMouseModeState() {
    global rtDown, ltDown, xDown, aDown, bDown
    global dpadUpDown, dpadDownDown, dpadLeftDown, dpadRightDown

    if rtDown {
        Click("left up")
        rtDown := false
    }
    if ltDown {
        Click("right up")
        ltDown := false
    }
    if xDown {
        Click("middle up")
        xDown := false
    }
    if aDown {
        Send("{Enter up}")
        aDown := false
    }
    if bDown {
        Send("{Escape up}")
        bDown := false
    }
    if dpadUpDown {
        Send("{Up up}")
        dpadUpDown := false
    }
    if dpadDownDown {
        Send("{Down up}")
        dpadDownDown := false
    }
    if dpadLeftDown {
        Send("{Left up}")
        dpadLeftDown := false
    }
    if dpadRightDown {
        Send("{Right up}")
        dpadRightDown := false
    }
}

; --- Custom on-screen keyboard (no external dependencies) ---
; Advantage over osk.exe/TabTip.exe: it's our own window, runs at the
; same integrity level as the rest of the script, and doesn't depend on
; any Windows service (which, in your case, the debloat removed).
;
; WHY IT WASN'T TYPING ANYTHING BEFORE (and Windows was beeping):
; Gui.Show("...NoActivate") only prevents the window from being
; activated the FIRST time it's shown. Without the WS_EX_NOACTIVATE
; extended style (0x08000000) set at window CREATION, Windows would
; activate it when clicking a button, focus would move there, and when
; sending keys, Windows looked for them as dialog "mnemonics" -> beep
; and nothing got typed. Fixed with "+E0x08000000" in the Gui() options.
;
; WHY IT COULDN'T BE DRAGGED:
; The trick of forwarding the click as WM_NCLBUTTONDOWN/HTCAPTION
; (moving the window "as if" you'd clicked its title bar) isn't reliable
; in every case, especially combined with WS_EX_NOACTIVATE. It's
; replaced with a simpler, more direct method: while the left mouse
; button stays pressed over the top bar, a timer moves the window
; following the cursor (WinMove). It's the same mechanism most
; overlays/HUDs use, and doesn't depend on Windows interpreting the
; message in any particular way.

oskGui := ""
oskDragBarHwnd := 0
oskCloseHwnd := 0
oskShiftHwnd := 0
oskKeyMeta := Map()       ; each key's hwnd -> {label, kind, action, bg, bgPress, ctrl}
oskLetterHwnds := []      ; hwnds of letter keys, to reflect upper/lowercase
oskKeyControls := []      ; key controls currently drawn (to destroy them when switching layer)
oskLayout := "letters"    ; "letters" or "symbols"
shiftActive := false

oskDragging := false
oskDragStartMouseX := 0
oskDragStartMouseY := 0
oskDragStartWinX := 0
oskDragStartWinY := 0

oskPressedHwnd := 0       ; currently pressed key (for the visual effect and the "click")
oskRepeatAction := ""     ; action currently auto-repeating while held (e.g. backspace)
oskRepeatFirst := false

; --- Long-press accents on vowels ---
; Tap a vowel key -> plain letter. Hold it past OSK_LONGPRESS_MS -> the
; key flips to show its accented form as a preview, and releasing it
; types the accent instead. No extra key or layout needed for á/é/í/ó/ú.
OSK_LONGPRESS_MS := 400
OSK_VOWEL_ACCENTS := Map("A", "Á", "E", "É", "I", "Í", "O", "Ó", "U", "Ú")
oskLongPressReached := false  ; whether the current press has crossed OSK_LONGPRESS_MS

; --- Keyboard size: percentages, not fixed pixels ---
; Previously OSK_WIDTH/OSK_HEIGHT (and everything else: bar, keys, gaps,
; typography) were fixed pixel numbers, designed for 1080p. On a bigger
; screen (1440p, 4K) that looks proportionally tiny, and on a smaller one
; it can run off the screen. Now everything is derived from percentages,
; so it looks equally big relative to the screen no matter the
; resolution.
;
; Note: this is calculated once at script startup. If you change the
; screen resolution (or plug the HTPC into another monitor/TV) while
; GSX is already running, the script needs to be restarted for the
; keyboard to recalculate its size.

OSK_WIDTH_PCT  := 0.44   ; % of screen width
OSK_HEIGHT_PCT := 0.40   ; % of screen height

; Safety limits (in pixels) so it doesn't end up absurdly small at a
; very low resolution, nor absurdly huge at a very high one (8K,
; ultrawide monitors, etc.).
OSK_WIDTH  := Max(620, Min(1600, Round(A_ScreenWidth  * OSK_WIDTH_PCT)))
OSK_HEIGHT := Max(300, Min(820,  Round(A_ScreenHeight * OSK_HEIGHT_PCT)))

; The rest of the keyboard's measurements (top bar, key height/width,
; spacing, typography) are percentages OF THE SIZE ALREADY CALCULATED
; above, so everything scales together and keeps the same proportions
; no matter what resolution OSK_WIDTH and OSK_HEIGHT ended up at. The
; percentages come from the previous design (which looked good at
; 660x316), just now applied relatively.
OSK_BARHEIGHT         := Round(OSK_HEIGHT * 0.089)
OSK_ROW_HEIGHT         := Round(OSK_HEIGHT * 0.152)
OSK_ROW_GAP             := Round(OSK_HEIGHT * 0.019)
OSK_KEY_GAP             := Round(OSK_WIDTH  * 0.009)
OSK_ROW_START_X         := Round(OSK_WIDTH  * 0.015)
OSK_KEY_WIDTH_NORMAL   := Round(OSK_WIDTH  * 0.070)
OSK_KEY_WIDTH_WIDE     := Round(OSK_WIDTH  * 0.145)
OSK_KEY_WIDTH_SPACE    := Round(OSK_WIDTH  * 0.409)

; Typography sized relative to whatever contains it (key or bar), with a
; readable minimum in case the keyboard ended up very small.
OSK_FONT_KEY   := Max(9, Round(OSK_ROW_HEIGHT * 0.27))
OSK_FONT_BAR   := Max(8, Round(OSK_BARHEIGHT * 0.36))
OSK_FONT_CLOSE := Max(9, Round(OSK_BARHEIGHT * 0.50))

; Margins relative to the SCREEN (not the keyboard): how much breathing
; room to leave against the edges, and how far to separate the keyboard
; from the cursor when it's placed above/below it.
OSK_MARGIN          := Round(A_ScreenHeight * 0.0185)
OSK_GAP_ABOVE_MOUSE := Round(A_ScreenHeight * 0.022)

; --- Color palette ---
OSK_COL_BG            := "1E1E1E"
OSK_COL_BAR           := "111111"
OSK_COL_KEY           := "3A3A3A"
OSK_COL_KEY_PRESS     := "2A2A2A"
OSK_COL_ACCENT        := "3D6EA5"
OSK_COL_ACCENT_PRESS  := "2C5480"
OSK_COL_DANGER        := "8A3B3B"
OSK_COL_DANGER_PRESS  := "6E2E2E"
OSK_COL_TOGGLE_ON     := "3D8A5A"
OSK_COL_TEXT          := "F0F0F0"

; Gui controls in AHK v2 do NOT have their own .Destroy() method (only
; the whole Gui object has one, and it destroys the ENTIRE window). To
; destroy a single control you have to call the Windows API directly on
; its handle.
DestroyOskControl(ctrl) {
    try DllCall("DestroyWindow", "Ptr", ctrl.Hwnd)
}

; "Text" controls don't always repaint themselves when you change their
; background color after creation (WM_CTLCOLORSTATIC is only queried on
; the next repaint, which doesn't always happen on its own). Forced here.
RedrawOskControl(ctrl) {
    DllCall("InvalidateRect", "Ptr", ctrl.Hwnd, "Ptr", 0, "Int", true)
    DllCall("UpdateWindow", "Ptr", ctrl.Hwnd)
}

ToggleOnScreenKeyboard() {
    global oskGui

    if (oskGui = "" || !WinExist("ahk_id " . oskGui.Hwnd)) {
        oskGui := BuildOnScreenKeyboardGui()
        ShowOnScreenKeyboardNearMouse()
        return
    }

    if DllCall("IsWindowVisible", "Ptr", oskGui.Hwnd)
        oskGui.Hide()
    else
        ShowOnScreenKeyboardNearMouse()
}

; Placed centered horizontally over the cursor, and ABOVE it (with a
; margin in between) rather than around it — this way it's much harder
; for the keyboard to cover the text box you're using, which is usually
; right where the cursor is or very close to it. If it doesn't fit above
; (cursor too close to the top edge of the screen), it's placed below the
; cursor instead. This is recalculated EVERY time you open the keyboard,
; following wherever the cursor is at that moment.
ShowOnScreenKeyboardNearMouse() {
    global oskGui, OSK_WIDTH, OSK_HEIGHT, OSK_MARGIN, OSK_GAP_ABOVE_MOUSE

    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)

    x := mx - (OSK_WIDTH / 2)
    if (x < OSK_MARGIN)
        x := OSK_MARGIN
    if (x + OSK_WIDTH > A_ScreenWidth - OSK_MARGIN)
        x := A_ScreenWidth - OSK_WIDTH - OSK_MARGIN

    y := my - OSK_HEIGHT - OSK_GAP_ABOVE_MOUSE
    if (y < OSK_MARGIN)
        y := my + OSK_GAP_ABOVE_MOUSE  ; doesn't fit above: placed below the cursor instead
    if (y + OSK_HEIGHT > A_ScreenHeight - OSK_MARGIN)
        y := A_ScreenHeight - OSK_HEIGHT - OSK_MARGIN

    oskGui.Show("x" . x . " y" . y . " w" . OSK_WIDTH . " h" . OSK_HEIGHT . " NoActivate")
}

BuildOnScreenKeyboardGui() {
    global oskDragBarHwnd, oskCloseHwnd, OSK_WIDTH, OSK_BARHEIGHT, OSK_FONT_BAR, OSK_FONT_CLOSE
    global OSK_COL_BG, OSK_COL_BAR, OSK_COL_TEXT

    ; +E0x08000000 = WS_EX_NOACTIVATE: this line is the key fix so the
    ; window never steals focus, whether when shown or when clicking on
    ; it (buttons or drag bar).
    g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000", "GSX Keyboard")
    g.BackColor := OSK_COL_BG
    g.MarginX := 0
    g.MarginY := 0
    g.OnEvent("Close", (*) => g.Hide())

    ; --- Top bar: title + drag zone + close button ---
    dragBar := g.Add("Text", "x0 y0 w" . (OSK_WIDTH - OSK_BARHEIGHT) . " h" . OSK_BARHEIGHT
        . " +0x300 Background" . OSK_COL_BAR . " c" . OSK_COL_TEXT, Tr("osk_drag_hint"))
    dragBar.SetFont("s" . OSK_FONT_BAR, "Segoe UI")
    oskDragBarHwnd := dragBar.Hwnd

    closeBtn := g.Add("Text", "x" . (OSK_WIDTH - OSK_BARHEIGHT) . " y0 w" . OSK_BARHEIGHT . " h" . OSK_BARHEIGHT
        . " Center +0x300 Background" . OSK_COL_BAR . " cSilver", "×")
    closeBtn.SetFont("s" . OSK_FONT_CLOSE . " Bold", "Segoe UI")
    oskCloseHwnd := closeBtn.Hwnd

    RebuildKeys(g, "letters")

    return g
}

; Rebuilds the visible key set for the given layer ("letters" or
; "symbols"). Destroys the previous keys and draws the new ones; the
; drag bar and close button are left untouched.
RebuildKeys(g, layout) {
    global oskLayout, oskKeyMeta, oskLetterHwnds, oskShiftHwnd, oskKeyControls
    global OSK_BARHEIGHT, OSK_ROW_HEIGHT, OSK_ROW_GAP, OSK_KEY_GAP, OSK_ROW_START_X
    global OSK_KEY_WIDTH_NORMAL, OSK_KEY_WIDTH_WIDE, OSK_KEY_WIDTH_SPACE

    for ctrl in oskKeyControls
        DestroyOskControl(ctrl)
    oskKeyControls := []
    oskKeyMeta := Map()
    oskLetterHwnds := []
    oskShiftHwnd := 0
    oskLayout := layout

    spaceLabel := Tr("osk_space")

    if (layout = "letters") {
        rows := [
            [["1","key"],["2","key"],["3","key"],["4","key"],["5","key"],["6","key"],["7","key"],["8","key"],["9","key"],["0","key"],["⌫","danger","BACKSPACE"]],
            [["Q","letter"],["W","letter"],["E","letter"],["R","letter"],["T","letter"],["Y","letter"],["U","letter"],["I","letter"],["O","letter"],["P","letter"]],
            [["A","letter"],["S","letter"],["D","letter"],["F","letter"],["G","letter"],["H","letter"],["J","letter"],["K","letter"],["L","letter"],["Ñ","letter"],["Enter","accent","ENTER"]],
            [["⇧ Shift","toggle","SHIFT"],["Z","letter"],["X","letter"],["C","letter"],["V","letter"],["B","letter"],["N","letter"],["M","letter"],[",","key"],[".","key"]],
            [["?123","accent","LAYOUT_SYMBOLS"],["Esc","accent","ESC"],[spaceLabel,"space","SPACE"],["Tab","accent","TAB"]]
        ]
    } else {
        rows := [
            [["!","key"],["@","key"],["#","key"],["$","key"],["%","key"],["^","key"],["&","key"],["*","key"],["(","key"],[")","key"],["⌫","danger","BACKSPACE"]],
            [["-","key"],["_","key"],["=","key"],["+","key"],["[","key"],["]","key"],["{","key"],["}","key"],["\","key"],["|","key"]],
            [[";","key"],[":","key"],["'","key"],['"',"key"],["<","key"],[">","key"],["Enter","accent","ENTER"]],
            [["~","key"],["``","key"],[",","key"],[".","key"],["/","key"],["?","key"]],
            [["ABC","accent","LAYOUT_LETTERS"],["Esc","accent","ESC"],[spaceLabel,"space","SPACE"],["Tab","accent","TAB"]]
        ]
    }

    y := OSK_BARHEIGHT + OSK_ROW_GAP
    for row in rows {
        x := OSK_ROW_START_X
        for item in row {
            label := item[1]
            kind := item[2]
            action := (item.Length >= 3) ? item[3] : label

            w := (kind = "space") ? OSK_KEY_WIDTH_SPACE
                : (kind = "danger" || kind = "accent" || kind = "toggle") ? OSK_KEY_WIDTH_WIDE
                : OSK_KEY_WIDTH_NORMAL

            ctrl := AddOskKey(g, x, y, w, OSK_ROW_HEIGHT, label, kind, action)
            oskKeyControls.Push(ctrl)

            if (kind = "letter")
                oskLetterHwnds.Push(ctrl.Hwnd)
            if (action = "SHIFT")
                oskShiftHwnd := ctrl.Hwnd

            x += w + OSK_KEY_GAP
        }
        y += OSK_ROW_HEIGHT + OSK_ROW_GAP
    }

    UpdateLetterCaseDisplay()
    UpdateShiftVisual()
}

; Creates a "key" as a text control (not a native button) so it can be
; given its own color per type — native Windows buttons don't let you
; easily customize their background color.
;
; IMPORTANT: style 0x100 (SS_NOTIFY) is added on top of 0x200
; (SS_CENTERIMAGE, to vertically center the text). Without SS_NOTIFY, a
; text control responds HTTRANSPARENT to WM_NCHITTEST: the click simply
; PASSES THROUGH it and reaches the window behind it instead of the key,
; so our click handling (OnMessage below) never finds out about it. This
; also applies to the drag bar and the close button, which is why they
; all use "+0x300" (0x100 | 0x200) in their options.
AddOskKey(g, x, y, w, h, label, kind, action) {
    global oskKeyMeta, OSK_COL_KEY, OSK_COL_KEY_PRESS, OSK_COL_ACCENT, OSK_COL_ACCENT_PRESS
    global OSK_COL_DANGER, OSK_COL_DANGER_PRESS, OSK_COL_TEXT, OSK_FONT_KEY

    switch kind {
        case "accent":
            bg := OSK_COL_ACCENT
            bgPress := OSK_COL_ACCENT_PRESS
        case "danger":
            bg := OSK_COL_DANGER
            bgPress := OSK_COL_DANGER_PRESS
        default:
            bg := OSK_COL_KEY
            bgPress := OSK_COL_KEY_PRESS
    }

    ctrl := g.Add("Text", "x" . x . " y" . y . " w" . w . " h" . h . " Center +0x300 Background" . bg . " c" . OSK_COL_TEXT, label)
    ctrl.SetFont("s" . OSK_FONT_KEY, "Segoe UI")

    oskKeyMeta[ctrl.Hwnd] := {label: label, kind: kind, action: action, bg: bg, bgPress: bgPress, ctrl: ctrl}
    return ctrl
}

; --- Low-level click and drag handling ---
; OnMessage is used instead of OnEvent("Click") because we need to know
; when the mouse button goes DOWN (for visual feedback and to be able to
; repeat while held) and when it goes UP (to fire the action), not just
; when a full click completes.
OnMessage(0x201, OSK_HandleLButtonDown)  ; WM_LBUTTONDOWN
OnMessage(0x202, OSK_HandleLButtonUp)    ; WM_LBUTTONUP

OSK_HandleLButtonDown(wParam, lParam, msg, hwnd) {
    global oskDragBarHwnd, oskCloseHwnd, oskKeyMeta, oskPressedHwnd, oskRepeatAction, oskRepeatFirst
    global oskDragging, oskDragStartMouseX, oskDragStartMouseY, oskDragStartWinX, oskDragStartWinY, oskGui
    global oskLongPressReached, OSK_LONGPRESS_MS, OSK_VOWEL_ACCENTS

    if (hwnd = oskCloseHwnd) {
        oskGui.Hide()
        return
    }

    if (hwnd = oskDragBarHwnd) {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&mx, &my)
        WinGetPos(&wx, &wy, , , "ahk_id " . oskGui.Hwnd)
        oskDragStartMouseX := mx
        oskDragStartMouseY := my
        oskDragStartWinX := wx
        oskDragStartWinY := wy
        oskDragging := true
        ; Raises the system timer resolution to 1ms for the duration of
        ; the drag (Windows rounds to ~15ms by default, which made the
        ; movement noticeably choppy). Reverted on release.
        DllCall("winmm\timeBeginPeriod", "UInt", 1)
        SetTimer(OSK_DragStep, -8)
        return
    }

    if oskKeyMeta.Has(hwnd) {
        oskPressedHwnd := hwnd
        oskLongPressReached := false
        meta := oskKeyMeta[hwnd]
        meta.ctrl.Opt("+Background" . meta.bgPress)
        RedrawOskControl(meta.ctrl)

        ; Backspace: sent immediately on press, and if held down, it
        ; repeats for as long as the mouse button (or the control's
        ; trigger, which also generates mouse clicks) stays down.
        if (meta.action = "BACKSPACE") {
            Send("{Backspace}")
            oskRepeatAction := "BACKSPACE"
            oskRepeatFirst := true
            SetTimer(OSK_RepeatStep, 350)
        }

        ; Vowels: arm a one-shot check that flips the key to its accented
        ; preview once the hold crosses OSK_LONGPRESS_MS. It bails out on
        ; its own (see OSK_VowelLongPressCheck) if the key was released
        ; or a different key is pressed by the time it fires.
        if (meta.kind = "letter" && OSK_VOWEL_ACCENTS.Has(meta.action))
            SetTimer(OSK_VowelLongPressCheck.Bind(hwnd), -OSK_LONGPRESS_MS)
    }
}

; Fires once, OSK_LONGPRESS_MS after a vowel key was pressed. If that
; same key is still the one being held, marks the press as "long" and
; swaps the key's label to its accented form so the user can see what
; they're about to type before letting go.
OSK_VowelLongPressCheck(hwnd) {
    global oskPressedHwnd, oskKeyMeta, oskLongPressReached, shiftActive, OSK_VOWEL_ACCENTS

    if (oskPressedHwnd != hwnd || !oskKeyMeta.Has(hwnd))
        return

    oskLongPressReached := true
    meta := oskKeyMeta[hwnd]
    accented := OSK_VOWEL_ACCENTS[meta.action]
    meta.ctrl.Text := shiftActive ? accented : StrLower(accented)
    RedrawOskControl(meta.ctrl)
}

OSK_DragStep() {
    global oskDragging, oskGui, oskDragStartMouseX, oskDragStartMouseY, oskDragStartWinX, oskDragStartWinY

    if !GetKeyState("LButton", "P") {
        oskDragging := false
        DllCall("winmm\timeEndPeriod", "UInt", 1)
        return
    }
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)
    newX := oskDragStartWinX + (mx - oskDragStartMouseX)
    newY := oskDragStartWinY + (my - oskDragStartMouseY)
    WinMove(newX, newY, , , "ahk_id " . oskGui.Hwnd)

    ; Self-scheduled: it calls itself again only once this run finishes,
    ; instead of a fixed period that could stack up overlapping calls.
    ; Feels smoother and more consistent.
    SetTimer(OSK_DragStep, -8)
}

OSK_RepeatStep() {
    global oskRepeatAction, oskRepeatFirst
    if !GetKeyState("LButton", "P") {
        SetTimer(OSK_RepeatStep, 0)
        oskRepeatAction := ""
        return
    }
    if oskRepeatFirst {
        oskRepeatFirst := false
        SetTimer(OSK_RepeatStep, 45)  ; repeat speed, after the initial delay
    }
    if (oskRepeatAction = "BACKSPACE")
        Send("{Backspace}")
}

OSK_HandleLButtonUp(wParam, lParam, msg, hwnd) {
    global oskPressedHwnd, oskKeyMeta, oskRepeatAction, oskLongPressReached, shiftActive, OSK_VOWEL_ACCENTS

    if (oskPressedHwnd = 0)
        return

    meta := oskKeyMeta.Has(oskPressedHwnd) ? oskKeyMeta[oskPressedHwnd] : 0
    if !meta {
        oskPressedHwnd := 0
        return
    }

    meta.ctrl.Opt("+Background" . meta.bg)
    ; If this was a vowel showing its accented preview, put its label
    ; back to the plain letter now that the press is over.
    if (meta.kind = "letter" && OSK_VOWEL_ACCENTS.Has(meta.action))
        meta.ctrl.Text := shiftActive ? meta.action : StrLower(meta.action)
    RedrawOskControl(meta.ctrl)

    wasRepeating := (oskRepeatAction != "")
    SetTimer(OSK_RepeatStep, 0)
    oskRepeatAction := ""

    ; Only fires the action if you released over the SAME key you
    ; pressed (if you dragged off it, it's canceled, like a normal
    ; button). Backspace was already sent on "down"/repeat.
    if (hwnd = oskPressedHwnd && !wasRepeating)
        OSK_FireKeyAction(meta, oskLongPressReached)

    oskPressedHwnd := 0
}

OSK_FireKeyAction(meta, longPress := false) {
    global shiftActive, OSK_VOWEL_ACCENTS

    switch meta.action {
        case "ENTER":
            Send("{Enter}")
        case "TAB":
            Send("{Tab}")
        case "ESC":
            Send("{Escape}")
        case "SPACE":
            Send("{Space}")
        case "SHIFT":
            shiftActive := !shiftActive
            UpdateShiftVisual()
            UpdateLetterCaseDisplay()
        case "LAYOUT_SYMBOLS":
            RebuildKeys(meta.ctrl.Gui, "symbols")
        case "LAYOUT_LETTERS":
            RebuildKeys(meta.ctrl.Gui, "letters")
        case "BACKSPACE":
            ; already handled in OSK_HandleLButtonDown / OSK_RepeatStep
        default:
            ch := meta.action
            if (meta.kind = "letter") {
                ; Long-pressing a vowel types its accented form instead
                ; of the plain letter.
                if (longPress && OSK_VOWEL_ACCENTS.Has(ch))
                    ch := OSK_VOWEL_ACCENTS[ch]
                ch := shiftActive ? ch : StrLower(ch)
            }
            SendText(ch)
    }
}

; Highlights the Shift key in green while it's active (like caps-lock),
; so it's noticeable at a glance.
UpdateShiftVisual() {
    global oskShiftHwnd, oskKeyMeta, shiftActive, OSK_COL_TOGGLE_ON, OSK_COL_KEY

    if !oskShiftHwnd
        return
    meta := oskKeyMeta[oskShiftHwnd]
    meta.bg := shiftActive ? OSK_COL_TOGGLE_ON : OSK_COL_KEY
    meta.ctrl.Opt("+Background" . meta.bg)
    RedrawOskControl(meta.ctrl)
    meta.ctrl.Text := shiftActive ? "⇧ SHIFT" : "⇧ Shift"
}

; Reflects on the letter keys whether they'll type upper- or lowercase
; based on Shift's current state.
UpdateLetterCaseDisplay() {
    global oskLetterHwnds, oskKeyMeta, shiftActive

    for h in oskLetterHwnds {
        meta := oskKeyMeta[h]
        meta.ctrl.Text := shiftActive ? meta.action : StrLower(meta.action)
    }
}
