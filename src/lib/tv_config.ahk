; WindowsTvGameMode app-specific config. Loads into the global TvConfig Map
; and migrates the legacy config.ini (if present next to the .exe) into
; %APPDATA%\WindowsTvGameMode\config.ini on first run.

global TvConfig := Map()

TvConfigLoad() {
    global TvConfig, APP_CONFIG_FILE

    ; Migrate legacy config.ini next to the executable, if present and no
    ; APPDATA config exists yet.
    legacy := A_ScriptDir "\config.ini"
    if (FileExist(legacy) && !FileExist(APP_CONFIG_FILE))
        FileCopy(legacy, APP_CONFIG_FILE)

    TvConfig["PollInterval"]     := Integer(ConfigRead("General", "PollInterval", "75"))
    TvConfig["ShowNotifications"]:= ConfigReadBool("General", "ShowNotifications", true)
    TvConfig["HoldDurationMs"]   := Integer(ConfigRead("General", "HoldDurationMs", "0"))

    TvConfig["MonitorSwitcher"] := ExpandEnv(ConfigRead("Tools", "MonitorSwitcher", ""))
    TvConfig["SoundVolumeView"] := ExpandEnv(ConfigRead("Tools", "SoundVolumeView", ""))

    TvConfig["TvProfile"]      := ExpandEnv(ConfigRead("Display", "TvProfile", ""))
    TvConfig["DesktopProfile"] := ExpandEnv(ConfigRead("Display", "DesktopProfile", ""))
    TvConfig["SettleDelayMs"]  := Integer(ConfigRead("Display", "SettleDelayMs", "1500"))

    TvConfig["TvDevice"]      := ConfigRead("Audio", "TvDevice", "")
    TvConfig["DesktopDevice"] := ConfigRead("Audio", "DesktopDevice", "")
    TvConfig["AudioRole"]     := ConfigRead("Audio", "Role", "all")

    TvConfig["PlayniteLaunch"]      := ConfigReadBool("Playnite", "Launch", true)
    TvConfig["PlaynitePath"]        := ExpandEnv(ConfigRead("Playnite", "Path", ""))
    TvConfig["PlayniteCloseOnExit"] := ConfigReadBool("Playnite", "CloseOnExit", true)
}

ExpandEnv(str) {
    if (str = "")
        return ""
    size := DllCall("ExpandEnvironmentStrings", "Str", str, "Ptr", 0, "UInt", 0, "UInt")
    buf := Buffer(size * 2, 0)
    DllCall("ExpandEnvironmentStrings", "Str", str, "Ptr", buf, "UInt", size, "UInt")
    return StrGet(buf, "UTF-16")
}

; True when the essentials are unset — used to trigger the first-run wizard.
TvConfigIsFirstRun() {
    return TvConfig["MonitorSwitcher"] = ""
        && TvConfig["SoundVolumeView"] = ""
        && TvConfig["TvProfile"] = ""
        && TvConfig["DesktopProfile"] = ""
}
