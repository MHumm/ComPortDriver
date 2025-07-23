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
unit AboutTTY;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls;

type
  TAboutBoxForm = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Image1: TImage;
    Label2: TLabel;
    Label3: TLabel;
    Panel3: TPanel;
    Label4: TLabel;
    Label5: TLabel;
    Image2: TImage;
    Image3: TImage;
    Label1: TLabel;
    procedure Panel1Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    FIsModal: boolean;
    FReqToClose: boolean;

    procedure CloseMe;
  public
    // Constructor
    constructor Create( AOwner: TComponent; isModal: boolean ); reintroduce; virtual;

    property ReqToClose: boolean read FReqToClose;
  end;

var
  AboutBoxForm: TAboutBoxForm;

implementation

{$R *.DFM}

// Constructor
constructor TAboutBoxForm.Create( AOwner: TComponent; isModal: boolean );
begin
  inherited Create( AOwner );
  FIsModal := isModal;
  FReqToClose := false;
end;

procedure TAboutBoxForm.CloseMe;
begin
  if FIsModal then
    ModalResult := mrOk
  else
    FReqToClose := true;
end;

procedure TAboutBoxForm.Panel1Click(Sender: TObject);
begin
  CloseMe;
end;

procedure TAboutBoxForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  CloseMe;
end;

end.
