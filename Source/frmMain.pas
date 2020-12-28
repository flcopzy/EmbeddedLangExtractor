unit frmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TFormMain = class(TForm)
    MemoLog: TMemo;
    LabeledEditExeFile: TLabeledEdit;
    ButtonSelectExe: TButton;
    LabeledEditLangSavedDirectory: TLabeledEdit;
    ButtonSelectSavedPath: TButton;
    ButtonExtract: TButton;
    procedure ButtonExtractClick(Sender: TObject);
    procedure ButtonSelectExeClick(Sender: TObject);
    procedure ButtonSelectSavedPathClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    procedure OnLangExtracting(const ASavedDirectory, ALangFileName: string; ACurrentIndex, ATotalCount: Integer);
    procedure AddLog(const ALog: string);
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

uses
  {$WARN UNIT_PLATFORM OFF}FileCtrl{$WARN UNIT_PLATFORM ON}
  , LangExtractor
  ;

{$R *.dfm}

procedure TFormMain.FormCreate(Sender: TObject);
begin
  Application.Title := 'Embedded Lang Extractor (v0.0.0.1)';
  Caption := Application.Title;
end;

procedure TFormMain.OnLangExtracting(const ASavedDirectory, ALangFileName: string; ACurrentIndex, ATotalCount: Integer);
begin
  if ATotalCount = 0 then
  begin
    AddLog('Language files not found.');
    Exit;
  end;

  if ACurrentIndex = 0 then
    AddLog(Format('Start to extract lang file to ''%s''.', [ASavedDirectory]));

  AddLog(Format('[%3d/%3d] extracting %s', [ACurrentIndex + 1, ATotalCount, ALangFileName]));

  if (ACurrentIndex = ATotalCount - 1) then
    AddLog('All language files extracted successful.');
end;

procedure TFormMain.AddLog(const ALog: string);
begin
  MemoLog.Lines.Add(Format('%s => %s', [DateTimeToStr(Now), ALog]));
end;

procedure TFormMain.ButtonExtractClick(Sender: TObject);
var
  LExeFileName,
  LLangSavedDirectory: string;
begin
  MemoLog.Lines.Clear;

  LExeFileName := Trim(LabeledEditExeFile.Text);
  if not FileExists(LExeFileName) then
  begin
    AddLog('Exe file not found.');
    Exit;
  end;

  LLangSavedDirectory := Trim(LabeledEditLangSavedDirectory.Text);
  if LLangSavedDirectory = '' then
  begin
    AddLog('Language saved directory is empty.');
    Exit;
  end;

  LangExtractor.ExtractLang(LExeFileName, LLangSavedDirectory, OnLangExtracting);
end;

procedure TFormMain.ButtonSelectExeClick(Sender: TObject);
begin
  with TOpenDialog.Create(nil) do
    try
      Filter := 'exe files (*.exe)|*.EXE';
      if Execute then
        LabeledEditExeFile.Text := FileName;
    finally
      Free;
    end;
end;

procedure TFormMain.ButtonSelectSavedPathClick(Sender: TObject);
var
  LDir: string;
begin
  if SelectDirectory('Please select language saved directory', '', LDir) then
    LabeledEditLangSavedDirectory.Text := LDir;
end;

end.
