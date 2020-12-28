object FormMain: TFormMain
  Left = 0
  Top = 0
  ClientHeight = 355
  ClientWidth = 676
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Courier New'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  DesignSize = (
    676
    355)
  PixelsPerInch = 96
  TextHeight = 15
  object MemoLog: TMemo
    Left = 8
    Top = 129
    Width = 660
    Height = 218
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssVertical
    TabOrder = 5
    WordWrap = False
  end
  object LabeledEditExeFile: TLabeledEdit
    Left = 8
    Top = 22
    Width = 630
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    EditLabel.Width = 63
    EditLabel.Height = 15
    EditLabel.Caption = 'Exe File:'
    TabOrder = 0
  end
  object ButtonSelectExe: TButton
    Left = 637
    Top = 20
    Width = 31
    Height = 23
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 1
    OnClick = ButtonSelectExeClick
  end
  object LabeledEditLangSavedDirectory: TLabeledEdit
    Left = 8
    Top = 69
    Width = 630
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    EditLabel.Width = 175
    EditLabel.Height = 15
    EditLabel.Caption = 'Language Saved Directory:'
    TabOrder = 2
  end
  object ButtonSelectSavedPath: TButton
    Left = 637
    Top = 67
    Width = 31
    Height = 23
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 3
    OnClick = ButtonSelectSavedPathClick
  end
  object ButtonExtract: TButton
    Left = 8
    Top = 98
    Width = 81
    Height = 25
    Caption = 'Extract'
    TabOrder = 4
    OnClick = ButtonExtractClick
  end
end
