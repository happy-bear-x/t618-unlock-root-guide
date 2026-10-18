@echo off
rem ================================================
rem Backup KEY partitions to backup\ (read-only)
rem Skips userdata/cache (user data not needed).
rem Run FIRST, then plug USB into powered-off phone.
rem ~7GB total, about 5-10 min, DO NOT unplug.
rem ================================================
cd /d "%~dp0"
if not exist backup mkdir backup
echo *** Waiting for BROM... NOW PLUG USB into powered-off phone ***
echo.
spd_dump --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec path "%~dp0backup" ^
 r splloader ^
 r uboot_a r uboot_b ^
 r boot_a r boot_b ^
 r vendor_boot_a r vendor_boot_b ^
 r init_boot_a r init_boot_b ^
 r dtb_a r dtb_b ^
 r dtbo_a r dtbo_b ^
 r vbmeta_a r vbmeta_b ^
 r vbmeta_system_a r vbmeta_system_b ^
 r vbmeta_vendor_a r vbmeta_vendor_b ^
 r vbmeta_system_ext_a r vbmeta_system_ext_b ^
 r vbmeta_product_a r vbmeta_product_b ^
 r vbmeta_odm_a r vbmeta_odm_b ^
 r avbmeta_rs_a r avbmeta_rs_b ^
 r common_rs1_a r common_rs1_b r common_rs2_a r common_rs2_b ^
 r trustos_a r trustos_b r sml_a r sml_b r teecfg_a r teecfg_b r pm_sys_a r pm_sys_b ^
 r hypervsior_a r hypervsior_b ^
 r miscdata r misc r metadata r sysdumpdb ^
 r super ^
 r prodnv r persist r l_fixnv1_a r l_fixnv2_a r l_fixnv1_b r l_fixnv2_b ^
 r l_runtimenv1 r l_runtimenv2 r l_deltanv_a r l_deltanv_b ^
 r l_modem_a r l_modem_b r wcnmodem_a r wcnmodem_b r gnssmodem_a r gnssmodem_b ^
 r l_gdsp_a r l_gdsp_b r l_ldsp_a r l_ldsp_b r l_agdsp_a r l_agdsp_b r l_cdsp_a r l_cdsp_b ^
 reset
echo.
dir /b backup | find /c /v ""
echo files backed up. If it is around 60+, SUCCESS.
pause
