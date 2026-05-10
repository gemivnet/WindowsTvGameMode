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
    target := '"' GetExecutablePath() '"'
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

; A_ScriptFullPath points at the .ahk in dev; when compiled, Ahk2Exe sets it
; to the running .exe. Either way it is what we want to relaunch.
GetExecutablePath() {
    return A_IsCompiled ? A_ScriptFullPath : A_AhkPath
}
