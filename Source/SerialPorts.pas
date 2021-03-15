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

// Original author: "Jackson" from German delphipraxis.net
unit SerialPorts;

interface

uses
  Generics.Collections;

type
  TSerialPort = record
    PortNr      : Word;
    Linked      : Boolean;
    PortName,
    Description,
    FriendlyName,
    Decive,
    KeyDevice,
    KeyEnum     : String;
  end;

  /// <summary>
  ///   List of serial ports found
  /// </summary>
  TSerialPortList = TList<TSerialPort>;

  SerialPort_Ar = Array of TSerialPort;

  /// <summary>
  ///   Create a list of all serial ports found in the system
  /// </summary>
  function GetComPorts:TSerialPortList;

implementation

uses
  WinAPI.Windows, System.SysUtils, System.Classes, System.Win.Registry;

const Key_Devices = '\SYSTEM\CurrentControlSet\Control\DeviceClasses\{86e0d1e0-8089-11d0-9ce4-08003e301f73}\';
      Key_Enum   = '\SYSTEM\CurrentControlSet\Enum\';

//procedure SortComPorts(VAR Daten:SerialPort_Ar);
//var Sort_Max,
//    Sort_From,
//    Sort_To,
//    Sort_Size : LongInt;
//    TempData : SerialPort_Rec;
//begin
// if Daten = NIL then
//  Exit;
//
// Sort_Max := High(Daten);
// Sort_Size := Sort_Max shr 1; { div 2 }
// while Sort_Size > 0 do
//  begin
//   for Sort_From := 0 to Sort_Max - Sort_Size do
//    begin
//     Sort_To := Sort_From;
//     while (Sort_To >= 0) AND (Daten[Sort_To].PortNr > Daten[Sort_To + Sort_Size].PortNr) do
//      begin // Tauschen
//       TempData                  := Daten[Sort_To];
//       Daten[Sort_To]            := Daten[Sort_To + Sort_Size];
//       Daten[Sort_To + Sort_Size] := TempData;
//       Dec(Sort_To,Sort_Size);
//      end;
//    end;
//   Sort_Size := Sort_Size shr 1; { div 2 }
// end;
//end;

function GetComPorts:TSerialPortList;
var
  Reg         : TRegistry;
  Keys        : TStrings;
  Count,
  Linked      : Integer;
  Key1,
  Key2,
  Device,
  Description,
  FriendlyName,
  PortName    : string;
  SerialPort  : TSerialPort;
begin
  Result := TSerialPortList.Create;
  Reg   := TRegistry.Create;
  Keys  := TStringList.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly(Key_Devices) then
    begin
      Reg.GetKeyNames(Keys);
      if Keys.Count > 0 then
      begin
        for Count := 0 to Keys.Count-1 do
        begin
          Key1 := Key_Devices+Keys[Count] + '\';
          if Reg.OpenKeyReadOnly(Key1) then
          begin
            Device := Reg.ReadString('DeviceInstance');
            Key2   := Key_Enum + Device + '\';
            if Reg.OpenKeyReadOnly(Key1 + '#\Control\') then
            begin
              Linked := Reg.ReadInteger('Linked');
              if Reg.OpenKeyReadOnly(Key2) then
              begin
                if (Reg.ReadString('Class') = 'Ports') AND Reg.KeyExists('Device Parameters') then
                begin
                  FriendlyName := Reg.ReadString('FriendlyName');
                  Description := Reg.ReadString('DeviceDesc');
                  if Reg.OpenKeyReadOnly(Key2+'\Device Parameters\') AND Reg.ValueExists('PortName') then
                  begin
                    PortName := Reg.ReadString('PortName');
                    if Pos('COM',PortName) = 1 then
                    begin

                      Delete(Description,1,Pos(';',Description));
                      SerialPort.PortNr       := StrToIntDef(Copy(PortName,4),0);
                      SerialPort.Linked       := Linked > 0;
                      SerialPort.PortName     := PortName;
                      SerialPort.Description  := Description;
                      SerialPort.FriendlyName := FriendlyName;
                      SerialPort.Decive       := Device;
                      SerialPort.KeyDevice    := Key1;
                      SerialPort.KeyEnum      := Key2;
                      Result.Add(SerialPort);
                    end;
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  finally
   Keys.Free;
   Reg.CloseKey;
   Reg.Free;
//  SortComPorts(Result);
  end;
end;

end. 