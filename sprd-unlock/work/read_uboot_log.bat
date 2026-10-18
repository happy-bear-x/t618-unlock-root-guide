@echo off
rem ============================================================
rem   [ 诊断 ] 读出展锐启动日志 uboot_log (4MB) 分析为什么起不来
rem   1. 手机关机 (长按电源 ~10 秒)
rem   2. 先运行本脚本等 Waiting..., 再插 USB 线
rem ============================================================
cd /d "%~dp0"

echo.
echo *** READING: uboot_log -> uboot_log_dump.bin ***
echo *** Plug in POWERED-OFF phone when window says Waiting... ***
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec r uboot_log uboot_log_dump.bin reset
echo.
echo DONE. Tell me and I will analyze uboot_log_dump.bin
pause
