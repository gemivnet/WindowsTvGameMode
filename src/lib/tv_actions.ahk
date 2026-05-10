; Mode toggle + side-effects: display switching, audio, Playnite, window minimize.

global TvModeActive := false

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
    global TvModeActive, TvConfig
    TvModeActive := true
    UpdateTrayIcon()
    Notify("TV mode: ON", "Switching to couch setup…")

    LoadMonitorProfile(TvConfig["TvProfile"], "TV")
    Sleep TvConfig["SettleDelayMs"]
    SwitchAudio(TvConfig["TvDevice"])
    MinimizeAllWindows()

    if TvConfig["PlayniteLaunch"] {
        ; Extra settle before launching Playnite — Playnite Fullscreen can
        ; crash/close immediately if the primary display isn't fully stable.
        Sleep 1500
        LaunchPlaynite()
    }
}

DisableTvMode() {
    global TvModeActive, TvConfig
    TvModeActive := false
    UpdateTrayIcon()
    Notify("TV mode: OFF", "Restoring desktop setup…")

    if TvConfig["PlayniteCloseOnExit"]
        ClosePlaynite()
    SwitchAudio(TvConfig["DesktopDevice"])
    LoadMonitorProfile(TvConfig["DesktopProfile"], "Desktop")
}

MinimizeAllWindows() {
    Log("Minimizing all windows (Shell.Application.MinimizeAll)")
    try {
        ComObject("Shell.Application").MinimizeAll()
    } catch as e {
        Log("  ERROR: " e.Message)
    }
}

LoadMonitorProfile(profilePath, label) {
    global TvConfig
    tool := TvConfig["MonitorSwitcher"]
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
    global TvConfig
    if (deviceName = "") {
        Log("Audio: no device name in config, skipping")
        return
    }
    tool := TvConfig["SoundVolumeView"]
    if (tool = "" || !FileExist(tool)) {
        Log("Audio skipped: SoundVolumeView path missing: " tool)
        Notify("Audio skipped", "SoundVolumeView path is not set or missing.")
        return
    }
    RunAndLog('"' tool '" /SetDefault "' deviceName '" ' TvConfig["AudioRole"], "SVV SetDefault " deviceName)
}

LaunchPlaynite() {
    global TvConfig
    path := TvConfig["PlaynitePath"]
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

UpdateTrayIcon() {
    global TvModeActive
    A_IconTip := "WindowsTvGameMode (" (TvModeActive ? "TV mode ON" : "idle") ") v" APP_VERSION
}

Notify(title, msg) {
    global TvConfig
    if !TvConfig["ShowNotifications"]
        return
    TrayTip msg, title, 0x10
}
