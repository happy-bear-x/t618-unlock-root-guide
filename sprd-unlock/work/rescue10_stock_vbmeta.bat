@echo off
rem ============================================================
rem RESCUE-10: slot=_a + FACTORY vbmeta_a (undo disable-verity)
rem Tests if slot-a boots with fully stock AVB.
rem Plug in POWERED-OFF phone (hold Vol-Down 3s while plugging).
rem ============================================================
cd /d "%~dp0"
echo.
echo [RESCUE-10] w vbmeta_a factory + reset ...
echo ** Plug in POWERED-OFF phone (Vol-Down 3s trick) ... **
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec w vbmeta_a F://dev-cache//sprd-unlock//work//backup//vbmeta_a.bin reset
echo.
echo DONE-10. Power on manually. Fully stock slot a expected to boot.
pause
