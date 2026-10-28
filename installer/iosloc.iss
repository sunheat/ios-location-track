; Inno Setup script for the Windows location simulator.
; The installer does not include Apple Mobile Device Support. The application
; checks for it at launch and runs as the current user. Install it separately
; with administrator privileges only when it is missing.

#define MyAppName "iOS 虚拟定位轨迹工具"
#define MyAppNameEn "iOSLocationTrack"
#define MyAppVersion "1.1.0"
#define MyAppPublisher "本地工具"
#define MyAppExeName "iOSLocationTrack.exe"
#define DistDir "..\dist\iOSLocationTrack"

[Setup]
AppId={{8F3A5C21-6B4E-4D7A-9E15-2C7B0A4F9D31}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Programs\{#MyAppNameEn}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
; 每用户安装，不需要管理员；但程序自身启动时会请求提权（装 Apple 驱动用）
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=..\dist\installer
; 产物名带 _win 后缀，与 macOS 的 _mac 对应，Release 页面上一眼能分清平台。
OutputBaseFilename={#MyAppNameEn}-{#MyAppVersion}_win-setup
SetupIconFile=..\resources\AppIcon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
; 程序需要 Windows 10 1809+ / Windows 11
DisableWelcomePage=no
LicenseFile=..\README.md

[Languages]
; Inno Setup 6.7 起官方安装包不再自带简体中文，因此把翻译文件随仓库一起带着
; （installer\languages\ChineseSimplified.isl），保证任何机器上都能构建出中文安装向导。
; 文件缺失时自动退回英文，不会让构建失败。
#define ChineseIsl "languages\ChineseSimplified.isl"
#if FileExists(AddBackslash(SourcePath) + ChineseIsl)
Name: "chinese"; MessagesFile: "compiler:Default.isl,{#ChineseIsl}"
#endif
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务:"; Flags: checkedonce
Name: "quicklaunchicon"; Description: "创建快速启动栏快捷方式"; GroupDescription: "附加任务:"; Flags: unchecked

[Files]
Source: "{#DistDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; 注意：不要在这里放 Apple 的驱动/安装包。程序会按需自动下载，避免分发第三方二进制。

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\检查 Apple 驱动"; Filename: "{app}\{#MyAppExeName}"; Parameters: "--check-driver"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "立即运行 {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; 只删安装目录内的临时文件；用户数据（%LOCALAPPDATA%\iOSLocationTrack）保留，
; 里面有 config.json 和瓦片缓存，卸载后重装还能用。
Type: filesandordirs; Name: "{app}\_internal\__pycache__"
