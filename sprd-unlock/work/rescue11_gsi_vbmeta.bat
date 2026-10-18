@echo off
rem ============================================================
rem RESCUE-11: slot=_a + GSI super head + SELF-CONSISTENT vbmeta
rem (avbtool-generated, flags=2, properly signed header)
rem Plug in POWERED-OFF phone (hold Vol-Down 3s while plugging).
rem ============================================================
cd /d "%~dp0"
echo.
echo [RESCUE-11] w super gsi_head + w vbmeta_a custom + w misc _a ...
echo ** Plug in POWERED-OFF phone (Vol-Down 3s trick) ... **
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec w super F://dev-cache//gsi//super_gsi_head_512k.bin w vbmeta_a F://dev-cache//gsi//vbmeta_custom.img w misc F://dev-cache//sprd-unlock//work//misc_a2.bin reset
echo.
echo DONE-11. Power on. A12L GSI first boot: wait 10-15 min.
pause
