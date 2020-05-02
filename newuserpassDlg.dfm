object newuserpassFrm: TnewuserpassFrm
  Left = 362
  Top = 207
  BorderStyle = bsDialog
  Caption = 'Insert the requested user/pass'
  ClientHeight = 131
  ClientWidth = 302
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object userBox: TLabeledEdit
    Left = 104
    Top = 16
    Width = 121
    Height = 21
    EditLabel.Width = 48
    EditLabel.Height = 13
    EditLabel.Caption = 'Username'
    LabelPosition = lpLeft
    TabOrder = 0
  end
  object pwdBox: TLabeledEdit
    Left = 104
    Top = 40
    Width = 121
    Height = 21
    EditLabel.Width = 46
    EditLabel.Height = 13
    EditLabel.Caption = 'Password'
    LabelPosition = lpLeft
    PasswordChar = '*'
    TabOrder = 1
  end
  object pwd2Box: TLabeledEdit
    Left = 104
    Top = 64
    Width = 121
    Height = 21
    EditLabel.Width = 85
    EditLabel.Height = 13
    EditLabel.Caption = 'Re-type password'
    LabelPosition = lpLeft
    PasswordChar = '*'
    TabOrder = 2
  end
  object okBtn: TButton
    Left = 104
    Top = 96
    Width = 75
    Height = 25
    Caption = '&Ok'
    Default = True
    TabOrder = 3
    OnClick = okBtnClick
  end
  object resetBtn: TButton
    Left = 192
    Top = 96
    Width = 75
    Height = 25
    Caption = '&Reset'
    TabOrder = 4
    OnClick = resetBtnClick
  end
end
