unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, ACL.UI.Menus, ACL.Classes,
  ACL.UI.TrayIcon, Vcl.ExtCtrls, CB.DarkMode, Net.HttpClient, REST.HttpClient, REST.Types, REST.Json,
  REST.Client, Data.Bind.Components, Data.Bind.ObjectScope, System.JSON, Generics.Collections,
  Vcl.JumpList, ACL.UI.Controls.Base, ACL.UI.Controls.Panel, ACL.UI.Application,
  ACL.UI.Controls.Labels, ACL.UI.Controls.Buttons, ACL.UI.DropSource,
  ACL.UI.DropTarget, ACL.UI.Controls.TreeList.Options,
  ACL.UI.Controls.TreeList.SubClass, ACL.UI.Controls.TreeList.Types,
  ACL.UI.Controls.CompoundControl, ACL.UI.Controls.TreeList,
  ACL.UI.Controls.BaseEditors, ACL.UI.Controls.ScrollBox, ACL.UI.Controls.Memo,
  CB.Downloader, ACL.UI.Controls.FormattedLabel;

const
  RELEASEURL = 'https://api.github.com/repos/vhanla/zed-windows/releases/latest';
  WM_WINDOWMSG = WM_USER + 1;

type
  TfrmMain = class(TForm)
    TrayIcon1: TTrayIcon;
    PopupMenu1: TPopupMenu;
    MenuExit: TMenuItem;
    Timer1: TTimer;
    MenuRestart: TMenuItem;
    RESTRequest1: TRESTRequest;
    RESTResponse1: TRESTResponse;
    RESTClient1: TRESTClient;
    JumpList1: TJumpList;
    ACLLabel1: TACLLabel;
    ACLApplicationController1: TACLApplicationController;
    ACLPanel1: TACLPanel;
    ACLButton1: TACLButton;
    ACLButton2: TACLButton;
    lblZedVersion: TACLLabel;
    lblCheckUpdateResult: TACLLabel;
    zedvulkandownloader: TCBDownloader;
    zedopengldownloader: TCBDownloader;
    ACLPanel2: TACLPanel;
    ACLFormattedLabel1: TACLFormattedLabel;
    procedure FormCreate(Sender: TObject);
    procedure MenuRestartClick(Sender: TObject);
    procedure MenuExitClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure ACLButton1Click(Sender: TObject);
    procedure ACLButton2Click(Sender: TObject);
    procedure zedopengldownloaderDownloadClick(Sender: TObject;
      button: Integer);
    procedure zedvulkandownloaderDownloadClick(Sender: TObject;
      button: Integer);
    procedure zedvulkandownloaderDownloaded(Sender: TObject;
      DownloadCode: Integer);
    procedure zedopengldownloaderDownloaded(Sender: TObject;
      DownloadCode: Integer);
  private
    { Private declarations }
    FTargetProcessHandle: THandle;
    FTargetProcessID: Cardinal;
    FCommandLine: string;
    FAssets: TStringList;
    FTagName: string;
    FRelName: string;
    FDescription: string;
    FReleaseDate: TDateTime;

    FZedFilePath: string;
    FZedVersion: string;

    procedure LaunchTargetApplication(const Params: string);
    procedure RestartTargetApplication;
    procedure MonitorTargetApplication;
    procedure ShowNotification(const Title, Msg: string);
    procedure CheckForUpdates;
    function CloseZedInstances(Sender: TObject): Boolean;
    procedure UnpackZipAndReplaceZed(Sender: TObject);
    procedure CreateParams(var Params: TCreateParams); override;

    procedure WMMsgHandler(var Msg: TMessage); message WM_WINDOWMSG;
  public
    { Public declarations }

    procedure CheckRelease;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  System.DateUtils, Winapi.ShellAPI, TlHelp32, Zip;//, dxLib_WinInjection;

function SetCurrentProcessExplicitAppUserModelID(AppID: PWideChar): HRESULT; stdcall;
  external 'shell32.dll' name 'SetCurrentProcessExplicitAppUserModelID';


{$R *.dfm}

function InjectDLLAndData(const pTargetProcessID: DWORD; const pSourceDLLFullPathName: string; const pConstantData: string; const pSuppressOSError: Boolean = True): Boolean;
var
  vKernel32Handle: HMODULE;
  vTargetProcessHandle: THandle;
  vRemoteThreadID: DWORD;
  vRemoteThreadHandle: THandle;
  pRemoteBuffer, pConstantDataRemote: Pointer;
  vBytesToWrite, vBytesWritten: NativeUInt;
  vLoadLibraryProc: FARPROC;
  hDllModule: HMODULE;
  hDllInInjector: HMODULE;
  pFuncInInjector: FARPROC;
  rva: DWORD_PTR;
  pFuncInTarget: FARPROC;
  dataSize: NativeUInt;
  vExitCode: DWORD;
begin
  Result := False;
  if pTargetProcessID = 0 then Exit;

  vTargetProcessHandle := OpenProcess(PROCESS_CREATE_THREAD or PROCESS_QUERY_INFORMATION or PROCESS_VM_OPERATION or PROCESS_VM_WRITE or PROCESS_VM_READ, False, pTargetProcessID);
  if vTargetProcessHandle = 0 then
  begin
    if not pSuppressOSError then RaiseLastOSError();
    Exit;
  end;

  try
    // Allocate and write DLL path
    vBytesToWrite := (Length(pSourceDLLFullPathName) + 1) * SizeOf(Char);
    pRemoteBuffer := VirtualAllocEx(vTargetProcessHandle, nil, vBytesToWrite, MEM_COMMIT, PAGE_READWRITE);
    if pRemoteBuffer = nil then
    begin
      if not pSuppressOSError then RaiseLastOSError();
      Exit;
    end;

    try
      if not WriteProcessMemory(vTargetProcessHandle, pRemoteBuffer, PChar(pSourceDLLFullPathName), vBytesToWrite, vBytesWritten) then
      begin
        if not pSuppressOSError then RaiseLastOSError();
        Exit;
      end;

      vKernel32Handle := GetModuleHandle('kernel32.dll');
      if vKernel32Handle = 0 then
      begin
        if not pSuppressOSError then RaiseLastOSError();
        Exit;
      end;

      {$IFDEF UNICODE}
      vLoadLibraryProc := GetProcAddress(vKernel32Handle, 'LoadLibraryW');
      {$ELSE}
      vLoadLibraryProc := GetProcAddress(vKernel32Handle, 'LoadLibraryA');
      {$ENDIF}
      if vLoadLibraryProc = nil then
      begin
        if not pSuppressOSError then RaiseLastOSError();
        Exit;
      end;

      // Inject DLL
      vRemoteThreadHandle := CreateRemoteThread(vTargetProcessHandle, nil, 0, vLoadLibraryProc, pRemoteBuffer, 0, vRemoteThreadID);
      if vRemoteThreadHandle = 0 then
      begin
        if not pSuppressOSError then RaiseLastOSError();
        Exit;
      end;

      try
        WaitForSingleObject(vRemoteThreadHandle, INFINITE);
        if not GetExitCodeThread(vRemoteThreadHandle, vExitCode) then
        begin
          if not pSuppressOSError then RaiseLastOSError();
          Exit;
        end;

        hDllModule := HMODULE(vExitCode); // Correctly assign the received value

        // Allocate and write constant data
        dataSize := (Length(pConstantData) + 1) * SizeOf(Char);
        pConstantDataRemote := VirtualAllocEx(vTargetProcessHandle, nil, dataSize, MEM_COMMIT, PAGE_READWRITE);
        if pConstantDataRemote = nil then
        begin
          if not pSuppressOSError then RaiseLastOSError();
          Exit;
        end;

        try
          if not WriteProcessMemory(vTargetProcessHandle, pConstantDataRemote, PChar(pConstantData), dataSize, vBytesWritten) then
          begin
            if not pSuppressOSError then RaiseLastOSError();
            Exit;
          end;

          // Get exported function address in target process
          hDllInInjector := LoadLibraryEx(PChar(pSourceDLLFullPathName), 0, DONT_RESOLVE_DLL_REFERENCES);
          if hDllInInjector = 0 then
          begin
            if not pSuppressOSError then RaiseLastOSError();
            Exit;
          end;

          try
            pFuncInInjector := GetProcAddress(hDllInInjector, 'InitializeData');
            if pFuncInInjector = nil then
            begin
              if not pSuppressOSError then RaiseLastOSError();
              Exit;
            end;

            rva := DWORD_PTR(pFuncInInjector) - DWORD_PTR(hDllInInjector);
            pFuncInTarget := FARPROC(DWORD_PTR(hDllModule) + rva);

            // Call InitializeData in target process
            vRemoteThreadHandle := CreateRemoteThread(vTargetProcessHandle, nil, 0, pFuncInTarget, pConstantDataRemote, 0, vRemoteThreadID);
            if vRemoteThreadHandle = 0 then
            begin
              if not pSuppressOSError then RaiseLastOSError();
              Exit;
            end;

            try
              WaitForSingleObject(vRemoteThreadHandle, INFINITE);
            finally
              CloseHandle(vRemoteThreadHandle);
            end;
          finally
            FreeLibrary(hDllInInjector);
          end;
        finally
          // Note: Do not free pConstantDataRemote here; the DLL should free it when done
        end;

        Result := True;
      finally
        CloseHandle(vRemoteThreadHandle);
      end;
    finally
      VirtualFreeEx(vTargetProcessHandle, pRemoteBuffer, 0, MEM_RELEASE);
    end;
  finally
    CloseHandle(vTargetProcessHandle);
  end;
end;

function GetTempDirectory: string;
var
  TempPathBuffer: array[0..MAX_PATH] of Char;
begin
  // Retrieve the path to the temporary directory
  if GetTempPath(MAX_PATH, @TempPathBuffer) > 0 then
    Result := StrPas(TempPathBuffer) // Convert the C-style string to a Delphi string
  else
    raise Exception.Create('Unable to retrieve the temporary directory.');
end;

function FindMainWindow(ProcessID: DWORD): HWND;
var
  lhWnd: HWND;
  PID: DWORD;
begin
  Result := 0;
  lhWnd := FindWindow(nil, nil);
  while lhWnd <> 0 do
  begin
    GetWindowThreadProcessId(lhWnd, @PID);
    if PID = ProcessID then
    begin
      if IsWindowVisible(lhWnd) and (GetWindow(lhWnd, GW_OWNER) = 0) then
      begin
        Result := lhWnd;
        Exit;
      end;
    end;
    lhWnd := GetWindow(lhWnd, GW_HWNDNEXT);
  end;
end;


function ReplaceFile(const TargetPath: string; const NewFilePath: string): Boolean;
var
  BackupPath: string;
begin
  BackupPath := TargetPath + '.old';

  // Try to delete existing backup
  if FileExists(BackupPath) then
    DeleteFile(BackupPath);

  // Rename current executable to backup
  if not RenameFile(TargetPath, BackupPath) then
  begin
    Result := False;
    Exit;
  end;

  // Move new file into place
  Result := MoveFile(PChar(NewFilePath), PChar(TargetPath));

  // Cleanup backup if successful
  if Result then
    DeleteFile(BackupPath)
  else
    RenameFile(BackupPath, TargetPath); // Restore backup if failed
end;

function GetProductVersion(const FileName: string): string;
var
  Dummy: DWORD;
  VerInfoSize: DWORD;
  VerInfo: Pointer;
  VerValue: Pointer;
  VerValueSize: DWORD;
begin
  Result := '';
  VerInfoSize := GetFileVersionInfoSize(PChar(FileName), Dummy);
  if VerInfoSize > 0 then
  begin
    GetMem(VerInfo, VerInfoSize);
    try
      if GetFileVersionInfo(PChar(FileName), 0, VerInfoSize, VerInfo) then
      begin
        if VerQueryValue(VerInfo, '\', VerValue, VerValueSize) then
        begin
          with PVSFixedFileInfo(VerValue)^ do
          begin
//            Result := Format('%d.%d.%d.%d',
//              [dwFileVersionMS div $10000,
//               dwFileVersionMS mod $10000,
//               dwFileVersionLS div $10000,
//               dwFileVersionLS mod $10000]);
            Result := Format('%d.%d.%d',
              [dwFileVersionMS div $10000,
               dwFileVersionMS mod $10000,
               dwFileVersionLS div $10000]);
          end;
        end;
      end;
    finally
      FreeMem(VerInfo);
    end;
  end;
end;

function NormalizeVersion(Version: string; out Extra: string): string;
var
  VersionParts: TStringList;
  i: Integer;
  VersionWithoutExtra: string;
begin
  Result := '';
  Extra := '';
  VersionParts := TStringList.Create;
  try
    // Remove leading 'v' if present
    if Copy(Version, 1, 1) = 'v' then
      Version := Copy(Version, 2, Length(Version) - 1);

    // Split the version string into parts
    VersionParts.Delimiter := '.';
    VersionParts.DelimitedText := Version;

    // Ensure we have at least 3 parts
    if VersionParts.Count < 3 then
      Exit;

    // Take the first 3 parts
    for i := 0 to 2 do
    begin
      if i < VersionParts.Count then
        Result := Result + VersionParts[i];
      if i < 2 then
        Result := Result + '.';
    end;

    // Check for extra non-numeric suffix
    VersionWithoutExtra := Result;
    if Length(Version) > Length(VersionWithoutExtra) then
    begin
      Extra := Copy(Version, Length(VersionWithoutExtra) + 1, Length(Version) - Length(VersionWithoutExtra));
    end;
  finally
    VersionParts.Free;
  end;
end;

function ExtractDelimited(Index: Integer; const S: string; Delimiter: Char): string;
var
  StartPos, EndPos, LastPos: Integer;
begin
  Result := '';
  StartPos := 1;
  LastPos := 0;
  for EndPos := 1 to Length(S) do
  begin
    if S[EndPos] = Delimiter then
    begin
      if Index = LastPos + 1 then
      begin
        Result := Copy(S, StartPos, EndPos - StartPos);
        Exit;
      end;
      Inc(LastPos);
      StartPos := EndPos + 1;
    end;
  end;
  if Index = LastPos + 1 then
    Result := Copy(S, StartPos, Length(S) - StartPos + 1);
end;

function CompareVersions(Version1, Version2: string): Integer;
var
  Version1Parts, Version2Parts: array[0..2] of Integer;
  i: Integer;
  Extra1, Extra2: string;
begin
  Result := 0;

  // Normalize and split the versions
  Version1 := NormalizeVersion(Version1, Extra1);
  Version2 := NormalizeVersion(Version2, Extra2);

  // Split the version strings into their components
  Version1Parts[0] := StrToIntDef(ExtractDelimited(1, Version1, '.'), 0);
  Version1Parts[1] := StrToIntDef(ExtractDelimited(2, Version1, '.'), 0);
  Version1Parts[2] := StrToIntDef(ExtractDelimited(3, Version1, '.'), 0);

  Version2Parts[0] := StrToIntDef(ExtractDelimited(1, Version2, '.'), 0);
  Version2Parts[1] := StrToIntDef(ExtractDelimited(2, Version2, '.'), 0);
  Version2Parts[2] := StrToIntDef(ExtractDelimited(3, Version2, '.'), 0);

  // Compare the version components
  for i := 0 to 2 do
  begin
    if Version1Parts[i] < Version2Parts[i] then
    begin
      Result := -1;
      Exit;
    end
    else if Version1Parts[i] > Version2Parts[i] then
    begin
      Result := 1;
      Exit;
    end;
  end;
end;

function ISO8601ToDateTime(const ADate: string): TDateTime;
var
  DateValue: string;
  TimeValue: string;
  Y, M, D, H, N, S: Word;
begin
  DateValue := Copy(ADate, 1, 10);
  TimeValue := Copy(ADate, 12, 8);
  Y := StrToInt(Copy(DateValue, 1, 4));
  M := StrToInt(Copy(DateValue, 6, 2));
  D := StrToInt(Copy(DateValue, 9, 2));
  H := StrToInt(Copy(TimeValue, 1, 2));
  N := StrToInt(Copy(TimeValue, 4, 2));
  S := StrToInt(Copy(TimeValue, 7, 2));
  Result := EncodeDateTime(Y, M, D, H, N, S, 0);
end;

function GetProcessWindow(ProcessHandle: THandle): HWND;
var
  ProcessID: DWORD;
  ThreadID: DWORD;
  WindowHandle: HWND;
begin
  Result := 0;
  ProcessID := GetProcessId(ProcessHandle);
  WindowHandle := GetWindow(GetDesktopWindow, GW_CHILD);
  while WindowHandle <> 0 do
  begin
    ThreadID := GetWindowThreadProcessId(WindowHandle, @ProcessID);
    if ThreadID = GetCurrentThreadId then
    begin
      WindowHandle := GetWindow(WindowHandle, GW_HWNDNEXT);
      Continue;
    end;
    if ProcessID = GetProcessId(ProcessHandle) then
    begin
      Result := WindowHandle;
      Break;
    end;
    WindowHandle := GetWindow(WindowHandle, GW_HWNDNEXT);
  end;
end;

procedure TfrmMain.ACLButton1Click(Sender: TObject);
var
  I: TCollectionItem;
  ComparisonResult: Integer;
  Extra1, Extra2: string;
  Key: string;

begin
  CheckRelease;

  if FAssets.Count > 0 then
  begin
    ACLFormattedLabel1.Caption := FRelName + #13#10 + FTagName + #13#10 + FDescription;

    ComparisonResult := CompareVersions(FTagName, FZedVersion);

    if ComparisonResult > 0 then
      lblCheckUpdateResult.Caption := 'There is a new Zed version: ' + FTagName
    else if ComparisonResult < 0 then
      lblCheckUpdateResult.Caption := 'Your Zed version is newer than: ' + FTagName
    else
      lblCheckUpdateResult.Caption := 'You are up to date: ' + FTagName;

    for var j := 0 to FAssets.Count - 1 do
    begin
      if not FAssets[j].Contains('sha256') then
      begin
        if FAssets[j].Contains('opengl') then
        begin
          Key := FAssets.Names[j];
          zedopengldownloader.Caption := Key;
          zedopengldownloader.URL := FAssets.Values[Key];
          zedopengldownloader.SavePath := GetTempDirectory + Key;
        end;
        if FAssets[j].Contains('vulkan') then
        begin
          Key := FAssets.Names[j];
          zedvulkandownloader.Caption := Key;
          zedvulkandownloader.URL := FAssets.Values[Key];
          zedvulkandownloader.SavePath := GetTempDirectory + Key;
        end;
      end;

    end;
  end;
end;

procedure TfrmMain.ACLButton2Click(Sender: TObject);
begin

  ShellExecute(0, 'OPEN', PChar(ExtractFilePath(FZedFilePath)), nil, nil, SW_SHOWNORMAL);
end;

procedure TfrmMain.CheckForUpdates;
begin
//  try
//    RESTRequest1.Resource := 'endpoint'; // Replace with your REST API endpoint
//    RESTRequest1.Execute;
//
//    if RESTResponse1.StatusCode = 200 then
//    begin
//      var JSON := TJSONObject.ParseJSONValue(RESTResponse1.Content);
//      try
//        if JSON.TryGetValue<string>('update', var UpdateMessage) then
//          ShowNotification('Update Available', UpdateMessage);
//      finally
//        JSON.Free;
//      end;
//    end;
//  except
//    on E: Exception do
//      ShowNotification('Error', 'Failed to check updates: ' + E.Message);
//  end;
end;

procedure TfrmMain.CheckRelease;
var
  HttpClient: THTTPClient;
  Response: IHTTPResponse;
  JsonObj, AssetsObj: TJSONObject;
  JsonArray: TJSONArray;
  JsonValue: TJSONValue;
  I: Integer;
  Url, TagName, FileName: string;
  ResultList: TStringList;
  LGitHub: string;
begin
  LGitHub := RELEASEURL;
  ResultList := TStringList.Create;
  HttpClient := THTTPClient.Create;
  try
    Response := HttpClient.Get(LGitHub);
    if Response.StatusCode = 200 then
    begin
      JsonObj := TJSONObject.ParseJSONValue(Response.ContentAsString()) as TJSONObject;
      try
        FRelName := JsonObj.GetValue('name').Value;
        FTagName := JsonObj.GetValue('tag_name').Value;
        FDescription := JsonObj.GetValue('body').Value;
        var fecha := JsonObj.GetValue('published_at').Value;
        FReleaseDate := ISO8601ToDateTime(fecha);
        JsonArray := JsonObj.GetValue('assets') as TJSONArray;
        for I := 0 to JsonArray.Count - 1 do
        begin
          AssetsObj := JsonArray.Items[I] as TJSONObject;
          FileName := AssetsObj.GetValue('name').Value;
          Url := AssetsObj.GetValue('browser_download_url').Value;

          // Filter conditions
          ResultList.AddPair(FileName, Url);
        end;
      finally
        JsonObj.Free;
      end;
    end;

    if Assigned(FAssets) then
      FAssets.Free;
    FAssets := ResultList;
  finally
    HttpClient.Free;
//    ResultList.Free;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  SetCurrentProcessExplicitAppUserModelID('C:\Users\vhanla\projects\rust\zed\target\release\zed.exe');

//  SetDarkMode(Handle, True);

  // Tray Icon setup
  TrayIcon1.Visible := True;
  TrayIcon1.Icon := Application.Icon;
  TrayIcon1.Hint := 'Transparent Proxy Launcher';

  // Popup Menu setup
  MenuRestart.Caption := 'Restart Application';
  MenuExit.Caption := 'Exit';
//  PopupMenu1.Items.Add(MenuRestart);
//  PopupMenu1.Items.Add(MenuExit);
//  TrayIcon1.PopupMenu := PopupMenu;

  // Capture command-line parameters
  FCommandLine := ParamStr(1);
  for var I := 2 to ParamCount do
    FCommandLine := FCommandLine + ' ' + ParamStr(I);

  // Launch the target application
  LaunchTargetApplication(FCommandLine);

  // Timer to monitor application and updates (interval: 10 seconds)
  Timer1.Interval := 10000;
  Timer1.Enabled := True;

  // Assets direct download links
  FAssets := TStringList.Create;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FAssets.Free;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_HIDE);
end;

procedure TfrmMain.UnpackZipAndReplaceZed(Sender: TObject);
var
  ZipPath: string;
  TempDir: string;
  TempPathBuffer: array[0..MAX_PATH] of Char;
  Guid: TGUID;
begin
  if GetTempPath(MAX_PATH, @TempPathBuffer) > 0 then
    TempDir := IncludeTrailingPathDelimiter(StrPas(TempPathBuffer))
  else
    raise Exception.Create('Unable to retrieve the temporary directory.'); // + 'zed_update\';

  if CreateGUID(Guid) = S_OK then
    TempDir := TempDir + GUIDToString(Guid).Replace('{', '').Replace('}', '')
  else
    raise Exception.Create('Unable to generate a unique directory name.');

  if not CreateDirectory(PChar(TempDir), nil) then
    raise Exception.Create('Unalbe to create temporary directory: ' + TempDir);

  ZipPath := TCBDownloader(Sender).SavePath;
  try
    // ForceDirectories(TempDir);
    TZipFile.ExtractZipFile(ZipPath, TempDir);

    // Replace executable
    if ReplaceFile(FZedFilePath, TempDir + '\zed.exe') then
    begin
      ShowMessage('Update successful!');
      RestartTargetApplication;
    end
    else
      ShowMessage('Update failed: Could not replace executable.');
  except
    on E: Exception do
      ShowMessage('Update failed: ' + E.Message);
  end;

  // Cleanup
  DeleteFile(ZipPath);
//  DeleteDirectory(TempDir, False);
end;

procedure TfrmMain.WMMsgHandler(var Msg: TMessage);
begin
  Show;
end;

procedure TfrmMain.LaunchTargetApplication(const Params: string);
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  vLastError: DWORD;
begin
  FZedFilePath := 'C:\Users\vhanla\projects\rust\zed\target\release\zed.exe'; // Replace with the actual target application path

  FZedVersion := GetProductVersion(FZedFilePath);

  FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
  StartupInfo.cb := SizeOf(TStartupInfo);

  if CreateProcess(nil, PChar(FZedFilePath + ' ' + Params), nil, nil, False, 0, nil, nil { PChar(ExtractFilePath(AppPath))}, StartupInfo, ProcessInfo) then
  begin
    FTargetProcessHandle := ProcessInfo.hProcess;
    FTargetProcessID := ProcessInfo.dwProcessId;


    lblZedVersion.Caption := 'Current Zed version: ' + FZedVersion;

    if not InjectDLLAndData(FTargetProcessID,
      ExtractFilePath(ParamStr(0)) + 'ZedHook.dll',
      ExtractFilePath(ParamStr(0)),
      True) then
    begin
      vLastError := GetLastError();
      if vLastError <> 0 then
        ShowMessage(SysErrorMessage(vLastError));
    end;

    CloseHandle(ProcessInfo.hThread);
  end
  else
    ShowNotification('Error', 'Failed to launch application: ' + SysErrorMessage(GetLastError));

end;

procedure TfrmMain.MenuExitClick(Sender: TObject);
var
  MainWindowHandle: HWND;
begin
  // Clean up and terminate
  if FTargetProcessHandle <> 0 then
  begin
    MainWindowHandle := GetWindow(GetProcessWindow(FTargetProcessHandle), GW_HWNDFIRST);
    if MainWindowHandle <> 0 then
    begin
      PostMessage(MainWindowHandle, WM_CLOSE, 0, 0);
      WaitForSingleObject(FTargetProcessHandle, INFINITE);
    end;
//    TerminateProcess(FTargetProcessHandle, 0);
    CloseHandle(FTargetProcessHandle);
  end;

  Application.Terminate;
end;

procedure TfrmMain.MenuRestartClick(Sender: TObject);
begin
  RestartTargetApplication;
end;

procedure TfrmMain.MonitorTargetApplication;
var
  ExitCode: Cardinal;
begin
  if FTargetProcessHandle <> 0 then
  begin
    if GetExitCodeProcess(FTargetProcessHandle, ExitCode) and (ExitCode <> STILL_ACTIVE) then
    begin
      ShowNotification('Info', 'Target application has exited.');
      CloseHandle(FTargetProcessHandle);
      FTargetProcessHandle := 0;
    end;
  end;
end;

procedure TfrmMain.RestartTargetApplication;
begin
  // Terminate the current process if running
  if FTargetProcessHandle <> 0 then
    TerminateProcess(FTargetProcessHandle, 0);

  // Restart the target application with the same command-line arguments
  LaunchTargetApplication(FCommandLine);
end;

procedure TfrmMain.ShowNotification(const Title, Msg: string);
begin
//  TrayIcon.BalloonHint := Msg;
//  TrayIcon.BalloonTitle := Title;
//  TrayIcon.ShowBalloonHint;
end;

procedure TfrmMain.Timer1Timer(Sender: TObject);
begin
  MonitorTargetApplication;
  CheckForUpdates;
end;

procedure TfrmMain.TrayIcon1DblClick(Sender: TObject);
begin
  if not Visible then
    Show
  else
    Hide;
end;

function TfrmMain.CloseZedInstances(Sender: TObject): Boolean;
var
//  hProcess: THandle;
  ProcessID: DWORD;
//  BackupPath: string;
//  NewExePath: string;
//  ZipPath: string;

  // Check if target process is running which for sure, since we are the launchers :P
  // But maybe another instance is running outside of our launcher parenting
  function IsProcessRunning: Boolean;
  var
    SnapShot: THandle;
    ProcEntry: TProcessEntry32;
  begin
    Result := False;
    SnapShot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if SnapShot <> INVALID_HANDLE_VALUE then
    try
      ProcEntry.dwSize := SizeOf(ProcEntry);
      if Process32First(SnapShot, ProcEntry) then
      repeat
        if SameText(ProcEntry.szExeFile, ExtractFileName(FZedFilePath)) then
        begin
          ProcessID := ProcEntry.th32ProcessID;
          Result := True;
          Break;
        end;
      until not Process32Next(SnapShot, ProcEntry);
    finally
      CloseHandle(SnapShot);
    end;
  end;

  // Try to gracefully close the process
  function TryCloseProcess: Boolean;
  var
    lhWnd: HWND;
    Timeout: Cardinal;
  begin
    Result := False;
    lhWnd := FindMainWindow(ProcessID);
    if lhWnd <> 0 then
    begin
      SetForegroundWindow(lhWnd);
      PostMessage(lhWnd, WM_CLOSE, 0, 0);
      Timeout := GetTickCount + 10000;
      while GetTickCount < Timeout do
      begin
        if not IsProcessRunning then
        begin
          Result := True;
          Exit;
        end;
        Sleep(100);
      end;
    end;
  end;

begin
  Result := False; //
  if not IsProcessRunning then
  begin
    Result := True;
    Exit;
  end;

  if TryCloseProcess then
  begin
    Result := True;
    Exit;
  end;

  // If we get here, ask the user to close manually
  case MessageDlg('Please close the application to continue with the update.',
    mtConfirmation, [mbRetry, mbAbort], 0) of
    mrRetry: CloseZedInstances(Sender);
    mrAbort: Exit;
  end;
end;

procedure TfrmMain.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.WinClassName := 'Zed::Window';
end;

procedure TfrmMain.zedopengldownloaderDownloadClick(Sender: TObject;
  button: Integer);
begin
  if not zedopengldownloader.IsDownloading then
    zedopengldownloader.DoStartDownload;
end;

procedure TfrmMain.zedopengldownloaderDownloaded(Sender: TObject;
  DownloadCode: Integer);
begin
  if CloseZedInstances(Sender) then
    UnpackZipAndReplaceZed(Sender);
end;

procedure TfrmMain.zedvulkandownloaderDownloadClick(Sender: TObject;
  button: Integer);
begin
  if not zedvulkandownloader.IsDownloading then
    zedvulkandownloader.DoStartDownload;
end;

procedure TfrmMain.zedvulkandownloaderDownloaded(Sender: TObject;
  DownloadCode: Integer);
begin
  if CloseZedInstances(Sender) then
    UnpackZipAndReplaceZed(Sender);
end;

end.

