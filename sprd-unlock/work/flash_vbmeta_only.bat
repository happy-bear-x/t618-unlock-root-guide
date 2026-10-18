@echo off
rem ============================================================
rem   [ 单独刷免校验 vbmeta_b ]
rem   用于: 已经刷过 magisk boot_b, 但仍在 bootloader 循环时的补救
rem   1. 手机关机
rem   2. 先运行本脚本等 Waiting..., 再插 USB 线
rem ============================================================
cd /d "%~dp0"

echo.
echo *** WRITING: vbmeta_b_flags2.img (verification OFF) ***
echo *** Plug in POWERED-OFF phone when window says Waiting... ***
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec w vbmeta_b vbmeta_b_flags2.img reset
echo.
echo DONE.
pause
