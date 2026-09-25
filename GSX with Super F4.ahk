#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

RUN_KEY := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
RUN_VALUE_NAME := "GuideStartXInput"

; --- Menú de la bandeja ---
; No se llama a TraySetIcon: así se usa automáticamente el ícono que le
; pusiste al .exe al compilarlo con Ahk2Exe. Si corres el .ahk directo
; (sin compilar), verás el ícono default de AutoHotkey en su lugar.
A_TrayMenu.Delete()  ; quita las opciones default (Open, Reload, Pause, Exit, etc.)
A_TrayMenu.Add("About", ShowAbout)
A_TrayMenu.Add("Donations", (*) => Run("https://www.patreon.com/cw/Yabazta"))
A_TrayMenu.Add()  ; separador
A_TrayMenu.Add("Run at startup", ToggleStartup)
A_TrayMenu.Add()  ; separador
A_TrayMenu.Add("Salir", (*) => ExitApp())
A_TrayMenu.Default := "About"

; Refleja en el checkmark si ya está configurado para iniciar con Windows.
if IsStartupEnabled()
    A_TrayMenu.Check("Run at startup")

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
        A_TrayMenu.Uncheck("Run at startup")
    } else {
        ; Comillas por si la ruta tiene espacios.
        RegWrite('"' . A_ScriptFullPath . '"', "REG_SZ", RUN_KEY, RUN_VALUE_NAME)
        A_TrayMenu.Check("Run at startup")
    }
}

; Windows solo muestra el menú en clic derecho por defecto.
; Interceptamos el mensaje del ícono para que el clic izquierdo también lo abra.
OnMessage(0x404, TrayIconClick)
TrayIconClick(wParam, lParam, msg, hwnd) {
    static WM_LBUTTONUP := 0x202
    if (lParam = WM_LBUTTONUP)
        A_TrayMenu.Show()
}

ShowAbout(*) {
    MsgBox(
        "Guide+Start -> Ctrl+Alt+F4`n`n"
        . "By Yabazta`n"
        . "Vibecoded btw.",
        "About",
        "Iconi"
    )
}

; --- Aviso de primer uso ---
; Se guarda una marca en %AppData% para no volver a mostrarlo después.
ShowFirstRunWarning()

ShowFirstRunWarning() {
    markerDir := A_AppData . "\GuideStartXInput"
    markerFile := markerDir . "\.firstrun"

    if FileExist(markerFile)
        return

    reqs := "- Tener instalado SuperF4 (https://github.com/stefansundin/superf4), "
        . "que es quien realmente cierra la ventana al recibir Ctrl+Alt+F4."

    if !A_IsCompiled
        reqs .= "`n- Tener instalado AutoHotkey v2 (este .ahk no está compilado)."
    else
        reqs .= "`n`n(AutoHotkey ya viene incluido en este .exe, no necesitas instalarlo aparte)."

    MsgBox(
        "Este programa requiere:`n`n" . reqs,
        "Antes de continuar",
        "Iconi"
    )

    try {
        if !DirExist(markerDir)
            DirCreate(markerDir)
        FileAppend("1", markerFile)
    }
}

; Bits del bitmask de XInputGetStateEx (no documentada, ordinal 100)
XINPUT_GAMEPAD_START := 0x0010
XINPUT_GAMEPAD_GUIDE := 0x0400  ; solo visible vía GetStateEx, no en la API pública
COMBO := XINPUT_GAMEPAD_START | XINPUT_GAMEPAD_GUIDE

; DLL a usar: xinput1_4 viene integrada desde Windows 8+.
XINPUT_DLL := "xinput1_4.dll"

; Resolver la dirección de XInputGetStateEx (ordinal 100, no documentada).
; GetProcAddress trata el 2do parámetro como ordinal cuando el valor es < 0x10000.
hModule := DllCall("GetModuleHandle", "Str", XINPUT_DLL, "Ptr")
if !hModule
    hModule := DllCall("LoadLibrary", "Str", XINPUT_DLL, "Ptr")
if !hModule
    throw Error("No se pudo cargar " . XINPUT_DLL)

pGetStateEx := DllCall("GetProcAddress", "Ptr", hModule, "Ptr", 100, "Ptr")
if !pGetStateEx
    throw Error("No se encontró XInputGetStateEx (ordinal 100) en " . XINPUT_DLL)

wasPressed := false
lastScan := 0
ScanIntervalMs := 3000  ; cada cuánto revisa si hay controles nuevos/desconectados

; Un buffer reutilizable por slot (evita alocar memoria en cada tick).
bufs := [Buffer(16, 0), Buffer(16, 0), Buffer(16, 0), Buffer(16, 0)]
; Cache de qué slots (0-3) tienen control conectado.
connected := [false, false, false, false]

SetTimer(CheckCombo, 100)  ; 100ms sigue siendo instantáneo al tacto humano

CheckCombo() {
    global wasPressed, COMBO, pGetStateEx, bufs, connected, lastScan, ScanIntervalMs
    anyPressed := false

    ; Cada pocos segundos revisa los 4 slots para actualizar cuáles están conectados.
    ; El resto de los ticks solo consulta los que ya sabemos que están activos,
    ; así se ahorran llamadas cuando hay menos de 4 controles (el caso común).
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
            wButtons := NumGet(bufs[i], 4, "UShort")
            if ((wButtons & COMBO) = COMBO)
                anyPressed := true
        }
    }

    if (anyPressed && !wasPressed) {
        Send("^!{F4}")
        wasPressed := true
    } else if (!anyPressed) {
        wasPressed := false
    }
}
