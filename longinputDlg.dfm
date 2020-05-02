object longinputFrm: TlonginputFrm
  Left = 191
  Top = 187
  BorderStyle = bsSizeToolWin
  Caption = 'longinputFrm'
  ClientHeight = 314
  ClientWidth = 465
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object bottomPnl: TPanel
    Left = 0
    Top = 282
    Width = 465
    Height = 32
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    OnResize = bottomPnlResize
    object okBtn: TButton
      Left = 55
      Top = 4
      Width = 75
      Height = 25
      Caption = '&OK'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object cancelBtn: TButton
      Left = 135
      Top = 4
      Width = 75
      Height = 25
      Caption = '&Cancel'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object topPnl: TPanel
    Left = 0
    Top = 0
    Width = 465
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    object msgLbl: TLabel
      Left = 0
      Top = 0
      Width = 17
      Height = 13
      Align = alClient
      Caption = 'test'
      Layout = tlCenter
      WordWrap = True
    end
  end
  object inputBox: TMemo
    Left = 0
    Top = 41
    Width = 465
    Height = 241
    Align = alClient
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssVertical
    TabOrder = 0
    OnKeyDown = inputBoxKeyDown
  end
end
