object fmUartMain: TfmUartMain
  Left = 0
  Top = 0
  Caption = 'UART'
  ClientHeight = 332
  ClientWidth = 805
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 15
  object lbOutput: TLabel
    Left = 240
    Top = 80
    Width = 41
    Height = 15
    Caption = 'Output:'
  end
  object Label6: TLabel
    Left = 424
    Top = 8
    Width = 126
    Height = 15
    Caption = 'Temperature Resolution'
  end
  object Label7: TLabel
    Left = 240
    Top = 8
    Width = 109
    Height = 15
    Caption = 'Humidity Resolution'
  end
  object gbCOMSettings: TGroupBox
    Left = 0
    Top = 0
    Width = 225
    Height = 337
    Caption = 'Com Settings'
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 72
      Width = 53
      Height = 15
      Caption = 'Baud Rate'
    end
    object Label2: TLabel
      Left = 16
      Top = 120
      Width = 46
      Height = 15
      Caption = 'Data Bits'
    end
    object Label3: TLabel
      Left = 16
      Top = 170
      Width = 30
      Height = 15
      Caption = 'Parity'
    end
    object Label4: TLabel
      Left = 16
      Top = 220
      Width = 68
      Height = 15
      Caption = 'Flow Control'
    end
    object Label5: TLabel
      Left = 16
      Top = 16
      Width = 22
      Height = 15
      Caption = 'Port'
    end
    object cbDataBits: TComboBox
      Left = 16
      Top = 141
      Width = 65
      Height = 23
      Style = csDropDownList
      TabOrder = 2
      Items.Strings = (
        '7'
        '8')
    end
    object cbParity: TComboBox
      Left = 16
      Top = 191
      Width = 145
      Height = 23
      Style = csDropDownList
      TabOrder = 4
      Items.Strings = (
        'None'
        'Odd'
        'Even'
        'Mark'
        'Space')
    end
    object cbFlowControl: TComboBox
      Left = 16
      Top = 241
      Width = 145
      Height = 23
      Style = csDropDownList
      TabOrder = 3
      Items.Strings = (
        'None'
        'XON/XOFF'
        'RTS/CTS'
        'DSR/DTR')
    end
    object cbPort: TComboBox
      Left = 16
      Top = 37
      Width = 65
      Height = 23
      Style = csDropDownList
      TabOrder = 0
      Items.Strings = (
        'COM1'
        'COM2'
        'COM3'
        'COM4'
        'COM5'
        'COM6'
        'COM7'
        'COM8'
        'COM9'
        'COM10')
    end
    object cbBaudRate: TComboBox
      Left = 16
      Top = 91
      Width = 185
      Height = 23
      TabOrder = 1
      Items.Strings = (
        '110'
        '300'
        '600'
        '1200'
        '2400'
        '4800'
        '9600'
        '14400'
        '19200'
        '38400'
        '56000'
        '57600'
        '115200'
        '128000'
        '256000')
    end
    object btnInitialize: TButton
      Left = 16
      Top = 288
      Width = 75
      Height = 25
      Caption = 'Initialize'
      TabOrder = 5
      OnClick = btnInitializeClick
    end
  end
  object cbTemperatureResolution: TComboBox
    Left = 424
    Top = 29
    Width = 145
    Height = 23
    Style = csDropDownList
    TabOrder = 1
    Items.Strings = (
      '14 Bit'
      '11 Bit')
  end
  object cbHumidityResolution: TComboBox
    Left = 240
    Top = 29
    Width = 145
    Height = 23
    Style = csDropDownList
    TabOrder = 2
    Items.Strings = (
      '14 Bit'
      '11 Bit'
      '8 Bit')
  end
  object btnSetResolution: TButton
    Left = 584
    Top = 28
    Width = 105
    Height = 25
    Caption = 'Set Resolution'
    TabOrder = 3
    OnClick = btnSetResolutionClick
  end
  object comPort: TApdComPort
    TraceName = 'APRO.TRC'
    LogName = 'APRO.LOG'
    OnTriggerAvail = comPortTriggerAvail
    Left = 120
    Top = 24
  end
end
