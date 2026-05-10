# WindowsTvGameMode

Press the **Xbox Guide button** on your controller to flip your PC between **desktop mode** and **couch/TV mode**. Press it again to flip back.

In TV mode the app:

1. Switches the display layout to your TV (via Monitor Profile Switcher).
2. Sets default audio to your TV (via SoundVolumeView).
3. Minimizes all desktop windows.
4. Launches Playnite Fullscreen (optional).

In desktop mode it reverses all four.

> **HDR note:** system-wide HDR is intentionally not toggled. When the TV is the *only* active display on many sets, Windows refuses to expose HDR. Rely on per-game HDR / Windows AutoHDR instead.

Distributed as a single self-contained `.exe` — no AutoHotkey install required.

---

## Install

1. Grab `WindowsTvGameModeSetup.exe` from the [Releases page](https://github.com/gemivnet/WindowsTvGameMode/releases).
2. Double-click to run. The installer is per-user — no admin prompt.
3. SmartScreen will warn (unsigned) — click **More info → Run anyway**.
4. The setup wizard walks through:
   - **External tools** — file pickers for `MonitorSwitcher.exe` and `SoundVolumeView.exe` (with download links)
   - **Display profiles** — pickers for your `tv.xml` / `desktop.xml`
   - **Audio devices** — substring of TV / desktop device names
   - **Playnite** — auto-detected if installed at the default path
   - **Behavior** — poll interval, hold duration

Settings are written to `%APPDATA%\WindowsTvGameMode\config.ini`. Re-running the installer (or the auto-updater) preserves and updates them in place. The app installs to `%LOCALAPPDATA%\Programs\WindowsTvGameMode\` and registers in **Settings → Apps → Installed apps** for clean uninstall.

A tray icon appears once running — right-click it for Settings, autostart toggle, update check, and exit. You can re-edit any of the wizard's values anytime from the in-app Settings dialog.

## External tools (you supply)

Licensing prevents bundling these — install them yourself once:

| Tool | Why | Where |
|---|---|---|
| **Monitor Profile Switcher** (Martin Krämer) | Save + restore full display layouts via the Windows CCD API. | <https://sourceforge.net/projects/monitorswitcher/> |
| **SoundVolumeView** (NirSoft) | Switch default audio device by name. | <https://www.nirsoft.net/utils/sound_volume_view.html> |
| **Playnite** (optional) | Fullscreen launcher. | <https://playnite.link/> |

Drop the `.exe`s somewhere stable (e.g. `C:\Tools\…`) and point the Settings window at them.

> **Why these tools?** Windows has no clean CLI for "switch to exactly this monitor layout" or "make this audio device default". MonitorSwitcher wraps `SetDisplayConfig` (atomic CCD layout swap — the same API the Display Settings page uses), and SoundVolumeView is the smallest reliable CLI for default-audio switching.

## Setup

### 1. Save display profiles

Launch `MonitorSwitcher.exe`. It sits in the tray.

1. In Windows Display Settings, arrange things for **desktop mode** (desktop monitors on, TV off). Set the TV's native resolution and refresh rate first, while it's still enabled — Windows remembers these per-display.
2. Right-click the MonitorSwitcher tray icon → **Save profile as…** → `desktop`.
3. Arrange for **TV mode** (TV on, other monitors off).
4. Right-click → **Save profile as…** → `tv`.

Profiles are stored as XML under `%APPDATA%\MonitorSwitcher\Profiles\`.

### 2. Find your audio device names

```
SoundVolumeView.exe /scomma devices.csv
```

Find the exact `Name` column value for your TV and desktop speakers. Substring matching, so `Hisense` usually works.

### 3. Configure via Settings

Right-click the tray icon → **Settings…**. Fill in:

- **Tools** — paths to `MonitorSwitcher.exe` and `SoundVolumeView.exe`
- **Display** — full paths to your `tv.xml` and `desktop.xml` profiles, settle delay
- **Audio** — device name substrings, role (default `all`)
- **Playnite** — launch toggle, path to `Playnite.FullscreenApp.exe`, close-on-exit
- **General** — poll interval, hold duration, notifications toggle

Settings save to `%APPDATA%\WindowsTvGameMode\config.ini`. A legacy `config.ini` next to the .exe is migrated on first run.

### 4. Press the Guide button

Tray tip should fire and your display/audio/Playnite flip. Press again to flip back.

To launch at login, tray menu → **Start with Windows**.

---

## How it works

- **Guide button detection** — calls `XInputGetStateEx` (undocumented ordinal `100` in `xinput1_4.dll`), which exposes the Guide button as bit `0x0400`. Polls all 4 XInput slots and fires on button-up after the configured hold duration.
- **Display switching** — runs `MonitorSwitcher.exe -load:<profile.xml>`, which calls `SetDisplayConfig` to apply the saved CCD topology atomically.
- **Audio** — `SoundVolumeView.exe /SetDefault "<name>" all` sets both Console and Multimedia default devices.
- **Playnite** — `Playnite.FullscreenApp.exe` is launched on entry and closed with `ProcessClose` on exit.

## Tray menu

- **Toggle TV mode** — same effect as pressing the Guide button
- **Reload config** — re-reads `config.ini` (useful after manual edits)
- **Settings…** — opens the config editor
- **Start with Windows** — toggleable; writes to `HKCU\…\Run`
- **Check for updates** — manual check (auto-runs 5 s after startup too)
- **About** / **Exit**

Logs go to `%APPDATA%\WindowsTvGameMode\tv-mode.log`.

## Auto-update

On launch and via the tray, the app polls GitHub Releases. If a newer build is published it prompts with release notes; **Yes** downloads the new installer and runs it silently — files are replaced, the uninstaller registration stays in sync, and the app relaunches automatically. Your config in `%APPDATA%` is preserved.

## Troubleshooting

**Guide button does nothing.** Controller must be on XInput (USB, Xbox Wireless, or the Xbox Wireless Adapter). If you use Steam, disable Steam Input for the controller or Steam will capture the Guide button first.

**Audio switches to the wrong device.** Use a more specific substring (e.g. `Hisense 65U7N`, not just `Hisense`).

**Playnite doesn't launch.** Point at `Playnite.FullscreenApp.exe`, not `Playnite.DesktopApp.exe`. `%LOCALAPPDATA%` expansion is supported.

**Both modes fire on one press.** Increase **Hold duration** in Settings (try 300–500 ms).

## Building from source

Requires Windows + [AutoHotkey v2](https://www.autohotkey.com/) (which ships with Ahk2Exe under `Compiler\`):

```powershell
& "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" `
    /in src\main.ahk /out dist\WindowsTvGameMode.exe `
    /base "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
```

CI builds an artifact on every push; tag `vX.Y.Z` to trigger a release build.

## Layout

```
src/
  main.ahk                  # entry point
  lib/
    version.ahk             # APP_VERSION (replaced in CI)
    config.ahk              # %APPDATA% ini read/write
    autostart.ahk           # HKCU Run toggle
    updater.ahk             # GitHub Releases polling + swap
    updater_ui.ahk          # update prompt
    tray.ahk                # tray menu builder
    tv_config.ahk           # WindowsTvGameMode config schema + migration
    tv_log.ahk              # logging
    tv_xinput.ahk           # XInput polling for the Guide button
    tv_actions.ahk          # mode toggle + display/audio/Playnite actions
    tv_settings_gui.ahk     # settings window + first-run wizard
config-example.ini          # bundled reference config (also attached to releases)
.github/workflows/
  ci.yml                    # compile-check on push/PR
  release.yml               # build + publish on v*.*.* tag
```
