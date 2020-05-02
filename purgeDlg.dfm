object purgeFrm: TpurgeFrm
  Left = 0
  Top = 0
  Caption = 'Purge options'
  ClientHeight = 152
  ClientWidth = 186
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 127
    Height = 13
    Caption = 'Choose what to remove...'
  end
  object rmFilesChk: TCheckBox
    Left = 8
    Top = 35
    Width = 177
    Height = 17
    Caption = 'Non-existent files'
    Checked = True
    State = cbChecked
    TabOrder = 0
  end
  object rmRealFoldersChk: TCheckBox
    Left = 8
    Top = 58
    Width = 171
    Height = 17
    Caption = 'Non-existent real folders'
    Checked = True
    State = cbChecked
    TabOrder = 1
  end
  object rmEmptyFoldersChk: TCheckBox
    Left = 8
    Top = 81
    Width = 177
    Height = 17
    Caption = 'Empty folders'
    Checked = True
    State = cbChecked
    TabOrder = 2
  end
  object Button1: TButton
    Left = 8
    Top = 118
    Width = 75
    Height = 25
    Caption = '&Ok'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object Button2: TButton
    Left = 103
    Top = 118
    Width = 75
    Height = 25
    Caption = '&Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
