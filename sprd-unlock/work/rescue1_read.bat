@echo off
rem ============================================================
rem RESCUE STEP 1: read slot-marker partitions via BROM
rem Plug in POWERED-OFF phone when window says Waiting...
rem ============================================================
cd /d "%~dp0"

echo.
echo [RESCUE-1] Read misc / pm_sys_a / pm_sys_b / miscdata ...
echo *** Plug in POWERED-OFF phone when window says Waiting... ***
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec r misc rescue_misc.bin r pm_sys_a rescue_pm_a.bin r pm_sys_b rescue_pm_b.bin r miscdata rescue_md.bin reset
echo.
echo DONE. Tell the agent the files are ready.
pause
