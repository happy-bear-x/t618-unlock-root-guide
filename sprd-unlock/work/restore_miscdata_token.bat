@echo off
rem ============================================================
rem   [ 恢复解锁 ] 把带 unlock token 的 miscdata 写回分区
rem   写入文件: miscdata.bin (offset 8192 含本机有效 token)
rem   写完后开机应重新出现 "bootloader unlocked" 警告画面
rem   1. 手机关机 (长按电源 ~15 秒)
rem   2. 先运行本脚本等 Waiting..., 再插 USB 线
rem   *** 注意: 以后不要再执行任何 w misc 操作, 它会串位覆盖 miscdata ***
rem ============================================================
cd /d "%~dp0"

echo.
echo *** WRITING: miscdata.bin (restore unlock token) ***
echo *** Plug in POWERED-OFF phone when window says Waiting... ***
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec w miscdata miscdata.bin reset
echo.
echo DONE. Boot phone: you SHOULD see the "bootloader unlocked" warning again.
pause
