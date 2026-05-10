; XInput polling for the Xbox Guide button.
; Uses undocumented ordinal 100 (XInputGetStateEx) which exposes Guide bit 0x0400.

global XInputGetStateExPtr := 0
global GuideWasDown := false
global GuideDownSince := 0

InitXInput() {
    global XInputGetStateExPtr
    for dll in ["xinput1_4.dll", "xinput1_3.dll", "xinput9_1_0.dll"] {
        hMod := DllCall("LoadLibrary", "Str", dll, "Ptr")
        if hMod {
            XInputGetStateExPtr := DllCall("GetProcAddress", "Ptr", hMod, "Ptr", 100, "Ptr")
            if XInputGetStateExPtr
                return
        }
    }
    MsgBox "Could not load XInput. Xbox Guide button detection needs xinput1_4.dll (Windows 8+).", "WindowsTvGameMode", "Iconx"
    ExitApp 1
}

IsGuideDown() {
    global XInputGetStateExPtr
    state := Buffer(16, 0)
    Loop 4 {
        userIndex := A_Index - 1
        res := DllCall(XInputGetStateExPtr, "UInt", userIndex, "Ptr", state, "UInt")
        if (res = 0) {
            buttons := NumGet(state, 4, "UShort")
            if (buttons & 0x0400)
                return true
        }
    }
    return false
}

PollController(*) {
    global GuideWasDown, GuideDownSince, TvConfig
    down := IsGuideDown()
    if (down && !GuideWasDown) {
        GuideWasDown := true
        GuideDownSince := A_TickCount
    } else if (!down && GuideWasDown) {
        held := A_TickCount - GuideDownSince
        GuideWasDown := false
        if (held >= TvConfig["HoldDurationMs"])
            ToggleTvMode()
    }
}
