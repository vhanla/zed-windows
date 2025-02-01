library ZedHook;

uses
  Winapi.Windows,
  messages,
  DDetours,
  System.SysUtils,
  System.Classes,
  Winapi.CommCtrl; // Required for TaskDialogIndirect

{$R *.res}

type
  // Corrected declaration to match Windows API
  PTASKDIALOGCONFIG = ^TTaskDialogConfig;
  TCorrectTaskDialogIndirect = function(
    const pTaskConfig: PTASKDIALOGCONFIG;
    pnButton: PInteger;
    pnRadioButton: PInteger;
    pfVerificationFlagChecked: PBOOL
  ): HRESULT; stdcall;

var
  GlobalDataPtr: PChar;
  OriginalTaskDialogIndirect: TCorrectTaskDialogIndirect = nil;

procedure InitializeData(DataPtr: PChar); stdcall;
begin
  GlobalDataPtr := DataPtr;
end;

function HookedTaskDialogIndirect(const pTaskConfig: PTASKDIALOGCONFIG;
  pnButton: PInteger; pnRadioButton: PInteger;
  pfVerificationFlagChecked: PBOOL): HRESULT; stdcall;
const
  WM_WINDOWMSG = WM_USER + 1;
var
  lHandle: HWND;
begin
  if Assigned(pTaskConfig) then
  begin
    // Modify dialog content
//    pTaskConfig.pszMainInstruction := 'Hooked Instruction';

    if Pos('vhanla', pTaskConfig.pszContent) > 0 then
    begin
      lHandle := FindWindow('Zed::Window', 'Zed Launcher');
      if lHandle <> 0 then
      begin
        //ShowWindow(lHandle, SW_SHOW);
        PostMessage(lHandle, WM_WINDOWMSG, 0, 0);
      end;
      Result := S_OK;
      Exit;
    end;
//      pTaskConfig.pszContent := 'Please use the ZedWin launcher at the Tray!';
//    pTaskConfig.pszWindowTitle := 'Hooked Title';
  end;

  // Call original function with modified parameters
  Result := OriginalTaskDialogIndirect(pTaskConfig, pnButton, pnRadioButton, pfVerificationFlagChecked);
end;

procedure CreateIntercepts;
var
  hComCtrl32: HMODULE;
begin
  BeginHooks;

  hComCtrl32 := LoadLibrary('comctl32.dll');
  if hComCtrl32 = 0 then
    RaiseLastOSError;

  try
    @OriginalTaskDialogIndirect := InterceptCreate(
      GetProcAddress(hComCtrl32, 'TaskDialogIndirect'),
      @HookedTaskDialogIndirect
    );

    if not Assigned(OriginalTaskDialogIndirect) then
      RaiseLastOSError;
  finally
    FreeLibrary(hComCtrl32);
  end;

  EndHooks;
end;

procedure RemoveIntercepts;
begin
  if Assigned(OriginalTaskDialogIndirect) then
  begin
    BeginUnHooks;
    InterceptRemove(@HookedTaskDialogIndirect);
    OriginalTaskDialogIndirect := nil;
    EndUnHooks;
  end;
end;

procedure DllEntry(pReason: DWORD);
begin
  case pReason of
    DLL_PROCESS_ATTACH: CreateIntercepts();
    DLL_PROCESS_DETACH: RemoveIntercepts();
    DLL_THREAD_ATTACH:;
    DLL_THREAD_DETACH:;
  end;
end;

exports
  InitializeData;

begin
  DllProc := @DllEntry;
  DllEntry(DLL_PROCESS_ATTACH);
end.
