; Inno Setup installer for WindowsTvGameMode.
; Custom wizard pages collect tool paths, display profiles, audio devices, and
; Playnite path, then write them to %APPDATA%\WindowsTvGameMode\config.ini.

#ifndef AppVersion
  #define AppVersion "0.0.0-dev"
#endif

#define AppName       "WindowsTvGameMode"
#define AppPublisher  "gemivnet"
#define AppExeName    "AutoHotkey64.exe"
#define AppScript     "src\main.ahk"
#define AppURL        "https://github.com/gemivnet/WindowsTvGameMode"

[Setup]
AppId={{9AD86FFB-CE19-4FD1-BB6D-0E1D21C27C79}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}/issues
AppUpdatesURL={#AppURL}/releases
DefaultDirName={userpf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
DisableDirPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputBaseFilename=WindowsTvGameModeSetup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\{#AppExeName}
AppMutex=WindowsTvGameMode-9AD86FFB
#if FileExists(AddBackslash(SourcePath) + "..\assets\icon.ico")
SetupIconFile=..\assets\icon.ico
#endif
CloseApplications=force
RestartApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked
Name: "startupicon"; Description: "Start {#AppName} when Windows starts"; GroupDescription: "Autostart:"

[Files]
Source: "..\ahk\AutoHotkey64.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\src\*"; DestDir: "{app}\src"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\config-example.ini"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Parameters: """{app}\{#AppScript}"""; WorkingDir: "{app}"; IconFilename: "{app}\{#AppExeName}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{userdesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Parameters: """{app}\{#AppScript}"""; WorkingDir: "{app}"; IconFilename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "{#AppName}"; ValueData: """{app}\{#AppExeName}"" ""{app}\{#AppScript}"""; Flags: uninsdeletevalue; Tasks: startupicon

[Run]
Filename: "{app}\{#AppExeName}"; Parameters: """{app}\{#AppScript}"""; WorkingDir: "{app}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent

; -----------------------------------------------------------------------------
; Custom wizard pages
; -----------------------------------------------------------------------------
[Code]
const
  MS_DOWNLOAD_URL  = 'https://sourceforge.net/projects/monitorswitcher/';
  SVV_DOWNLOAD_URL = 'https://www.nirsoft.net/utils/sound_volume_view.html';

var
  ToolsPage:    TInputFileWizardPage;
  ProfilesPage: TInputFileWizardPage;
  AudioPage:    TInputQueryWizardPage;
  PlaynitePage: TInputFileWizardPage;
  GeneralPage:  TInputQueryWizardPage;

function GetConfigDir(): String;
begin
  Result := ExpandConstant('{userappdata}\{#AppName}');
end;

function GetConfigFile(): String;
begin
  Result := GetConfigDir() + '\config.ini';
end;

procedure ReadExistingConfig(var msPath, svvPath, tvProfile, dskProfile,
  tvDevice, dskDevice, playnitePath, pollInterval, holdMs: String);
var
  cfg: String;
begin
  cfg := GetConfigFile();
  msPath := '';        svvPath := '';
  tvProfile := '';     dskProfile := '';
  tvDevice := '';      dskDevice := '';
  playnitePath := '';
  pollInterval := '75'; holdMs := '0';
  if not FileExists(cfg) then exit;
  msPath        := GetIniString('Tools',    'MonitorSwitcher',  '', cfg);
  svvPath       := GetIniString('Tools',    'SoundVolumeView',  '', cfg);
  tvProfile     := GetIniString('Display',  'TvProfile',        '', cfg);
  dskProfile    := GetIniString('Display',  'DesktopProfile',   '', cfg);
  tvDevice      := GetIniString('Audio',    'TvDevice',         '', cfg);
  dskDevice     := GetIniString('Audio',    'DesktopDevice',    '', cfg);
  playnitePath  := GetIniString('Playnite', 'Path',             '', cfg);
  pollInterval  := GetIniString('General',  'PollInterval',  '75', cfg);
  holdMs        := GetIniString('General',  'HoldDurationMs','0',  cfg);
end;

function DefaultPlaynitePath(): String;
begin
  Result := ExpandConstant('{localappdata}\Playnite\Playnite.FullscreenApp.exe');
end;

procedure InitializeWizard();
var
  msPath, svvPath, tvProfile, dskProfile, tvDevice, dskDevice, playnitePath: String;
  pollInterval, holdMs: String;
begin
  ReadExistingConfig(msPath, svvPath, tvProfile, dskProfile,
    tvDevice, dskDevice, playnitePath, pollInterval, holdMs);

  ToolsPage := CreateInputFilePage(wpSelectTasks,
    'External tools',
    'Locate Monitor Profile Switcher and SoundVolumeView',
    'WindowsTvGameMode drives display and audio switching through these two tools.' + #13#10 +
    'Download them from the links below if you don''t have them yet, then point at the .exe paths.' + #13#10#13#10 +
    'Monitor Profile Switcher: ' + MS_DOWNLOAD_URL + #13#10 +
    'SoundVolumeView: ' + SVV_DOWNLOAD_URL);
  ToolsPage.Add('MonitorSwitcher.exe path:', 'Executable files (*.exe)|*.exe', '.exe');
  ToolsPage.Add('SoundVolumeView.exe path:', 'Executable files (*.exe)|*.exe', '.exe');
  ToolsPage.Values[0] := msPath;
  ToolsPage.Values[1] := svvPath;

  ProfilesPage := CreateInputFilePage(ToolsPage.ID,
    'Display profiles',
    'Saved Monitor Profile Switcher XML profiles',
    'Use Monitor Profile Switcher''s tray menu (Save profile as…) to capture your TV-only and ' +
    'desktop-only display arrangements as XML files. They live under %APPDATA%\MonitorSwitcher\Profiles\.' + #13#10#13#10 +
    'Skip this page if you''ll set the paths later from the in-app Settings dialog.');
  ProfilesPage.Add('TV profile XML:',      'Profile XML files (*.xml)|*.xml', '.xml');
  ProfilesPage.Add('Desktop profile XML:', 'Profile XML files (*.xml)|*.xml', '.xml');
  ProfilesPage.Values[0] := tvProfile;
  ProfilesPage.Values[1] := dskProfile;

  AudioPage := CreateInputQueryPage(ProfilesPage.ID,
    'Audio devices',
    'Default audio device names for each mode',
    'Match by substring against the Name column shown in Windows Sound settings or in ' +
    'SoundVolumeView. Use a longer substring if you have multiple devices with similar names ' +
    '(e.g. your full TV model name rather than just "Hisense").');
  AudioPage.Add('TV audio device (substring):',      False);
  AudioPage.Add('Desktop audio device (substring):', False);
  AudioPage.Values[0] := tvDevice;
  AudioPage.Values[1] := dskDevice;

  PlaynitePage := CreateInputFilePage(AudioPage.ID,
    'Playnite (optional)',
    'Path to Playnite Fullscreen',
    'If you use Playnite as a couch launcher, point at Playnite.FullscreenApp.exe. ' +
    'Leave blank to skip Playnite integration entirely.');
  PlaynitePage.Add('Playnite.FullscreenApp.exe path:', 'Executable files (*.exe)|*.exe', '.exe');
  if (playnitePath = '') and FileExists(DefaultPlaynitePath()) then
    PlaynitePage.Values[0] := DefaultPlaynitePath()
  else
    PlaynitePage.Values[0] := playnitePath;

  GeneralPage := CreateInputQueryPage(PlaynitePage.ID,
    'Behavior',
    'Polling and toggle behavior',
    'These can be tuned later from the in-app Settings dialog.');
  GeneralPage.Add('Poll interval (ms, default 75):', False);
  GeneralPage.Add('Hold duration to toggle (ms, 0 = instant):', False);
  GeneralPage.Values[0] := pollInterval;
  GeneralPage.Values[1] := holdMs;
end;

procedure WriteConfig();
var
  cfg: String;
begin
  cfg := GetConfigFile();
  if not DirExists(GetConfigDir()) then
    ForceDirectories(GetConfigDir());

  SetIniString('General',  'PollInterval',     GeneralPage.Values[0], cfg);
  SetIniString('General',  'HoldDurationMs',   GeneralPage.Values[1], cfg);
  if GetIniString('General', 'ShowNotifications', '', cfg) = '' then
    SetIniString('General', 'ShowNotifications', 'true', cfg);

  SetIniString('Tools',    'MonitorSwitcher',  ToolsPage.Values[0], cfg);
  SetIniString('Tools',    'SoundVolumeView',  ToolsPage.Values[1], cfg);

  SetIniString('Display',  'TvProfile',        ProfilesPage.Values[0], cfg);
  SetIniString('Display',  'DesktopProfile',   ProfilesPage.Values[1], cfg);
  if GetIniString('Display', 'SettleDelayMs', '', cfg) = '' then
    SetIniString('Display', 'SettleDelayMs', '2500', cfg);

  SetIniString('Audio',    'TvDevice',         AudioPage.Values[0], cfg);
  SetIniString('Audio',    'DesktopDevice',    AudioPage.Values[1], cfg);
  if GetIniString('Audio', 'Role', '', cfg) = '' then
    SetIniString('Audio', 'Role', 'all', cfg);

  if PlaynitePage.Values[0] <> '' then begin
    SetIniString('Playnite', 'Launch',      'true', cfg);
    SetIniString('Playnite', 'Path',        PlaynitePage.Values[0], cfg);
    if GetIniString('Playnite', 'CloseOnExit', '', cfg) = '' then
      SetIniString('Playnite', 'CloseOnExit', 'true', cfg);
  end else begin
    SetIniString('Playnite', 'Launch', 'false', cfg);
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    WriteConfig();
end;
