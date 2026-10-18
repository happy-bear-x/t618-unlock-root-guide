@echo off
rem ============================================================
rem RESCUE STEP 6: restore metadata + verify + read crash dump
rem Plug in phone (power off, hold Vol-Down 3s while plugging) when Waiting...
rem KEEP THE WINDOW OPEN - do not press reset, we may add commands.
rem ============================================================
cd /d "%~dp0"

echo.
echo [RESCUE-6] w metadata + verify + read sysdumpdb ...
echo ** Plug in phone (Vol-Down 3s trick) when Waiting... **
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec w metadata F://dev-cache//sprd-unlock//work//backup//metadata.bin r metadata r sysdumpdb
echo.
echo DONE-6. KEEP THIS WINDOW OPEN. Tell the agent.
pause
