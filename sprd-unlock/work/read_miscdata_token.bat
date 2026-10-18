@echo off
rem ============================================================
rem   [ 诊断 ] 读 miscdata 偏移8192 的 64 字节解锁 token
rem   输出文件固定叫 m.bin (spd_dump 的 read_part 忽略自定义名)
rem   1. 手机关机 (长按电源 ~10 秒)
rem   2. 先运行本脚本等 Waiting..., 再插 USB 线
rem ============================================================
cd /d "%~dp0"

echo.
echo *** READING: miscdata offset 8192 len 64 -> m.bin ***
echo *** Plug in POWERED-OFF phone when window says Waiting... ***
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec verbose 2 read_part miscdata 8192 64 m.bin reset
echo.
echo DONE. Tell me and I will decode m.bin
pause
