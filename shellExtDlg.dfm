object shellExtFrm: TshellExtFrm
  Left = 226
  Top = 146
  Caption = 'Option...'
  ClientHeight = 265
  ClientWidth = 388
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 0
    Top = 0
    Width = 388
    Height = 169
    Align = alTop
    AutoSize = True
  end
  object Panel1: TPanel
    Left = 0
    Top = 169
    Width = 388
    Height = 96
    Align = alClient
    BevelOuter = bvLowered
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 16
      Width = 215
      Height = 13
      Caption = 'Do you want HFS in your shell context menu?'
    end
    object Button1: TButton
      Left = 108
      Top = 56
      Width = 75
      Height = 25
      Caption = '&Yes'
      Default = True
      ModalResult = 6
      TabOrder = 0
    end
    object Button2: TButton
      Left = 204
      Top = 56
      Width = 75
      Height = 25
      Caption = '&No'
      ModalResult = 7
      TabOrder = 1
    end
  end
end
