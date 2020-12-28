program EmbeddedLangExtractor;

uses
  Forms,
  frmMain in 'frmMain.pas' {FormMain},
  LangExtractor in 'LangExtractor.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
