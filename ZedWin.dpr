program ZedWin;

uses
  System.IOUtils,
  Winapi.Windows,
  SysUtils,
  Vcl.Forms,
  FileCtrl,
  Winapi.ShellAPI,
  Dialogs,
  JSON,
  Controls,
  main in 'main.pas' {frmMain},
  frmInstaller in 'frmInstaller.pas' {formInstaller};

{$R *.res}

var
  MutexHandle: THandle = 0;

function CheckSingleInstance: Boolean;
const
  MutexName = 'Global\ZedWinMutex';
begin
  MutexHandle := CreateMutex(nil, True, PChar(MutexName));
  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    // another instance is runnign
    Result := False;
  end
  else
    Result := True;
end;

procedure ReleaseMutex;
begin
  if MutexHandle <> 0 then
    CloseHandle(MutexHandle);
end;

function SelectDirectory(const Caption: string; const Root: WideString; var Directory: string): Boolean;
begin
  Result := FileCtrl.SelectDirectory(Caption, Root, Directory, [sdNewUI, sdNewFolder]);
end;

function PerformSetup: Boolean;
var
  TargetDir, ExePath, NewExePath, SettingsPath: string;
  JSON: TJSONObject;
begin
  Result := False;
  // Get default directory (LocalAppData\ZedWindows)
  TargetDir := IncludeTrailingPathDelimiter(GetEnvironmentVariable('LOCALAPPDATA')) + 'ZedWindows';

  case MessageDlg(PChar('This will install Zed Windows on your machine at:'#13#10#13#10 + TargetDir
   + '\'+#13#10#13#10'Do you confirm that location path?'),
   TMsgDlgType.mtConfirmation, [mbYes, mbNo, mbAbort], 0
  ) of
    mrNo:
    begin
      // Prompt user to select directory
      if SelectDirectory('Select Install Directory', '', TargetDir) then
      begin
        try
          ForceDirectories(TargetDir);
          ExePath := ParamStr(0);
          NewExePath := IncludeTrailingPathDelimiter(TargetDir) + ExtractFileName(ExePath);

          // Copy executable to target directory
          if CopyFile(PChar(ExePath), PChar(NewExePath), False) then
          begin
            // Save settings.json
            JSON := TJSONObject.Create;
            try
              JSON.AddPair('HomeDirectory', TargetDir);
              JSON.AddPair('TargetPath', ''); // Set target path later if needed
              SettingsPath := IncludeTrailingPathDelimiter(TargetDir) + 'settings.json';
              TFile.WriteAllText(SettingsPath, JSON.ToString);
            finally
              JSON.Free;
            end;

            // Launch new instance and exit
            ShellExecute(0, 'OPEN', PChar(NewExePath), nil, nil, SW_SHOWNORMAL);
            Result := True;
          end;
        except
          on E: Exception do
            MessageDlg('Setup failed: ' + E.Message, mtError, [mbOK], 0);
        end;
      end;
    end;
    mrAbort:
      Application.Terminate;
  end;
end;

begin

  Application.Initialize;
  Application.MainFormOnTaskbar := True;

  // Check if settings exist in the current directory
  if TFile.Exists(ExtractFilePath(ParamStr(0)) + 'settings.json') then
  begin
    // Perform setup and exit if successful
//    if PerformSetup then
//      Exit
//    else
//      Application.Terminate;
    Application.ShowMainForm := True;
//    Application.CreateForm(TfrmMain, frmMain);
    Application.CreateForm(TformInstaller, formInstaller);
    Application.Run;
  end

  else if CheckSingleInstance then // if false, another instance is running
  begin
    Application.ShowMainForm := False;
    Application.CreateForm(TfrmMain, frmMain);
//    Application.CreateForm(TFormInstaller, formInstaller);
    Application.Run;
  end
  else if not CheckSingleInstance then
  begin
    frmMain.Show;
  end;
end.
