@echo off
rem ============================================================
rem RESCUE STEP 3: set BCB bootonce-bootloader (force fastboot menu)
rem Plug in POWERED-OFF phone when window says Waiting...
rem Then phone reboots into STOCK slot b automatically.
rem ============================================================
cd /d "%~dp0"

echo.
echo [RESCUE-3] Write BCB bootonce-bootloader ...
echo *** Plug in POWERED-OFF phone when window says Waiting... ***
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec w misc misc_bootonce.bin r misc miscy.bin reset
echo.
echo DONE. Power on: phone will STAY in fastboot menu.
pause
