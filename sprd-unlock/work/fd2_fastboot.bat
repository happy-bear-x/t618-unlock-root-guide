@echo off
rem One-shot: reboot phone into fastboot via BROM.
cd /d "%~dp0"
echo ** Plug in POWERED-OFF phone (Vol-Down 3s trick) ... **
spd_dump.exe --wait 600 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec reboot-fastboot
echo Phone is rebooting into fastboot. You can close this window.
pause
