#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

RUN_KEY := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
RUN_VALUE_NAME := "GSX"

; Cuánto esperar (en segundos) después del Alt+F4 "educado" antes de matar
; el proceso a la fuerza si la ventana sigue abierta. Ajustable.
FORCE_KILL_GRACE_SEC := 2.0

; --- Menú de la bandeja ---
A_TrayMenu.Delete()
A_TrayMenu.Add("About", ShowAbout)
A_TrayMenu.Add("Donations", (*) => Run("https://www.patreon.com/cw/Yabazta"))
A_TrayMenu.Add()
A_TrayMenu.Add("Run at startup", ToggleStartup)
A_TrayMenu.Add()
A_TrayMenu.Add("Salir", (*) => ExitApp())
A_TrayMenu.Default := "About"

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
        RegWrite('"' . A_ScriptFullPath . '"', "REG_SZ", RUN_KEY, RUN_VALUE_NAME)
        A_TrayMenu.Check("Run at startup")
    }
}

OnMessage(0x404, TrayIconClick)
TrayIconClick(wParam, lParam, msg, hwnd) {
    static WM_LBUTTONUP := 0x202
    if (lParam = WM_LBUTTONUP)
        A_TrayMenu.Show()
}

ShowAbout(*) {
    MsgBox(
        "Guide+Start -> Alt+F4 (con auto force-kill si no responde)`n"
        . "Guide+Back -> Activar/desactivar modo mouse`n"
        . "Y (en modo mouse) -> Mostrar/ocultar teclado en pantalla`n"
        . "   (arrástralo desde su barra superior, botón ?123 para símbolos,`n"
        . "   Shift queda fijo hasta que lo vuelvas a tocar)`n`n"
        . "By Yabazta`n"
        . "Vibecoded btw.",
        "About",
        "Iconi"
    )
}

; --- Aviso de primer uso ---
ShowFirstRunWarning()

ShowFirstRunWarning() {
    markerDir := A_AppData . "\GSX"
    markerFile := markerDir . "\.firstrun"

    if FileExist(markerFile)
        return

    msg := "GSX no necesita ningún programa externo para funcionar: "
        . "manda Alt+F4 a la ventana activa y, si no cierra en unos segundos, "
        . "mata el proceso a la fuerza automáticamente.`n`n"
        . "También incluye un modo mouse (Guide+Back para activarlo/desactivarlo) "
        . "que te deja controlar el cursor y el teclado con el control."

    if !A_IsCompiled
        msg .= "`n`nComo estás corriendo el .ahk sin compilar, necesitas AutoHotkey v2 instalado."
    else
        msg .= "`n`n(AutoHotkey ya viene incluido en este .exe, no necesitas instalarlo aparte)."

    MsgBox(msg, "Antes de continuar", "Iconi")

    try {
        if !DirExist(markerDir)
            DirCreate(markerDir)
        FileAppend("1", markerFile)
    }
}

; ==================== XInput setup ====================

; Bits del bitmask de botones de XInputGetStateEx (no documentada, ordinal 100)
XI_DPAD_UP    := 0x0001
XI_DPAD_DOWN  := 0x0002
XI_DPAD_LEFT  := 0x0004
XI_DPAD_RIGHT := 0x0008
XI_START      := 0x0010
XI_BACK       := 0x0020
XI_L3         := 0x0040  ; click del stick izquierdo
XI_R3         := 0x0080  ; click del stick derecho
XI_LB         := 0x0100
XI_RB         := 0x0200
XI_GUIDE      := 0x0400  ; solo visible vía GetStateEx, no en la API pública
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
    throw Error("No se pudo cargar " . XINPUT_DLL)

pGetStateEx := DllCall("GetProcAddress", "Ptr", hModule, "Ptr", 100, "Ptr")
if !pGetStateEx
    throw Error("No se encontró XInputGetStateEx (ordinal 100) en " . XINPUT_DLL)

; ==================== Polling state ====================

comboCloseWasPressed := false
comboToggleWasPressed := false

lastScan := 0
ScanIntervalMs := 3000

bufs := [Buffer(16, 0), Buffer(16, 0), Buffer(16, 0), Buffer(16, 0)]
connected := [false, false, false, false]

; Intervalos: rápido mientras el modo mouse está activo (cursor fluido),
; lento el resto del tiempo (ahorra CPU).
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

    ; --- Guide+Start: cerrar/matar ventana activa (funciona en cualquier modo) ---
    comboCloseNow := (combinedButtons & COMBO_CLOSE_WINDOW) = COMBO_CLOSE_WINDOW
    if (comboCloseNow && !comboCloseWasPressed)
        CloseOrKillActiveWindow()
    comboCloseWasPressed := comboCloseNow

    ; --- Guide+Back: alternar modo mouse ---
    comboToggleNow := (combinedButtons & COMBO_TOGGLE_MOUSE) = COMBO_TOGGLE_MOUSE
    if (comboToggleNow && !comboToggleWasPressed)
        ToggleMouseMode()
    comboToggleWasPressed := comboToggleNow

    ; --- Lógica del modo mouse (solo con el primer control detectado) ---
    if (mouseModeActive && anyConnected)
        HandleMouseMode(bufs[primaryIndex], guideHeld)
}

; Intenta cerrar la ventana activa educadamente (Alt+F4). Si no responde
; dentro de FORCE_KILL_GRACE_SEC, mata el proceso a la fuerza.
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

; ==================== Modo mouse ====================

ToggleMouseMode() {
    global mouseModeActive, POLL_INTERVAL_IDLE_MS, POLL_INTERVAL_MOUSE_MS

    mouseModeActive := !mouseModeActive

    if mouseModeActive {
        SetTimer(CheckCombo, POLL_INTERVAL_MOUSE_MS)
        TrayTip("GSX", "Modo mouse activado", 1)
    } else {
        ReleaseAllMouseModeState()
        SetTimer(CheckCombo, POLL_INTERVAL_IDLE_MS)
        TrayTip("GSX", "Modo mouse desactivado", 1)
    }
}

; Deadzones estándar de XInput.
LEFT_STICK_DEADZONE  := 7849
RIGHT_STICK_DEADZONE := 8689

; Velocidad del cursor (píxeles por tick a máxima inclinación, con el
; timer corriendo a POLL_INTERVAL_MOUSE_MS = 16ms). Ajusta a tu gusto.
CURSOR_MAX_SPEED := 32

; Exponente de la curva de respuesta del stick:
;   1.0 = lineal (proporcional y predecible — recomendado para empezar).
;   >1.0 (ej. 1.5, 2.0) = movimientos lentos/medios se sienten más lentos
;        de lo que parece por la inclinación, pero conservas la misma
;        velocidad máxima al fondo. Más "impreciso" en el rango medio.
;   <1.0 (ej. 0.7) = el cursor se siente más sensible cerca del centro.
CURSOR_CURVE_EXPONENT := 1.0

TRIGGER_THRESHOLD := 100  ; 0-255. RT/LT pasan este umbral para "clic".

; Estados de "tecla/botón sostenido" para poder enviar down/up en vez de
; solo taps, y para hacer detección de flanco (edge) en los toggles.
rtDown := false        ; RT -> clic izquierdo
ltDown := false        ; LT -> clic derecho
xDown  := false        ; X  -> clic central
aDown  := false        ; A  -> Enter
bDown  := false        ; B  -> Escape
dpadUpDown := false
dpadDownDown := false
dpadLeftDown := false
dpadRightDown := false

yWasPressed := false      ; Y -> toggle teclado en pantalla (tap)
lbWasPressed := false     ; LB -> scroll arriba (tap, un paso)
rbWasPressed := false     ; RB -> scroll abajo (tap, un paso)
l3WasPressed := false     ; L3 -> Alt+Tab (tap)
r3WasPressed := false     ; R3 -> Play/Pause (tap)
startAloneWasPressed := false  ; Start solo -> tecla Windows (tap)
backAloneWasPressed := false   ; Back solo -> Tab (tap)

; Volumen (stick derecho arriba/abajo): repetición mientras se mantiene inclinado.
lastVolumeRepeat := 0
VOLUME_REPEAT_MS := 120

; Pista siguiente/anterior (stick derecho izq/der): un solo disparo por
; inclinación, hay que volver al centro antes de repetir.
mediaHorizArmed := true
MEDIA_TRACK_DEADZONE := 20000  ; más alto que el deadzone normal, para evitar disparos accidentales

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

    ; --- Mover cursor (stick izquierdo) ---
    normX := ApplyDeadzone(lx, LEFT_STICK_DEADZONE)
    normY := ApplyDeadzone(ly, LEFT_STICK_DEADZONE)
    if (normX != 0 || normY != 0) {
        curvedX := ApplyCurve(normX, CURSOR_CURVE_EXPONENT)
        curvedY := ApplyCurve(normY, CURSOR_CURVE_EXPONENT)
        dx := Round(curvedX * CURSOR_MAX_SPEED)
        dy := Round(-curvedY * CURSOR_MAX_SPEED)  ; stick arriba (Y+) = cursor arriba (pantalla Y-)
        if (dx != 0 || dy != 0)
            MouseMove(dx, dy, 0, "R")
    }

    ; --- RT: clic izquierdo (mantenido según el trigger analógico) ---
    rtNow := rTrigger >= TRIGGER_THRESHOLD
    if (rtNow && !rtDown)
        Click("left down")
    else if (!rtNow && rtDown)
        Click("left up")
    rtDown := rtNow

    ; --- LT: clic derecho ---
    ltNow := lTrigger >= TRIGGER_THRESHOLD
    if (ltNow && !ltDown)
        Click("right down")
    else if (!ltNow && ltDown)
        Click("right up")
    ltDown := ltNow

    ; --- RB: scroll abajo / LB: scroll arriba (un paso por pulsación) ---
    rbNow := (wButtons & XI_RB) != 0
    if (rbNow && !rbWasPressed)
        Click("WheelDown")
    rbWasPressed := rbNow

    lbNow := (wButtons & XI_LB) != 0
    if (lbNow && !lbWasPressed)
        Click("WheelUp")
    lbWasPressed := lbNow

    ; --- A: Enter (mantenido) / B: Escape (mantenido) ---
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

    ; --- X: clic central (mantenido) ---
    xNow := (wButtons & XI_X) != 0
    if (xNow && !xDown)
        Click("middle down")
    else if (!xNow && xDown)
        Click("middle up")
    xDown := xNow

    ; --- Y: toggle teclado en pantalla (tap) ---
    yNow := (wButtons & XI_Y) != 0
    if (yNow && !yWasPressed)
        ToggleOnScreenKeyboard()
    yWasPressed := yNow

    ; --- D-Pad: flechas (mantenidas, permite auto-repeat del sistema) ---
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

    ; --- Start solo (sin Guide): tecla Windows (tap) ---
    startBitNow := (wButtons & XI_START) != 0
    startAloneNow := startBitNow && !guideHeld
    if (startAloneNow && !startAloneWasPressed)
        Send("{LWin}")
    startAloneWasPressed := startAloneNow

    ; --- Back solo (sin Guide): Tab (tap) ---
    backBitNow := (wButtons & XI_BACK) != 0
    backAloneNow := backBitNow && !guideHeld
    if (backAloneNow && !backAloneWasPressed)
        Send("{Tab}")
    backAloneWasPressed := backAloneNow

    ; --- Stick derecho: volumen (arriba/abajo, repetible) y pista sig/ant (izq/der, un tiro) ---
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

; Convierte un valor crudo de stick (-32768..32767) a un valor normalizado
; -1.0..1.0, aplicando zona muerta. Devuelve 0 si está dentro de la zona muerta.
ApplyDeadzone(rawValue, deadzone) {
    if (Abs(rawValue) < deadzone)
        return 0.0
    sign := rawValue > 0 ? 1 : -1
    magnitude := (Abs(rawValue) - deadzone) / (32767.0 - deadzone)
    if (magnitude > 1.0)
        magnitude := 1.0
    return sign * magnitude
}

; Aplica el exponente de curva a un valor normalizado (-1.0..1.0),
; preservando el signo. Con exponent=1.0 esto es una identidad (lineal).
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

; --- Teclado en pantalla propio (sin dependencias externas) ---
; Ventaja sobre osk.exe/TabTip.exe: es nuestra propia ventana, corre a la
; misma integridad que el resto del script, y no depende de ningún
; servicio de Windows (que en tu caso, el debloat borró).
;
; POR QUÉ NO ESCRIBÍA NADA ANTES (y sonaba el beep de Windows):
; Gui.Show("...NoActivate") solo evita que la ventana se active la
; PRIMERA vez que se muestra. Sin el estilo extendido WS_EX_NOACTIVATE
; (0x08000000) puesto en la CREACIÓN de la ventana, Windows la activaba
; al hacer clic en un botón, el foco se movía ahí, y al mandar teclas,
; Windows las buscaba como "mnemónicos" del diálogo -> beep y nada se
; escribía. Se corrige con "+E0x08000000" en las opciones de Gui().
;
; POR QUÉ NO SE PODÍA ARRASTRAR:
; El truco de reenviar el clic como WM_NCLBUTTONDOWN/HTCAPTION (mover la
; ventana "como si" hubieras hecho clic en su barra de título) no es
; confiable en todos los casos, sobre todo combinado con
; WS_EX_NOACTIVATE. Se reemplaza por un método más simple y directo:
; mientras el botón izquierdo del mouse siga presionado sobre la barra
; superior, un timer mueve la ventana siguiendo al cursor (WinMove). Es
; el mismo mecanismo que usan la mayoría de overlays/HUDs, y no depende
; de que Windows interprete el mensaje de una forma particular.

oskGui := ""
oskDragBarHwnd := 0
oskCloseHwnd := 0
oskShiftHwnd := 0
oskKeyMeta := Map()       ; hwnd de cada tecla -> {label, kind, action, bg, bgPress, ctrl}
oskLetterHwnds := []      ; hwnds de teclas de letras, para reflejar mayúscula/minúscula
oskKeyControls := []      ; controles de teclas actualmente dibujados (para destruirlos al cambiar de capa)
oskLayout := "letters"    ; "letters" o "symbols"
shiftActive := false

oskDragging := false
oskDragStartMouseX := 0
oskDragStartMouseY := 0
oskDragStartWinX := 0
oskDragStartWinY := 0

oskPressedHwnd := 0       ; tecla actualmente presionada (para el efecto visual y el "click")
oskRepeatAction := ""     ; acción en auto-repetición mientras se mantiene presionada (ej. backspace)
oskRepeatFirst := false

; Lado de la pantalla donde aparece el teclado la primera vez, para que
; no tape el cuadro de texto que estás usando (cambia a "left" si
; prefieres que aparezca del lado izquierdo). Después de la primera vez,
; el teclado recuerda dónde lo dejaste (incluida cualquier posición a la
; que lo hayas arrastrado).
OSK_DEFAULT_SIDE := "right"
OSK_WIDTH     := 620
OSK_HEIGHT    := 284
OSK_MARGIN    := 20
OSK_BARHEIGHT := 26

; --- Paleta de colores ---
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

; Los controles de un Gui en AHK v2 NO tienen método .Destroy() propio
; (solo el objeto Gui completo lo tiene, y destruye TODA la ventana). Para
; destruir un control individual hay que llamar a la API de Windows
; directamente sobre su handle.
DestroyOskControl(ctrl) {
    try DllCall("DestroyWindow", "Ptr", ctrl.Hwnd)
}

; Los controles "Text" no siempre se repintan solos cuando cambias su
; color de fondo después de creados (WM_CTLCOLORSTATIC solo se consulta
; en el próximo repintado, que no siempre ocurre solo). Se fuerza aquí.
RedrawOskControl(ctrl) {
    DllCall("InvalidateRect", "Ptr", ctrl.Hwnd, "Ptr", 0, "Int", true)
    DllCall("UpdateWindow", "Ptr", ctrl.Hwnd)
}

ToggleOnScreenKeyboard() {
    global oskGui

    if (oskGui = "" || !WinExist("ahk_id " . oskGui.Hwnd)) {
        oskGui := BuildOnScreenKeyboardGui()
        ShowOnScreenKeyboardAtDefaultPosition()
        return
    }

    if DllCall("IsWindowVisible", "Ptr", oskGui.Hwnd)
        oskGui.Hide()
    else
        oskGui.Show("NoActivate")
}

ShowOnScreenKeyboardAtDefaultPosition() {
    global oskGui, OSK_DEFAULT_SIDE, OSK_WIDTH, OSK_HEIGHT, OSK_MARGIN

    y := (A_ScreenHeight - OSK_HEIGHT) / 2
    x := (OSK_DEFAULT_SIDE = "left")
        ? OSK_MARGIN
        : A_ScreenWidth - OSK_WIDTH - OSK_MARGIN

    oskGui.Show("x" . x . " y" . y . " w" . OSK_WIDTH . " h" . OSK_HEIGHT . " NoActivate")
}

BuildOnScreenKeyboardGui() {
    global oskDragBarHwnd, oskCloseHwnd, OSK_WIDTH, OSK_BARHEIGHT
    global OSK_COL_BG, OSK_COL_BAR, OSK_COL_TEXT

    ; +E0x08000000 = WS_EX_NOACTIVATE: esta línea es la corrección clave
    ; para que la ventana jamás robe el foco, ni al mostrarse ni al
    ; hacer clic en ella (botones o barra de arrastre).
    g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000", "GSX Keyboard")
    g.BackColor := OSK_COL_BG
    g.MarginX := 0
    g.MarginY := 0
    g.OnEvent("Close", (*) => g.Hide())

    ; --- Barra superior: título + zona de arrastre + botón cerrar ---
    dragBar := g.Add("Text", "x0 y0 w" . (OSK_WIDTH - OSK_BARHEIGHT) . " h" . OSK_BARHEIGHT
        . " +0x300 Background" . OSK_COL_BAR . " c" . OSK_COL_TEXT, "  ⠿  GSX Keyboard   ·   arrastra aquí para mover")
    dragBar.SetFont("s9", "Segoe UI")
    oskDragBarHwnd := dragBar.Hwnd

    closeBtn := g.Add("Text", "x" . (OSK_WIDTH - OSK_BARHEIGHT) . " y0 w" . OSK_BARHEIGHT . " h" . OSK_BARHEIGHT
        . " Center +0x300 Background" . OSK_COL_BAR . " cSilver", "×")
    closeBtn.SetFont("s12 Bold", "Segoe UI")
    oskCloseHwnd := closeBtn.Hwnd

    RebuildKeys(g, "letters")

    return g
}

; Reconstruye el set de teclas visibles según la capa ("letters" o
; "symbols"). Destruye las teclas anteriores y dibuja las nuevas; la
; barra de arrastre y el botón de cerrar no se tocan.
RebuildKeys(g, layout) {
    global oskLayout, oskKeyMeta, oskLetterHwnds, oskShiftHwnd, oskKeyControls, OSK_BARHEIGHT

    for ctrl in oskKeyControls
        DestroyOskControl(ctrl)
    oskKeyControls := []
    oskKeyMeta := Map()
    oskLetterHwnds := []
    oskShiftHwnd := 0
    oskLayout := layout

    if (layout = "letters") {
        rows := [
            [["1","key"],["2","key"],["3","key"],["4","key"],["5","key"],["6","key"],["7","key"],["8","key"],["9","key"],["0","key"],["⌫","danger","BACKSPACE"]],
            [["Q","letter"],["W","letter"],["E","letter"],["R","letter"],["T","letter"],["Y","letter"],["U","letter"],["I","letter"],["O","letter"],["P","letter"]],
            [["A","letter"],["S","letter"],["D","letter"],["F","letter"],["G","letter"],["H","letter"],["J","letter"],["K","letter"],["L","letter"],["Enter","accent","ENTER"]],
            [["⇧ Shift","toggle","SHIFT"],["Z","letter"],["X","letter"],["C","letter"],["V","letter"],["B","letter"],["N","letter"],["M","letter"],[",","key"],[".","key"]],
            [["?123","accent","LAYOUT_SYMBOLS"],["Esc","accent","ESC"],["Espacio","space","SPACE"],["Tab","accent","TAB"]]
        ]
    } else {
        rows := [
            [["!","key"],["@","key"],["#","key"],["$","key"],["%","key"],["^","key"],["&","key"],["*","key"],["(","key"],[")","key"],["⌫","danger","BACKSPACE"]],
            [["-","key"],["_","key"],["=","key"],["+","key"],["[","key"],["]","key"],["{","key"],["}","key"],["\","key"],["|","key"]],
            [[";","key"],[":","key"],["'","key"],['"',"key"],["<","key"],[">","key"],["Enter","accent","ENTER"]],
            [["~","key"],["``","key"],[",","key"],[".","key"],["/","key"],["?","key"]],
            [["ABC","accent","LAYOUT_LETTERS"],["Esc","accent","ESC"],["Espacio","space","SPACE"],["Tab","accent","TAB"]]
        ]
    }

    y := OSK_BARHEIGHT + 6
    for row in rows {
        x := 8
        for item in row {
            label := item[1]
            kind := item[2]
            action := (item.Length >= 3) ? item[3] : label

            w := (kind = "space") ? 246
                : (kind = "danger" || kind = "accent" || kind = "toggle") ? 88
                : 42

            ctrl := AddOskKey(g, x, y, w, 42, label, kind, action)
            oskKeyControls.Push(ctrl)

            if (kind = "letter")
                oskLetterHwnds.Push(ctrl.Hwnd)
            if (action = "SHIFT")
                oskShiftHwnd := ctrl.Hwnd

            x += w + 6
        }
        y += 48
    }

    UpdateLetterCaseDisplay()
    UpdateShiftVisual()
}

; Crea una "tecla" como control de texto (no botón nativo) para poder
; darle color propio según su tipo -- los botones nativos de Windows no
; permiten personalizar el color de fondo fácilmente.
;
; IMPORTANTE: se agrega el estilo 0x100 (SS_NOTIFY) además de 0x200
; (SS_CENTERIMAGE, para centrar el texto verticalmente). Sin SS_NOTIFY,
; un control de texto responde HTTRANSPARENT a WM_NCHITTEST: el clic
; simplemente lo ATRAVIESA y le llega a la ventana de fondo en vez de a
; la tecla, así que nuestro manejo de clics (OnMessage abajo) nunca se
; entera de nada. Esto también aplica a la barra de arrastre y al botón
; de cerrar, por eso todos usan "+0x300" (0x100 | 0x200) en sus opciones.
AddOskKey(g, x, y, w, h, label, kind, action) {
    global oskKeyMeta, OSK_COL_KEY, OSK_COL_KEY_PRESS, OSK_COL_ACCENT, OSK_COL_ACCENT_PRESS
    global OSK_COL_DANGER, OSK_COL_DANGER_PRESS, OSK_COL_TEXT

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
    ctrl.SetFont("s12", "Segoe UI")

    oskKeyMeta[ctrl.Hwnd] := {label: label, kind: kind, action: action, bg: bg, bgPress: bgPress, ctrl: ctrl}
    return ctrl
}

; --- Manejo de clics y arrastre a bajo nivel ---
; Se usa OnMessage en vez de OnEvent("Click") porque necesitamos saber
; cuándo el botón del mouse BAJA (para dar retroalimentación visual y
; poder repetir mientras se mantiene) y cuándo SUBE (para disparar la
; acción), no solo cuando se completa un clic.
OnMessage(0x201, OSK_HandleLButtonDown)  ; WM_LBUTTONDOWN
OnMessage(0x202, OSK_HandleLButtonUp)    ; WM_LBUTTONUP

OSK_HandleLButtonDown(wParam, lParam, msg, hwnd) {
    global oskDragBarHwnd, oskCloseHwnd, oskKeyMeta, oskPressedHwnd, oskRepeatAction, oskRepeatFirst
    global oskDragging, oskDragStartMouseX, oskDragStartMouseY, oskDragStartWinX, oskDragStartWinY, oskGui

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
        ; Sube la resolución del temporizador del sistema a 1ms mientras
        ; dura el arrastre (por defecto Windows redondea a ~15ms, lo que
        ; hacía el movimiento notoriamente tosco). Se revierte al soltar.
        DllCall("winmm\timeBeginPeriod", "UInt", 1)
        SetTimer(OSK_DragStep, -8)
        return
    }

    if oskKeyMeta.Has(hwnd) {
        oskPressedHwnd := hwnd
        meta := oskKeyMeta[hwnd]
        meta.ctrl.Opt("+Background" . meta.bgPress)
        RedrawOskControl(meta.ctrl)

        ; Backspace: se manda de inmediato al presionar, y si se
        ; mantiene presionado, se repite solo mientras el botón del
        ; mouse (o el trigger del control, que también genera clics de
        ; mouse) siga abajo.
        if (meta.action = "BACKSPACE") {
            Send("{Backspace}")
            oskRepeatAction := "BACKSPACE"
            oskRepeatFirst := true
            SetTimer(OSK_RepeatStep, 350)
        }
    }
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

    ; Auto-programado: se vuelve a llamar solo cuando esta ejecución
    ; termina, en vez de un periodo fijo que podía acumular llamadas
    ; encimadas. Se siente más fluido y consistente.
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
        SetTimer(OSK_RepeatStep, 45)  ; velocidad de repetición, tras la espera inicial
    }
    if (oskRepeatAction = "BACKSPACE")
        Send("{Backspace}")
}

OSK_HandleLButtonUp(wParam, lParam, msg, hwnd) {
    global oskPressedHwnd, oskKeyMeta, oskRepeatAction

    if (oskPressedHwnd = 0)
        return

    meta := oskKeyMeta.Has(oskPressedHwnd) ? oskKeyMeta[oskPressedHwnd] : 0
    if !meta {
        oskPressedHwnd := 0
        return
    }

    meta.ctrl.Opt("+Background" . meta.bg)
    RedrawOskControl(meta.ctrl)

    wasRepeating := (oskRepeatAction != "")
    SetTimer(OSK_RepeatStep, 0)
    oskRepeatAction := ""

    ; Solo dispara la acción si soltaste sobre la MISMA tecla que
    ; presionaste (si arrastraste fuera, se cancela, como un botón
    ; normal). El backspace ya se mandó en el "down"/repetición.
    if (hwnd = oskPressedHwnd && !wasRepeating)
        OSK_FireKeyAction(meta)

    oskPressedHwnd := 0
}

OSK_FireKeyAction(meta) {
    global shiftActive

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
            ; ya se maneja en OSK_HandleLButtonDown / OSK_RepeatStep
        default:
            ch := meta.action
            if (meta.kind = "letter")
                ch := shiftActive ? ch : StrLower(ch)
            SendText(ch)
    }
}

; Resalta la tecla Shift en verde mientras está activa (como un
; caps-lock), para que se note de un vistazo.
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

; Refleja en las teclas de letras si se van a escribir en mayúscula o
; minúscula según el estado actual de Shift.
UpdateLetterCaseDisplay() {
    global oskLetterHwnds, oskKeyMeta, shiftActive

    for h in oskLetterHwnds {
        meta := oskKeyMeta[h]
        meta.ctrl.Text := shiftActive ? meta.action : StrLower(meta.action)
    }
}
