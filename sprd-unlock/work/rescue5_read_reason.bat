@echo off
rem ============================================================
rem RESCUE STEP 5: read procp (reboot reason) + misc
rem Plug in phone (power off, hold Vol-Down 3s while plugging) when Waiting...
rem KEEP THE WINDOW OPEN after done - more commands may follow.
rem ============================================================
cd /d "%~dp0"

echo.
echo [RESCUE-5] Read procp + misc ...
echo ** Plug in phone (Vol-Down 3s trick) when window says Waiting... **
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec r procp r misc
echo.
echo DONE-READ. Tell the agent. KEEP THIS WINDOW OPEN.
pause
