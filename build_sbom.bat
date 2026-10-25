@echo off
where dxcomply.exe >nul 2>nul

:: errorlevel 0 bedeutet: Gefunden
if %errorlevel% == 0 (
    goto :found
) else (
    goto :missing
)

:found
  dxcomply.exe --library --project=Packages\ComPortDrv.dproj --source-dir=..\Source --version-from-git-tag --repo-url=https://github.com/MHumm/ComPortDriver --licence=Apache-2.0 --supplier="Markus Humm" --supplier-url=https://github.com/MHumm/ComPortDriver --sbom-creator=markus.humm@gmail.com --report=html --output=..\bom.json
  goto :end

:missing
  ECHO dx.comply Delphi IDE plugin from Olaf Monien needed
  
:end
  
  