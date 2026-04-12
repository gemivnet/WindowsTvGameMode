#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; =============================================================================
; WindowsTvGameMode
; Toggle couch-gaming mode on Windows by pressing the Xbox Guide button.
; See README.md for setup. Config lives in config.ini next to this script.
; =============================================================================

global Config := Map()
global TvModeActive := false
global GuideWasDown := false
global GuideDownSince := 0
global XInputGetStateExPtr := 0
global LogFile := A_ScriptDir "\tv-mode.log"

Log("========== WindowsTvGameMode starting ==========")
LoadConfig()
InitXInput()
SetupTray()

SetTimer PollController, Config["PollInterval"]

; -----------------------------------------------------------------------------
; Config
; -----------------------------------------------------------------------------
LoadConfig() {
    global Config
    cfg := A_ScriptDir "\config.ini"
    if !FileExist(cfg) {
        MsgBox "config.ini not found next to WindowsTvGameMode.ahk.`nCopy the template and edit it.", "WindowsTvGameMode", "Iconx"
        ExitApp 1
    }

    ; [General]
    Config["PollInterval"]     := Integer(IniRead(cfg, "General", "PollInterval", "75"))
    Config["ShowNotifications"]:= IniReadBool(cfg, "General", "ShowNotifications", true)
    Config["HoldDurationMs"]   := Integer(IniRead(cfg, "General", "HoldDurationMs", "0"))

    ; [Tools]
    Config["MonitorSwitcher"] := ExpandEnv(IniRead(cfg, "Tools", "MonitorSwitcher", ""))
    Config["SoundVolumeView"] := ExpandEnv(IniRead(cfg, "Tools", "SoundVolumeView", ""))

    ; [Display]
    Config["TvProfile"]      := ExpandEnv(IniRead(cfg, "Display", "TvProfile", ""))
    Config["DesktopProfile"] := ExpandEnv(IniRead(cfg, "Display", "DesktopProfile", ""))
    Config["SettleDelayMs"]  := Integer(IniRead(cfg, "Display", "SettleDelayMs", "1500"))

    ; [Audio]
    Config["TvDevice"]      := IniRead(cfg, "Audio", "TvDevice", "")
    Config["DesktopDevice"] := IniRead(cfg, "Audio", "DesktopDevice", "")
    Config["AudioRole"]     := IniRead(cfg, "Audio", "Role", "all")

    ; [Playnite]
    Config["PlayniteLaunch"]    := IniReadBool(cfg, "Playnite", "Launch", true)
    Config["PlaynitePath"]      := ExpandEnv(IniRead(cfg, "Playnite", "Path", ""))
    Config["PlayniteCloseOnExit"] := IniReadBool(cfg, "Playnite", "CloseOnExit", true)
}

IniReadBool(file, section, key, default) {
    val := IniRead(file, section, key, default ? "true" : "false")
    val := StrLower(Trim(val))
    return (val = "true" || val = "1" || val = "yes" || val = "on")
}

Log(msg) {
    global LogFile
    try FileAppend FormatTime(, "yyyy-MM-dd HH:mm:ss") "  " msg "`r`n", LogFile
}

RunAndLog(cmd, label) {
    Log("RUN: " label)
    Log("  cmd: " cmd)
    exitCode := 0
    err := ""
    try {
        exitCode := RunWait(cmd)
    } catch as e {
        err := e.Message
    }
    if (err != "")
        Log("  ERROR: " err)
    else
        Log("  exit code: " exitCode)
    return exitCode
}

ExpandEnv(str) {
    if (str = "")
        return ""
    size := DllCall("ExpandEnvironmentStrings", "Str", str, "Ptr", 0, "UInt", 0, "UInt")
    buf := Buffer(size * 2, 0)
    DllCall("ExpandEnvironmentStrings", "Str", str, "Ptr", buf, "UInt", size, "UInt")
    return StrGet(buf, "UTF-16")
}

; -----------------------------------------------------------------------------
; XInput (uses undocumented ordinal 100 = XInputGetStateEx, exposes Guide bit)
; -----------------------------------------------------------------------------
InitXInput() {
    global XInputGetStateExPtr
    for dll in ["xinput1_4.dll", "xinput1_3.dll", "xinput9_1_0.dll"] {
        hMod := DllCall("LoadLibrary", "Str", dll, "Ptr")
        if hMod {
            XInputGetStateExPtr := DllCall("GetProcAddress", "Ptr", hMod, "Ptr", 100, "Ptr")
            if XInputGetStateExPtr
                return
        }
    }
    MsgBox "Could not load XInput. Xbox Guide button detection needs xinput1_4.dll (Windows 8+).", "WindowsTvGameMode", "Iconx"
    ExitApp 1
}

; XINPUT_STATE: DWORD dwPacketNumber (0), WORD wButtons (4), ... size 16
; Guide button bit = 0x0400 (exposed only by XInputGetStateEx, ordinal 100).
IsGuideDown() {
    global XInputGetStateExPtr
    state := Buffer(16, 0)
    Loop 4 {
        userIndex := A_Index - 1
        res := DllCall(XInputGetStateExPtr, "UInt", userIndex, "Ptr", state, "UInt")
        if (res = 0) {
            buttons := NumGet(state, 4, "UShort")
            if (buttons & 0x0400)
                return true
        }
    }
    return false
}

PollController(*) {
    global GuideWasDown, GuideDownSince
    down := IsGuideDown()

    if (down && !GuideWasDown) {
        GuideWasDown := true
        GuideDownSince := A_TickCount
    } else if (!down && GuideWasDown) {
        held := A_TickCount - GuideDownSince
        GuideWasDown := false
        if (held >= Config["HoldDurationMs"])
            ToggleTvMode()
    }
}

; -----------------------------------------------------------------------------
; Mode toggle
; -----------------------------------------------------------------------------
ToggleTvMode() {
    global TvModeActive
    Log("---- ToggleTvMode called. Current state: " (TvModeActive ? "ON->OFF" : "OFF->ON") " ----")
    if TvModeActive
        DisableTvMode()
    else
        EnableTvMode()
    Log("---- Toggle complete ----")
}

EnableTvMode() {
    global TvModeActive
    TvModeActive := true
    UpdateTrayIcon()
    Notify("TV mode: ON", "Switching to couch setup…")

    LoadMonitorProfile(Config["TvProfile"], "TV")
    Sleep Config["SettleDelayMs"]

    SwitchAudio(Config["TvDevice"])

    MinimizeAllWindows()

    if Config["PlayniteLaunch"] {
        ; Extra settle before launching Playnite — Playnite Fullscreen can
        ; crash/close immediately if the primary display isn't fully stable.
        Sleep 1500
        LaunchPlaynite()
    }
}

MinimizeAllWindows() {
    Log("Minimizing all windows (Shell.Application.MinimizeAll)")
    try {
        ComObject("Shell.Application").MinimizeAll()
    } catch as e {
        Log("  ERROR: " e.Message)
    }
}

DisableTvMode() {
    global TvModeActive
    TvModeActive := false
    UpdateTrayIcon()
    Notify("TV mode: OFF", "Restoring desktop setup…")

    if Config["PlayniteCloseOnExit"]
        ClosePlaynite()

    SwitchAudio(Config["DesktopDevice"])

    LoadMonitorProfile(Config["DesktopProfile"], "Desktop")
}

; -----------------------------------------------------------------------------
; Actions
; -----------------------------------------------------------------------------
LoadMonitorProfile(profilePath, label) {
    tool := Config["MonitorSwitcher"]
    if (tool = "" || !FileExist(tool)) {
        Log("MonitorSwitcher skipped: tool path missing: " tool)
        Notify("Display skipped", "MonitorSwitcher path is not set or missing.")
        return
    }
    if (profilePath = "" || !FileExist(profilePath)) {
        Log("MonitorSwitcher skipped: profile path missing: " profilePath)
        Notify("Display skipped", label " profile not found: " profilePath)
        return
    }
    RunAndLog('"' tool '" -load:"' profilePath '"', "MonitorSwitcher load " label)
}

SwitchAudio(deviceName) {
    if (deviceName = "") {
        Log("Audio: no device name in config, skipping")
        return
    }
    tool := Config["SoundVolumeView"]
    if (tool = "" || !FileExist(tool)) {
        Log("Audio skipped: SoundVolumeView path missing: " tool)
        Notify("Audio skipped", "SoundVolumeView path is not set or missing.")
        return
    }
    RunAndLog('"' tool '" /SetDefault "' deviceName '" ' Config["AudioRole"], "SVV SetDefault " deviceName)
}

LaunchPlaynite() {
    path := Config["PlaynitePath"]
    if (path = "" || !FileExist(path)) {
        Log("Playnite skipped: path not found: " path)
        Notify("Playnite skipped", "Path not found: " path)
        return
    }
    if ProcessExist("Playnite.FullscreenApp.exe") {
        Log("Playnite already running, activating window")
        try WinActivate "ahk_exe Playnite.FullscreenApp.exe"
        return
    }
    Log("Playnite: launching " path)
    try Run '"' path '"'
}

ClosePlaynite() {
    for name in ["Playnite.FullscreenApp.exe", "Playnite.DesktopApp.exe"] {
        if ProcessExist(name) {
            try ProcessClose(name)
        }
    }
}

; -----------------------------------------------------------------------------
; Tray & notifications
; -----------------------------------------------------------------------------
SetupTray() {
    A_IconTip := "WindowsTvGameMode (idle)"
    tray := A_TrayMenu
    tray.Delete()
    tray.Add("Toggle TV mode", (*) => ToggleTvMode())
    tray.Add("Reload config",  (*) => (LoadConfig(), Notify("Config reloaded", "")))
    tray.Add()
    tray.Add("Exit",           (*) => ExitApp())
    tray.Default := "Toggle TV mode"
}

UpdateTrayIcon() {
    A_IconTip := "WindowsTvGameMode (" (TvModeActive ? "TV mode ON" : "idle") ")"
}

Notify(title, msg) {
    if !Config["ShowNotifications"]
        return
    TrayTip msg, title, 0x10
}
