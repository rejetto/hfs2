object ipsEverFrm: TipsEverFrm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Addresses ever connected'
  ClientHeight = 271
  ClientWidth = 286
  Color = clBtnFace
  Constraints.MaxHeight = 300
  Constraints.MinHeight = 300
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnShow = FormShow
  DesignSize = (
    286
    271)
  PixelsPerInch = 96
  TextHeight = 13
  object totalLbl: TLabel
    Left = 197
    Top = 246
    Width = 61
    Height = 13
    Anchors = [akLeft]
    Caption = 'Total label...'
  end
  object ipsBox: TMemo
    Left = 0
    Top = 0
    Width = 286
    Height = 236
    Align = alTop
    Anchors = [akLeft, akTop, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object resetBtn: TButton
    Left = 114
    Top = 241
    Width = 75
    Height = 25
    Anchors = [akLeft]
    Caption = '&Reset'
    TabOrder = 1
    OnClick = resetBtnClick
  end
  object editBtn: TButton
    Left = 8
    Top = 241
    Width = 95
    Height = 25
    Anchors = [akLeft]
    Caption = '&Open in editor'
    TabOrder = 2
    OnClick = editBtnClick
  end
end
