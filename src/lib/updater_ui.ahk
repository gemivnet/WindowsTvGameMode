; UI glue for the updater. Splits the silent-on-startup path from the
; interactive "Check for updates" tray click.
;
;   UpdaterCheckAndPrompt(interactive)
;     interactive = true  -> show result even if no update / on errors
;     interactive = false -> silent unless update available

UpdaterCheckAndPrompt(interactive) {
    res := UpdaterCheck()
    if (res["error"] != "") {
        if interactive
            MsgBox("Update check failed: " res["error"], TRAY_APP_NAME, "Iconx")
        return
    }
    if !res["hasUpdate"] {
        if interactive
            MsgBox("You're on the latest version (" APP_VERSION ").", TRAY_APP_NAME, "Iconi")
        return
    }
    notes := res["notes"] = "" ? "(no release notes)" : res["notes"]
    answer := MsgBox(
        "A new version is available.`n`n"
        . "Current: " APP_VERSION "`n"
        . "Latest:  " res["version"] "`n`n"
        . "Release notes:`n" notes "`n`n"
        . "Download and install now?",
        TRAY_APP_NAME " — update available",
        "YesNo Iconi")
    if (answer != "Yes")
        return
    if !UpdaterApply(res["assetUrl"]) {
        MsgBox("Download failed. Try again later.", TRAY_APP_NAME, "Iconx")
        return
    }
    ExitApp()
}
