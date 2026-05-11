; Windows "Start with Windows" toggle via HKCU Run key.
; AutostartInit must be called once with the app name. The registry value is
; the full quoted path to the current executable (or .ahk in dev), so the
; entry survives the user moving the .exe between runs only if they reapply.

global AUTOSTART_APP_NAME := ""
global AUTOSTART_REG := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"

AutostartInit(appName) {
    global AUTOSTART_APP_NAME
    AUTOSTART_APP_NAME := appName
}

AutostartIsEnabled() {
    global AUTOSTART_APP_NAME, AUTOSTART_REG
    try {
        val := RegRead(AUTOSTART_REG, AUTOSTART_APP_NAME)
        return val != ""
    } catch {
        return false
    }
}

AutostartEnable() {
    global AUTOSTART_APP_NAME, AUTOSTART_REG
    if A_IsCompiled {
        target := '"' A_ScriptFullPath '"'
    } else {
        ; Bundled-runtime form — re-launch AHK with our script path.
        target := '"' A_AhkPath '" "' A_ScriptFullPath '"'
    }
    RegWrite(target, "REG_SZ", AUTOSTART_REG, AUTOSTART_APP_NAME)
}

AutostartDisable() {
    global AUTOSTART_APP_NAME, AUTOSTART_REG
    try RegDelete(AUTOSTART_REG, AUTOSTART_APP_NAME)
}

AutostartToggle() {
    if AutostartIsEnabled()
        AutostartDisable()
    else
        AutostartEnable()
    return AutostartIsEnabled()
}

; Returns the path of the file that gets replaced by the installer when an
; update is applied. For bundled-runtime apps that's the AHK interpreter; for
; compiled .exe apps that's the .exe itself. The updater uses this for swap.
GetExecutablePath() {
    return A_IsCompiled ? A_ScriptFullPath : A_AhkPath
}
