@echo off
rem ============================================================
rem RESCUE STEP 4: full rollback to known-good state
rem  1) restore factory super metadata head (slot a view)
rem  2) erase metadata / userdata / cache (data will be LOST)
rem Plug in POWERED-OFF phone (hold Vol-Down 3s while off) when Waiting...
rem ============================================================
cd /d "%~dp0"

echo.
echo [RESCUE-4] Restore super head + erase data partitions ...
echo ** DATA ON PHONE WILL BE WIPED (userdata/metadata/cache) **
echo ** Plug in POWERED-OFF phone when window says Waiting... **
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec w super super_head_factory_512k.bin e metadata e userdata e cache reset
echo.
echo DONE. Power on: stock slot b with fresh data.
pause
