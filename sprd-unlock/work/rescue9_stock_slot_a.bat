@echo off
rem ============================================================
rem RESCUE-9: slot=_a + FACTORY super head (stock system on slot a)
rem Test: does the slot-a boot chain work with STOCK system?
rem Plug in POWERED-OFF phone (hold Vol-Down 3s while plugging).
rem ============================================================
cd /d "%~dp0"
echo.
echo [RESCUE-9] w super factory_head + w misc _a ...
echo ** Plug in POWERED-OFF phone (Vol-Down 3s trick) ... **
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec w super F://dev-cache//sprd-unlock//work//super_head_factory_512k.bin w misc F://dev-cache//sprd-unlock//work//misc_a2.bin reset
echo.
echo DONE-9. Power on manually. Slot a + stock system + fresh data.
pause
