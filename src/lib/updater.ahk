; GitHub-release auto-updater.
;
; UpdaterInit(appName, repoOwner, repoName) must be called before any other
; function. Versioning assumes release tags of the form "vMAJOR.MINOR.PATCH"
; and the .exe asset name matches "<appName>.exe".

global UPDATER_APP_NAME := ""
global UPDATER_REPO := ""
global UPDATER_USER_AGENT := ""

UpdaterInit(appName, repoOwner, repoName) {
    global UPDATER_APP_NAME, UPDATER_REPO, UPDATER_USER_AGENT
    UPDATER_APP_NAME := appName
    UPDATER_REPO := repoOwner "/" repoName
    UPDATER_USER_AGENT := appName "-updater/" APP_VERSION
}

; Returns a Map with keys: hasUpdate (bool), version (str), notes (str), assetUrl (str), error (str).
UpdaterCheck() {
    global UPDATER_REPO, UPDATER_USER_AGENT, UPDATER_APP_NAME
    result := Map("hasUpdate", false, "version", "", "notes", "", "assetUrl", "", "error", "")
    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", "https://api.github.com/repos/" UPDATER_REPO "/releases/latest", false)
        http.SetRequestHeader("User-Agent", UPDATER_USER_AGENT)
        http.SetRequestHeader("Accept", "application/vnd.github+json")
        http.Send()
        if (http.Status != 200) {
            result["error"] := "HTTP " http.Status
            return result
        }
        body := http.ResponseText
        tag := JsonExtract(body, "tag_name")
        notes := JsonExtract(body, "body")
        if (tag = "") {
            result["error"] := "no tag_name in response"
            return result
        }
        latest := (SubStr(tag, 1, 1) = "v") ? SubStr(tag, 2) : tag
        assetUrl := FindAssetUrl(body, UPDATER_APP_NAME ".exe")
        result["version"] := latest
        result["notes"] := notes
        result["assetUrl"] := assetUrl
        result["hasUpdate"] := SemverGreater(latest, APP_VERSION)
    } catch as e {
        result["error"] := e.Message
    }
    return result
}

; Download the new exe and spawn a swap script. Returns true if the swap was
; initiated (caller should ExitApp).
UpdaterApply(assetUrl) {
    global UPDATER_APP_NAME, UPDATER_USER_AGENT
    if (assetUrl = "")
        return false
    tempExe := A_Temp "\" UPDATER_APP_NAME "-update.exe"
    tempBat := A_Temp "\" UPDATER_APP_NAME "-update.bat"
    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", assetUrl, false)
        http.SetRequestHeader("User-Agent", UPDATER_USER_AGENT)
        http.SetRequestHeader("Accept", "application/octet-stream")
        http.Send()
        if (http.Status != 200)
            return false
        stream := ComObject("ADODB.Stream")
        stream.Type := 1
        stream.Open()
        stream.Write(http.ResponseBody)
        if FileExist(tempExe)
            FileDelete(tempExe)
        stream.SaveToFile(tempExe, 2)
        stream.Close()
    } catch {
        return false
    }
    targetExe := GetExecutablePath()
    bat := "@echo off`r`n"
        . "ping -n 3 127.0.0.1 > nul`r`n"
        . ":retry`r`n"
        . 'copy /Y "' tempExe '" "' targetExe '" > nul`r`n'
        . "if errorlevel 1 (ping -n 2 127.0.0.1 > nul & goto retry)`r`n"
        . 'start "" "' targetExe '"`r`n'
        . 'del "' tempExe '"`r`n'
        . '(goto) 2>nul & del "%~f0"`r`n'
    if FileExist(tempBat)
        FileDelete(tempBat)
    FileAppend(bat, tempBat)
    Run('"' A_ComSpec '" /c "' tempBat '"', , "Hide")
    return true
}

; Compare two "MAJOR.MINOR.PATCH" strings. Returns true if a > b.
SemverGreater(a, b) {
    aParts := StrSplit(StrSplit(a, "-",,1)[1], ".")
    bParts := StrSplit(StrSplit(b, "-",,1)[1], ".")
    Loop 3 {
        ai := aParts.Has(A_Index) ? Integer(aParts[A_Index]) : 0
        bi := bParts.Has(A_Index) ? Integer(bParts[A_Index]) : 0
        if (ai > bi)
            return true
        if (ai < bi)
            return false
    }
    return false
}

; Lightweight JSON value extraction — only safe for top-level string keys that
; appear once. Sufficient for "tag_name" and "body" in GitHub release JSON.
JsonExtract(json, key) {
    pos := InStr(json, '"' key '"')
    if (!pos)
        return ""
    colon := InStr(json, ':', , pos)
    if (!colon)
        return ""
    rest := SubStr(json, colon + 1)
    rest := LTrim(rest)
    if (SubStr(rest, 1, 1) != '"')
        return ""
    out := ""
    i := 2
    Loop {
        ch := SubStr(rest, i, 1)
        if (ch = "")
            break
        if (ch = "\") {
            next := SubStr(rest, i + 1, 1)
            if (next = "n")
                out .= "`n"
            else if (next = "r")
                out .= "`r"
            else if (next = "t")
                out .= "`t"
            else if (next = '"')
                out .= '"'
            else if (next = "\")
                out .= "\"
            else
                out .= next
            i += 2
            continue
        }
        if (ch = '"')
            break
        out .= ch
        i++
    }
    return out
}

; Find the browser_download_url for the asset whose name matches assetName.
FindAssetUrl(json, assetName) {
    needle := '"name":"' assetName '"'
    p := InStr(json, needle)
    if (!p)
        return ""
    urlPos := InStr(json, '"browser_download_url"', , p)
    if (!urlPos)
        return ""
    colon := InStr(json, ':', , urlPos)
    rest := LTrim(SubStr(json, colon + 1))
    if (SubStr(rest, 1, 1) != '"')
        return ""
    endQuote := InStr(rest, '"', , 2)
    if (!endQuote)
        return ""
    return SubStr(rest, 2, endQuote - 2)
}
