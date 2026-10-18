@echo off
rem *** 刷入 Magisk 修补后的 boot_b (当前活动槽 _b) ***
cd /d F:\dev-cache\sprd-unlock\work
echo *** waiting for fastboot device ***
fastboot devices
echo *** flashing boot_b ***
fastboot flash boot_b magisk_patched_b.img
if errorlevel 1 goto fail
echo *** flash OK, rebooting ***
fastboot reboot
echo *** done ***
pause
exit /b 0
:fail
echo *** FLASH FAILED - do not reboot, check errors ***
pause
exit /b 1
