@echo off
rem ============================================================
rem RESCUE-12: FULL CLONE slot b static parts into slot a
rem boot_a/dtbo_a/vendor_boot_a/vbmeta_*_a all from _b copies.
rem Plus factory super head (slot-a extents share slot-b blocks).
rem If this boots, slot-a chain is fine and GSI issue is elsewhere.
rem Plug in POWERED-OFF phone (hold Vol-Down 3s while plugging).
rem ============================================================
cd /d "%~dp0"
set B=F://dev-cache//sprd-unlock//work//backup
echo.
echo [RESCUE-12] clone b to a + factory super head ...
echo ** Plug in POWERED-OFF phone (Vol-Down 3s trick) ... **
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec w boot_a %B%oot_b.bin w dtbo_a %B%\dtbo_b.bin w vendor_boot_a %B%endor_boot_b.bin w init_boot_a %B%\init_boot_b.bin w dtb_a %B%\dtb_b.bin w vbmeta_a %B%bmeta_b.bin w vbmeta_system_a %B%bmeta_system_b.bin w vbmeta_vendor_a %B%bmeta_vendor_b.bin w vbmeta_product_a %B%bmeta_product_b.bin w vbmeta_system_ext_a %B%bmeta_system_ext_b.bin w super F://dev-cache//sprd-unlock//work//super_head_factory_512k.bin reset
echo.
echo DONE-12. Power on. Slot a is now a full clone of slot b.
pause
