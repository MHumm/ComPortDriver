{$WARN UNSAFE_CODE OFF}
//------------------------------------------------------------------------
// UNIT           : CPDrv.pas
// CONTENTS       : TCommPortDriver component
// VERSION        : 3.0
// TARGET         : Embarcadero Delphi 10.3 Rio or higher
// AUTHOR         : Original author: Marco Cocco, updated/enhanced by Markus Humm
// STATUS         : Open source under Apache 2.0 library
// INFOS          : Implementation of TCommPortDriver component:
//                  - non multithreaded serial I/O
// KNOWN BUGS     : none
// COMPATIBILITY  : Windows 7, 8/8.1, 10
// REPLACES       : TCommPortDriver v2.00    (Delphi 4.0)
//                  TCommPortDriver v1.08/16 (Delphi 1.0)
//                  TCommPortDriver v1.08/32 (Delphi 2.0/3.0)
// BACK/COMPAT.   : partial - a lot of properties have been renamed
// RELEASE DATE   : 06/06/2000
//                  (Replaces v2.0 released on 30/NOV/1998)
//
{*****************************************************************************
  The CPDrv team (see file NOTICE.txt) licenses this file
  to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License. A copy of this licence is found in the root directory of
  this project in the file LICENCE.txt or alternatively at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an
  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  KIND, either express or implied.  See the License for the
  specific language governing permissions and limitations
  under the License.
*****************************************************************************}

unit CPDrv;

interface

uses
  // Delphi units
  Winapi.Windows, Messages, System.SysUtils, System.Classes;

//------------------------------------------------------------------------
// Property types
//------------------------------------------------------------------------

type
  /// <summary>
  ///   Baud Rates (custom or 110...256k bauds)
  /// </summary>
  TBaudRate = (brCustom,
                br110, br300, br600, br1200, br2400, br4800,
                br9600, br14400, br19200, br38400, br56000,
                br57600, br115200, br128000, br256000);
  /// <summary>
  ///   Port Numbers (custom or COM1..COM16)
  /// </summary>
  TPortNumber = (pnCustom,
                  pnCOM1, pnCOM2, pnCOM3, pnCOM4, pnCOM5, pnCOM6, pnCOM7,
                  pnCOM8, pnCOM9, pnCOM10, pnCOM11, pnCOM12, pnCOM13,
                  pnCOM14, pnCOM15, pnCOM16);
  /// <summary>
  ///   Data bits (5, 6, 7, 8)
  /// </summary>
  TDataBits = (db5BITS, db6BITS, db7BITS, db8BITS);
  /// <summary>
  ///   Stop bits (1, 1.5, 2)
  /// </summary>
  TStopBits = (sb1BITS, sb1HALFBITS, sb2BITS);
  /// <summary>
  ///   Parity (None, odd, even, mark, space)
  /// </summary>
  TParity = (ptNONE, ptODD, ptEVEN, ptMARK, ptSPACE);
  /// <summary>
  ///   Hardware Flow Control (None, None + RTS always on, RTS/CTS)
  /// </summary>
  THwFlowControl = (hfNONE, hfNONERTSON, hfRTSCTS);
  /// <summary>
  ///   Software Flow Control (None, XON/XOFF)
  /// </summary>
  TSwFlowControl = (sfNONE, sfXONXOFF);
  /// <summary>
  ///   What to do with incomplete (incoming) packets (Discard, Pass)
  /// </summary>
  TPacketMode = (pmDiscard, pmPass);

//------------------------------------------------------------------------
// Event types
//------------------------------------------------------------------------

type
  /// <summary>
  ///   RX/receive event (packet mode disabled)
  /// </summary>
  /// <param name="Sender">
  ///   Object calling this eventhandler
  /// </param>
  /// <param name="DataPtr">
  ///   Pointer to the received data
  /// </param>
  /// <param name="DataSize">
  ///   Number of bytes received
  /// </param>
  TReceiveDataEvent = procedure(Sender: TObject; DataPtr: pointer; DataSize: DWORD) of object;
  /// <summary>
  ///   RX/receive event (packed mode enabled)
  /// </summary>
  /// <param name="Sender">
  ///   Object calling this eventhandler
  /// </param>
  /// <param name="Packet">
  ///   Pointer to the received data packet
  /// </param>
  /// <param name="DataSize">
  ///   Number of bytes received
  /// </param>
  TReceivePacketEvent = procedure(Sender: TObject; Packet: pointer; DataSize: DWORD) of object;

//------------------------------------------------------------------------
// Other types
//------------------------------------------------------------------------

type
  /// <summary>
  ///   Line status (Clear To Send, Data Set Ready, Ring, Carrier Detect)
  /// </summary>
  TLineStatus = (lsCTS, lsDSR, lsRING, lsCD);
  /// <summary>
  ///   Set of line status
  /// </summary>
  TLineStatusSet = set of TLineStatus;

//------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------

const
  /// <summary>
  ///   Handle value checked when manually setting the handle. If that handle
  ///   has this value the receive timer is stopped and the handle declared as
  ///   invalid.
  /// </summary>
  RELEASE_NOCLOSE_PORT = HFILE(INVALID_HANDLE_VALUE-1);

//------------------------------------------------------------------------
// TCommPortDriver component
//------------------------------------------------------------------------

type
  /// <summary>
  ///   Non visual component for RS232 communications
  /// </summary>
  TCommPortDriver = class(TComponent)
  protected
    /// <summary>
    ///   Device Handle (File Handle)
    /// </summary>
    FHandle                    : HFILE;
    /// <summary>
    ///   # of the COM port to use, or pnCustom to use custom port name
    /// </summary>
    FPort                      : TPortNumber;
    /// <summary>
    ///   Custom port name (usually '\\.\COMn', with n = 1..x)
    /// </summary>
    FPortName                  : string;
    /// <summary>
    ///   COM Port speed (brXXX)
    /// </summary>
    FBaudRate                  : TBaudRate;
    /// <summary>
    ///   Baud rate (actual numeric value)
    /// </summary>
    FBaudRateValue             : DWORD;
    /// <summary>
    ///   Data bits size (dbXXX)
    /// </summary>
    FDataBits                  : TDataBits;
    /// <summary>
    ///   How many stop bits to use (sbXXX)
    /// </summary>
    FStopBits                  : TStopBits;
    /// <summary>
    ///   Type of parity to use (ptXXX)
    /// </summary>
    FParity                    : TParity;
    /// <summary>
    ///   Type of hw handshaking (hw flow control) to use (hfXXX)
    /// </summary>
    FHwFlow                    : THwFlowControl;
    /// <summary>
    ///   Type of sw handshaking (sw flow control) to use (sFXXX)
    /// </summary>
    FSwFlow                    : TSwFlowControl;
    /// <summary>
    ///   Size of the input buffer
    /// </summary>
    FInBufSize                 : DWORD;
    /// <summary>
    ///   Size of the output buffer
    /// </summary>
    FOutBufSize                : DWORD;
    /// <summary>
    ///   Size of a data packet
    /// </summary>
    FPacketSize                : Smallint;
    /// <summary>
    ///   ms to wait for a complete packet (<=0 = disabled)
    /// </summary>
    FPacketTimeout             : Integer;
    /// <summary>
    ///   What to do with incomplete packets (pmXXX)
    /// </summary>
    FPacketMode                : TPacketMode;
    /// <summary>
    ///   Event to raise on data reception (asynchronous)
    /// </summary>
    FOnReceiveData             : TReceiveDataEvent;
    /// <summary>
    ///   Event to raise on packet reception (asynchronous)
    /// </summary>
    FOnReceivePacket           : TReceivePacketEvent;
    /// <summary>
    ///   ms of delay between COM port pollings
    /// </summary>
    FPollingDelay              : Word;
    /// <summary>
    ///   Specifies if the DTR line must be enabled/disabled on connect
    /// </summary>
    FEnableDTROnOpen           : Boolean;
    /// <summary>
    ///   Output timeout - milliseconds
    /// </summary>
    FOutputTimeout             : Word;
    /// <summary>
    ///   Timeout for ReadData
    /// </summary>
    FInputTimeout              : DWORD;
    /// <summary>
    ///   Set to TRUE to prevent hangs when no device connected or device is OFF
    /// </summary>
    FCkLineStatus              : Boolean;
    /// <summary>
    ///   This is used for the timer
    /// </summary>
    FNotifyWnd                 : HWND;
    /// <summary>
    ///   Temporary buffer (RX) - used internally
    /// </summary>
    FTempInBuffer              : Pointer;
    /// <summary>
    ///   Time of the first byte of current RX packet
    /// </summary>
    FFirstByteOfPacketTime     : DWORD;
    /// <summary>
    ///   Number of RX polling timer pauses
    /// </summary>
    FRXPollingPauses           : Integer;

    /// <summary>
    ///   Sets the COM port handle
    /// </summary>
    /// <param name="Value">
    ///   File handle to the port
    /// </param>
    procedure SetHandle(Value: HFILE);
    /// <summary>
    ///   Selects the COM port to use
    /// </summary>
    /// <param name="Value">
    ///   Number from the predefined enum of the port to use
    /// </param>
    procedure SetPort(Value: TPortNumber);
    /// <summary>
    ///   Sets the port name
    /// </summary>
    /// <param name="Value">
    ///   Name of the port to use in the form of \\.\COM3. This form is especially
    ///   necessary for port numbers bigger than 10.
    /// </param>
    procedure SetPortName(Value: string);
    /// <summary>
    ///   Selects the baud rate
    /// </summary>
    /// <param name="Baudrate">
    ///   Changes the baudrate to one of the fixed baudrates of this enum.
    ///   Be aware to not exceed the maximum baudrate supported by the equipment used.
    /// </param>
    procedure SetBaudRate(Value: TBaudRate);
    /// <summary>
    ///   Selects the baud rate (actual baud rate value)
    /// </summary>
    /// <param name="Value">
    ///   Freely defines a baudrate. Be aware to not exceed the maximum baudrate
    ///   supported by the equipment used.
    /// </param>
    procedure SetBaudRateValue(Value: DWORD);
    /// <summary>
    ///   Selects the number of data bits
    /// </summary>
    /// <param name="Value">
    ///   New number of data bits per byte. Be aware that not all ports support
    ///   all values defined but we can't detect this.
    /// </param>
    procedure SetDataBits(Value: TDataBits);
    /// <summary>
    ///   Selects the number of stop bits
    /// </summary>
    /// <param name="Value">
    ///   New number of stopbits. Be aware that not all ports support all values
    ///   defined but we can't detect this. Especially 1.5 is often unsupported.
    /// </param>
    procedure SetStopBits(Value: TStopBits);
    /// <summary>
    ///   Selects the kind of parity
    /// </summary>
    /// <param name="Value">
    ///   New parity value. Be aware that not all ports support all values
    ///   defined but we can't detect this.
    /// </param>
    procedure SetParity(Value: TParity);
    /// <summary>
    ///   Selects the kind of hardware flow control
    /// </summary>
    /// <param name="Value">
    ///   New value for the hardware flow control mode to use.
    /// </param>
    procedure SetHwFlowControl(Value: THwFlowControl);
    /// <summary>
    ///   Selects the kind of software flow control
    /// </summary>
    /// <param name="Value">
    ///   New value for the software flow control mode to use.
    /// </param>
    procedure SetSwFlowControl(Value: TSwFlowControl);
    /// <summary>
    ///   Sets the RX buffer size
    /// </summary>
    /// <param name="Value">
    ///   New receive buffer size in byte. Restricted to MinRXBufferSize and
    ///   MaxRXBufferSize.
    /// </param>
    procedure SetInBufSize(Value: DWORD);
    /// <summary>
    ///   Sets the TX buffer size
    /// </summary>
    /// <param name="Value">
    ///   New receive buffer size in byte. Restricted to MinTBufferSize and
    ///   MaxTBufferSize.
    /// </param>
    procedure SetOutBufSize(Value: DWORD);
    /// <summary>
    ///   Sets the size of incoming packets
    /// </summary>
    /// <param name="Value">
    ///   Size of incomming packets in byte. If ther Receive buffer size is smaller
    ///   than the packet size specified here it will be automatically increased
    ///   to the size specified here.
    /// </param>
    procedure SetPacketSize(Value: Smallint);
    /// <summary>
    ///   Sets the timeout for incoming packets
    /// </summary>
    /// <param name="Value">
    ///   Time in ms to wait for arrival of incomming packets before assuming a
    ///   timeout. It cannot be less than polling delay + some extra ms so it is
    ///   adjusted to that if value given is less than polling delay.
    /// </param>
    procedure SetPacketTimeout(Value: Integer);
    /// <summary>
    ///   Sets the delay between polling checks
    /// </summary>
    /// <param name="Value">
    ///   New polling interval in ms. Be aware that accurancy is a bit limited
    ///   because of the use of the standard Windows timer.
    /// </param>
    procedure SetPollingDelay(Value: Word);
    /// <summary>
    ///   Applies current settings like baudrate and flow control to the open COM port
    /// </summary>
    /// <returns>
    ///   false if WInAPI call to activate these failures failed.
    /// </returns>
    function ApplyCOMSettings: Boolean;
    /// <summary>
    ///   Polling proc: fetches received data from the port and calls the
    ///   apropriate receive callbacks if necessary
    /// </summary>
    procedure TimerWndProc(var msg: TMessage);
  public
    /// <summary>
    ///   Constructor
    /// <summary>
    /// <param name="AOwner">
    ///   The owner is responsible for automatically freeint the component if it
    ///   is not manually created.
    /// </param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>
    ///   Close existing connection and free internal ressources
    /// </summary>
    destructor Destroy; override;

    /// <summary>    
    //    Opens the COM port and takes of it. Returns false if something goes wrong.
    /// </summary>    
    function Connect: Boolean;
    /// <summary>    
    ///   Closes the COM port and releases control of it
    /// </summary>    
    procedure Disconnect;
    /// <summary>
    ///    Returns true if COM port has been opened
    /// </summary>    
    function Connected: Boolean;
    /// <summary>
    ///   Returns the current state of CTS, DSR, RING and RLSD (CD) lines.
    ///   The function fails if the hardware does not support the control-register
    ///   values (that is, returned set is always empty).
    /// </summary>
    function GetLineStatus: TLineStatusSet;
    /// <summary>
    ///   Returns true if polling has not been paused
    /// </summary>
    function IsPolling: Boolean;
    /// <summary>    
    ///   Pauses polling 
    /// </summary>    
    procedure PausePolling;
    /// <summary>    
    ///   Re-starts polling (after pause) 
    /// </summary>    
    procedure ContinuePolling;
    /// <summary>    
    ///   Flushes the rx/tx buffers
    /// </summary>
    /// <param name="inBuf">
    ///   when true the receive buffer is cleared
    /// </param>
    /// <param name="outBuf">
    ///   when true the transmit buffer is cleared
    /// </param>
    function FlushBuffers(inBuf, outBuf: Boolean): Boolean;
    /// <summary>    
    ///   Returns number of received bytes in the RX buffer 
    /// </summary>    
    function CountRX: Integer;
    /// <summary>    
    ///   Returns the output buffer free space or 65535 if not connected 
    /// </summary>
    function OutFreeSpace: Word;
    /// <summary>    
    ///   Sends binary data 
    /// </summary>    
    /// <param name="DataPtr">
    ///   Pointer to the memory containing the data to send
    /// </param>
    /// <param name="DataSize">
    ///   Number of bytes to send
    /// </param>
    /// <returns>
    ///   Number of bytes sent
    /// </returns>
    function SendData(DataPtr: pointer; DataSize: DWORD): DWORD;
    /// <summary>    
    ///   Sends binary data. Returns number of bytes sent. Timeout overrides
    ///   the value specifiend in the OutputTimeout property
    /// </summary>
    /// <param name="DataPtr">
    ///   Pointer to the memory containing the data to send
    /// </param>
    /// <param name="DataSize">
    ///   Number of bytes to send
    /// </param>
    /// <param name="Timeout">
    ///   Timeout in ms. If this time elapsed and not all data could be sent 
    ///   further sending will be stoped.
    /// </param>
    /// <returns>
    ///   Number of bytes sent
    /// </returns>
    function SendDataEx(DataPtr: PAnsiChar; DataSize, Timeout: DWORD): DWORD;
    /// <summary>        
    ///   Sends a byte. Returns true if the byte has been sent
    /// </summary>        
    /// <param name="Value">
    ///   Byte to send
    /// </param>
    function SendByte(Value: byte): Boolean;
    /// <summary>
    ///   Sends a AnsiChar. Returns true if the AnsiChar has been sent
    /// </summary>        
    /// <param name="Value">
    ///   Char to send
    /// </param>
    function SendChar(Value: AnsiChar): Boolean;
    /// <summary>            
    ///   Sends a Pascal AnsiString (NULL terminated if $H+ (default))
    /// </summary>        
    /// <param name="s">
    ///   String to send
    /// </param>    
    function SendString(s: AnsiString): Boolean;
    /// <summary>            
    //    Sends a C-style Ansi string (NULL terminated) 
    /// </summary>        
    /// <param name="s">
    ///   string to send
    /// </param>    
    function SendZString(s: PAnsiChar): Boolean;
    /// <summary>         
    //    Reads binary data. Returns number of bytes read 
    /// </summary>         
    /// <param name="DataPtr">
    ///   Pointer to the memory where the read out data shall be stored.
    /// </param>
    /// <param name="MaxDataSize">
    ///   Maximum available memory space in byte.
    /// </param>
    /// <returns>
    ///   Number of bytes read, maximum MaxDataSize
    /// </returns>
    function ReadData(DataPtr: PAnsiChar; MaxDataSize: DWORD): DWORD;
    /// <summary>         
    //    Reads a byte. Returns true if the byte has been read 
    /// </summary>
    /// <param name="Value">
    ///   Byte variable into which the byte read out shall be written
    /// </param>
    function ReadByte(var Value: Byte): Boolean;
    /// <summary>         
    //    Reads a AnsiChar. Returns true if AnsiChar has been read
    /// </summary>         
    /// <param name="Value">
    ///   AnsiChar variable into which the byte read out shall be written
    /// </param>
    function ReadChar(var Value: AnsiChar): Boolean;
    /// <summary>         
    ///   Set DTR line high (onOff=TRUE) or low (onOff=FALSE).
    ///   You must not use HW handshaking.
    /// </summary>         
    /// <param name="onOff">
    ///   true for setting Data Terminal Ready line to high, false for low
    /// </param>
    procedure ToggleDTR(onOff: Boolean);
    /// <summary>         
    ///   Set RTS line high (onOff=TRUE) or low (onOff=FALSE).
    ///   You must not use HW handshaking.
    /// </summary>         
    /// <param name="onOff">
    ///   true for setting Request To Send line to high, false for low
    /// </param>
    procedure ToggleRTS(onOff: Boolean);

    /// <summary>
    ///   Returns the maximum size the receive buffer can be set to in byte
    /// </summary>
    function GetMaxRXBufferSize: DWord;
    /// <summary>
    ///   Returns the maximum size the transmit buffer can be set to in byte
    /// </summary>
    function GetMaxTXBufferSize: DWord;
    /// <summary>
    ///   Returns the maximum size the receive buffer can be set to in byte
    /// </summary>
    function GetMinRXBufferSize: DWord;
    /// <summary>
    ///   Returns the maximum size the transmit buffer can be set to in byte
    /// </summary>
    function GetMinTXBufferSize: DWord;

    /// <summary>
    ///   Puts the port into "break" state, means starts to send a break signal.
    ///   It does not flush any buffers and keeps sending this signal until
    ///   ClearCommBreak is being called.
    /// </summary>
    /// <returns>
    ///   true for success, false in case of failure
    /// </returns>
    function SetCommBreak: Boolean;
    /// <summary>
    ///   Stops sending a break signal started with SetCommBreak
    /// </summary>
    /// <returns>
    ///   true for success, false in case of failure
    /// </returns>
    function ClearCommBreak: Boolean;

    /// <summary>
    ///   Returns a list of available comports. It is not guaranteed that all
    ///   of them can be opened at the moment (some might be in use)
    /// </summary>
    /// <param name="ComPorts">
    ///   List to add the ports to
    /// </param>
    procedure EnumComPorts(ComPorts:TStrings);

    /// <summary>
    ///   Delivers the Windows API baudrate constant value for a given TBaudrate
    ///   enumeration value.
    /// </summary>
    /// <param name="bRate">
    ///   Enumeration value for which to return the Windows API constant value
    /// </param>
    /// <returns>
    ///   Windows API constant value or 0 if bRate = brCustom
    /// </returns>
    function BaudRateOf(bRate: TBaudRate): DWORD;
    /// <summary>
    ///   Calculates the time in ms it takes to receive a certain number of bytes at
    ///   a certain baudrate. The calculation is based on the current serial settings:
    ///   baudrate, databits per byte, number of stoppbits and parity.
    /// </summary>
    /// <param name="DataSize">
    ///   Number of bytes to send or receive
    /// </param>
    /// <returns>
    ///   Time in ms it takes to receive or send this amount of data
    /// </returns>
    function DelayForRX(DataSize: DWORD): DWORD;

    /// <summary>
    ///   Handle of the COM port (for TAPI...) [read/write]
    /// </summary>
    property Handle: HFILE read FHandle write SetHandle;
  published
    /// <summary>
    ///   Number of the COM Port to use (or pnCustom for port by name)
    /// </summary>
    property Port: TPortNumber read FPort write SetPort default pnCOM2;
    /// <summary>        
    ///   Name of COM port, if not specified via Port, in the form of \\.\COM3.
    ///   This syntax is especially relevant for port numbers bigger than 10.
    /// </summary>
    property PortName: string read FPortName write SetPortName;
    /// <summary>        
    //    Speed (Baud Rate) in form of an enumberation value
    /// </summary>        
    property BaudRate: TBaudRate read FBaudRate write SetBaudRate default br9600;
    /// <summary>        
    ///   Speed (Actual Baud Rate value) if not an enumeration value is used
    /// </summary>        
    property BaudRateValue: DWORD read FBaudRateValue write SetBaudRateValue default 9600;
    /// <summary>    
    ///   Data bits to use (5..8, for the 8250 the use of 5 data bits with 2 stop
    ///   bits is an invalid combination, as is 6, 7, or 8 data bits with 1.5 stop
    ///   bits)
    /// </summary>        
    property DataBits: TDataBits read FDataBits write SetDataBits default db8BITS;
    /// <summary>        
    ///  Stop bits to use (1, 1.5, 2). Be aware that not all ports support 1.5
    /// </summary>
    property StopBits: TStopBits read FStopBits write SetStopBits default sb1BITS;
    /// <summary>        
    ///   Kind of Parity to use (none,odd,even,mark,space)
    /// </summary>
    property Parity: TParity read FParity write SetParity default ptNONE;
    /// <summary>        
    ///   Kind of Hardware Flow Control to use:
    ///   hfNONE          none
    ///   hfNONERTSON     no flow control but keep RTS line on
    ///   hfRTSCTS        Request-To-Send/Clear-To-Send
    /// </summary>
    property HwFlow: THwFlowControl read FHwFlow write SetHwFlowControl default hfNONERTSON;
    /// <summary>        
    ///   Kind of Software Flow Control to use:
    ///   sfNONE          none
    ///   sfXONXOFF       XON/XOFF 
    /// </summary>
    property SwFlow: TSwFlowControl read FSwFlow write SetSwFlowControl default sfNONE;
    /// <summary>        
    ///   Input buffer size in byte (suggested - driver might ignore this setting !)
    /// <summary>        
    property InBufSize: DWORD read FInBufSize write SetInBufSize default 2048;
    /// <summary>        
    ///   Output buffer size in byte (suggested - driver usually ignores this setting !)
    /// </summary>
    property OutBufSize: DWORD read FOutBufSize write SetOutBufSize default 2048;
    /// <summary>        
    ///   RX packet size (this value must be less than InBufSize)
    ///   A value <= 0 means "no packet mode" (i.e. standard mode enabled)
    /// </summary>        
    property PacketSize: smallint read FPacketSize write SetPacketSize default -1;
    /// <summary>        
    ///   Timeout (ms) for a complete packet (in RX)
    /// </summary>        
    property PacketTimeout: integer read FPacketTimeout write SetPacketTimeout default -1;
    /// <summary>        
    ///   What to do with incomplete packets (in RX)
    /// </summary>
    property PacketMode: TPacketMode read FPacketMode write FPacketMode default pmDiscard;
    /// <summary>        
    ///   ms of delay between COM port pollings. Since they are handled by  
    ///   standard Windows timer accurancy is not overly high
    /// </summary>
    property PollingDelay: word read FPollingDelay write SetPollingDelay default 50;
    /// <summary>        
    ///   Set to TRUE to enable DTR line on connect and to leave it on until disconnect.
    ///   Set to FALSE to disable DTR line on connect. 
    /// </summary>
    property EnableDTROnOpen: Boolean read FEnableDTROnOpen write FEnableDTROnOpen default true;
    /// <summary>
    ///   Output timeout (milliseconds)
    /// </summary>
    property OutputTimeout: word read FOutputTimeOut write FOutputTimeout default 500;
    /// <summary>
    ///   Input timeout (milliseconds)
    /// </summary>
    property InputTimeout: DWORD read FInputTimeOut write FInputTimeout default 200;
    /// <summary>
    ///   Set to TRUE to prevent hangs when no device connected or device is OFF
    /// </summary>
    property CheckLineStatus: Boolean read FCkLineStatus write FCkLineStatus default false;
    /// <summary>
    ///   Event to raise when there is data available (input buffer has data)
    ///   (called only if PacketSize <= 0)
    /// </summary>
    property OnReceiveData: TReceiveDataEvent read FOnReceiveData write FOnReceiveData;
    /// <summary>        
    ///   Event to raise when there is data packet available (called only if PacketSize > 0)
    /// </summary>
    property OnReceivePacket: TReceivePacketEvent read FOnReceivePacket write FOnReceivePacket;

    /// <summary>
    ///   Returns the maximum size the receive buffer can be set to in byte
    /// </summary>
    property MaxRXBufferSize: DWord
      read   GetMaxRXBufferSize;
    /// <summary>
    ///   Returns the maximum size the transmit buffer can be set to in byte
    /// </summary>
    property MaxTXBufferSize: DWord
      read   GetMaxTXBufferSize;
    /// <summary>
    ///   Returns the maximum size the receive buffer can be set to in byte
    /// </summary>
    property MinRXBufferSize: DWord
      read   GetMinRXBufferSize;
    /// <summary>
    ///   Returns the maximum size the transmit buffer can be set to in byte
    /// </summary>
    property MinTXBufferSize: DWord
      read   GetMinTXBufferSize;
  end;

implementation

uses
  System.Win.Registry;

const
  /// <summary>
  ///   Baudrates defined in WinAPI
  /// </summary>
  Win32BaudRates: array[br110..br256000] of DWORD =
    (CBR_110, CBR_300, CBR_600, CBR_1200, CBR_2400, CBR_4800, CBR_9600,
      CBR_14400, CBR_19200, CBR_38400, CBR_56000, CBR_57600, CBR_115200,
      CBR_128000, CBR_256000);

const
  dcb_Binary              = $00000001;
  dcb_ParityCheck         = $00000002;
  dcb_OutxCtsFlow         = $00000004;
  dcb_OutxDsrFlow         = $00000008;
  dcb_DtrControlMask      = $00000030;
    dcb_DtrControlDisable   = $00000000;
    dcb_DtrControlEnable    = $00000010;
    dcb_DtrControlHandshake = $00000020;
  dcb_DsrSensivity        = $00000040;
  dcb_TXContinueOnXoff    = $00000080;
  dcb_OutX                = $00000100;
  dcb_InX                 = $00000200;
  dcb_ErrorChar           = $00000400;
  dcb_NullStrip           = $00000800;
  dcb_RtsControlMask      = $00003000;
    dcb_RtsControlDisable   = $00000000;
    dcb_RtsControlEnable    = $00001000;
    dcb_RtsControlHandshake = $00002000;
    dcb_RtsControlToggle    = $00003000;
  dcb_AbortOnError        = $00004000;
  dcb_Reserveds           = $FFFF8000;

  /// <summary>
  ///   Maximum size of the receive buffer in byte
  /// </summary>
  cMaxRXBufferSize = 65535;
  /// <summary>
  ///   Maximum size of the transmit buffer in byte
  /// </summary>
  cMaxTXBufferSize = 65535;
  /// <summary>
  ///   Minimum size of the receive buffer in byte
  /// </summary>
  cMinRXBufferSize = 128;
  /// <summary>
  ///   Minimum size of the transmit buffer in byte
  /// </summary>
  cMinTXBufferSize = 128;

function GetWinPlatform: string;
var
  ov : TOSVERSIONINFO;
begin
  Result := '??';

  ov.dwOSVersionInfoSize := sizeof(ov);
  if GetVersionEx(ov) then
  begin
    case ov.dwPlatformId of
      VER_PLATFORM_WIN32s: // Win32s on Windows 3.1
        Result := 'W32S';
      VER_PLATFORM_WIN32_WINDOWS: // Win32 on Windows 95/98
        Result := 'W95';
      VER_PLATFORM_WIN32_NT: //	Windows NT
        Result := 'WNT';
    end;
  end;
end;

function GetWinVersion: DWORD;
var
  ov : TOSVERSIONINFO;
begin
  ov.dwOSVersionInfoSize := sizeof(ov);
  if GetVersionEx(ov) then
    Result := MAKELONG(ov.dwMinorVersion, ov.dwMajorVersion)
  else
    Result := $00000000;
end;

function TCommPortDriver.BaudRateOf(bRate: TBaudRate): DWORD;
begin
  if bRate = brCustom then
    Result := 0
  else
    Result := Win32BaudRates[bRate];
end;

function TCommPortDriver.DelayForRX(DataSize: DWORD): DWORD;
var
  BitsForByte : Single;
begin
  BitsForByte := 10;

  case FStopBits of
    sb1HALFBITS : BitsForByte := BitsForByte + 1.5;
    sb2BITS     : BitsForByte := BitsForByte + 2;
    else
      ;
  end;

  if FParity <> TParity.ptNONE then
    BitsForByte := BitsForByte + 1;

  case DataBits of
    db5BITS: BitsForByte := BitsForByte - 3;
    db6BITS: BitsForByte := BitsForByte - 2;
    db7BITS: BitsForByte := BitsForByte - 1;
    else
      ;
  end;

  Result := round(DataSize / (FBaudRateValue / BitsForByte) * 1000);
end;

constructor TCommPortDriver.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Not connected
  FHandle                    := INVALID_HANDLE_VALUE;
  // COM 2
  FPort                      := pnCOM2;
  FPortName                  := '\\.\COM2';
  // 9600 bauds
  FBaudRate                  := br9600;
  FBaudRateValue             := BaudRateOf(br9600);
  // 8 data bits
  FDataBits                  := db8BITS;
  // 1 stop bit
  FStopBits                  := sb1BITS;
  // no parity
  FParity                    := ptNONE;
  // No hardware flow control but RTS on
  FHwFlow                    := hfNONERTSON;
  // No software flow control
  FSwFlow                    := sfNONE;
  // Input and output buffer of 2048 bytes
  FInBufSize                 := 2048;
  FOutBufSize                := 2048;
  // Don't pack data
  FPacketSize                := -1;
  // Packet timeout disabled 
  FPacketTimeout             := -1;
  // Discard incomplete packets
  FPacketMode                := pmDiscard;
  // Poll COM port every 50ms
  FPollingDelay              := 50;
  // Output timeout of 500ms
  FOutputTimeout             := 500;
  // Timeout for ReadData(), 200ms
  FInputTimeout              := 200;
  // DTR high on connect
  FEnableDTROnOpen           := true;
  // Time not valid (used by the packing routines)
  FFirstByteOfPacketTime     := DWORD(-1);
  // Don't check of off-line devices
  FCkLineStatus              := false;
  // Init number of RX polling timer pauses - not paused
  FRXPollingPauses := 0;
  // Temporary buffer for received data 
  FTempInBuffer := AllocMem(FInBufSize);
  // Allocate a window handle to catch timer's notification messages
  if not (csDesigning in ComponentState) then
    FNotifyWnd := AllocateHWnd(TimerWndProc);
end;

destructor TCommPortDriver.Destroy;
begin
  // Be sure to release the COM port
  Disconnect;
  // Free the temporary buffer
  FreeMem(FTempInBuffer, FInBufSize);
  // Destroy the timer's window
  if not (csDesigning in ComponentState) then
    DeallocateHWnd(FNotifyWnd);
  // Call inherited destructor
  inherited Destroy;
end;

// The COM port handle made public and writeable.
// This lets you connect to external opened com port.
// Setting ComPortHandle to INVALID_PORT_HANDLE acts as Disconnect.
procedure TCommPortDriver.SetHandle(Value: HFILE);
begin
  // If same COM port then do nothing
  if FHandle = Value then
    exit;
  // If value is RELEASE_NOCLOSE_PORT then stop controlling the COM port
  // without closing in
  if Value = RELEASE_NOCLOSE_PORT then
  begin
    // Stop the timer
    if Connected then
      KillTimer(FNotifyWnd, 1);
    // No more connected 
    FHandle := INVALID_HANDLE_VALUE;
  end
  else
  begin
    // Disconnect
    Disconnect;
    // If Value is INVALID_HANDLE_VALUE then exit now
    if Value = INVALID_HANDLE_VALUE then
      exit;
    // Set COM port handle
    FHandle := Value;
    // Start the timer (used for polling)
    SetTimer(FNotifyWnd, 1, FPollingDelay, nil);
  end;
end;

// Selects the COM port to use
procedure TCommPortDriver.SetPort(Value: TPortNumber);
begin
  // Be sure we are not using any COM port
  if Connected then
    exit;
  // Change COM port
  FPort := Value;
  // Update the port name
  if FPort <> pnCustom then
    FPortName := Format('\\.\COM%d', [ord(FPort)]);
end;

// Sets the port name
procedure TCommPortDriver.SetPortName(Value: string);
begin
  // Be sure we are not using any COM port
  if Connected then
    exit;
  // Change COM port
  FPort := pnCustom;
  // Update the port name
  FPortName := Value;
end;

// Selects the baud rate
procedure TCommPortDriver.SetBaudRate(Value: TBaudRate);
begin
  // Set new COM speed
  FBaudRate := Value;
  if FBaudRate <> brCustom then
    FBaudRateValue := BaudRateOf(FBaudRate);
  // Apply changes
  if Connected then
    ApplyCOMSettings;
end;

// Selects the baud rate (actual baud rate value)
procedure TCommPortDriver.SetBaudRateValue(Value: DWORD);
begin
  // Set new COM speed
  FBaudRate := brCustom;
  FBaudRateValue := Value;
  // Apply changes
  if Connected then
    ApplyCOMSettings;
end;

function TCommPortDriver.SetCommBreak: Boolean;
begin
  result := false;

  if not Connected then
    exit;

  result := Winapi.Windows.SetCommBreak(FHandle);
end;

// Selects the number of data bits
procedure TCommPortDriver.SetDataBits(Value: TDataBits);
begin
  // Set new data bits
  FDataBits := Value;
  // Apply changes
  if Connected then
    ApplyCOMSettings;
end;

// Selects the number of stop bits
procedure TCommPortDriver.SetStopBits(Value: TStopBits);
begin
  // Set new stop bits
  FStopBits := Value;
  // Apply changes 
  if Connected then
    ApplyCOMSettings;
end;

// Selects the kind of parity
procedure TCommPortDriver.SetParity(Value: TParity);
begin
  // Set new parity
  FParity := Value;
  // Apply changes 
  if Connected then
    ApplyCOMSettings;
end;

// Selects the kind of hardware flow control
procedure TCommPortDriver.SetHwFlowControl(Value: THwFlowControl);
begin
  // Set new hardware flow control
  FHwFlow := Value;
  // Apply changes 
  if Connected then
    ApplyCOMSettings;
end;

// Selects the kind of software flow control
procedure TCommPortDriver.SetSwFlowControl(Value: TSwFlowControl);
begin
  // Set new software flow control
  FSwFlow := Value;
  // Apply changes 
  if Connected then
    ApplyCOMSettings;
end;

// Sets the RX buffer size
procedure TCommPortDriver.SetInBufSize(Value: DWORD);
begin
  // Do nothing if connected
  if Connected then
    exit;
  // Free the temporary input buffer
  FreeMem(FTempInBuffer, FInBufSize);
  // Set new input buffer size
  if Value > cMaxRXBufferSize then
    Value := cMaxRXBufferSize
  else if Value < cMinRXBufferSize then
    Value := cMinRXBufferSize;

  FInBufSize := Value;
  // Allocate the temporary input buffer
  FTempInBuffer := AllocMem(FInBufSize);
  // Adjust the RX packet size
  SetPacketSize(FPacketSize);
end;

// Sets the TX buffer size
procedure TCommPortDriver.SetOutBufSize(Value: DWORD);
begin
  // Do nothing if connected
  if Connected then
    exit;
  // Set new output buffer size
  if Value > cMaxTXBufferSize then
    Value := cMaxTXBufferSize
  else
    if Value < cMinTXBufferSize then
      Value := cMinTXBufferSize;

  FOutBufSize := Value;
end;

// Sets the size of incoming packets
procedure TCommPortDriver.SetPacketSize(Value: Smallint);
begin
  // PackeSize <= 0 if data isn't to be 'packetized'
  if Value <= 0 then
    FPacketSize := -1
  // If the PacketSize if greater than then RX buffer size then
  // increase the RX buffer size
  else
    if DWORD(Value) > FInBufSize then
    begin
      FPacketSize := Value;
      SetInBufSize(FPacketSize);
    end;
end;

// Sets the timeout for incoming packets
procedure TCommPortDriver.SetPacketTimeout(Value: Integer);
begin
  // PacketTimeout <= 0 if packet timeout is to be disabled
  if Value < 1 then
    FPacketTimeout := -1
  // PacketTimeout cannot be less than polling delay + some extra ms
  else
    if Value < FPollingDelay then
      FPacketTimeout := FPollingDelay + (FPollingDelay*40) div 100;
end;

// Sets the delay between polling checks
procedure TCommPortDriver.SetPollingDelay(Value: Word);
begin
  // Make it greater than 4 ms
  if Value < 5 then
    Value := 5;
  // If new delay is not equal to previous value...
  if Value <> FPollingDelay then
  begin
    // Stop the timer 
    if Connected then
      KillTimer(FNotifyWnd, 1);
    // Store new delay value
    FPollingDelay := Value;
    // Restart the timer
    if Connected then
      SetTimer(FNotifyWnd, 1, FPollingDelay, nil);
    // Adjust the packet timeout 
    SetPacketTimeout(FPacketTimeout);
  end;
end;

// Apply COM settings 
function TCommPortDriver.ApplyCOMSettings: Boolean;
var dcb: TDCB;
begin
  // Do nothing if not connected
  Result := false;
  if not Connected then
    exit;

  // ** Setup DCB (Device Control Block) fields ******************************

  // Clear all
  fillchar(dcb, sizeof(dcb), 0);
  // DCB structure size
  dcb.DCBLength := sizeof(dcb);
  // Baud rate
  dcb.BaudRate := FBaudRateValue;
  // Set fBinary: Win32 does not support non binary mode transfers
  // (also disable EOF check) 
  dcb.Flags := dcb_Binary;
  // Enables the DTR line when the device is opened and leaves it on 
  if EnableDTROnOpen then
    dcb.Flags := dcb.Flags or dcb_DtrControlEnable;
  // Kind of hw flow control to use
  case FHwFlow of
    // No hw flow control
    hfNONE:;
    // No hw flow control but set RTS high and leave it high
    hfNONERTSON:
      dcb.Flags := dcb.Flags or dcb_RtsControlEnable;
    // RTS/CTS (request-to-send/clear-to-send) flow control
    hfRTSCTS:
      dcb.Flags := dcb.Flags or dcb_OutxCtsFlow or dcb_RtsControlHandshake;
  end;

  // Kind of sw flow control to use
  case FSwFlow of
    // No sw flow control
    sfNONE:;
    // XON/XOFF sw flow control
    sfXONXOFF:
      dcb.Flags := dcb.Flags or dcb_OutX or dcb_InX;
  end;

  // Set XONLim: specifies the minimum number of bytes allowed in the input
  // buffer before the XON character is sent (or CTS is set).
  if (GetWinPlatform = 'WNT') and (GetWinVersion >= $00040000) then
  begin
    // WinNT 4.0 + Service Pack 3 needs XONLim to be less than or
    // equal to 4096 bytes. Win95/98 doesn't have such limit.
    if FInBufSize div 4 > 4096 then
      dcb.XONLim := 4096
    else
      dcb.XONLim := FInBufSize div 4;
  end
  else
    dcb.XONLim := FInBufSize div 4;

  // Specifies the maximum number of bytes allowed in the input buffer before
  // the XOFF character is sent (or CTS is set low). The maximum number of bytes
  // allowed is calculated by subtracting this value from the size, in bytes, of
  // the input buffer.
  dcb.XOFFLim := dcb.XONLim;
  // How many data bits to use
  dcb.ByteSize := 5 + ord(FDataBits);
  // Kind of parity to use
  dcb.Parity := ord(FParity);
  // How many stop bits to use
  dcb.StopBits := ord(FStopbits);
  // XON ASCII AnsiChar - DC1, Ctrl-Q, ASCII 17
  dcb.XONChar := #17;
  // XOFF ASCII AnsiChar - DC3, Ctrl-S, ASCII 19
  dcb.XOFFChar := #19;

  // Apply new settings
  Result := SetCommState(FHandle, dcb);
  if not Result then
    exit;
  // Flush buffers
  Result := FlushBuffers(true, true);
  if not Result then
    exit;
  // Setup buffers size
  Result := SetupComm(FHandle, FInBufSize, FOutBufSize);
end;

function TCommPortDriver.ClearCommBreak: Boolean;
begin
  result := false;

  if not Connected then
    exit;

  result := Winapi.Windows.ClearCommBreak(FHandle);
end;

function TCommPortDriver.Connect: Boolean;
var tms: TCOMMTIMEOUTS;
begin
  // Do nothing if already connected
  Result := Connected;
  if Result then
    exit;
  // Open the COM port
  FHandle := CreateFile(PWideChar(FPortName),
                        GENERIC_READ or GENERIC_WRITE,
                        0, // Not shared
                        nil, // No security attributes
                        OPEN_EXISTING,
                        FILE_ATTRIBUTE_NORMAL,
                        0 // No template
                       );
  Result := Connected;
  if not Result then
    exit;
  // Apply settings
  Result := ApplyCOMSettings;
  if not Result then
  begin
    Disconnect;
    exit;
  end;
  // Set ReadIntervalTimeout: Specifies the maximum time, in milliseconds,
  // allowed to elapse between the arrival of two characters on the
  // communications line.
  // We disable timeouts because we are polling the com port!
  tms.ReadIntervalTimeout := 1;
  // Set ReadTotalTimeoutMultiplier: Specifies the multiplier, in milliseconds,
  // used to calculate the total time-out period for read operations.
  tms.ReadTotalTimeoutMultiplier := 0;
  // Set ReadTotalTimeoutConstant: Specifies the constant, in milliseconds,
  // used to calculate the total time-out period for read operations.
  tms.ReadTotalTimeoutConstant := 1;
  // Set WriteTotalTimeoutMultiplier: Specifies the multiplier, in milliseconds,
  // used to calculate the total time-out period for write operations.
  tms.WriteTotalTimeoutMultiplier := 0;
  // Set WriteTotalTimeoutConstant: Specifies the constant, in milliseconds,
  // used to calculate the total time-out period for write operations.
  tms.WriteTotalTimeoutConstant := 10;
  // Apply timeouts
  SetCommTimeOuts(FHandle, tms);
  // Start the timer (used for polling) 
  SetTimer(FNotifyWnd, 1, FPollingDelay, nil);
end;

procedure TCommPortDriver.Disconnect;
begin
  if Connected then
  begin
    // Stop the timer (used for polling)
    KillTimer(FNotifyWnd, 1);
    // Release the COM port
    CloseHandle(FHandle);
    // No more connected 
    FHandle := INVALID_HANDLE_VALUE;
  end;
end;

// Returns true if connected 
function TCommPortDriver.Connected: Boolean;
begin
  Result := FHandle <> INVALID_HANDLE_VALUE;
end;

// Returns CTS, DSR, RING and RLSD (CD) signals status 
function TCommPortDriver.GetLineStatus: TLineStatusSet;
var dwS: DWORD;
begin
  Result := [];
  // Retrieves modem control-register values.
  // The function fails if the hardware does not support the control-register
  // values.
  if (not Connected) or (not GetCommModemStatus(FHandle, dwS)) then
    exit;
  if (dwS and MS_CTS_ON)  <> 0 then Result := Result + [lsCTS];
  if (dwS and MS_DSR_ON)  <> 0 then Result := Result + [lsDSR];
  if (dwS and MS_RING_ON) <> 0 then Result := Result + [lsRING];
  if (dwS and MS_RLSD_ON) <> 0 then Result := Result + [lsCD];
end;

function TCommPortDriver.GetMaxRXBufferSize: DWord;
begin
  result := cMaxRXBufferSize;
end;

function TCommPortDriver.GetMaxTXBufferSize: DWord;
begin
  result := cMaxTXBufferSize;
end;

function TCommPortDriver.GetMinRXBufferSize: DWord;
begin
  result := cMinRXBufferSize;
end;

function TCommPortDriver.GetMinTXBufferSize: DWord;
begin
  result := cMinTXBufferSize;
end;

// Returns true if polling has not been paused
function TCommPortDriver.IsPolling: Boolean;
begin
  Result := FRXPollingPauses <= 0;
end;

// Pauses polling 
procedure TCommPortDriver.PausePolling;
begin
  // Inc. RX polling pauses counter 
  inc(FRXPollingPauses);
end;

// Re-starts polling (after pause) 
procedure TCommPortDriver.ContinuePolling;
begin
  // Dec. RX polling pauses counter 
  dec(FRXPollingPauses);
end;

// Flush rx/tx buffers 
function TCommPortDriver.FlushBuffers(inBuf, outBuf: Boolean): Boolean;
var dwAction: DWORD;
begin
  // Do nothing if not connected
  Result := false;
  if not Connected then
    exit;
  // Flush the RX data buffer
  dwAction := 0;
  if outBuf then
    dwAction := dwAction or PURGE_TXABORT or PURGE_TXCLEAR;
  // Flush the TX data buffer
  if inBuf then
    dwAction := dwAction or PURGE_RXABORT or PURGE_RXCLEAR;
  Result := PurgeComm(FHandle, dwAction);
  // Used by the RX packet mechanism
  if Result then
    FFirstByteOfPacketTime := DWORD(-1);
end;

// Returns number of received bytes in the RX buffer
function TCommPortDriver.CountRX: integer;
var stat: TCOMSTAT;
    errs: DWORD;
begin
  // Do nothing if port has not been opened 
  Result := 65535;
  if not Connected then
    exit;
  // Get count 
  ClearCommError(FHandle, errs, @stat);
  Result := stat.cbInQue;
end;

// Returns the output buffer free space or 65535 if not connected 
function TCommPortDriver.OutFreeSpace: word;
var stat: TCOMSTAT;
    errs: DWORD;
begin
  if not Connected then
    Result := 65535
  else
  begin
    ClearCommError(FHandle, errs, @stat);
    Result := FOutBufSize - stat.cbOutQue;
  end;
end;

// Sends binary data. Returns number of bytes sent. Timeout overrides
// the value specifiend in the OutputTimeout property
function TCommPortDriver.SendDataEx(DataPtr: PAnsiChar; DataSize, Timeout: DWORD): DWORD;
var
  nToSend, nSent, t1: DWORD;
begin
  // Do nothing if port has not been opened
  Result := 0;
  if not Connected then
    exit;
  // Current time
  t1 := GetTickCount;
  // Loop until all data sent or timeout occurred
  while DataSize > 0 do
  begin
    // Get TX buffer free space
    nToSend := OutFreeSpace;
    // If output buffer has some free space...
    if nToSend > 0 then
    begin
      // Check signals
      if FCkLineStatus and (GetLineStatus = []) then
        exit;
      // Don't send more bytes than we actually have to send
      if nToSend > DataSize then
        nToSend := DataSize;
      // Send
      WriteFile(FHandle, DataPtr^, nToSend, nSent, nil);
      nSent := abs(nSent);
      if nSent > 0 then
      begin
        // Update number of bytes sent
        Result := Result + nSent;
        // Decrease the count of bytes to send 
        DataSize := DataSize - nSent;
        // Inc. data pointer 
        DataPtr := DataPtr + nSent;
        // Get current time 
        t1 := GetTickCount;
        // Continue. This skips the time check below (don't stop
        // trasmitting if the Timeout is set too low)
        continue;
      end;
    end;
    // Buffer is full. If we are waiting too long then exit 
    if DWORD(GetTickCount-t1) > Timeout then
      exit;
  end;
end;

// Send data (breaks the data in small packets if it doesn't fit in the output
// buffer)
function TCommPortDriver.SendData(DataPtr: pointer; DataSize: DWORD): DWORD;
begin
  Result := SendDataEx(DataPtr, DataSize, FOutputTimeout);
end;

// Sends a byte. Returns true if the byte has been sent
function TCommPortDriver.SendByte(Value: byte): Boolean;
begin
  Result := SendData(@Value, 1) = 1;
end;

// Sends a AnsiChar. Returns true if the AnsiChar has been sent
function TCommPortDriver.SendChar(Value: AnsiChar): Boolean;
begin
  Result := SendData(@Value, 1) = 1;
end;

// Sends a pascal AnsiString (NULL terminated if $H+ (default))
function TCommPortDriver.SendString(s: AnsiString): Boolean;
var len: DWORD;
begin
  len := Length(String(s));
  {$IFOPT H+}  // New syle pascal AnsiString (NULL terminated)
  Result := SendData(PAnsiChar(s), len) = len;
  {$ELSE} // Old style pascal AnsiString (s[0] = length)
  Result := SendData(PAnsiChar(@s[1]), len) = len;
  {$ENDIF}
end;

// Sends a C-style AnsiString (NULL terminated)
function TCommPortDriver.SendZString(s: PAnsiChar): Boolean;
var len: DWORD;
begin
  len := length(s); //strlen(s);
  Result := SendData(s, len) = len;
end;

// Reads binary data. Returns number of bytes read 
function TCommPortDriver.ReadData(DataPtr: PAnsiChar; MaxDataSize: DWORD): DWORD;
var nToRead, nRead, t1: DWORD;
begin
  // Do nothing if port has not been opened 
  Result := 0;
  if not Connected then
    exit;
  // Pause polling 
  PausePolling;
  // Current time 
  t1 := GetTickCount;
  // Loop until all requested data read or timeout occurred 
  while MaxDataSize > 0 do
  begin
    // Get data bytes count in RX buffer 
    nToRead := CountRX;
    // If input buffer has some data... 
    if nToRead > 0 then
    begin
      // Don't read more bytes than we actually have to read 
      if nToRead > MaxDataSize then
        nToRead := MaxDataSize;
      // Read 
      ReadFile(FHandle, DataPtr^, nToRead, nRead, nil);
      // Update number of bytes read 
      Result := Result + nRead;
      // Decrease the count of bytes to read 
      MaxDataSize := MaxDataSize - nRead;
      // Inc. data pointer 
      DataPtr := DataPtr + nRead;
      // Get current time 
      t1 := GetTickCount;
      // Continue. This skips the time check below (don't stop
      // reading if the FInputTimeout is set too low)
      continue;
    end;
    // Buffer is empty. If we are waiting too long then exit 
    if (GetTickCount-t1) > FInputTimeout then
      break;
  end;
  // Continue polling 
  ContinuePolling;
end;

// Reads a byte. Returns true if the byte has been read 
function TCommPortDriver.ReadByte(var Value: byte): Boolean;
begin
  Result := ReadData(@Value, 1) = 1;
end;

// Reads a AnsiChar. Returns true if AnsiChar has been read
function TCommPortDriver.ReadChar(var Value: AnsiChar): Boolean;
begin
  Result := ReadData(@Value, 1) = 1;
end;

// Set DTR line high (onOff=TRUE) or low (onOff=FALSE).
// You must not use HW handshaking.
procedure TCommPortDriver.ToggleDTR(onOff: Boolean);
const funcs: array[Boolean] of integer = (CLRDTR,SETDTR);
begin
  if Connected then
    EscapeCommFunction(FHandle, funcs[onOff]);
end;

// Set RTS line high (onOff=TRUE) or low (onOff=FALSE).
// You must not use HW handshaking.
procedure TCommPortDriver.ToggleRTS(onOff: Boolean);
const funcs: array[Boolean] of integer = (CLRRTS,SETRTS);
begin
  if Connected then
    EscapeCommFunction(FHandle, funcs[onOff]);
end;

// COM port polling proc 
procedure TCommPortDriver.TimerWndProc(var msg: TMessage);
var nRead, nToRead, nToReadBuf, dummy: DWORD;
    comStat: TCOMSTAT;
begin
  if (msg.Msg = WM_TIMER) and Connected then
  begin
    // Do nothing if RX polling has been paused 
    if FRXPollingPauses > 0 then
      exit;
    // If PacketSize is > 0 then raise the OnReceiveData event only if the RX
    // buffer has at least PacketSize bytes in it.
    ClearCommError(FHandle, dummy, @comStat);
    if FPacketSize > 0 then
    begin
      // Complete packet received ?
      if DWORD(comStat.cbInQue) >= DWORD(FPacketSize) then
      begin
        repeat
          // Read the packet and pass it to the app
          nRead := 0;
          if ReadFile(FHandle, FTempInBuffer^, FPacketSize, nRead, nil) then
            if (nRead <> 0) and Assigned(FOnReceivePacket) then
              FOnReceivePacket(Self, FTempInBuffer, nRead);
          // Adjust time
          //if comStat.cbInQue >= FPacketSize then
            FFirstByteOfPacketTime := FFirstByteOfPacketTime +
                                      DelayForRX(FPacketSize);
          comStat.cbInQue := comStat.cbInQue - WORD(FPacketSize);
          if comStat.cbInQue = 0 then
            FFirstByteOfPacketTime := DWORD(-1);
        until DWORD(comStat.cbInQue) < DWORD(FPacketSize);
        // Done
        exit;
      end;
      // Handle packet timeouts
      if (FPacketTimeout > 0) and (FFirstByteOfPacketTime <> DWORD(-1)) and
         (GetTickCount - FFirstByteOfPacketTime > DWORD(FPacketTimeout)) then
      begin
        nRead := 0;
        // Read the "incomplete" packet
        if ReadFile(FHandle, FTempInBuffer^, comStat.cbInQue, nRead, nil) then
          // If PacketMode is not pmDiscard then pass the packet to the app
          if (FPacketMode <> pmDiscard) and (nRead <> 0) and Assigned(FOnReceivePacket) then
            FOnReceivePacket(Self, FTempInBuffer, nRead);
        // Restart waiting for a packet 
        FFirstByteOfPacketTime := DWORD(-1);
        // Done 
        exit;
      end;
      // Start time 
      if (comStat.cbInQue > 0) and (FFirstByteOfPacketTime = DWORD(-1)) then
        FFirstByteOfPacketTime := GetTickCount;
      // Done 
      exit;
    end;

    // Standard data handling 
    nRead   := 0;
    nToRead := comStat.cbInQue;

    while (nToRead > 0) do
    begin
      nToReadBuf := nToRead;
      if (nToReadBuf > FInBufSize) then
        nToReadBuf := FInBufSize;

      if ReadFile(FHandle, FTempInBuffer^, nToReadBuf, nRead, nil) then
      begin
        if (nRead <> 0) and Assigned(FOnReceiveData) then
          FOnReceiveData(Self, FTempInBuffer, nRead);
      end
      else
        break;

      dec(nToRead, nRead);
    end;
  end
  // Let Windows handle other messages
  else
    Msg.Result := DefWindowProc(FNotifyWnd, Msg.Msg, Msg.wParam, Msg.lParam) ;
end;

procedure TCommPortDriver.EnumComPorts(ComPorts:TStrings);
var
  I : Integer;
  N : TStringList;
  Reg: TRegistry;
begin
  Assert(Assigned(ComPorts), 'Not created list passed');

  N   := TStringList.Create;
  Reg := Tregistry.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    Reg.Access := KEY_READ;
    If Reg.KeyExists('HARDWARE\DEVICEMAP\SERIALCOMM') Then
      If Reg.OpenKey('HARDWARE\DEVICEMAP\SERIALCOMM', False) Then
      Begin
        Reg.GetValueNames(N);
        for I := 0 to N.count - 1 do
        begin
          if (ComPorts.IndexOf(Reg.ReadString(N[I])) = -1) then
            ComPorts.Add(Reg.ReadString(N[I]));
        end;
      end;
  finally
    Reg.Free;
    N.Free;
  end;
end;

end.
