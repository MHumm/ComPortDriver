unit CPDReg;

interface

procedure Register;

implementation

uses
  // Delphi units
  Classes,
  // ComDrv units
  CPDrv;

//{$R CPDReg.dcr}

const
  TargetTab = 'System';

procedure Register;
begin
  RegisterComponents( TargetTab, [TCommPortDriver]);
end;

end.
