; Builds Yoru-<version>-windows-setup.exe from the release build.
; iscc /DAppVersion=1.2.3 windows\packaging\installer.iss
;
; Installs per user (no admin prompt), so the in-app updater can run it
; with /SILENT; a silent install starts the app again when done.
;
; The app was called BacaKomik before. AppId is unchanged, so an update
; installs into the folder of the earlier install, and the old shortcuts
; are removed. The data folder (%APPDATA%\kurodev\BacaKomik) comes from
; ProductName in Runner.rc, which stays BacaKomik.

#ifndef AppVersion
  #error Pass the version: /DAppVersion=x.y.z
#endif

[Setup]
AppId={{96FFE1FF-7B89-4535-B164-60934AC07517}
AppName=Yoru
AppVersion={#AppVersion}
AppPublisher=Kurodev
AppPublisherURL=https://kurodev.org
DefaultDirName={localappdata}\Programs\Yoru
DisableProgramGroupPage=yes
DisableDirPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\dist
OutputBaseFilename=Yoru-{#AppVersion}-windows-setup
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

[InstallDelete]
Type: files; Name: "{autoprograms}\BacaKomik.lnk"
Type: files; Name: "{autodesktop}\BacaKomik.lnk"

[Icons]
Name: "{autoprograms}\Yoru"; Filename: "{app}\bacakomik.exe"
Name: "{autodesktop}\Yoru"; Filename: "{app}\bacakomik.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\bacakomik.exe"; Description: "{cm:LaunchProgram,Yoru}"; Flags: nowait postinstall skipifsilent
Filename: "{app}\bacakomik.exe"; Flags: nowait; Check: WizardSilent
