[Setup]
AppName=Everlastimer
AppVersion={#MyAppVersion}
DefaultDirName={autopf}\Everlastimer
DefaultGroupName=Everlastimer
OutputBaseFilename=Everlastimer-setup-{#MyAppVersion}
OutputDir=Output
Compression=lzma2
SolidCompression=yes

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Everlastimer"; Filename: "{app}\Everlastimer.exe"
