object optionsFrm: ToptionsFrm
  Left = 287
  Top = 162
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'Options'
  ClientHeight = 449
  ClientWidth = 805
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 14
  object pageCtrl: TPageControl
    Left = 0
    Top = 0
    Width = 805
    Height = 414
    ActivePage = accountsPage
    Align = alClient
    Images = mainFrm.images
    MultiLine = True
    TabOrder = 0
    object bansPage: TTabSheet
      Caption = 'Bans'
      ImageIndex = 25
      object Panel1: TPanel
        Left = 0
        Top = 0
        Width = 797
        Height = 30
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object addBtn: TButton
          Left = 4
          Top = 5
          Width = 73
          Height = 21
          Caption = 'Add row'
          TabOrder = 0
          OnClick = addBtnClick
        end
        object deleteBtn: TButton
          Left = 86
          Top = 5
          Width = 73
          Height = 21
          Caption = 'Delete row'
          TabOrder = 1
          OnClick = deleteBtnClick
        end
        object sortBanBtn: TButton
          Left = 168
          Top = 5
          Width = 73
          Height = 21
          Caption = 'Sort'
          TabOrder = 2
          OnClick = sortBanBtnClick
        end
      end
      object bansBox: TValueListEditor
        Left = 0
        Top = 30
        Width = 797
        Height = 329
        Align = alClient
        KeyOptions = [keyEdit, keyAdd, keyDelete]
        Strings.Strings = (
          '=')
        TabOrder = 1
        TitleCaptions.Strings = (
          'IP address mask'
          'Comment')
        ColWidths = (
          108
          683)
      end
      object Panel3: TPanel
        Left = 0
        Top = 359
        Width = 797
        Height = 26
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 2
        object noreplybanChk: TCheckBox
          Left = 5
          Top = 5
          Width = 145
          Height = 17
          Caption = 'Disconnect with no reply'
          TabOrder = 0
        end
        object Button1: TButton
          Left = 176
          Top = 4
          Width = 141
          Height = 19
          Caption = 'How to invert the logic?'
          TabOrder = 1
          OnClick = Button1Click
        end
      end
    end
    object accountsPage: TTabSheet
      Caption = 'Accounts'
      ImageIndex = 29
      DesignSize = (
        797
        385)
      object Label1: TLabel
        Left = 9
        Top = 16
        Width = 57
        Height = 14
        Caption = 'Account list'
        FocusControl = accountsBox
      end
      object Label7: TLabel
        Left = 251
        Top = 349
        Width = 328
        Height = 14
        Hint = 'You also need to right click on the folder, then restrict access'
        Anchors = [akLeft, akBottom]
        Caption = 
          'WARNING: creating an account is not enough to protect  your file' +
          's...'
        ParentShowHint = False
        ShowHint = True
        WordWrap = True
      end
      object accountpropGrp: TGroupBox
        Left = 163
        Top = 26
        Width = 619
        Height = 317
        Anchors = [akLeft, akTop, akRight, akBottom]
        Caption = 'Account properties'
        TabOrder = 7
        DesignSize = (
          619
          317)
        object Label3: TLabel
          Left = 11
          Top = 173
          Width = 257
          Height = 28
          Caption = 'Here you can see protected resources this user can access...'
          FocusControl = accountAccessBox
          WordWrap = True
        end
        object Label8: TLabel
          Left = 345
          Top = 20
          Width = 28
          Height = 14
          Caption = 'Notes'
          FocusControl = notesBox
          WordWrap = True
        end
        object accountenabledChk: TCheckBox
          Left = 11
          Top = 20
          Width = 97
          Height = 17
          Caption = '&Enabled'
          TabOrder = 0
          OnClick = accountenabledChkClick
        end
        object accountAccessBox: TTreeView
          Left = 11
          Top = 192
          Width = 302
          Height = 116
          Anchors = [akLeft, akTop, akBottom]
          Images = mainFrm.images
          Indent = 19
          ParentShowHint = False
          ReadOnly = True
          ShowHint = False
          ShowRoot = False
          TabOrder = 7
          OnContextPopup = accountAccessBoxContextPopup
          OnDblClick = accountAccessBoxDblClick
        end
        object ignoreLimitsChk: TCheckBox
          Left = 226
          Top = 20
          Width = 97
          Height = 17
          Caption = '&Ignore limits'
          TabOrder = 2
        end
        object pwdBox: TLabeledEdit
          Left = 11
          Top = 63
          Width = 198
          Height = 22
          EditLabel.Width = 50
          EditLabel.Height = 14
          EditLabel.Caption = '&Password'
          ParentShowHint = False
          PasswordChar = '*'
          ShowHint = True
          TabOrder = 3
          OnChange = pwdBoxChange
          OnMouseEnter = pwdBoxMouseEnter
        end
        object redirBox: TLabeledEdit
          Left = 11
          Top = 106
          Width = 198
          Height = 22
          EditLabel.Width = 111
          EditLabel.Height = 14
          EditLabel.Caption = 'After ~login, redirect to'
          TabOrder = 4
          OnChange = redirBoxChange
        end
        object accountLinkBox: TLabeledEdit
          Left = 11
          Top = 146
          Width = 198
          Height = 22
          EditLabel.Width = 51
          EditLabel.Height = 14
          EditLabel.Caption = 'Member of'
          TabOrder = 5
          OnExit = accountLinkBoxExit
        end
        object groupChk: TCheckBox
          Left = 114
          Top = 20
          Width = 97
          Height = 17
          Caption = '&Group'
          TabOrder = 1
          OnClick = groupChkClick
        end
        object groupsBtn: TButton
          Left = 215
          Top = 146
          Width = 90
          Height = 21
          Caption = 'Choose...'
          TabOrder = 6
          OnClick = groupsBtnClick
        end
        object notesBox: TMemo
          Left = 345
          Top = 39
          Width = 271
          Height = 269
          Anchors = [akLeft, akTop, akRight, akBottom]
          ParentShowHint = False
          ScrollBars = ssVertical
          ShowHint = False
          TabOrder = 8
        end
        object notesWrapChk: TCheckBox
          Left = 502
          Top = 21
          Width = 91
          Height = 17
          Anchors = [akTop, akRight]
          Caption = 'Wrap'
          Checked = True
          State = cbChecked
          TabOrder = 9
          OnClick = notesWrapChkClick
        end
      end
      object deleteaccountBtn: TButton
        Left = 3
        Top = 351
        Width = 45
        Height = 17
        Anchors = [akLeft, akBottom]
        Caption = 'de&lete'
        Enabled = False
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnClick = deleteaccountBtnClick
      end
      object renaccountBtn: TButton
        Left = 53
        Top = 328
        Width = 49
        Height = 17
        Anchors = [akLeft, akBottom]
        Caption = '&rename'
        Enabled = False
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        OnClick = renaccountBtnClick
      end
      object addaccountBtn: TButton
        Left = 3
        Top = 328
        Width = 45
        Height = 17
        Anchors = [akLeft, akBottom]
        Caption = 'ad&d'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnClick = addaccountBtnClick
      end
      object upBtn: TButton
        Left = 107
        Top = 328
        Width = 45
        Height = 17
        Anchors = [akLeft, akBottom]
        Caption = '&up'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 5
        OnClick = upBtnClick
        OnMouseUp = upBtnMouseUp
      end
      object downBtn: TButton
        Left = 107
        Top = 351
        Width = 45
        Height = 17
        Anchors = [akLeft, akBottom]
        Caption = 'do&wn'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 6
        OnClick = upBtnClick
        OnMouseUp = upBtnMouseUp
      end
      object sortBtn: TButton
        Left = 53
        Top = 351
        Width = 49
        Height = 17
        Anchors = [akLeft, akBottom]
        Caption = 'sort'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 4
        OnClick = sortBtnClick
        OnMouseUp = upBtnMouseUp
      end
      object accountsBox: TListView
        Left = 3
        Top = 35
        Width = 149
        Height = 287
        Anchors = [akLeft, akTop, akBottom]
        Columns = <>
        DragMode = dmAutomatic
        HideSelection = False
        OwnerData = True
        RowSelect = True
        ParentShowHint = False
        ShowHint = False
        SmallImages = mainFrm.images
        TabOrder = 0
        ViewStyle = vsList
        OnChange = accountsBoxChange
        OnClick = accountsBoxClick
        OnData = accountsBoxData
        OnDblClick = accountsBoxDblClick
        OnEdited = accountsBoxEdited
        OnEditing = accountsBoxEditing
        OnDragDrop = accountsBoxDragDrop
        OnDragOver = accountsBoxDragOver
        OnKeyDown = accountsBoxKeyDown
        OnKeyPress = accountsBoxKeyPress
      end
    end
    object mimePage: TTabSheet
      Caption = 'MIME types'
      ImageIndex = 7
      object mimeBox: TValueListEditor
        Left = 0
        Top = 30
        Width = 797
        Height = 355
        Align = alClient
        KeyOptions = [keyEdit, keyAdd, keyDelete]
        Strings.Strings = (
          '=')
        TabOrder = 0
        TitleCaptions.Strings = (
          'File Mask'
          'MIME Description')
        ColWidths = (
          108
          683)
      end
      object Panel5: TPanel
        Left = 0
        Top = 0
        Width = 797
        Height = 30
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
        object addMimeBtn: TButton
          Left = 4
          Top = 5
          Width = 73
          Height = 21
          Caption = 'Add row'
          TabOrder = 0
          OnClick = addMimeBtnClick
        end
        object deleteMimeBtn: TButton
          Left = 86
          Top = 5
          Width = 73
          Height = 21
          Caption = 'Delete row'
          TabOrder = 1
          OnClick = deleteMimeBtnClick
        end
        object inBrowserIfMIMEchk: TCheckBox
          Left = 184
          Top = 7
          Width = 305
          Height = 17
          Caption = 'Open directly in browser when MIME type is defined'
          TabOrder = 2
        end
      end
    end
    object trayPage: TTabSheet
      Caption = 'Tray Message'
      ImageIndex = 10
      object Label2: TLabel
        Left = 8
        Top = 16
        Width = 292
        Height = 168
        Caption = 
          'You can customize the message in the tray icon tip. '#13#10'The messag' +
          'e length is determined by your Windows version'#13#10'(in XP the limit' +
          ' is 127 characters including spaces).'#13#10'Available symbols:'#13#10#13#10'  %' +
          'uptime% - server uptime'#13#10'  %url% - server main URL'#13#10'  %ip% - IP ' +
          'address set as default'#13#10'  %port% - Port on which the server is l' +
          'istening'#13#10'  %hits% - number of requests made to the server'#13#10'  %d' +
          'ownloads% - number of files downloaded'#13#10'  %version% - HFS versio' +
          'n'
      end
      object Label10: TLabel
        Left = 291
        Top = 170
        Width = 40
        Height = 14
        Caption = 'Preview'
      end
      object traymsgBox: TMemo
        Left = 16
        Top = 192
        Width = 233
        Height = 121
        Lines.Strings = (
          'traymsgBox')
        TabOrder = 0
        OnChange = traymsgBoxChange
      end
      object traypreviewBox: TMemo
        Left = 291
        Top = 192
        Width = 233
        Height = 121
        Color = clInfoBk
        ReadOnly = True
        TabOrder = 1
      end
    end
    object a2nPage: TTabSheet
      Caption = 'Address2name'
      ImageIndex = -1
      object Panel4: TPanel
        Left = 0
        Top = 0
        Width = 797
        Height = 67
        Align = alTop
        Alignment = taLeftJustify
        BevelOuter = bvNone
        TabOrder = 0
        object Label4: TLabel
          Left = 8
          Top = 8
          Width = 243
          Height = 28
          Caption = 
            'You can associate a label to an address (or many addresses). It ' +
            'will be used in the log.'
          WordWrap = True
        end
        object deleteA2Nbtn: TButton
          Left = 83
          Top = 40
          Width = 73
          Height = 21
          Caption = '&Delete row'
          TabOrder = 0
          OnClick = deleteA2NbtnClick
        end
        object addA2Nbtn: TButton
          Left = 4
          Top = 41
          Width = 73
          Height = 21
          Caption = 'Add &row'
          TabOrder = 1
          OnClick = addA2NbtnClick
        end
      end
      object a2nBox: TValueListEditor
        Left = 0
        Top = 67
        Width = 797
        Height = 318
        Align = alClient
        KeyOptions = [keyEdit, keyAdd, keyDelete]
        Strings.Strings = (
          '=')
        TabOrder = 1
        TitleCaptions.Strings = (
          'Name'
          'IP Mask')
        ColWidths = (
          108
          683)
      end
    end
    object iconsPage: TTabSheet
      Caption = 'Icon masks'
      ImageIndex = -1
      DesignSize = (
        797
        385)
      object Label5: TLabel
        Left = 8
        Top = 32
        Width = 227
        Height = 14
        Caption = 'Each line is a file-mask associated with an icon'
        WordWrap = True
      end
      object Label6: TLabel
        Left = 272
        Top = 128
        Width = 76
        Height = 14
        Caption = 'Icon associated'
      end
      object iconMasksBox: TMemo
        Left = 8
        Top = 49
        Width = 225
        Height = 245
        Anchors = [akLeft, akTop, akBottom]
        TabOrder = 0
        OnChange = iconMasksBoxChange
      end
      object iconsBox: TComboBox
        Left = 272
        Top = 144
        Width = 76
        Height = 22
        Style = csOwnerDrawFixed
        TabOrder = 1
        OnChange = iconsBoxChange
        OnDrawItem = iconsBoxDrawItem
        OnDropDown = iconsBoxDropDown
      end
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 414
    Width = 805
    Height = 35
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      805
      35)
    object okBtn: TButton
      Left = 561
      Top = 6
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = '&OK'
      TabOrder = 0
      OnClick = okBtnClick
    end
    object applyBtn: TButton
      Left = 724
      Top = 6
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = '&Apply'
      TabOrder = 1
      OnClick = applyBtnClick
    end
    object cancelBtn: TButton
      Left = 643
      Top = 6
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = '&Cancel'
      TabOrder = 2
      OnClick = cancelBtnClick
    end
  end
end
