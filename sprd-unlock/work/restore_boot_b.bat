@echo off
rem *** 一键还原原厂 boot_b (救砖用) ***
cd /d F:\dev-cache\sprd-unlock\work
echo *** waiting for fastboot device ***
fastboot devices
echo *** restoring stock boot_b ***
fastboot flash boot_b backup\boot_b.bin
if errorlevel 1 goto fail
echo *** restore OK, rebooting ***
fastboot reboot
echo *** done ***
pause
exit /b 0
:fail
echo *** RESTORE FAILED - check errors ***
pause
exit /b 1
