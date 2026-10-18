@echo off
rem ================================================
rem BROM connect test (read-only, no write to phone)
rem 1. Run this FIRST (window stays open, waiting)
rem 2. THEN plug USB into powered-off phone
rem ================================================
cd /d "%~dp0"
echo.
echo  *** Waiting for BROM (up to 300s)... NOW PLUG USB into the powered-off phone ***
echo  *** If phone boots to charging logo, unplug, power off, and plug again ***
echo.
spd_dump --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec partition_list partitions.xml reset
if exist partitions.xml (
    echo.
    echo ================================================
    echo   SUCCESS! partitions.xml created - BROM works!
    echo   Next: run step0_backup_all.bat
    echo ================================================
) else (
    echo.
    echo   FAILED - no partitions.xml. Retry: keep this window open and re-plug USB.
)
pause
