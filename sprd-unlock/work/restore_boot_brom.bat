@echo off
rem ============================================================
rem RESTORE STOCK boot_b via BROM (rescue if magisk boot fails)
rem 1. Phone must be POWERED OFF
rem 2. Run this FIRST, wait for "Waiting..." on screen
rem 3. THEN plug in the USB cable
rem ============================================================
cd /d "%~dp0"

echo.
echo [RESCUE] Restoring stock boot_b ...
echo *** Plug in POWERED-OFF phone when window says Waiting... ***
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec w boot_b backup\boot_b.bin reset
echo.
echo DONE. Phone should reboot into stock Android (no root).
pause
