#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SetWorkingDir A_ScriptDir

;@Ahk2Exe-Set Name, WindowsTvGameMode
;@Ahk2Exe-Set Description, Toggle Windows couch-gaming mode with the Xbox Guide button
;@Ahk2Exe-Set Copyright, MIT License
;@Ahk2Exe-SetMainIcon ..\assets\icon.ico

#Include lib\version.ahk
#Include lib\config.ahk
#Include lib\autostart.ahk
#Include lib\updater.ahk
#Include lib\updater_ui.ahk
#Include lib\tray.ahk
#Include lib\tv_config.ahk
#Include lib\tv_log.ahk
#Include lib\tv_xinput.ahk
#Include lib\tv_actions.ahk
#Include lib\tv_settings_gui.ahk

global APP_NAME := "WindowsTvGameMode"

AppConfigInit(APP_NAME)
LogInit()
AutostartInit(APP_NAME)
UpdaterInit(APP_NAME, "gemivnet", "WindowsTvGameMode")

Log("========== " APP_NAME " v" APP_VERSION " starting ==========")
TvConfigLoad()
InitXInput()

trayItems := [
    {label: "Toggle TV mode", callback: (*) => ToggleTvMode(), default: true},
    {label: "Reload config",  callback: (*) => (TvConfigLoad(), Notify("Config reloaded", ""))}
]
TrayInit(APP_NAME, trayItems, ShowSettings, UpdaterCheckAndPrompt)
UpdateTrayIcon()

if TvConfigIsFirstRun()
    SetTimer(() => ShowFirstRunWizard(), -500)

SetTimer PollController, TvConfig["PollInterval"]
SetTimer(() => UpdaterCheckAndPrompt(false), -5000)
