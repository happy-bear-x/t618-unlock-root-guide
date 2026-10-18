@echo off
rem ============================================================
rem FLASH MAGISK boot_b via BROM (bypasses fastboot flashing lock)
rem 1. Phone must be POWERED OFF (long press power in fastboot ~10s)
rem 2. Run this FIRST, wait for "Waiting..." on screen
rem 3. THEN plug in the USB cable (approx 5 second window)
rem ============================================================
cd /d "%~dp0"

echo.
echo [MAGISK-BROM] Writing magisk-patched boot_b ...
echo *** Plug in POWERED-OFF phone when window says Waiting... ***
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec w boot_b magisk_patched_b.img reset
echo.
echo DONE. Phone should reboot into Android with Magisk.
pause
