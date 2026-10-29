; Builds BacaKomik-<version>-windows-setup.exe from the release build.
; iscc /DAppVersion=1.2.3 windows\packaging\installer.iss
;
; Installs per user (no admin prompt), so the in-app updater can run it
; with /SILENT; a silent install starts the app again when done.

#ifndef AppVersion
  #error Pass the version: /DAppVersion=x.y.z
#endif

[Setup]
AppId={{96FFE1FF-7B89-4535-B164-60934AC07517}
AppName=BacaKomik
AppVersion={#AppVersion}
AppPublisher=Kurodev
AppPublisherURL=https://kurodev.org
DefaultDirName={localappdata}\Programs\BacaKomik
DisableProgramGroupPage=yes
DisableDirPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\dist
OutputBaseFilename=BacaKomik-{#AppVersion}-windows-setup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\bacakomik.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Tasks]
Name: desktopicon; Description: "{cm:CreateDesktopIcon}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\BacaKomik"; Filename: "{app}\bacakomik.exe"
Name: "{autodesktop}\BacaKomik"; Filename: "{app}\bacakomik.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\bacakomik.exe"; Description: "{cm:LaunchProgram,BacaKomik}"; Flags: nowait postinstall skipifsilent
Filename: "{app}\bacakomik.exe"; Flags: nowait; Check: WizardSilent
