object filepropFrm: TfilepropFrm
  Left = 0
  Top = 0
  Caption = 'filepropFrm'
  ClientHeight = 401
  ClientWidth = 393
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poMainFormCenter
  ShowHint = True
  OnClose = FormClose
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pages: TPageControl
    Left = 0
    Top = 0
    Width = 393
    Height = 366
    ActivePage = flagsTab
    Align = alClient
    ParentShowHint = False
    RaggedRight = True
    ShowHint = True
    TabOrder = 0
    object permTab: TTabSheet
      Caption = 'Permissions'
      ImageIndex = 1
      object actionTabs: TTabControl
        Left = 0
        Top = 0
        Width = 385
        Height = 338
        Align = alClient
        MultiLine = True
        TabOrder = 0
        OnChange = actionTabsChange
        DesignSize = (
          385
          338)
        object newaccBtn: TButton
          Left = 278
          Top = 56
          Width = 92
          Height = 25
          Anchors = [akTop, akRight]
          Caption = 'New account'
          TabOrder = 0
          OnClick = newaccBtnClick
        end
        object anyAccChk: TCheckBox
          Left = 278
          Top = 151
          Width = 97
          Height = 17
          Anchors = [akTop, akRight]
          Caption = 'Any account'
          TabOrder = 1
          OnClick = anonChkClick
        end
        object anonChk: TCheckBox
          Left = 278
          Top = 183
          Width = 97
          Height = 17
          Anchors = [akTop, akRight]
          Caption = 'Anonymous'
          TabOrder = 2
          OnClick = anonChkClick
        end
        object allBtn: TButton
          Left = 278
          Top = 95
          Width = 92
          Height = 25
          Anchors = [akTop, akRight]
          Caption = 'All / None'
          TabOrder = 3
          OnClick = allBtnClick
        end
        object accountsBox: TListView
          Left = 16
          Top = 40
          Width = 247
          Height = 285
          Anchors = [akLeft, akTop, akRight, akBottom]
          Checkboxes = True
          Columns = <>
          TabOrder = 4
          ViewStyle = vsList
          OnChange = accountsBoxChange
          OnGetImageIndex = accountsBoxGetImageIndex
        end
        object anyoneChk: TCheckBox
          Left = 278
          Top = 216
          Width = 97
          Height = 17
          Anchors = [akTop, akRight]
          Caption = 'Anyone'
          TabOrder = 5
          OnClick = anonChkClick
        end
        object goToAccountsBtn: TButton
          Left = 278
          Top = 288
          Width = 92
          Height = 33
          Anchors = [akTop, akRight]
          Caption = 'Manage  accounts'
          TabOrder = 6
          WordWrap = True
          OnClick = goToAccountsBtnClick
        end
      end
    end
    object flagsTab: TTabSheet
      Caption = 'Flags'
      ImageIndex = 2
      object hiddenChk: TCheckBox
        Left = 32
        Top = 24
        Width = 180
        Height = 17
        Hint = 'Test'
        Caption = 'Hidden'
        Enabled = False
        TabOrder = 0
      end
      object hidetreeChk: TCheckBox
        Left = 32
        Top = 56
        Width = 180
        Height = 17
        Caption = 'Recursively  hidden'
        Enabled = False
        TabOrder = 1
      end
      object archivableChk: TCheckBox
        Left = 32
        Top = 121
        Width = 273
        Height = 17
        Caption = 'Archivable'
        Enabled = False
        TabOrder = 2
      end
      object browsableChk: TCheckBox
        Left = 32
        Top = 88
        Width = 97
        Height = 17
        Caption = 'Browsable'
        Enabled = False
        TabOrder = 3
      end
      object dontlogChk: TCheckBox
        Left = 32
        Top = 184
        Width = 97
        Height = 17
        Caption = 'Don'#39't log'
        Enabled = False
        TabOrder = 4
      end
      object nodlChk: TCheckBox
        Left = 32
        Top = 152
        Width = 97
        Height = 17
        Caption = 'No download'
        Enabled = False
        TabOrder = 5
      end
      object dontconsiderChk: TCheckBox
        Left = 32
        Top = 216
        Width = 273
        Height = 17
        Caption = 'Don'#39't consider as download'
        Enabled = False
        TabOrder = 6
      end
      object hideemptyChk: TCheckBox
        Left = 32
        Top = 249
        Width = 313
        Height = 17
        Caption = 'Auto-hide empty folders'
        Enabled = False
        TabOrder = 7
      end
      object hideextChk: TCheckBox
        Left = 32
        Top = 280
        Width = 201
        Height = 17
        Caption = 'Hide file extension in listing'
        Enabled = False
        TabOrder = 8
      end
    end
    object diffTab: TTabSheet
      Caption = 'Diff template'
      ImageIndex = 3
      object difftplBox: TMemo
        Left = 0
        Top = 0
        Width = 385
        Height = 338
        Hint = 
          'Here you can put a partial template that will overlap the main o' +
          'ne.'
        Align = alClient
        ScrollBars = ssVertical
        TabOrder = 0
        OnEnter = textinputEnter
      end
    end
    object commentTab: TTabSheet
      Caption = 'Comment'
      ImageIndex = 4
      object commentBox: TMemo
        Left = 0
        Top = 0
        Width = 385
        Height = 338
        Align = alClient
        ScrollBars = ssVertical
        TabOrder = 0
        OnEnter = textinputEnter
      end
    end
    object maskTab: TTabSheet
      Caption = 'File masks'
      ImageIndex = 5
      DesignSize = (
        385
        338)
      object filesfilterBox: TLabeledEdit
        Left = 10
        Top = 32
        Width = 365
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        EditLabel.Width = 46
        EditLabel.Height = 13
        EditLabel.Caption = 'Files filter'
        Enabled = False
        TabOrder = 0
        OnEnter = textinputEnter
      end
      object foldersfilterBox: TLabeledEdit
        Left = 10
        Top = 78
        Width = 365
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        EditLabel.Width = 60
        EditLabel.Height = 13
        EditLabel.Caption = 'Folders filter'
        Enabled = False
        TabOrder = 1
        OnEnter = textinputEnter
      end
      object deffileBox: TLabeledEdit
        Left = 10
        Top = 125
        Width = 365
        Height = 21
        Hint = 
          'When a folder is browsed, the default file mask is used to find ' +
          'a file to serve in place of the folder page. If no file is found' +
          ', the folder page is served.'
        Anchors = [akLeft, akTop, akRight]
        EditLabel.Width = 79
        EditLabel.Height = 13
        EditLabel.Caption = 'Default file mask'
        Enabled = False
        TabOrder = 2
        OnEnter = textinputEnter
      end
      object uploadfilterBox: TLabeledEdit
        Left = 10
        Top = 171
        Width = 365
        Height = 21
        Hint = 'Uploaded files are allowed only complying with this file mask'
        Anchors = [akLeft, akTop, akRight]
        EditLabel.Width = 85
        EditLabel.Height = 13
        EditLabel.Caption = 'Upload filter mask'
        Enabled = False
        TabOrder = 3
        OnEnter = textinputEnter
      end
      object dontconsiderBox: TLabeledEdit
        Left = 10
        Top = 218
        Width = 365
        Height = 21
        Hint = 
          'Files matching this filemask are not considered for global downl' +
          'oads counter. Moreover they never get tray icon.'
        Anchors = [akLeft, akTop, akRight]
        EditLabel.Width = 166
        EditLabel.Height = 13
        EditLabel.Caption = 'Don'#39't consider as download (mask)'
        Enabled = False
        TabOrder = 4
        OnEnter = textinputEnter
      end
    end
    object otherTab: TTabSheet
      Caption = 'Other'
      ImageIndex = 5
      DesignSize = (
        385
        338)
      object Label1: TLabel
        Left = 10
        Top = 72
        Width = 21
        Height = 13
        Caption = 'Icon'
        FocusControl = iconBox
      end
      object realmBox: TLabeledEdit
        Left = 10
        Top = 32
        Width = 365
        Height = 21
        Hint = 
          'The realm string is shown on the user/pass dialog of the browser' +
          '. This realm will be used for selected files and their descendan' +
          'ts.'
        Anchors = [akLeft, akTop, akRight]
        EditLabel.Width = 29
        EditLabel.Height = 13
        EditLabel.Caption = 'Realm'
        Enabled = False
        TabOrder = 0
        OnEnter = textinputEnter
      end
      object iconBox: TComboBoxEx
        Left = 10
        Top = 91
        Width = 127
        Height = 22
        ItemsEx = <>
        Style = csExDropDownList
        ItemHeight = 16
        TabOrder = 1
        Images = mainFrm.images
      end
      object addiconBtn: TButton
        Left = 152
        Top = 91
        Width = 75
        Height = 22
        Caption = 'Add new...'
        TabOrder = 2
        OnClick = addiconBtnClick
      end
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 366
    Width = 393
    Height = 35
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      393
      35)
    object okBtn: TButton
      Left = 152
      Top = 6
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = '&OK'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object cancelBtn: TButton
      Left = 313
      Top = 6
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
    object applyBtn: TButton
      Left = 232
      Top = 6
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = '&Apply'
      TabOrder = 2
      OnClick = applyBtnClick
    end
  end
end
