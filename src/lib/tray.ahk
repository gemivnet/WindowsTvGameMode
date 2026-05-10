; Common tray menu builder. The app passes in its name and a list of
; app-specific items as {label, callback} pairs.

global TRAY_APP_NAME := ""
global TRAY_AUTOSTART_ITEM_ID := "Start with Windows"
global TRAY_ON_SETTINGS := ""
global TRAY_ON_UPDATE_CHECK := ""

TrayInit(appName, appItems, onSettings, onUpdateCheck) {
    global TRAY_APP_NAME, TRAY_ON_SETTINGS, TRAY_ON_UPDATE_CHECK
    TRAY_APP_NAME := appName
    TRAY_ON_SETTINGS := onSettings
    TRAY_ON_UPDATE_CHECK := onUpdateCheck

    A_IconTip := appName " v" APP_VERSION
    tray := A_TrayMenu
    tray.Delete()
    tray.Add(appName " v" APP_VERSION, TrayNoop)
    tray.Disable(appName " v" APP_VERSION)
    tray.Add()
    for item in appItems {
        tray.Add(item.label, item.callback)
        if item.HasOwnProp("default") && item.default
            tray.Default := item.label
    }
    if (appItems.Length > 0)
        tray.Add()
    tray.Add("Settings…", TrayHandleSettings)
    tray.Add(TRAY_AUTOSTART_ITEM_ID, TrayHandleAutostart)
    TrayRefreshAutostart()
    tray.Add("Check for updates", TrayHandleUpdateCheck)
    tray.Add("About", TrayHandleAbout)
    tray.Add()
    tray.Add("Exit", (*) => ExitApp())
}

TrayRefreshAutostart() {
    tray := A_TrayMenu
    if AutostartIsEnabled()
        tray.Check(TRAY_AUTOSTART_ITEM_ID)
    else
        tray.Uncheck(TRAY_AUTOSTART_ITEM_ID)
}

TrayHandleAutostart(*) {
    AutostartToggle()
    TrayRefreshAutostart()
}

TrayHandleSettings(*) {
    global TRAY_ON_SETTINGS
    if (TRAY_ON_SETTINGS != "")
        TRAY_ON_SETTINGS.Call()
}

TrayHandleUpdateCheck(*) {
    global TRAY_ON_UPDATE_CHECK
    if (TRAY_ON_UPDATE_CHECK != "")
        TRAY_ON_UPDATE_CHECK.Call(true)
}

TrayHandleAbout(*) {
    MsgBox(TRAY_APP_NAME "`nVersion " APP_VERSION "`n`nhttps://github.com/" UPDATER_REPO, TRAY_APP_NAME, "Iconi")
}

TrayNoop(*) {
}
