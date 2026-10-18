@echo off
rem ============================================================
rem STEP2: Unlock bootloader via CVE-2022-38694 (ums512/T618)
rem Adapted from TomKing unlock_autopatch_512.bat for THIS device:
rem   - VAB device: only uboot_a/uboot_b exist  -> use uboot_b (active slot)
rem   - splloader/splloader_bak NOT in GPT (eMMC boot0/boot1) -> FDL handles them
rem   - Phase A uses local backup (no device dump needed)
rem Run ONLY AFTER step0b backup verified OK!
rem Each phase tells you when to re-enter BROM (unplug, keep power off, plug in)
rem ============================================================
setlocal enabledelayedexpansion
cd /d "%~dp0"

if not exist "backup\splloader.bin" (
    echo *** backup\splloader.bin missing - run step0b_backup_key.bat first ***
    pause
    exit /b 1
)

if not exist "spl-unlock.bin" (
    echo.
    echo [Phase A] Generate unlock-patched SPL from backup (NO PHONE NEEDED)
    copy /y "backup\splloader.bin" "splloader.bin" >nul
    gen_spl-unlock splloader.bin
    if errorlevel 1 (
        echo *** gen_spl-unlock FAILED - DO NOT CONTINUE ***
        pause
        exit /b 1
    )
    if not exist "spl-unlock.bin" (
        echo *** spl-unlock.bin not generated - DO NOT CONTINUE ***
        pause
        exit /b 1
    )
    copy /y "splloader.bin" "u-boot-spl-16k-sign.bin" >nul
    del "splloader.bin" >nul 2>&1
    copy /y "backup\uboot_b.bin" "uboot.bin" >nul
    chsize uboot.bin
    copy /y "uboot.bin" "uboot_bak.bin" >nul
    del "uboot.bin" >nul 2>&1
    echo Phase A done: spl-unlock.bin + uboot_bak.bin ready.
    pause
)

echo.
echo [Phase B] ERASE SPL (boot0/boot1). Phone will NOT boot until Phase F restores it.
echo           BROM rescue is always possible - this is expected.
echo           *** Plug in POWERED-OFF phone when window says Waiting... ***
spd_dump --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec e splloader e splloader_bak reset
echo.
echo (A "part not exist" message for splloader_bak is EXPECTED on this device.)
echo If you see "find port failed", close window, power off phone, run this bat again.
pause

echo.
echo [Phase C] Write cboot-fdl2 into uboot_b (active slot), then reset.
echo           *** Plug in POWERED-OFF phone when window says Waiting... ***
spd_dump --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec w uboot_b fdl2-cboot.bin reset
echo.
echo Waiting 10s for phone to reboot into BROM-wait state...
TIMEOUT /T 10 /NOBREAK >nul

echo.
echo [Phase D] Run unlock SPL - PASS 1 (no re-plug needed: phone is waiting in BROM)
spd_dump --wait 120 exec_addr 0x3ee8 fdl spl-unlock.bin 0x5500
echo.
echo If PASS 1 connected and ran: unlock may need a second pass.
echo ** Unplug, power off, plug in again, then press a key for PASS 2 **
pause >nul
spd_dump --wait 300 exec_addr 0x3ee8 fdl spl-unlock.bin 0x5500
echo.
echo (PASS 2: "part not exist" or connect errors can be OK - unlock token may already be written.)
pause >nul

echo.
echo [Phase E] Verify unlock state in miscdata.
echo           *** Plug in POWERED-OFF phone when window says Waiting... ***
spd_dump --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec verbose 2 read_part miscdata 8192 64 m.bin reset
echo.
echo Read m.bin (64 bytes at offset 8192):
echo   - all 00 = still LOCKED  - rerun Phase D
echo   - 32-char string + 2 hashes = UNLOCKED  - continue to Phase F
python -c "d=open('m.bin','rb').read(); print('m.bin:', d.hex() if len(d)==64 else d); print('UNLOCKED' if any(d) else 'STILL LOCKED (all zeros)')" 2>nul
pause >nul

echo.
echo [Phase F] RESTORE original SPL and uboot_b, wipe misc. (MANDATORY!)
echo           *** Plug in POWERED-OFF phone when window says Waiting... ***
spd_dump --wait 300 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec w splloader u-boot-spl-16k-sign.bin w uboot_b uboot_bak.bin w misc misc-wipe.bin reset
echo.
echo ============================================================
echo DONE. Reboot phone into fastboot (vol-down + power) and check:
echo   fastboot getvar unlocked     (should say: yes)
echo After that: fastboot flashing unlock / set_active a / flash GSI to slot A
echo ============================================================
pause
