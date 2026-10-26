; Version and paths are supplied by scripts/build-windows.ps1.
[Setup]
AppId=electblake.HoverRacer
AppName=Hover Racer
AppVersion={#AppVersion}
AppPublisher=electblake
AppPublisherURL=https://github.com/electblake/hover-racer
DefaultDirName={localappdata}\Programs\Hover Racer
DefaultGroupName=Hover Racer
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#ReleaseDir}
OutputBaseFilename=HoverRacer-{#AppVersion}-Windows-Setup
UninstallDisplayIcon={app}\HoverRacer.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Files]
Source: "{#PortableDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Icons]
Name: "{autoprograms}\Hover Racer"; Filename: "{app}\HoverRacer.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\Hover Racer"; Filename: "{app}\HoverRacer.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\HoverRacer.exe"; Description: "{cm:LaunchProgram,Hover Racer}"; Flags: nowait postinstall skipifsilent
