# WindowsTvGameMode

Press the **Xbox Guide button** on your controller to flip your PC between **desktop mode** and **couch/TV mode**. Press it again to flip back.

In TV mode, the script:

1. Switches the display to your TV only (e.g. monitor 3)
2. Sets default audio to your TV
3. Launches Playnite Fullscreen

In desktop mode, it reverses all three.

> **HDR note:** system-wide HDR is intentionally not toggled by this script. When the TV is the *only* active display on many sets (Hisense included), Windows refuses to expose HDR. If you want HDR, rely on per-game HDR / Windows AutoHDR instead — those work independently of the display output topology.

Everything is driven by `config.ini`, so others can adapt it to their own hardware without touching the script.

---

## Requirements

| Component | Why | Where |
|---|---|---|
| **AutoHotkey v2** | runs the script | <https://www.autohotkey.com/> |
| **Monitor Profile Switcher** (Martin Krämer) | save + restore full display layouts via the Windows CCD API | <https://sourceforge.net/projects/monitorswitcher/> |
| **SoundVolumeView** (NirSoft) | switch default audio device by name | <https://www.nirsoft.net/utils/sound_volume_view.html> |
| **Playnite** (optional) | fullscreen launcher | <https://playnite.link/> |
| **Xbox controller** (XInput) | the Guide button trigger | — |

> **Why these tools?** Windows has no clean CLI for "switch to exactly this monitor layout" or "make this audio device default". MonitorSwitcher uses the proper CCD (`SetDisplayConfig`) API to atomically load a saved layout — much more reliable than per-monitor enable/disable via MultiMonitorTool, which silently fails on many systems when disabling the current primary. SoundVolumeView is the smallest reliable CLI for audio default switching.

---

## Setup

### 1. Install the tools

Install AutoHotkey v2. Drop `MonitorSwitcher.exe` and `SoundVolumeView.exe` somewhere stable, e.g. `C:\Tools\MonitorSwitcher\` and `C:\Tools\SoundVolumeView\`.

### 2. Save your display profiles

Launch `MonitorSwitcher.exe` — it sits in the tray.

1. In Windows Display Settings, arrange things exactly how you want **desktop mode** (e.g. both desktop monitors on, TV off). Also set your TV's native resolution and refresh rate in Windows now, before disabling it — Windows remembers these per-display.
2. Right-click the MonitorSwitcher tray icon → **Save profile as…** → name it `desktop`.
3. Now arrange things for **TV mode** (TV on, other monitors off).
4. Right-click the tray icon → **Save profile as…** → name it `tv`.

Profiles are stored as XML under `%APPDATA%\MonitorSwitcher\Profiles\`. You can verify by running:

```
dir "$env:AppData\MonitorSwitcher\Profiles"
```

Test that both load correctly from the command line before wiring them into the script:

```
MonitorSwitcher.exe -load:"$env:AppData\MonitorSwitcher\Profiles\tv.xml"
MonitorSwitcher.exe -load:"$env:AppData\MonitorSwitcher\Profiles\desktop.xml"
```

> The CLI wants a **full path** to the XML file, not just the profile name.

### 3. Find your audio device names

Run:

```
SoundVolumeView.exe /scomma devices.csv
```

Open `devices.csv`, find the exact **Name** column value of your TV and your desktop speakers. Put them in `config.ini` under `[Audio]`. Matching is by substring, so `Hisense` usually works.

### 4. Create your `config.ini`

Copy `config-example.ini` to `config.ini` in the same folder, then update every path in `[Tools]`, `[Display]`, and `[Playnite]`, plus device names in `[Audio]`. Everything is commented inline.

> `config.ini` is gitignored so your personal paths never end up in the repo. Only `config-example.ini` is committed.

### 5. Run it

Double-click `WindowsTvGameMode.ahk`. It goes to the tray. Press the Xbox Guide button on your controller — you should see a tray tip and your TV/HDR/audio/Playnite flip over.

To run it at login, put a shortcut to the `.ahk` file in `shell:startup`.

---

## How it works

- **Guide button detection** — the Xbox Guide button is not a normal joystick button. Windows intercepts it for Game Bar, and AHK's `GetKeyState "JoyN"` doesn't see it. This script calls `XInputGetStateEx` (undocumented ordinal `100` in `xinput1_4.dll`), which exposes the Guide button as bit `0x0400`. The polling loop watches all 4 XInput slots and fires on button-up (after an optional hold duration).
- **Display switching** — runs `MonitorSwitcher.exe -load:<profile.xml>` to load a pre-saved layout. MonitorSwitcher wraps the Windows CCD API (`QueryDisplayConfig` / `SetDisplayConfig`) and applies the full topology atomically — enabled displays, disabled displays, resolutions, primary, and arrangement all in one call. This is what Windows' own Display Settings page uses internally. An earlier version of this script composed the layout dynamically with MultiMonitorTool `/enable` / `/disable` / `/SetPrimary`, but MMT silently no-ops when asked to disable the current primary on many systems, and no amount of ordering worked around it reliably.
- **Audio** — `SoundVolumeView.exe /SetDefault "<name>" all` sets both the console and multimedia default devices.
- **Playnite** — launched via `Playnite.FullscreenApp.exe` (the fullscreen "big picture" build) and closed with `ProcessClose` on exit.

---

## Config reference

See `config.ini` for the full template. Keys worth highlighting:

- `General.HoldDurationMs` — set to e.g. `400` if you want to require a short hold to toggle (prevents accidental double-toggles if a game doesn't swallow the Guide button).
- `General.PollInterval` — 75 ms is a good default. Lower if the button feels laggy.
- `Display.SettleDelayMs` — how long to wait after switching displays before switching audio. Bump this if your TV is slow to sync.
- `Playnite.CloseOnExit` — set `false` if you'd rather leave Playnite running in the background.

---

## Troubleshooting

**The Guide button does nothing.** Make sure the controller is connected via XInput (USB, Xbox Wireless, or the "Xbox Wireless Adapter"). DirectInput-only controllers won't work. If you use Steam, disable "Steam Input" for the Xbox controller or Steam will capture the Guide button before us.

**Audio switches to the wrong device.** `SoundVolumeView` matches by substring against the device name. Use a more specific name, e.g. `Hisense 65U7N` instead of `Hisense`, if you have multiple Hisense outputs (HDMI + ARC).

**Playnite doesn't launch.** Verify `Playnite.Path` points at `Playnite.FullscreenApp.exe` (not `Playnite.DesktopApp.exe`). `%LOCALAPPDATA%` expansion is supported.

**Both modes fire on a single press.** Increase `General.PollInterval` slightly, or set `General.HoldDurationMs` to `300+`.

---

## Files

- `WindowsTvGameMode.ahk` — main script
- `config-example.ini` — template config (committed)
- `config.ini` — your local config (gitignored)
- `.gitignore`
- `README.md` — this file
