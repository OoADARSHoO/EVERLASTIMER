[Setup]
AppName=Everlastimer
AppVersion={#MyAppVersion}
AppPublisher=Everlastimer
AppPublisherURL=https://github.com/OoADARSHoO/EVERLASTIMER
DefaultDirName={autopf}\Everlastimer
DefaultGroupName=Everlastimer
OutputBaseFilename=Everlastimer-setup-{#MyAppVersion}
OutputDir=Output
Compression=lzma2
SolidCompression=yes
UninstallDisplayIcon={app}\everlastimer.exe
SetupIconFile=..\app\windows\runner\resources\app_icon.ico
PrivilegesRequired=admin

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Everlastimer"; Filename: "{app}\everlastimer.exe"
Name: "{group}\Everlastimer Widget"; Filename: "{app}\widget\EverlastimerWidget.exe"
Name: "{group}\Uninstall Everlastimer"; Filename: "{uninstallexe}"
Name: "{commondesktop}\Everlastimer"; Filename: "{app}\everlastimer.exe"
