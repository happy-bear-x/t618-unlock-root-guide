@echo off
rem ============================================================
rem FDL2 interactive shell (BROM).
rem Plug in POWERED-OFF phone (hold Vol-Down 3s while plugging).
rem At FDL2 prompt useful commands:
rem   reboot-fastboot    - reboot into fastboot/bootloader
rem   reboot-recovery    - reboot into recovery
rem   r PARTITION        - read partition to file (saved as PARTITION.bin)
rem   w PARTITION FILE   - write file to partition
rem   e PARTITION        - erase partition
rem   partition_list out.xml - dump partition table
rem   reset              - reboot phone
rem   poweroff
rem ============================================================
cd /d "%~dp0"
echo ** Plug in POWERED-OFF phone (Vol-Down 3s trick) ... **
spd_dump.exe --wait 600 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec
pause
