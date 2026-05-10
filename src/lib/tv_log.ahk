; Logging — writes to %APPDATA%\WindowsTvGameMode\tv-mode.log.

global LogFile := ""

LogInit() {
    global LogFile, APP_CONFIG_DIR
    LogFile := APP_CONFIG_DIR "\tv-mode.log"
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
