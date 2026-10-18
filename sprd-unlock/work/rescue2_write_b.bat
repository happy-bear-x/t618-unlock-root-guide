@echo off
rem ============================================================
rem RESCUE STEP 2: write misc with slot suffix = _b (stock)
rem Plug in POWERED-OFF phone when window says Waiting...
rem Then phone reboots into STOCK slot b automatically.
rem ============================================================
cd /d "%~dp0"

echo.
echo [RESCUE-2] Write misc (active slot back to _b) ...
echo *** Plug in POWERED-OFF phone when window says Waiting... ***
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec w misc misc_b.bin r misc verify_misc.bin reset
echo.
echo DONE. Phone should boot into stock Android now.
pause
