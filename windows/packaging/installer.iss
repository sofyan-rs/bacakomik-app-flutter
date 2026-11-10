; Builds Yoru-<version>-windows-setup.exe from the release build.
; iscc /DAppVersion=1.2.3 windows\packaging\installer.iss
;
; Installs per user (no admin prompt), so the in-app updater can run it
; with /SILENT; a silent install starts the app again when done.
;
; The app was called BacaKomik before (bacakomik.exe in
; Programs\BacaKomik). AppId is unchanged, so an update replaces that
; install: it goes to Programs\Yoru (UsePreviousAppDir=no), and the old
; folder and shortcuts are removed. The app moves its data folder from
; %APPDATA%\kurodev\BacaKomik to %APPDATA%\kurodev\Yoru on its first start.

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
UsePreviousAppDir=no
DisableProgramGroupPage=yes
DisableDirPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\dist
OutputBaseFilename=Yoru-{#AppVersion}-windows-setup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\yoru.exe
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
; The BacaKomik install, replaced by this one.
Type: filesandordirs; Name: "{localappdata}\Programs\BacaKomik"
; bacakomik.exe and its files, if this folder ever held them.
Type: files; Name: "{app}\bacakomik.exe"

[Icons]
Name: "{autoprograms}\Yoru"; Filename: "{app}\yoru.exe"
Name: "{autodesktop}\Yoru"; Filename: "{app}\yoru.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\yoru.exe"; Description: "{cm:LaunchProgram,Yoru}"; Flags: nowait postinstall skipifsilent
Filename: "{app}\yoru.exe"; Flags: nowait; Check: WizardSilent
