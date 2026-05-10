; Settings window — edits all config.ini keys and saves back.

global tvSettingsGui := ""

ShowSettings(*) {
    global tvSettingsGui, TvConfig
    if (tvSettingsGui != "") {
        try {
            tvSettingsGui.Show()
            return
        } catch {
        }
    }
    g := Gui("+AlwaysOnTop", TRAY_APP_NAME " — Settings")
    g.SetFont("s9")

    AddField(g, "General")
    g.Add("Text", "xs y+10 w160", "Poll interval (ms):")
    g.Add("Edit", "x+5 yp-3 w80 vPollInterval", TvConfig["PollInterval"])
    g.Add("Text", "xs y+10 w160", "Hold duration (ms):")
    g.Add("Edit", "x+5 yp-3 w80 vHoldDurationMs", TvConfig["HoldDurationMs"])
    g.Add("Checkbox", "xs y+10 vShowNotifications Checked" (TvConfig["ShowNotifications"] ? 1 : 0), "Show tray notifications")

    AddField(g, "Tools")
    g.Add("Text", "xs y+8 w120", "MonitorSwitcher.exe:")
    g.Add("Edit", "xs y+2 w450 vMonitorSwitcher", TvConfig["MonitorSwitcher"])
    g.Add("Text", "xs y+8 w120", "SoundVolumeView.exe:")
    g.Add("Edit", "xs y+2 w450 vSoundVolumeView", TvConfig["SoundVolumeView"])

    AddField(g, "Display")
    g.Add("Text", "xs y+8 w120", "TV profile XML:")
    g.Add("Edit", "xs y+2 w450 vTvProfile", TvConfig["TvProfile"])
    g.Add("Text", "xs y+8 w120", "Desktop profile XML:")
    g.Add("Edit", "xs y+2 w450 vDesktopProfile", TvConfig["DesktopProfile"])
    g.Add("Text", "xs y+8 w160", "Settle delay (ms):")
    g.Add("Edit", "x+5 yp-3 w80 vSettleDelayMs", TvConfig["SettleDelayMs"])

    AddField(g, "Audio")
    g.Add("Text", "xs y+8 w120", "TV device name:")
    g.Add("Edit", "xs y+2 w450 vTvDevice", TvConfig["TvDevice"])
    g.Add("Text", "xs y+8 w120", "Desktop device name:")
    g.Add("Edit", "xs y+2 w450 vDesktopDevice", TvConfig["DesktopDevice"])
    g.Add("Text", "xs y+8 w160", "Role (Console/Multimedia/all):")
    g.Add("Edit", "x+5 yp-3 w120 vAudioRole", TvConfig["AudioRole"])

    AddField(g, "Playnite")
    g.Add("Checkbox", "xs y+8 vPlayniteLaunch Checked" (TvConfig["PlayniteLaunch"] ? 1 : 0), "Launch Playnite Fullscreen on TV mode")
    g.Add("Text", "xs y+8 w120", "Playnite path:")
    g.Add("Edit", "xs y+2 w450 vPlaynitePath", TvConfig["PlaynitePath"])
    g.Add("Checkbox", "xs y+8 vPlayniteCloseOnExit Checked" (TvConfig["PlayniteCloseOnExit"] ? 1 : 0), "Close Playnite when exiting TV mode")

    saveBtn := g.Add("Button", "xs y+15 w100 Default", "Save")
    cancelBtn := g.Add("Button", "x+10 w100", "Cancel")
    saveBtn.OnEvent("Click", (*) => TvSettingsSave(g))
    cancelBtn.OnEvent("Click", (*) => g.Hide())
    g.OnEvent("Close", (*) => g.Hide())
    tvSettingsGui := g
    g.Show()
}

AddField(g, label) {
    g.Add("Text", "xs y+15 cBlue", "── " label " ──")
}

TvSettingsSave(g) {
    data := g.Submit(false)
    ConfigWrite("General", "PollInterval", data.PollInterval)
    ConfigWrite("General", "HoldDurationMs", data.HoldDurationMs)
    ConfigWriteBool("General", "ShowNotifications", data.ShowNotifications ? true : false)

    ConfigWrite("Tools", "MonitorSwitcher", data.MonitorSwitcher)
    ConfigWrite("Tools", "SoundVolumeView", data.SoundVolumeView)

    ConfigWrite("Display", "TvProfile", data.TvProfile)
    ConfigWrite("Display", "DesktopProfile", data.DesktopProfile)
    ConfigWrite("Display", "SettleDelayMs", data.SettleDelayMs)

    ConfigWrite("Audio", "TvDevice", data.TvDevice)
    ConfigWrite("Audio", "DesktopDevice", data.DesktopDevice)
    ConfigWrite("Audio", "Role", data.AudioRole)

    ConfigWriteBool("Playnite", "Launch", data.PlayniteLaunch ? true : false)
    ConfigWrite("Playnite", "Path", data.PlaynitePath)
    ConfigWriteBool("Playnite", "CloseOnExit", data.PlayniteCloseOnExit ? true : false)

    TvConfigLoad()
    g.Hide()
    Notify("Config saved", "")
}

ShowFirstRunWizard() {
    answer := MsgBox(
        "WindowsTvGameMode needs two third-party tools that you must download yourself"
        . " (licensing prevents bundling):`n`n"
        . "  • Monitor Profile Switcher — display layout swapping`n"
        . "    https://sourceforge.net/projects/monitorswitcher/`n`n"
        . "  • SoundVolumeView (NirSoft) — default audio device switching`n"
        . "    https://www.nirsoft.net/utils/sound_volume_view.html`n`n"
        . "Download both, then open Settings to point at the .exe paths and your monitor profiles.`n`n"
        . "Open Settings now?",
        "WindowsTvGameMode — first run", "YesNo Iconi")
    if (answer = "Yes")
        ShowSettings()
}
