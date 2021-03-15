program TTY;

uses
  Forms,
  MnForm in 'MnForm.pas' {MainForm},
  SettingsDlg in 'SettingsDlg.pas' {SettingsForm},
  AboutTTY in 'AboutTTY.pas' {AboutBoxForm},
  CPDrv in '..\Source\CPDrv.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'TTY Demo';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
