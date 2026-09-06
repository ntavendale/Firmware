unit UartMain;

interface

uses
  System.IOUtils, System.SysUtils, System.Variants, System.Classes, System.UITypes,
  Winapi.Windows, Winapi.Messages, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, OoMisc, AdPort, Vcl.ComCtrls;

type
  TfmUartMain = class(TForm)
    gbCOMSettings: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    cbDataBits: TComboBox;
    cbParity: TComboBox;
    cbFlowControl: TComboBox;
    cbPort: TComboBox;
    cbBaudRate: TComboBox;
    comPort: TApdComPort;
    btnInitialize: TButton;
    lbOutput: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    cbTemperatureResolution: TComboBox;
    cbHumidityResolution: TComboBox;
    btnSetResolution: TButton;
    procedure btnInitializeClick(Sender: TObject);
    procedure comPortTriggerAvail(CP: TObject; Count: Word);
    procedure btnSetResolutionClick(Sender: TObject);
  private
    { Private declarations }
    procedure InitializePort;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  fmUartMain: TfmUartMain;

implementation

{$R *.dfm}

constructor TfmUartMain.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  cbBaudRate.ItemIndex := 12;
  cbPort.ItemIndex := 3;
  cbDataBits.ItemIndex := 1;
  cbParity.ItemIndex := 0;
  cbFlowControl.ItemIndex := 0;
  comPort.LogName :=  String.Format('%s\APRO.LOG', [ TPath.GetDirectoryName(ParamStr(0)) ]);
  comPort.TraceName := String.Format('%s\APRO.TRC', [ TPath.GetDirectoryName(ParamStr(0)) ]);
end;

destructor TfmUartMain.Destroy;
begin
  comPort.Open := FALSE;
  inherited Destroy;
end;

procedure TfmUartMain.InitializePort;
begin
  comPort.ComNumber := cbPort.ItemIndex + 1;
  comPort.Baud := StrToIntDef(cbBaudRate.Items[cbBaudRate.ItemIndex], 115200);
  case cbDataBits.ItemIndex of
  0: comPort.DataBits := 7;
  else
    comPort.DataBits := 8;
  end;
  case cbParity.ItemIndex of
  1: comPort.Parity := pOdd;
  2: comPort.Parity := pEven;
  3: comPort.Parity := pMark;
  4: comPort.Parity := pSpace;
  else
    comPort.Parity := pNone;
  end;

  comPort.Logging := tlOn;
  comPort.Tracing := tlOn;
  comPort.PromptForPort := FALSE;
  comPort.Open := TRUE;
 end;

procedure TfmUartMain.btnInitializeClick(Sender: TObject);
begin
  if not comPort.Open then
  begin
    InitializePort;
    MessageDlg(String.Format('COM%d initialized', [comPort.ComNumber]), mtInformation, [mbOK], 0);
  end
  else
    MessageDlg(String.Format('COM%d already open', [comPort.ComNumber]), mtError, [mbOK], 0);
end;

procedure TfmUartMain.comPortTriggerAvail(CP: TObject; Count: Word);
var
  LByteArray: array [0..3] of Byte;
begin
  if Count <> 4 then
  begin
    lbOutput.Caption := String.Format('Invalid Byte Count: %d', [Count]);
    EXIT;
  end;

  for var i := 0 to (Count - 1) do
  begin
    LByteArray[i] := Ord(comPort.GetChar);
  end;

  var LHumidityData: Word := LByteArray[3];
  LHumidityData := (LHumidityData shl 8) or LByteArray[2];

  var LTempData: Word := LByteArray[1];
  LTempData := (LTempData shl 8) or LByteArray[0];

  var LTemperature := (( LTempData/ 65536) * 165.00) - 40.0;
  var LHumidity := (LHumidityData / 65536) * 100.00;
  lbOutput.Caption := String.Format('Temperature : %.2f deg C. Humidity: %.2f %%', [LTemperature, LHumidity]);
end;

procedure TfmUartMain.btnSetResolutionClick(Sender: TObject);
begin
  if -1 = cbTemperatureResolution.ItemIndex then
  begin
    MessageDlg('You must select a temperature resolution.', mtError, [mbOK], 0);
    EXIT;
  end;

  if -1 = cbHumidityResolution.ItemIndex then
  begin
    MessageDlg('You must select a humidity resolution.', mtError, [mbOK], 0);
    EXIT;
  end;

  var b: Byte := 14;
  try
    case cbTemperatureResolution.ItemIndex of
      0: b := 14;
      1: b := 11;
    end;
    var c := AnsiChar(b);
    comPort.Output := c;

    b :=  0;
    c := AnsiChar(b);
    comPort.Output := c;

    case cbHumidityResolution.ItemIndex of
      0: b := 14;
      1: b := 11;
      2: b := 8;
    end;
    c := AnsiChar(b);
    comPort.Output := c;

    b :=  0;
    c := AnsiChar(b);
    comPort.Output := c;
  except on E:Exception do
    MessageDlg(E.Message, mtError, [mbOK], 0);
  end;

end;

end.
