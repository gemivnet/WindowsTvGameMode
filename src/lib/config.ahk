; Config persistence in %APPDATA%\<AppName>\config.ini.
; AppConfigInit() must be called once with the app name before any read/write.

global APP_CONFIG_DIR := ""
global APP_CONFIG_FILE := ""

AppConfigInit(appName) {
    global APP_CONFIG_DIR, APP_CONFIG_FILE
    APP_CONFIG_DIR := EnvGet("APPDATA") "\" appName
    APP_CONFIG_FILE := APP_CONFIG_DIR "\config.ini"
    if !DirExist(APP_CONFIG_DIR)
        DirCreate(APP_CONFIG_DIR)
}

ConfigRead(section, key, default) {
    global APP_CONFIG_FILE
    return IniRead(APP_CONFIG_FILE, section, key, default)
}

ConfigReadBool(section, key, default) {
    val := ConfigRead(section, key, default ? "true" : "false")
    val := StrLower(Trim(val))
    return (val = "true" || val = "1" || val = "yes" || val = "on")
}

ConfigWrite(section, key, value) {
    global APP_CONFIG_FILE
    IniWrite(value, APP_CONFIG_FILE, section, key)
}

ConfigWriteBool(section, key, value) {
    ConfigWrite(section, key, value ? "true" : "false")
}
