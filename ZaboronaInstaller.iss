; TODO: Возможно стоит добавить какую-то кастомную страницу в диалог, которая будет спрашивать, добавлять ли программу в Автозагрузку

; Имя программы лдя всяких заголовков окон инсталлятора, группы програм в пуске и т.п.
#define MyAppName "Zaborona OpenVPN"
; Краткое имя программы без пробелов
#define ShortAppName "ZaboronaVPN"
; Имя исполнительного файла инсталлятора, которое будет дано файлу загруженному из Интернета
#define InstallerExeName "open-vpn-latest.msi"
; Имя базового файла конфигурации OpenVPN от Zaborona Help
;#define ConfigName "zaborona-help.ovpn"
#define ConfigName "zaborona-help-max-tcp.ovpn"
; Возможные параметры запуска OpenVPN можно посмотреть в командной строке: "openvpn-gui.exe --help"
#define LnkParamString "--connect " + ConfigName + " --show_balloon 2 --silent_connection 1 --show_script_window 0"; 
#define LnkComment "Запускает OpenVPN и подключается к Zaborona Help";
#define GuiExePath "{app}\bin\openvpn-gui.exe";

[Setup]
AppName={#MyAppName}
; Версия тут ни к селу, ни к городу, но убрать нельзя
AppVerName="{#MyAppName} (последний релиз)"
WizardStyle=modern
DefaultDirName={autopf}\{#ShortAppName}
DefaultGroupName={#ShortAppName}
Uninstallable=yes
OutputDir=..\InnoSetupOutput
OutputBaseFilename=ZaboronaInstaller
DisableReadyPage=Yes
DisableReadyMemo=No
; Ни в коем случае не отключать эту страницу, т.к. после перехода с неё начинается закачка файлов, 
; но если её запретить, тогда надо разрешить, тогда нужно разрешить какую-то другую страницу - см. секцию [Code]
;DisableDirPage=No
DirExistsWarning=No
DisableFinishedPage=No
; Запрещаем изменять имя группы в каталоге установке
DisableProgramGroupPage=Yes
; запрещаем страницу приветствия
DisableWelcomePage=Yes

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Files]
; These files will be downloaded
Source: "{tmp}\{#InstallerExeName}"; DestDir: "{tmp}\Downloads"; Flags: external
Source: "{tmp}\{#ConfigName}"; DestDir: "{app}\Config"; Flags: external

[Icons]
; Добавляем два одинаковых ярлыка на Рабочий стол и в группу Программ
Name: "{commondesktop}\{#MyAppName}"; Filename: {#GuiExePath}; Parameters: {#LnkParamString}; Comment: {#LnkComment}; Flags: preventpinning;
Name: "{group}\{#MyAppName}"; Filename: {#GuiExePath}; Parameters: {#LnkParamString}; Comment: {#LnkComment}; Flags: preventpinning;
Name: "{group}\{#MyAppName}"; Filename: {#GuiExePath}; Parameters: {#LnkParamString}; Comment: {#LnkComment}; Flags: preventpinning;

[Run]
; параметры установки OpenVPN взяты отсюда: https://forums.openvpn.net/viewtopic.php?f=5&t=27017
; msiexec /i OpenVPN-2.5.0-I601-amd64.msi ADDLOCAL=OpenVPN.Service,OpenVPN,Drivers,Drivers.Wintun /passive
Filename: "msiexec"; Description: "Open VPN с настройками от проекта Zaborona Help"; StatusMsg: "Установка OpenVPN..."; Parameters: "/i {tmp}\Downloads\{#InstallerExeName} /passive PRODUCTDIR=""{app}""";

[UninstallRun]
; Без параметры /S диалог удаления выглядит нелогично для пользователя, т.к. появляется 2 диалога
Filename: "msiexec"; Parameters: "/passive /uninstall A662F537-DB6E-4F00-9C2F-7946CBD3F807"

;[Registry]
; Пытаться удалить ключ здесь бесполезно (хотя это помогает в т.ч. для настройки в GUI), т.к. он создаётся только после первой перезагрузки
;Root: HKCU; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "OPENVPN-GUI"; Flags: deletekey

[Code]
const
  AMD64_WIN_INSTALL_URL = 'https://build.openvpn.net/downloads/releases/latest/openvpn-latest-stable-amd64.msi';
  X86_WIN_INSTALL_URL = 'https://build.openvpn.net/downloads/releases/latest/openvpn-latest-stable-x86.msi';

var
  DownloadPage: TDownloadWizardPage;

function OnDownloadProgress(const Url, FileName: String; const Progress, ProgressMax: Int64): Boolean;
begin
  if Progress = ProgressMax then
    Log(Format('Successfully downloaded file to {tmp}: %s', [FileName]));
  Result := True;
end;

procedure InitializeWizard;
begin
  DownloadPage := CreateDownloadPage(SetupMessage(msgWizardPreparing), SetupMessage(msgPreparingDesc), @OnDownloadProgress);
end;


function NextButtonClick(CurPageID: Integer): Boolean;
var
  installUrl : string;
begin
  {
  PageID values for predefined wizard pages
    wpWelcome, wpLicense, wpPassword, wpInfoBefore, wpUserInfo, wpSelectDir, wpSelectComponents, wpSelectProgramGroup, wpSelectTasks, wpReady, wpPreparing, wpInstalling, wpInfoAfter, wpFinished
  } 
  //if CurPageID = wpReady then begin
  if CurPageID = wpSelectDir then begin  
    DownloadPage.Clear();    
    if (IsWin64()) then
      begin
        installUrl := AMD64_WIN_INSTALL_URL;
      end
    else
      begin
        installUrl := X86_WIN_INSTALL_URL;
      end;
    DownloadPage.Add(installUrl, ExpandConstant('{#InstallerExeName}'), '');    // last param - known file hash to check after download
    //эта ссылка тоже работает, но на сайте её уже не пуюликуют
    //DownloadPage.Add('https://zaborona.help/zaborona-help.ovpn', 'zaborona-help.ovpn', '');
    DownloadPage.Add('https://zaborona.help/openvpn-client-config/srv0.zaborona-help_maxroutes.ovpn', '{#ConfigName}', '');
    DownloadPage.Show();
    try
      try
        DownloadPage.Download(); // This downloads the files to {tmp}
        Result := True;
      except
        if DownloadPage.AbortedByUser then
          Log('Aborted by user.')
        else
          SuppressibleMsgBox(AddPeriod(GetExceptionMessage), mbCriticalError, MB_OK, IDOK);
        Result := False;
      end;
    finally
      DownloadPage.Hide();
    end;
  end else
    Result := True;
end;
