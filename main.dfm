object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Zed Launcher'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  FormStyle = fsStayOnTop
  StyleElements = [seFont, seClient]
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 15
  object ACLPanel1: TACLPanel
    Left = 0
    Top = 0
    Width = 624
    Height = 441
    Align = alClient
    TabOrder = 0
    Borders = []
    object ACLLabel1: TACLLabel
      Left = 32
      Top = 32
      Width = 180
      Height = 25
      AutoSize = True
      Caption = 'About: Zed Windows '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblZedVersion: TACLLabel
      Left = 32
      Top = 75
      Width = 72
      Height = 15
      AutoSize = True
      Caption = 'lblZedVersion'
    end
    object lblCheckUpdateResult: TACLLabel
      Left = 224
      Top = 75
      Width = 72
      Height = 15
      AutoSize = True
      Caption = 'lblZedVersion'
    end
    object ACLButton1: TACLButton
      Left = 408
      Top = 384
      Width = 120
      Height = 25
      TabOrder = 0
      OnClick = ACLButton1Click
      Caption = 'Check Updates'
    end
    object ACLButton2: TACLButton
      Left = 32
      Top = 384
      Width = 145
      Height = 25
      TabOrder = 1
      OnClick = ACLButton2Click
      Caption = 'Show in File Explorer'
    end
    object ACLPanel2: TACLPanel
      Left = 16
      Top = 120
      Width = 593
      Height = 67
      TabOrder = 2
      object zedvulkandownloader: TCBDownloader
        AlignWithMargins = True
        Left = 5
        Top = 37
        Width = 583
        Height = 26
        Align = alTop
        Caption = 'Zed-Windows Vulkan'
        TabOrder = 0
        OnDownloaded = zedvulkandownloaderDownloaded
        OnDownloadClick = zedvulkandownloaderDownloadClick
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
        DownloadStartIcon = #57624
        DownloadPauseIcon = #57603
        DownloadCancelIcon = #57610
        DownloadRestartIcon = #57673
        Detail = ''
        ExtraDetail = ''
        Status = 'Status'
        ProgressTop = 'Message 1'
        ProgressBottom = '0kb/s'
        ProxyHost = ''
        ProxyPort = 0
      end
      object zedopengldownloader: TCBDownloader
        AlignWithMargins = True
        Left = 5
        Top = 5
        Width = 583
        Height = 26
        Align = alTop
        Caption = 'Zed-Windows OpenGL'
        TabOrder = 1
        OnDownloaded = zedopengldownloaderDownloaded
        OnDownloadClick = zedopengldownloaderDownloadClick
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
        DownloadStartIcon = #57624
        DownloadPauseIcon = #57603
        DownloadCancelIcon = #57610
        DownloadRestartIcon = #57673
        Detail = ''
        ExtraDetail = ''
        Status = 'Status'
        ProgressTop = 'Message 1'
        ProgressBottom = '0kb/s'
        ProxyHost = ''
        ProxyPort = 0
      end
    end
    object ACLFormattedLabel1: TACLFormattedLabel
      Left = 24
      Top = 208
      Width = 580
      Height = 161
      TabOrder = 3
      Caption = ''
    end
  end
  object TrayIcon1: TTrayIcon
    Hint = 'Zed'
    PopupMenu = PopupMenu1
    Visible = True
    OnDblClick = TrayIcon1DblClick
    Left = 232
    Top = 304
  end
  object PopupMenu1: TPopupMenu
    Left = 504
    Top = 137
    object MenuRestart: TMenuItem
      Caption = 'Restart'
      OnClick = MenuRestartClick
    end
    object MenuExit: TMenuItem
      Caption = 'E&xit'
      OnClick = MenuExitClick
    end
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 312
    Top = 232
  end
  object RESTRequest1: TRESTRequest
    Client = RESTClient1
    Params = <>
    Response = RESTResponse1
    SynchronizedEvents = False
    Left = 112
    Top = 216
  end
  object RESTResponse1: TRESTResponse
    Left = 376
    Top = 56
  end
  object RESTClient1: TRESTClient
    Params = <>
    SynchronizedEvents = False
    Left = 456
    Top = 296
  end
  object JumpList1: TJumpList
    Enabled = True
    ApplicationID = 'ZED'
    CustomCategories = <>
    TaskList = <>
    Left = 192
    Top = 152
  end
  object ACLApplicationController1: TACLApplicationController
    DarkMode = False
    Left = 288
    Top = 104
  end
end
