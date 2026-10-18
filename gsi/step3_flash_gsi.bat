@echo off
rem ============================================================
rem STEP3: Flash TrebleDroid GSI (A14 vanilla) to slot A
rem Stock Android 12 stays on slot B as instant fallback.
rem GSI 2.0GB fits system_a (2.38GB) - no space surgery needed.
rem ============================================================

setlocal enabledelayedexpansion
cd /d "%~dp0"

if not exist "td_arm64_ab.img" (
    echo *** td_arm64_ab.img not found next to this script ***
    pause
    exit /b 1
)
if not exist "backup\vbmeta_a.bin" (
    echo *** backup\vbmeta_a.bin not found ***
    pause
    exit /b 1
)

echo.
echo [Phase 1] Reboot to bootloader + flash vbmeta_a (AVB off for slot a)
adb reboot bootloader
echo Waiting for fastboot...
TIMEOUT /T 8 /NOBREAK
fastboot getvar unlocked 2>&1 | findstr /i unlocked
fastboot --disable-verity --disable-verification flash vbmeta_a backup\vbmeta_a.bin
if errorlevel 1 (
    echo *** vbmeta_a flash FAILED ***
    pause
    exit /b 1
)

echo.
echo [Phase 2] Reboot into fastbootd (userspace fastboot)
fastboot reboot fastboot
echo Waiting 15s for fastbootd...
TIMEOUT /T 15 /NOBREAK
fastboot getvar is-userspace 2>&1 | findstr /i userspace
echo.
echo (should say: yes - if nothing, re-plug cable and press a key)
pause

echo.
echo [Phase 3] Delete slot-a product/system_ext (GSI cleanup, stock B untouched)
fastboot delete-logical-partition product_a
fastboot delete-logical-partition system_ext_a

echo.
echo [Phase 4] Flash GSI into system_a (2-5 min, DO NOT unplug)
fastboot flash system_a td_arm64_ab.img
if errorlevel 1 (
    echo *** system_a flash FAILED ***
    pause
    exit /b 1
)

echo.
echo [Phase 5] Switch active slot to A and reboot
fastboot --set-active=a
fastboot reboot
echo.
echo ============================================================
echo DONE. First GSI boot takes 5-15 min - be patient.
echo Bootloops? power+vol-down = fastboot, then:
echo   fastboot --set-active=b     (instant return to stock)
echo ============================================================
pause
