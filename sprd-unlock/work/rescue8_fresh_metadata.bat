@echo off
rem ============================================================
rem RESCUE-8: slot=_b + EMPTY metadata (force FBE fresh-install)
rem Plug in POWERED-OFF phone (hold Vol-Down 3s while plugging).
rem ============================================================
cd /d "%~dp0"
echo.
echo [RESCUE-8] w misc factory_b + e metadata ...
echo ** Plug in POWERED-OFF phone (Vol-Down 3s trick) ... **
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec w misc F://dev-cache//sprd-unlock//work//misc_b2.bin e metadata reset
echo.
echo DONE-8. Power on manually. Wait 5 min for first boot.
pause
