#define AppName "ZED Windows"
#define AppPublisher "vhanla"
#define AppURL "https://github.com/vhanla/zed-windows/"

[Setup]
AppName={#AppName}
AppVersion=1.0
WizardStyle=modern
AppPublisher={#AppPublisher}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={localappdata}\ZedWin
//DisableProgramGroupPage=no
//DisableDirPage=no
//OutputBaseFilename=ZedWinSetup
PrivilegesRequired=lowest
UninstallDisplayIcon={app}\{#AppName}.exe
//SetupLogging=yes
; my customization
DefaultGroupName={#AppName}
Compression=lzma2
SolidCompression=yes
//OutputDir=userdocs:Inno Setup Examples Output
OutputBaseFilename=ZedWinSetup
; "ArchitecturesAllowed=x64compatible" specifies that Setup cannot run
; on anything but x64 and Windows 11 on Arm.
ArchitecturesAllowed=x64compatible
; "ArchitecturesInstallIn64BitMode=x64compatible" requests that the
; install be done in "64-bit mode" on x64 or Windows 11 on Arm,
; meaning it should use the native 64-bit Program Files directory and
; the 64-bit view of the registry.
ArchitecturesInstallIn64BitMode=x64compatible

[Files]
Source: "C:\Users\vhanla\projects\rust\zed\launcher\Win64\Debug\ZedWin.exe"; DestDir: "{app}"; Flags: external
Source: "C:\Users\vhanla\projects\rust\zed\launcher\Win64\Debug\ZedHook.dll"; DestDir: "{app}"; Flags: external
; These files will be downloaded
;Source: "{tmp}\zed.exe"; DestDir: "{app}"; Flags: external

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\ZedWin.exe"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\ZedWin.exe"

[UninstallDelete]
Type: files; Name: "{app}\ZedWin.exe"
Type: files; Name: "{app}\zed.exe"
Type: files; Name: "{app}\*"

[Code]
#Include "JsonParser.pas" 
//https://stackoverflow.com/a/34291316 How to parse a JSON string in Inno Setup?

const
  SHCONTCH_NOPROGRESSBOX = 4;
  SHCONTCH_RESPONDYESTOALL = 16;

type
  TAsset = record
    Name: string;
    URL: string;
  end;

var
  DownloadPage: TDownloadWizardPage;
  Packages: array of TAsset;
  RadioButtonPage: TInputOptionWizardPage;
  SelectedPackage: Integer;

function GetJsonRoot(Output: TJsonParserOutput): TJsonObject;
begin
  Result := Output.Objects[0];
end;

function FindJsonValue(
  Output: TJsonParserOutput; Parent: TJsonObject; Key: TJsonString;
  var Value: TJsonValue): Boolean;
var
  I: Integer;
begin
  for I := 0 to Length(Parent) - 1 do
  begin
    if Parent[I].Key = Key then
    begin
      Value := Parent[I].Value;
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

function FindJsonObject(
  Output: TJsonParserOutput; Parent: TJsonObject; Key: TJsonString;
  var Object: TJsonObject): Boolean;
var
  JsonValue: TJsonValue;
begin
  Result :=
    FindJsonValue(Output, Parent, Key, JsonValue) and
    (JsonValue.Kind = JVKObject);
  if Result then
    Object := Output.Objects[JsonValue.Index];
end;

function FindJsonArray(
  Output: TJsonParserOutput; Parent: TJsonObject; Key: TJsonString;
  var lArray: TJsonArray): Boolean;
var
  JsonValue: TJsonValue;
begin
  Result :=
    FindJsonValue(Output, Parent, Key, JsonValue) and
    (JsonValue.Kind = JVKArray);
  if Result then
    lArray := Output.Arrays[JsonValue.Index];
end;

function FindJsonString(
  Output: TJsonParserOutput; Parent: TJsonObject; Key: TJsonString;
  var Str: TJsonString): Boolean;
var
  JsonValue: TJsonValue;
begin
  Result :=
    FindJsonValue(Output, Parent, Key, JsonValue) and
    (JsonValue.Kind = JVKString);
  if Result then
    Str := Output.Strings[JsonValue.Index];
end;

function ParseJsonAndLogErrors(
  var JsonParser: TJsonParser; const Source: WideString): Boolean;
var
  I: Integer;
begin
  ParseJson(JsonParser, Source);
  Result := (Length(JsonParser.Output.Errors) = 0);
  if not Result then
  begin
    Log('JSON parsing errors:');
    for I := 0 to Length(JsonParser.Output.Errors) - 1 do
      Log(JsonParser.Output.Errors[I]);
  end;
end;
  
procedure LoadAssets;
var
  WinHttpReq: Variant;
  Response: string;
  JsonParser: TJsonParser;
  RootObj: TJsonObject;
  AssetsArray: TJsonArray;
  AssetObj: TJsonObject;
  I: Integer;
  AssetName, AssetUrl: TJsonString;
begin
  try
    WinHttpReq := CreateOleObject('WinHttp.WinHttpRequest.5.1');
    WinHttpReq.Open('GET', 'https://api.github.com/repos/vhanla/zed-windows/releases/latest', False);
    WinHttpReq.Send;
    
    if WinHttpReq.Status = 200 then
    begin
      Response := WinHttpReq.ResponseText;
      if ParseJsonAndLogErrors(JsonParser, Response) then
      begin
        RootObj := GetJsonRoot(JsonParser.Output);
        if FindJsonArray(JsonParser.Output, RootObj, 'assets', AssetsArray) then
        begin
          for I := 0 to Length(AssetsArray) - 1 do
          begin
            AssetObj := JsonParser.Output.Objects[AssetsArray[I].Index];
            if FindJsonString(JsonParser.Output, AssetObj, 'name', AssetName) and
               FindJsonString(JsonParser.Output, AssetObj, 'browser_download_url', AssetUrl) then
            begin
              if ((Pos('zed-opengl', AssetName) > 0) or (Pos('zed-vulkan', AssetName) > 0)) and not (Pos('.sha256', AssetName) > 0) then
              begin                 
                SetArrayLength(Packages, GetArrayLength(Packages) + 1);
                Packages[GetArrayLength(Packages)-1].Name := AssetName;
                Packages[GetArrayLength(Packages)-1].URL := AssetUrl;
              end;
            end;
          end;
        end;
      end;
      ClearJsonParser(JsonParser);
    end;
  except
    Log('Error loading assets: ' + GetExceptionMessage);
  end;
end;

//https://stackoverflow.com/a/40706549 
procedure UnZip(ZipPath, TargetPath: string);
var
  Shell: Variant;
  ZipFile: Variant;
  TargetFolder: Variant;
  MaxWait: Integer;
  Tries: Integer;
begin
  Shell := CreateOleObject('Shell.Application');
  ForceDirectories(TargetPath);
  
  ZipFile := Shell.NameSpace(ZipPath);
  if VarIsClear(ZipFile) then
    RaiseException(Format('ZIP file "%s" does not exist or cannot be opened', [ZipPath]));

  TargetFolder := Shell.NameSpace(TargetPath);
  if VarIsClear(TargetFolder) then
    RaiseException(Format('Failed to create target directory: "%s"', [TargetPath]));

  TargetFolder.CopyHere(
    ZipFile.Items, SHCONTCH_NOPROGRESSBOX or SHCONTCH_RESPONDYESTOALL);
   // Wait for extraction to complete (max 30 seconds)
  MaxWait := 30;
  Tries := 0;
  while (Tries < MaxWait) and not FileExists(ExpandConstant('{app}\zed.exe')) do
  begin
    Sleep(1000);
    Tries := Tries + 1;
    Log(Format('Waiting for extraction... %d/%d', [Tries, MaxWait]));
  end;

  if Tries >= MaxWait then
  begin
    WizardForm.NextButton.Enabled := True;
    WizardForm.BackButton.Enabled := True;
    WizardForm.CancelButton.Enabled := True;        
    RaiseException('Extraction timed out - zed.exe not found');
  end;
end;


function OnDownloadProgress(const Url, FileName: String; const Progress, ProgressMax: Int64): Boolean;
begin
  if Progress = ProgressMax then
    Log(Format('Successfully downloaded file to {tmp}: %s', [FileName]));
  Result := True;
end;

procedure InitializeWizard;
var
  i: Integer;
begin
  LoadAssets;
  
  RadioButtonPage := CreateInputOptionPage(wpWelcome,
    'Select Package', 'Which version do you want to install?',
    'Please select the graphics API version:', True, False);
    
  for i := 0 to GetArrayLength(Packages) - 1 do
    RadioButtonPage.Add(Packages[i].Name);
  
  RadioButtonPage.SelectedValueIndex := 0;
  
  DownloadPage := CreateDownloadPage(SetupMessage(msgWizardPreparing), SetupMessage(msgPreparingDesc), @OnDownloadProgress);
  //DownloadPage.ShowBaseNameInsteadOfUrl := True;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  ZipPath: string;  
begin
  Result := True;
  
  if CurPageID = RadioButtonPage.ID then
  begin
    SelectedPackage := RadioButtonPage.SelectedValueIndex;
  end
  else if CurPageID = wpReady then
  begin
    DownloadPage.Clear;
    ZipPath := ExpandConstant('{tmp}\') + Packages[SelectedPackage].Name;
    
    // Add only the selected package to download
    DownloadPage.Add(Packages[SelectedPackage].URL, Packages[SelectedPackage].Name, '');
    
    try
      DownloadPage.Show;
      try
        DownloadPage.Download;
      finally
        DownloadPage.Hide;
      end;
      // Extract using Windows Shell
      try
        WizardForm.NextButton.Enabled := False;
        WizardForm.BackButton.Enabled := False;
        WizardForm.CancelButton.Enabled := False;        
        UnZip(ZipPath, ExpandConstant('{app}'));
        
        // Verify extraction
        if not FileExists(ExpandConstant('{app}\zed.exe')) then
          RaiseException('zed.exe not found in the downloaded package');
      except
        WizardForm.NextButton.Enabled := True;
        WizardForm.BackButton.Enabled := True;
        WizardForm.CancelButton.Enabled := True;        
        MsgBox('Extraction failed: ' + GetExceptionMessage, mbError, MB_OK);
        Result := False;
        Exit;
      end;
          
    except
      if DownloadPage.AbortedByUser then
        Log('Aborted by user.')
      else
        MsgBox('Download failed: ' + GetExceptionMessage, mbError, MB_OK);
      Result := False;
      Exit;
    end;
    
    // Extract ZIP using Windows built-in tar since build 17063 (version 1803) Windows 10
    //if not ShellExec('', 'tar', ExpandConstant('-xf "{tmp}\' + Packages[SelectedPackage].Name + '" -C "{app}"'), '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    //begin
    //  MsgBox('Failed to extract files', mbError, MB_OK);
    //  Result := False;
    //end;
  end;
end;

(*function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  if not FileExists(ExpandConstant('{app}\zed.exe')) then
  begin
      NeedsRestart := False;
      Result := 'fasdfasd';
    
  end else
    Result := 'sfsdfds';
end;*)
