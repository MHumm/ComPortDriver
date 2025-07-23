object SettingsForm: TSettingsForm
  Left = 406
  Top = 310
  BorderStyle = bsDialog
  Caption = 'Settings'
  ClientHeight = 206
  ClientWidth = 314
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Position = poDesktopCenter
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 314
    Height = 206
    Align = alClient
    BevelOuter = bvNone
    BorderWidth = 2
    TabOrder = 0
    object SettingsPageControl: TPageControl
      Left = 2
      Top = 2
      Width = 310
      Height = 202
      ActivePage = BaseSettingsTabSheet
      Align = alClient
      TabOrder = 0
      object BaseSettingsTabSheet: TTabSheet
        Caption = 'Base Settings'
        object Label1: TLabel
          Left = 32
          Top = 24
          Width = 51
          Height = 13
          Alignment = taRightJustify
          Caption = 'Port name:'
          FocusControl = PortComboBox
        end
        object Label2: TLabel
          Left = 34
          Top = 52
          Width = 49
          Height = 13
          Alignment = taRightJustify
          Caption = 'Baud rate:'
          FocusControl = BaudRateComboBox
        end
        object Label3: TLabel
          Left = 38
          Top = 80
          Width = 45
          Height = 13
          Alignment = taRightJustify
          Caption = 'Data bits:'
          FocusControl = DataBitsComboBox
        end
        object Label4: TLabel
          Left = 54
          Top = 108
          Width = 29
          Height = 13
          Alignment = taRightJustify
          Caption = 'Parity:'
          FocusControl = ParityComboBox
        end
        object Label5: TLabel
          Left = 39
          Top = 136
          Width = 44
          Height = 13
          Alignment = taRightJustify
          Caption = 'Stop bits:'
          FocusControl = StopBitsComboBox
        end
        object PortComboBox: TComboBox
          Left = 88
          Top = 20
          Width = 114
          Height = 21
          TabOrder = 0
          Items.Strings = (
            '\\.\COM1'
            '\\.\COM2'
            '\\.\COM3'
            '\\.\COM4'
            '\\.\COM5'
            '\\.\COM6'
            '\\.\COM7'
            '\\.\COM8'
            '\\.\COM9'
            '\\.\COM10'
            '\\.\COM11'
            '\\.\COM12'
            '\\.\COM13'
            '\\.\COM14'
            '\\.\COM15'
            '\\.\COM16')
        end
        object BaudRateComboBox: TComboBox
          Left = 88
          Top = 48
          Width = 114
          Height = 21
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
            '230400'
            '256000'
            '460800'
            '921600')
        end
        object DataBitsComboBox: TComboBox
          Left = 88
          Top = 76
          Width = 114
          Height = 21
          Style = csDropDownList
          TabOrder = 2
          Items.Strings = (
            '5'
            '6'
            '7'
            '8')
        end
        object ParityComboBox: TComboBox
          Left = 88
          Top = 104
          Width = 114
          Height = 21
          Style = csDropDownList
          TabOrder = 3
          Items.Strings = (
            'None'
            'Odd'
            'Even'
            'Mark'
            'Space')
        end
        object StopBitsComboBox: TComboBox
          Left = 88
          Top = 132
          Width = 114
          Height = 21
          Style = csDropDownList
          TabOrder = 4
          Items.Strings = (
            '1'
            '1.5'
            '2')
        end
      end
      object FlowControlTabSheet: TTabSheet
        Caption = 'Flow Control'
        ImageIndex = 1
        object Label6: TLabel
          Left = 12
          Top = 24
          Width = 71
          Height = 13
          Alignment = taRightJustify
          Caption = 'Hardware flow:'
          FocusControl = HwFlowComboBox
        end
        object Label7: TLabel
          Left = 16
          Top = 52
          Width = 67
          Height = 13
          Alignment = taRightJustify
          Caption = 'Software flow:'
          FocusControl = SwFlowComboBox
        end
        object Label8: TLabel
          Left = 22
          Top = 80
          Width = 61
          Height = 13
          Alignment = taRightJustify
          Caption = 'DTR control:'
          FocusControl = DTRControlComboBox
        end
        object HwFlowComboBox: TComboBox
          Left = 88
          Top = 20
          Width = 114
          Height = 21
          Style = csDropDownList
          TabOrder = 0
          Items.Strings = (
            'None'
            'None but RTS on'
            'RTS/CTS')
        end
        object SwFlowComboBox: TComboBox
          Left = 88
          Top = 48
          Width = 114
          Height = 21
          Style = csDropDownList
          TabOrder = 1
          Items.Strings = (
            'None'
            'XON/XOFF')
        end
        object DTRControlComboBox: TComboBox
          Left = 88
          Top = 76
          Width = 114
          Height = 21
          Style = csDropDownList
          TabOrder = 2
          Items.Strings = (
            'Standard'
            'Keep off')
        end
      end
      object TabSheet1: TTabSheet
        Caption = 'Device Control'
        ImageIndex = 2
        object Label9: TLabel
          Left = 13
          Top = 24
          Width = 70
          Height = 13
          Alignment = taRightJustify
          Caption = 'Device check:'
          FocusControl = DevCheckComboBox
        end
        object DevCheckComboBox: TComboBox
          Left = 88
          Top = 20
          Width = 114
          Height = 21
          Style = csDropDownList
          TabOrder = 0
          Items.Strings = (
            'Yes'
            'No')
        end
      end
    end
  end
  object CancelButton: TButton
    Left = 228
    Top = 60
    Width = 76
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
  object OkButton: TButton
    Left = 228
    Top = 32
    Width = 75
    Height = 25
    Caption = 'Ok'
    Default = True
    TabOrder = 1
    OnClick = OkButtonClick
  end
end
