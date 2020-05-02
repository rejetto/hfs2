object listSelectFrm: TlistSelectFrm
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  ClientHeight = 173
  ClientWidth = 183
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
  object listBox: TCheckListBox
    Left = 0
    Top = 0
    Width = 183
    Height = 136
    Align = alClient
    ItemHeight = 13
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 136
    Width = 183
    Height = 37
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object okBtn: TButton
      Left = 8
      Top = 6
      Width = 75
      Height = 25
      Caption = '&OK'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object cancelBtn: TButton
      Left = 96
      Top = 6
      Width = 75
      Height = 25
      Caption = '&Cancel'
      ModalResult = 2
      TabOrder = 1
    end
  end
end
