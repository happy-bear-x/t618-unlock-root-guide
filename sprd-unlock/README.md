# GOFLY 红鲨6P (UNISOC T618 / UMS512) BL 解锁方案

## 原理

**CVE-2022-38694**：展锐 BootROM 加载 SPL 时只校验 DHTB 哈希、**不校验 RSA 签名**。
BootROM 独立于 LK/fastboot，本机被阉割的解锁命令、OemLock HAL 弹回全部无效——
BROM 层直接绕过。同芯片（UMS512/T618）机型有大量成功案例：
Retroid Pocket 3+、Umidigi G1 Max、Moto G20、Realme C25y 等。

工具：TomKing062/CVE-2022-38694_unlock_bootloader（Release 1.72，
预编译 exe 直接来自 ums512_Umidigi_G1_Max.zip，T618 同平台通用，无需编译）。

## 为什么之前的路全堵死（已实测）

| 路径 | 结果 |
|---|---|
| fastboot flashing unlock | unknown cmd（LK 剥除）|
| fastboot oem download / getvar | unknown cmd / 输出剥空 |
| OEM 解锁开关 | SPRD OemLock HAL 自动弹回 |
| 9008 深刷 | 高通专用，展锐不适用 |
| **BROM 漏洞（本方案）** | **不经过以上任何一层** |

## 你需要手动做的两件事

### ① Zadig 绑定 BROM 驱动（一次即可，永久生效）

1. 手机**彻底关机**（长按电源键关机，等屏幕全黑）
2. 插 USB 线连电脑（**不需要按任何键**，关机直插即进 BROM）
3. 设备管理器会短暂出现一个未知设备（VID_1782&PID_4D00）
4. 立刻运行 `F:\dev-cache\sprd-unlock\zadig.exe`：
   - 菜单 Options → 勾选 "List All Devices"
   - 下拉框选 `SPRD U2S Diag`（或显示 VID_1782 PID_4D00 的设备）
   - 右侧驱动选 **WinUSB** → 点 **Install Driver** / **Replace Driver**
5. 若操作期间设备消失（BROM 超时重启了手机）：重新关机插线再绑，**绑定一次后永久生效**，以后不用再绑

### ② 跑 step0：全盘备份（零风险，强烈建议先做）

1. 手机再次**关机、插线**（进 BROM）
2. 双击 `work\step0_backup_all.bat`
3. 看到 `partitions.xml` 生成 = 连接成功；之后全自动把所有分区 dump 到 `work\backup\`
4. 有这份备份，后面无论怎么折腾都能救回来（甚至包括误刷错分区）

⚠️ super 分区有几个 GB，全程可能 15~30 分钟，别拔线。

### ③ 备份完成后 → 解锁

双击 `work\step2_unlock.bat`，按脚本提示操作（会要求多次重新进 BROM）。
流程：dump SPL → 补丁（NOP 掉 RSA 校验）→ 借 uboot 分区执行解锁 → 写回原 SPL/uboot → 验证 miscdata token。

解锁成功标志：`fastboot getvar unlocked` 返回 yes，或开发者选项 OEM 解锁不再弹回。

## 风险与兜底

- 擦 SPL 期间手机不会启动，但 **BROM 永远可用**（BootROM 在掩膜 ROM 里，不可擦除）——
  只要 step0 的备份在手，救砖能力是完整的
- 解锁后 AVB 校验放开，届时可以 fastboot flash 任意分区 / 刷 GSI
- A/B 双槽 + super 动态分区都在，可以在**另一个槽（_a）**上刷实验系统，
  刷坏了 `fastboot set_active b` 一键回滚，主系统不受影响
- 解锁会触发数据清空（用户已确认数据不重要）

## 文件清单

- `work\spd_dump.exe` — BROM 通信核心（G1_Max 包预编译）
- `work\fdl1-dl.bin / fdl2-dl.bin` — 未签名 FDL（ums512 平台通用）
- `work\gen_spl-unlock.exe / chsize.exe` — SPL 补丁生成
- `work\fdl2-cboot.bin / spl-unlock.bin（生成后）` — 解锁执行载体
- `work\step0_backup_all.bat` — 阶段1：连接测试 + 全盘备份（只读）
- `work\step2_unlock.bat` — 阶段2：解锁（依赖备份完成）
- `zadig.exe` — BROM 端口 WinUSB 驱动绑定
- `tomking\` — 源码（供审计/参考）
