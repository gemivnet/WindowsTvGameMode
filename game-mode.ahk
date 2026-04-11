#Requires AutoHotkey v2.0
Loop {
    loop 32 {
        if GetKeyState("Joy" A_Index)
            ToolTip "Button: Joy" A_Index
    }
    Sleep 50
}