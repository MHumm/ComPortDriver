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
unit MnForm;

interface

uses
  // Delphi units
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Menus, ComCtrls, ExtCtrls, StdCtrls, ToolWin, ImgList, ClipBrd,idglobal,
  // ComDrv32 units
  CPDrv,
  // TTY units
  AboutTTY,
  SettingsDlg, System.ImageList;

type
  TMainForm = class(TForm)
    cpDrv: TCommPortDriver;
    MainMenu: TMainMenu;
    FileMenu: TMenuItem;
    OptionsMenu: TMenuItem;
    Splitter1: TSplitter;
    RXPanel: TPanel;
    IncomingRichEdit: TRichEdit;
    Panel2: TPanel;
    TXPanel: TPanel;
    OutgoingRichEdit: TRichEdit;
    Panel3: TPanel;
    ToolBar1: TToolBar;
    ConnectToolButton: TToolButton;
    DisconnectToolButton: TToolButton;
    SettingsToolButton: TToolButton;
    E_ImageList: TImageList;
    QuitTTYToolButton: TToolButton;
    SerialIOSettingsCmd: TMenuItem;
    Label1: TLabel;
    Label2: TLabel;
    IT_PopupMenu: TPopupMenu;
    OT_PopupMenu: TPopupMenu;
    IT_ClearCmd: TMenuItem;
    OT_ClearCmd: TMenuItem;
    N1: TMenuItem;
    OT_CutCmd: TMenuItem;
    OT_CopyCmd: TMenuItem;
    N3: TMenuItem;
    IT_CopyCmd: TMenuItem;
    ActionsMenu: TMenuItem;
    ActionsConnectCmd: TMenuItem;
    ActionsDisconnectCmd: TMenuItem;
    FileQuitCmd: TMenuItem;
    HelpMenu: TMenuItem;
    HelpAboutCmd: TMenuItem;
    ToolButton1: TToolButton;
    OT_PasteCmd: TMenuItem;
    Panel1: TPanel;
    StatusPanel: TPanel;
    FrameSettingsPanel: TPanel;
    FlowSettingsPanel: TPanel;
    procedure SettingsToolButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ConnectToolButtonClick(Sender: TObject);
    procedure DisconnectToolButtonClick(Sender: TObject);
    procedure OutgoingRichEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure OT_ClearCmdClick(Sender: TObject);
    procedure OutgoingRichEditKeyPress(Sender: TObject; var Key: Char);
    /// <summary>
    ///   Handles all incoming data
    /// </summary>
    procedure cpDrvReceiveData(Sender: TObject; DataPtr: Pointer;
      DataSize: DWord);
    procedure IT_ClearCmdClick(Sender: TObject);
    procedure QuitTTYToolButtonClick(Sender: TObject);
    procedure HelpAboutCmdClick(Sender: TObject);
    procedure OT_CutCmdClick(Sender: TObject);
    procedure OT_CopyCmdClick(Sender: TObject);
    procedure OT_PasteCmdClick(Sender: TObject);
    procedure IT_CopyCmdClick(Sender: TObject);
    procedure OT_PopupMenuPopup(Sender: TObject);
    procedure IT_PopupMenuPopup(Sender: TObject);
  private
    // Startup about-box (splash screen)
    FAboutBox: TAboutBoxForm;
    FAboutBoxShownTime: DWORD;

    // Called when the message queue gets empty.
    procedure IdleProc( Sender: TObject; var Done: boolean );
    // Updates the panels on bottom of this window.
    procedure UpdateStatusPanels;
    // Displays an error box informing the user we can't send data
    procedure CannotSendError;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.DFM}

// Form setup
procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Redirect OnIdle
  Application.OnIdle := IdleProc;
  // Display the splash screen
  FAboutBox := TAboutBoxForm.Create( nil, false );
  Enabled := false;
  FAboutBoxShownTime := GetTickCount();
  FAboutBox.Show;
  FAboutBox.Update;
end;

// Lets the user to customize I/O settings
procedure TMainForm.SettingsToolButtonClick(Sender: TObject);
var dlg: TSettingsForm;
begin
  // Tell the user we cannot change settings while a connection is active
  if cpDrv.Connected then
  begin
    if Application.MessageBox( 'Could not change settings while a connection is active.'#13#10+
                               'Close the connection and continue ?',
                               'Confirm',
                               MB_OKCANCEL or MB_ICONQUESTION ) <> ID_OK then
      exit;
    cpDrv.Disconnect;
  end;
  // Let the user to customize settings
  dlg := nil;
  try
    dlg := TSettingsForm.Create( Self, cpDrv );
    dlg.ShowModal;
  finally
    dlg.Free;
  end;
end;

// Called when the message queue gets empty.
procedure TMainForm.IdleProc( Sender: TObject; var Done: boolean );
var elapsedTime: DWORD;
begin
  Done := false;
  // Hides the splash-screen
  if FAboutBox <> nil then
  begin
    elapsedTime := GetTickCount - FAboutBoxShownTime;
    if elapsedTime < 400 then
      SetForegroundWindow( FAboutBox.Handle );
    if (elapsedTime > 5000) or FAboutBox.ReqToClose then
    begin
      FAboutBox.Free;
      FAboutBox := nil;
      Enabled := true;
    end;
  end;
  // Updates status panels
  UpdateStatusPanels;
end;

// Updates the panels on bottom of this window.
procedure TMainForm.UpdateStatusPanels;
const _databits: array[TDataBits] of string = ('5','6','7','8');
      _parity: array[TParity] of string = ('N','E','O','M','S');
      _stopbits: array[TStopBits] of string = ('1','1.5','2');
      _hwflow: array[THwFlowControl] of string = ('None','None+DTR on','RTS/CTS');
      _swflow: array[TSwFlowControl] of string = ('None','XON/XOFF');
var
  s: string;
begin
  // Updates the connection status
  if cpDrv.Connected then
    s := 'Connected to "' + string(cpDrv.PortName) + '"'
  else
    s := 'Not connected';
  StatusPanel.Caption := s;
  // Show current frame settings
  s := IntToStr( cpDrv.BaudRateValue ) + ',' +
       _databits[ cpDrv.DataBits ] + ',' +
       _parity[ cpDrv.Parity ] + ',' +
       _stopbits[ cpDrv.StopBits ];
  FrameSettingsPanel.Caption := s;
  // Show current flow control settings
  s := 'Hw:' + _hwflow[ cpDrv.HwFlow ] + ' - Sw:' + _swflow[ cpDrv.SwFlow ];
  FlowSettingsPanel.Caption := s;
end;

// Connect
procedure TMainForm.ConnectToolButtonClick(Sender: TObject);
begin
  // Do nothing if already connected
  if cpDrv.Connected then
    exit;
  // Try connecting
  if not cpDrv.Connect then
  begin
    Application.MessageBox( 'Could not connect to serial port.'#13#10+
                            'Please, check settings and try again.',
                            'Error',
                            MB_OK or MB_ICONERROR );
    exit;
  end;
end;

// Disconnect
procedure TMainForm.DisconnectToolButtonClick(Sender: TObject);
begin
  // Do nothing if not connected
  if not cpDrv.Connected then
    exit;
  // Disconnect
  cpDrv.Disconnect;
end;

// If user is trying to send text but the connection is not active then
// automatically bring it on.
procedure TMainForm.OutgoingRichEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if not cpDrv.Connected then
  begin
    ConnectToolButtonClick( nil );
    if not cpDrv.Connected then
      Key := 0;
  end;
end;

procedure TMainForm.OT_ClearCmdClick(Sender: TObject);
begin
  OutgoingRichEdit.Lines.BeginUpdate;
  OutgoingRichEdit.Lines.Clear;
  OutgoingRichEdit.Lines.EndUpdate;
end;


// Displays an error box informing the user we can't send data
procedure TMainForm.CannotSendError;
begin
  if cpDrv.CheckLineStatus then
    Application.MessageBox( 'Could not send data.'#13#10+
                            'No device connected to serial port or device is off. Please, turn it on.'#13#10 +
                            'Try setting Device Check to Off in the settings dialog box.'#13#10 +
                            'Also, replace your two wires serial cable with a full wires cable.',
                            'Warning',
                            MB_OK or MB_ICONINFORMATION )
  else
    Application.MessageBox( 'Could not send data.'#13#10+
                            'Please, check connections and try again.'#13#10 +
                            'Turn serial device on or, try setting Device Check to On in the settings dialog box.'#13#10 +
                            'Also, disable Hardware Flow Control if you are using a two wires cable.',
                            'Warning',
                            MB_OK or MB_ICONINFORMATION )
end;

procedure TMainForm.OutgoingRichEditKeyPress(Sender: TObject;
  var Key: Char);
begin
  // Do nothing if not connected
  if not cpDrv.Connected then
    exit;
  // Send the character
  if not cpDrv.SendChar(AnsiChar(Key)) then
    CannotSendError;
end;

procedure TMainForm.cpDrvReceiveData(Sender: TObject; DataPtr: Pointer;
  DataSize: DWord);
var iLastLine, i: integer;
    s, ss: string;
begin
  // Convert incoming data into a string
  s := StringOfChar( ' ', DataSize );

  ShowMessage('DataSize='+inttostr(DataSize));
  for i:=1 to DataSize do begin
    ShowMessage('<'+s[i]+'>'+#10+inttostr(ord(s[i]))+'/'+inttohex(ord(s[i]),2));
  end;

  ShowMessage('DataSize='+inttostr(DataSize)+#10+'<'+s+'>'+inttostr(length(s)));

  move( DataPtr^, pchar(s)^, DataSize );

//  for i:=1 to 9 do showmessage(inttobin(ord(s[i])));
  // Exit if s is empty. This usually occurs when one or more NULL characters
  // (chr(0)) are received.
  while pos( #0, s ) > 0 do
    delete( s, pos( #0, s ), 1 );
  if s = '' then
    exit;
  // Remove line feeds
  i := pos( #10, s );
  while i <> 0 do
  begin
    delete( s, i, 1 );
    i := pos( #10, s );
  end;

  // Don't redraw the rich edit control until we finished updating it
  //IncomingRichEdit.Lines.BeginUpdate;
  // Get last line index
  iLastLine := IncomingRichEdit.Lines.Count-1;
  // If the rich edit is empty...
  if iLastLine = -1 then
  begin
    // Remove line feeds from the string
    i := pos( #10, s );
    while i <> 0 do
    begin
      delete( s, i, 1 );
      i := pos( #10, s );
    end;
    // Remove carriage returns from the string (break lines)
    i := pos( #13, s );
    while i <> 0 do
    begin
      ss := copy( s, 1, i-1 );
      delete( s, 1, i );
      IncomingRichEdit.Lines.Append( ss );
      i := pos( #13, s );
    end;
    IncomingRichEdit.Lines.Append( s );
  end
  else
  begin
    // String to add is : last line added + new one
    s := IncomingRichEdit.Lines[iLastLine] + s;
    // Remove carriage returns (break lines)
    i := pos( #13, s );
    while i <> 0 do
    begin
      ss := copy( s, 1, i-1 );
      delete( s, 1, i );
      if iLastLine <> -1 then
      begin
        IncomingRichEdit.Lines[iLastLine] := ss;
        iLastLine := -1;
      end
      else
        IncomingRichEdit.Lines.Append( ss );
      i := pos( #13, s );
    end;
    if iLastLine <> -1 then
      IncomingRichEdit.Lines[iLastLine] := s
    else
      IncomingRichEdit.Lines.Append( s );
  end;
  //IncomingRichEdit.Lines.EndUpdate;
  // Scroll incoming text rich edit
  SendMessage( IncomingRichEdit.Handle, EM_SCROLLCARET, 0, 0 );
end;

procedure TMainForm.IT_ClearCmdClick(Sender: TObject);
begin
  IncomingRichEdit.Lines.BeginUpdate;
  IncomingRichEdit.Lines.Clear;
  IncomingRichEdit.Lines.EndUpdate;
end;

// Quits TTY
procedure TMainForm.QuitTTYToolButtonClick(Sender: TObject);
begin
  PostQuitMessage( Handle );
end;

procedure TMainForm.HelpAboutCmdClick(Sender: TObject);
var dlg: TAboutBoxForm;
begin
  dlg := nil;
  try
    dlg := TAboutBoxForm.Create( Self, true );
    dlg.ShowModal;
  finally
    dlg.Free;
  end;
end;

procedure TMainForm.OT_CutCmdClick(Sender: TObject);
begin
  OutgoingRichEdit.CutToClipboard;
end;

procedure TMainForm.OT_CopyCmdClick(Sender: TObject);
begin
  OutgoingRichEdit.CopyToClipboard;
end;

procedure TMainForm.OT_PasteCmdClick(Sender: TObject);
var clp: TClipboard;
    s, ss: string;
    iLastLine, i: integer;
begin
  // Get the clipboard object
  clp := Clipboard;
  // If the clipboard contains some text...
  if clp.HasFormat( CF_TEXT ) then
  begin
    // Automatically connect
    if not cpDrv.Connected then
    begin
      ConnectToolButtonClick( nil );
      if not cpDrv.Connected then
        exit;
    end;
    // Get the text
    s := clp.AsText;
    // Remove line feeds
    i := pos( #10, s );
    while i <> 0 do
    begin
      delete( s, i, 1 );
      i := pos( #10, s );
    end;
    // Add the text to the rich edit and send it
    iLastLine := OutgoingRichEdit.Lines.Count-1;
    i := pos( #13, s );
    while i <> 0 do
    begin
      ss := copy( s, 1, i-1 );
      delete( s, 1, i );
      if iLastLine <> -1 then
      begin
        OutgoingRichEdit.Lines[iLastLine] := OutgoingRichEdit.Lines[iLastLine] + ss;
        iLastLine := -1;
      end
      else
        OutgoingRichEdit.Lines.Append( ss );
      if not cpDrv.SendString(AnsiString(ss) + #13 ) then
      begin
        CannotSendError;
        exit;
      end;
      i := pos( #13, s );
    end;
    if iLastLine <> -1 then
      OutgoingRichEdit.Lines[iLastLine] := OutgoingRichEdit.Lines[iLastLine] + s
    else
      OutgoingRichEdit.Lines.Append( s );
    if not cpDrv.SendString(AnsiString(s)) then
      CannotSendError;
  end;
end;

procedure TMainForm.IT_CopyCmdClick(Sender: TObject);
begin
  IncomingRichEdit.CopyToClipboard;
end;

procedure TMainForm.OT_PopupMenuPopup(Sender: TObject);
begin
  OT_ClearCmd.Enabled := OutgoingRichEdit.Lines.Count > 0;
  OT_CutCmd.Enabled := OutgoingRichEdit.SelLength > 0;
  OT_CopyCmd.Enabled := OutgoingRichEdit.SelLength > 0;
  OT_PasteCmd.Enabled := Clipboard.HasFormat( CF_TEXT );
end;

procedure TMainForm.IT_PopupMenuPopup(Sender: TObject);
begin
  IT_ClearCmd.Enabled := IncomingRichEdit.Lines.Count > 0;
  IT_CopyCmd.Enabled := IncomingRichEdit.SelLength > 0;
end;

end.
