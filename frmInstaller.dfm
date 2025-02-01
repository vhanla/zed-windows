object formInstaller: TformInstaller
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Zed Windows Installer'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  StyleElements = [seFont, seClient]
  OnCreate = FormCreate
  TextHeight = 15
  object ACLPanel1: TACLPanel
    Left = 0
    Top = 0
    Width = 624
    Height = 441
    Align = alClient
    TabOrder = 0
    Borders = []
    ExplicitLeft = 8
    ExplicitTop = -8
    object ACLValidationLabel1: TACLValidationLabel
      Left = 13
      Top = 160
      Width = 109
      Height = 16
      SubControl.Position = mBottom
      Caption = 'Installation Path:'
      Icon = vliError
    end
    object ACLLabel1: TACLLabel
      Left = 16
      Top = 16
      Width = 293
      Height = 25
      AutoSize = True
      Caption = 'Welcome to Zed Windows installer'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object ACLValidationLabel2: TACLValidationLabel
      Left = 16
      Top = 47
      Width = 454
      Height = 16
      Caption = 
        'Caution! Zed Windows builds are not officially released yet! Use' +
        ' it at your own risk.'
    end
    object ACLButton1: TACLButton
      Left = 487
      Top = 182
      Width = 120
      Height = 25
      TabOrder = 1
      OnClick = ACLButton1Click
      Caption = 'Select Directory'
    end
    object ACLGroupBox1: TACLGroupBox
      Left = 13
      Top = 262
      Width = 591
      Height = 145
      TabOrder = 2
      Caption = 
        'Available Zed builds '#55357#56391#55356#57339'. You can only pick one to download and' +
        ' install:'
      object CBDownloader1: TCBDownloader
        Left = 7
        Top = 16
        Width = 577
        Align = alTop
        Caption = 'Zed Vulkan'
        TabOrder = 0
        URL = ''
        Header = ''
        UserAgent = ''
        SavePath = ''
        IconFont.Charset = DEFAULT_CHARSET
        IconFont.Color = clWindowText
        IconFont.Height = -21
        IconFont.Name = 'Segoe MDL2 Assets'
        IconFont.Style = []
        CustomBackColor = clNone
        FontIcon = #59219
        DownloadStartIcon = #57624#60045
        DownloadPauseIcon = #57603
        DownloadCancelIcon = ''
        DownloadRestartIcon = ''
        Detail = 'Vulkan GPU version'
        ExtraDetail = 'Download && install  '#8212'> '
        Status = 'Click here '#55357#56393#55356#57339
        ProgressTop = 'Message 1'
        ProgressBottom = '0kb/s'
        ProxyHost = ''
        ProxyPort = 0
        ExplicitLeft = 11
        ExplicitTop = 32
      end
      object CBDownloader2: TCBDownloader
        Left = 7
        Top = 76
        Width = 577
        Align = alTop
        Caption = 'Zed OpenGL'
        TabOrder = 1
        URL = ''
        Header = ''
        UserAgent = ''
        SavePath = ''
        IconFont.Charset = DEFAULT_CHARSET
        IconFont.Color = clWindowText
        IconFont.Height = -21
        IconFont.Name = 'Segoe MDL2 Assets'
        IconFont.Style = []
        CustomBackColor = clNone
        FontIcon = #59219
        DownloadStartIcon = #57624#60045
        DownloadPauseIcon = #57603
        DownloadCancelIcon = ''
        DownloadRestartIcon = ''
        Detail = 'OpenGL version'
        ExtraDetail = 'Download && install  '#8212'> '
        Status = 'Click here '#55357#56393#55356#57339
        ProgressTop = 'Message 1'
        ProgressBottom = '0kb/s'
        ProxyHost = ''
        ProxyPort = 0
        ExplicitLeft = 24
        ExplicitTop = 69
        ExplicitWidth = 998
      end
    end
    object ACLEdit1: TACLEdit
      Left = 13
      Top = 182
      Width = 457
      Height = 23
      TabOrder = 0
      Buttons = <>
      Text = ''
    end
    object ACLFormattedLabel1: TACLFormattedLabel
      Left = 64
      Top = 69
      Width = 543
      Height = 92
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      Caption = 
        'This is an unofficial installer for Zed on Windows.'#13#10'These Zed b' +
        'uilds are built with GitHub Actions using the Stable Releases fr' +
        'om the official Zed repository.'#13#10'The workflow file to generate t' +
        'hese builds using GitHub Actions is this one: '#13#10'https://github.c' +
        'om/vhanla/zed-windows/blob/main/.github/workflows/stable.yml'#13#10'As' +
        ' they don'#39't offer a Windows binary yet, it means current builds ' +
        'for Windows might have many bugs.'
    end
    object ACLCheckBox1: TACLCheckBox
      Left = 16
      Top = 216
      Width = 452
      Height = 17
      TabOrder = 4
      Caption = 
        'Add this Zed'#39's installation path to current user'#39's Environment V' +
        'ariables (%PATH%)'
    end
    object ACLCheckBox2: TACLCheckBox
      Left = 16
      Top = 239
      Width = 271
      Height = 17
      TabOrder = 5
      Caption = 'Add Windows Context Menu to open with Zed.'
    end
  end
  object ACLApplicationController1: TACLApplicationController
    DarkMode = False
    Left = 360
    Top = 8
  end
  object FileOpenDialog1: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = [fdoPickFolders]
    Left = 560
    Top = 24
  end
  object Taskbar1: TTaskbar
    TaskBarButtons = <
      item
      end
      item
      end
      item
      end>
    TabProperties = []
    Left = 304
    Top = 224
  end
end
