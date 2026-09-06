program UartApp;

uses
  Vcl.Forms,
  UartMain in 'UartMain.pas' {fmUartMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmUartMain, fmUartMain);
  Application.Run;
end.
