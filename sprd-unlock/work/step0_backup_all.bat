@echo off
rem ================================================
rem STEP0: BROM connect test + FULL partition backup
rem ZERO RISK: read-only, nothing is written to phone
rem Phone must be in BROM mode (power off, plug USB)
rem ================================================
cd /d "%~dp0"

echo [1/2] Exporting partition table...
spd_dump --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec partition_list partitions.xml reset
if not exist partitions.xml (
    echo.
    echo *** FAILED: no partitions.xml produced ***
    echo If you see "find port failed":
    echo   1. BROM driver not bound - run Zadig, select VID_1782^&PID_4D00, install WinUSB
    echo   2. Or re-enter BROM: power off completely, then plug USB cable
    pause
    exit /b 1
)

echo.
echo [2/2] Backing up ALL partitions to backup\ (slow, do not unplug)...
if not exist backup mkdir backup
spd_dump --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec path "%~dp0backup" r all reset

echo.
echo DONE. Check backup\ folder size.
pause
