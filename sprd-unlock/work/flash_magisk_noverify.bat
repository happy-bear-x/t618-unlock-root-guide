@echo off
rem ============================================================
rem   [ ROOT 一步到位 ]  boot_b = Magisk 修补镜像 + vbmeta_b = 关闭校验
rem   *** 两个都必须写，只刷 magisk boot 会被 LK 弹回 bootloader 无限重启 ***
rem   1. 手机关机 (长按电源 ~10 秒)
rem   2. 先运行本脚本，等窗口出现 Waiting...
rem   3. 再插 USB 线 (约 5 秒窗口)
rem   看到屏幕上出现两次 "Write Part Done" 才算成功
rem ============================================================
cd /d "%~dp0"

echo.
echo *** WRITING: magisk_patched_b.img  (ROOTED boot) ***
echo *** WRITING: vbmeta_b_flags2.img   (verification OFF) ***
echo *** Plug in POWERED-OFF phone when window says Waiting... ***
echo.
spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec w boot_b magisk_patched_b.img w vbmeta_b vbmeta_b_flags2.img reset
echo.
echo DONE. Phone should reboot WITH ROOT (Magisk).
pause
