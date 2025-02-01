unit frmInstaller;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, ACL.UI.Controls.Base,
  ACL.UI.Controls.Panel, CB.DarkMode, ACL.Classes, ACL.UI.Application,
  ACL.UI.Controls.GroupBox, ACL.UI.Controls.Buttons, ACL.UI.Controls.ScrollBox,
  ACL.UI.Controls.Memo, ACL.UI.Controls.SearchBox, ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.TextEdit, ACL.UI.Controls.Labels, ACL.UI.Dialogs,
  Vcl.ExtCtrls, CB.Downloader, ACL.UI.Controls.CompoundControl,
  ACL.UI.Controls.FormattedLabel, Vcl.JumpList, System.Win.TaskbarCore,
  Vcl.Taskbar, fspTaskbarMgr;

type
  TformInstaller = class(TForm)
    ACLPanel1: TACLPanel;
    ACLApplicationController1: TACLApplicationController;
    ACLValidationLabel1: TACLValidationLabel;
    ACLEdit1: TACLEdit;
    ACLButton1: TACLButton;
    ACLGroupBox1: TACLGroupBox;
    ACLLabel1: TACLLabel;
    CBDownloader1: TCBDownloader;
    CBDownloader2: TCBDownloader;
    FileOpenDialog1: TFileOpenDialog;
    ACLFormattedLabel1: TACLFormattedLabel;
    ACLValidationLabel2: TACLValidationLabel;
    ACLCheckBox1: TACLCheckBox;
    ACLCheckBox2: TACLCheckBox;
    Taskbar1: TTaskbar;
    procedure FormCreate(Sender: TObject);
    procedure ACLButton1Click(Sender: TObject);
  private
    { Private declarations }
    procedure CreateParams(var Params: TCreateParams); override;
  public
    { Public declarations }
  end;

var
  formInstaller: TformInstaller;

implementation

uses
  CB.WhereIs;

function SetCurrentProcessExplicitAppUserModelID(AppID: PWideChar): HRESULT; stdcall;
  external 'shell32.dll' name 'SetCurrentProcessExplicitAppUserModelID';

{$R *.dfm}

procedure TformInstaller.ACLButton1Click(Sender: TObject);
begin
  if FileOpenDialog1.Execute then
  begin
    if DirectoryExists(FileOpenDialog1.FileName) then
    begin
      ACLValidationLabel1.Icon := TACLValidationLabelIcon.vliSuccess;
      ACLEdit1.Text := FileOpenDialog1.FileName;
    end;
  end;
end;

procedure TformInstaller.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.WinClassName := 'Zed::Window';
end;

procedure TformInstaller.FormCreate(Sender: TObject);
begin
//  SetDarkMode(Handle, True);
  SetCurrentProcessExplicitAppUserModelID('C:\Users\vhanla\projects\rust\zed\target\release\zed.exe');
end;

end.
