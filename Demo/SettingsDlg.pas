{*****************************************************************************
  The TComportDrv team licenses this file
  to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License. A copy of this licence is found in the root directory
  of this project in the file LICENCE.txt or alternatively at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an
  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  KIND, either express or implied.  See the License for the
  specific language governing permissions and limitations
  under the License.
*****************************************************************************}
unit SettingsDlg;

interface

uses
  // Delphi units
  Windows, Messages, SysUtils, Classes,
  Graphics, Controls, Forms, Dialogs, StdCtrls, ComCtrls, ExtCtrls,
  // ComDrv32 units
  CPDrv;

type
  TSettingsForm = class( TForm )
    Panel1: TPanel;
    SettingsPageControl: TPageControl;
    BaseSettingsTabSheet: TTabSheet;
    OkButton: TButton;
    CancelButton: TButton;
    PortComboBox: TComboBox;
    Label1: TLabel;
    BaudRateComboBox: TComboBox;
    Label2: TLabel;
    Label3: TLabel;
    DataBitsComboBox: TComboBox;
    Label4: TLabel;
    ParityComboBox: TComboBox;
    Label5: TLabel;
    StopBitsComboBox: TComboBox;
    FlowControlTabSheet: TTabSheet;
    Label6: TLabel;
    HwFlowComboBox: TComboBox;
    Label7: TLabel;
    SwFlowComboBox: TComboBox;
    Label8: TLabel;
    DTRControlComboBox: TComboBox;
    TabSheet1: TTabSheet;
    Label9: TLabel;
    DevCheckComboBox: TComboBox;
    procedure OkButtonClick(Sender: TObject);
  private
    // TCommPortDriver whose settings must be customized
    FCPDrv: TCommPortDriver;
    // Shows current settings
    procedure UpdateControls;
  public
    // Constructor
    constructor Create( AOwner: TComponent; ACPDrv: TCommPortDriver ); reintroduce; virtual;
  end;

implementation

{$R *.DFM}

// Constructor
constructor TSettingsForm.Create( AOwner: TComponent; ACPDrv: TCommPortDriver );
begin
  // Call inherited constructor
  inherited Create( AOwner );
  // Save the cpDrv reference
  FCPDrv := ACPDrv;
  // Show current settings
  UpdateControls;
  // Be sure the "Base Settings" tab control is the one selected
  SettingsPageControl.ActivePage := BaseSettingsTabSheet;
end;

// Shows current settings
procedure TSettingsForm.UpdateControls;
begin
  // Base Settings page
  PortComboBox.Text := string(FCPDrv.PortName);
  BaudRateComboBox.Text := IntToStr( FCPDrv.BaudRateValue );
  DataBitsComboBox.ItemIndex := ord( FCPDrv.DataBits );
  ParityComboBox.ItemIndex := ord( FCPDrv.Parity );
  StopBitsComboBox.ItemIndex := ord( FCPDrv.StopBits );
  // Flow Control page
  HwFlowComboBox.ItemIndex := ord( FCPDrv.HwFlow );
  SwFlowComboBox.ItemIndex := ord( FCPDrv.SwFlow );
  DTRControlComboBox.ItemIndex := ord( not FCPDrv.EnableDTROnOpen );
  // Device Control page
  DevCheckComboBox.ItemIndex := ord( not FCPDrv.CheckLineStatus );
end;

procedure TSettingsForm.OkButtonClick(Sender: TObject);
var newPortName: string;
    newBaudRate: DWORD;
begin
  // Validate settings
  newPortName := Trim( PortComboBox.Text );
  if newPortName = '' then
  begin
    Application.MessageBox( 'Please, enter a valid port name.',
                            'Error',
                            MB_OK or MB_ICONERROR );
    exit;
  end;
  newBaudRate := DWORD( StrToIntDef( BaudRateComboBox.Text, -1 ) );
  if (newBaudRate < 110) or (newBaudRate > 921600) then
  begin
    Application.MessageBox( 'Please, enter a valid baud rate.',
                            'Error',
                            MB_OK or MB_ICONERROR );
    exit;
  end;
  // Apply new settings
  FCPDrv.PortName := newPortName;
  FCPDrv.BaudRateValue := newBaudRate;
  FCPDrv.DataBits := TDataBits( DataBitsComboBox.ItemIndex );
  FCPDrv.Parity := TParity( ParityComboBox.ItemIndex );
  FCPDrv.StopBits := TStopBits( StopBitsComboBox.ItemIndex );
  FCPDrv.HwFlow := THwFlowControl( HwFlowComboBox.ItemIndex );
  FCPDrv.SwFlow := TSwFlowControl( SwFlowComboBox.ItemIndex );
  FCPDrv.EnableDTROnOpen := DTRControlComboBox.ItemIndex = 0;
  FCPDrv.CheckLineStatus := DevCheckComboBox.ItemIndex = 0;
  // Done
  ModalResult := mrOk;
end;

end.
