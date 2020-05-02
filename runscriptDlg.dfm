object runScriptFrm: TrunScriptFrm
  Left = 0
  Top = 0
  Caption = 'Run script'
  ClientHeight = 312
  ClientWidth = 544
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object resultBox: TMemo
    Left = 0
    Top = 41
    Width = 544
    Height = 271
    Align = alClient
    Lines.Strings = (
      'Write your script in the external editor, then click Run.'
      'In this box will see the result of the script you run.')
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 544
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object sizeLbl: TLabel
      Left = 503
      Top = 24
      Width = 32
      Height = 13
      Alignment = taRightJustify
      Caption = 'Size: 0'
    end
    object runBtn: TButton
      Left = 16
      Top = 10
      Width = 75
      Height = 25
      Caption = '&Run'
      TabOrder = 0
      OnClick = runBtnClick
    end
    object autorunChk: TCheckBox
      Left = 104
      Top = 16
      Width = 169
      Height = 17
      Caption = '&Auto run at every saving'
      Checked = True
      State = cbChecked
      TabOrder = 1
    end
  end
end
