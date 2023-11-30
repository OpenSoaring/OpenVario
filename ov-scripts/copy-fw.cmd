@echo off

set VERSION=3.2.20
set HARDWARE=CH57
set machine=ov-ch57

set LW=F:
:: set LW=E:
:: set LW=G:
:: set DIR=%~dp0..\tmp\deploy\images\openvario-57-lvds
:: set DIR=\\wsl.localhost\Debian\home\august2111\OpenVario\OpenVario\tmp\deploy\images\openvario-57-lvds

echo "Copy to '%LW%'!"
set DIR=%~dp0..\tmp\deploy\images\%machine%
set DIR=\\wsl.localhost\Debian\home\august2111\OpenVario\OpenVario\tmp\deploy\images\%machine%


:: read %DIR%\OV-%VERSION%-CB2-%HARDWARE%.img.gz
:: filesize=$(ls -lh %DIR%\OV-%VERSION%-CB2-%HARDWARE%.img.gz | awk '{print  $5}')

call :get_filesize %DIR%\OV-%VERSION%-CB2-%HARDWARE%.img.gz
echo "FileSize = '%filesize%', '%DIR%\OV-%VERSION%-CB2-%HARDWARE%.img.gz'!"
:: pause
if %filesize% GTR 50000000 echo "OV-%VERSION%-CB2-%HARDWARE%.img.gz > 50000000 (%filesize%)"
:: if %filesize% GTR 40000000 echo "%VERSION%-20-CB2-%HARDWARE%.img.gz > 40000000 (%filesize%)"
:: if %filesize% GTR 30000000 echo "%VERSION%-20-CB2-%HARDWARE%.img.gz > 30000000 (%filesize%)"
if %filesize% LEQ 20000000 goto :SmallerThen

:: exit /b 0

:: 
xcopy %DIR%\OV-%VERSION%-CB2-%HARDWARE%.img.gz %LW%\openvario\images\* /Y
:: 
xcopy %DIR%\ov-recovery.itb %LW%\openvario\* /Y
:: 
xcopy %DIR%\ov-recovery.itb %LW%\openvario\images\%HARDWARE%\* /Y
xcopy %DIR%\bootsector.bin.gz %LW%\openvario\images\%HARDWARE%\* /Y
:: xcopy \\wsl.localhost\Debian\home\august2111\OpenVario\OpenVario\meta-openvario\recipes-apps\ovmenu-ng-skripts\files\fw-upgrade.sh %LW%\* /Y
:: xcopy \\wsl.localhost\Debian\home\august2111\OpenVario\OpenVario\meta-openvario\recipes-apps\ovmenu-ng-skripts\files\fw-upgrade.sh %LW%\openvario\* /Y
:: 
xcopy D:\Projects\OpenVario\OpenVario\meta-openvario\recipes-apps\ovmenu-ng-skripts\files\fw-upgrade.sh %LW%\openvario\* /Y
:: xcopy D:\Projects\OpenVario\OpenVario\meta-openvario\recipes-apps\ovmenu-ng-skripts\files\fw-upgrade.py %LW%\openvario\* /Y
:: xcopy \\wsl.localhost\Debian\home\august2111\OpenVario\OpenVario\meta-openvario\recipes-apps\ovmenu-ng-skripts\files\fw-upgrade.py %LW%\openvario\* /Y

pause
exit /b 0


:get_filesize
set filesize=%~z1
goto :eof

: SmallerThen
echo "OV-%VERSION%-CB2-%HARDWARE%.img.gz < 20000000 (%filesize%)"
pause
exit /b %filesize%

