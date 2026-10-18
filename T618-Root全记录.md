# GOFLY 红鲨 6P（T618）Root 全记录

> Magisk 修补 boot + BROM 刷入 | 2026-10-18 凌晨 | 机型 Hongsha 6P（序列号已隐去）
> 前置文档：《T618-BL解锁全记录》（2026-10-17）——BL 已解锁、活动槽 **_b**、BROM 通道已打通、82 分区 7.3GB 全量备份在手

---

## 1. 前置状态

| 项目 | 值 |
| --- | --- |
| BL | 已解锁（BROM 攻击解锁，`ro.boot.vbmeta.device_state=unlocked`） |
| 活动槽 | `_b`（VAB 双槽） |
| 原始诉求 | **A/B 双槽**：b 槽保留完整原厂，a 槽刷自选系统，随时切回 |
| 目标 | 干净系统 + 去广告/去捆绑，同时保住钉钉（企业版）打卡 |
| 时间线 | 10-17 晚 AB/GSI 战役穷尽失败 → 10-18 00:27 先做无 root 冻结 → 01:10 熊哥拍板转 root |

## 2. 为什么最终是 Root——不是选出来的，是 AB 双槽走到最后一步才认输

**先说结论：不是没试双槽，恰恰相反——双槽的每一步工程难点我们都解决了，最后死在展锐 vendor 兼容墙上。Root 是 GSI 战役穷尽后的被迫路线。**

### 2.1 原始诉求就是 AB 双槽

10-17 用户明确提出"搞 A/B 刷机"：活动槽 b 保留完整原厂，a 槽刷自己的系统。**BL 解锁（CVE-2022-38694）就是为这条路铺的**——不解锁连槽都切不动。当时 root 只是 TomKing wiki 里一句"后续可选"，根本没排上。

### 2.2 工程上，双槽手术全部成功（这些都做成了）

- **super LP 元数据手术**：SPRD 把标准 liblp 改成 **3 槽制**（slot0=工厂 a 视图、slot1=b 活动视图含 cow），逆向 geometry/magic `gDlA`/双 SHA256 后，自制 `lp_patch.py` 改 4 处：system_a extent → 尾部空闲 8493616 扇区（GSI 精确整除），vendor_a/product_a/system_ext_a/vendor_dlkm_a 指向 b 槽物理块（**0 空间开销**）。
- **刷入通道破解**：fastbootd 拒写物理 super（No such file）；LK 不认 DONT_CARE sparse；实测 **LK 只收"小于分区的裸 RAW"** → 512KB head 成功刷入。验证闭环：`fastbootd getvar system_a` = GSI 精确大小 ✓，GSI flash 8/8 OKAY（105s）。
- **槽位与救砖机制摸透**：misc @0x800 的 BCAB 块（suffix + magic + CRC32）= 槽位标记；"关机按住音量下 3 秒插线"稳定进 BROM；E1 复活咒语（`e metadata` + misc 切 _b）= 等价 factory reset 的正规重建路径。
- 至此 a 槽"有空间、有系统、可引导、可切回"的基础设施**全部就绪**，b 槽字节未动。

### 2.3 死在兼容墙：三代 GSI 全部 init 早期挂死

| # | GSI | vbmeta / 数据态 | 结果 |
| --- | --- | --- | --- |
| 1 | phh A14 arm64ab vanilla | fastboot 现场改 flags（坏签名） | 黑屏 10min 无 adb（事后确认 GSI 从未被引导） |
| 2 | phh A12L | avbtool+openssl 自签 / `-w` ext4 | init 挂死 |
| 3 | phh A12L | 自签 / `e metadata` 自愈 f2fs | init 挂死 |
| 4 | phh A14 | 自签 / 自愈数据 + b 槽内核克隆 | init 挂死 |
| 5 | **官方 A12** SQ3A.220705.003.A1 | Google 官方签名链 + 官方 vbmeta_system descriptor | LK 拒 Google key（bootloader 循环） |
| 6 | 官方 A12 | flags2 rawpatch | LK 放行 → **12 分钟黑屏无 adb** |

失败模式完全一致：**logo 闪一下 → 黑屏 → adbd 从未出现 = init 早期挂死**。已逐项排除：镜像损坏、LP 元数据、AVB 描述符/尺寸、签名链、数据态配对（3 种）、内核（2 套）。

**终审**：展锐私有 vendor（keymaster/TEE/ICE inlinecrypt/selinux 合并/vendor 私有 init 扩展）与通用 GSI 的 system 层**深层不兼容**——平台限制，非操作问题。除非拿到同机型完整 ported ROM，此路不通。

> 附带发现（LK 魔改校验逻辑）：unlocked 态**容忍坏签名 vbmeta**（hash 校验失败放行），但**拒绝非信任 key 的自洽签名**——所以 flags2 硬改能过第一关、自签 key 过不了第二关。这台 LK 不能按 AOSP 标准行为推断。

**余波**：GSI 失败启动还写脏了 userdata，10-18 00:15 靠 BROM 写 `zero64m.bin` 破坏 f2fs superblock + `e metadata` 才救回（期间 `e userdata` 还暴露了 spd_dump 串位 bug，误擦 persist）。

### 2.4 Root = 保住双槽核心理念的替代形式

双槽的真正价值是"**随时回到完整原厂**"。root 路线保住了这一点，只是回滚形式从"切槽秒回"变成"BROM 写回备份"：

| | AB 双槽 | Root (Magisk) |
| --- | --- | --- |
| 回到完整原厂 | `--set-active=b` 重启即回，0 成本 | `w boot_b backup\boot_b.bin`，~2min（Rawdata 协议实测 40MB/s），必要时补 `e metadata` |
| 原厂系统完整性 | b 槽原样 | 原样 + Magisk systemless（卸载模块即净） |
| userdata | 共用，GSI 首启要清 | 完全不动 |
| 去广告/捆绑能力 | ❌ | ✅ 全套（hosts / 组件 disable / bind mount） |
| 钉钉风控 | 非认证 ROM 设备指纹更可疑 | DenyList + 随机包名（成熟方案） |
| **可行性** | **平台级不可行（已穷尽 3 代 GSI）** | ✅ |

一句话：**双槽是"想走没走成"，root 是"走成了的备胎"——而且这个备胎把完整原厂留在 7.3GB 备份里，回滚成本只多了 2 分钟。**

### 2.5 AB 战役工具存档（§2 相关）

`lp_patch.py`（自制，super 元数据手术/双 SHA256）、avbtool（LineageOS android_external_avb）+ openssl RSA4096（自签 vbmeta）、fastboot/fastbootd、spd_dump（BROM 直刷 super_gsi_full.img，Rawdata 40MB/s）、phh GSI A14/A12L + 官方 A12 GSI 镜像、rescue*.bat 救砖系列。

## 3. 路线总览

```
BROM 备份的 boot_b.bin（无 root 时 dd 读不出，见 §7.3）
  → 推到手机 /sdcard/Download
  → Magisk App「安装→选择并修补一个文件」→ magisk_patched-30700_*.img
  → pull 回 PC
  → spd_dump BROM 写入 boot_b + reset
  → 排查 bootloop（§4.4）→ 恢复 miscdata token（§4.5）
  → Magisk 授权 shell → root 可用
```

## 4. 实际过程（含两次失败与真因）

### 4.1 准备

- Magisk **v30.7**（当时最新，2026-02-23）APK 位于仓库 `gsi/Magisk-v30.7.apk`（11.6MB），`adb install` ✓
- 本机 Ramdisk=是（Android 12 无 init_boot 分区改动），直接补 `boot`，不需要 init_boot
- 修补源用 BROM 全量备份 `work\backup\boot_b.bin`（67MB，md5 763cb029…）——**不能现场 dd 读**（无 root 读出 0 字节）

### 4.2 修补（手机端，全程 adb）

1. `adb push backup/boot_b.img /sdcard/Download/`（重命名为 .img）
2. Magisk App → 安装 → **选择并修补一个文件** → 选中 boot_b.img
3. 产物 `/sdcard/Download/magisk_patched-30700_z2H6u.img`（日志：Stock boot detected → Patching ramdisk → **All done!**；Pre-init storage partition: **metadata**）
4. `adb pull` 回 `sprd-unlock/work/magisk_patched_b.img`

### 4.3 fastboot 通道被拒（重要情报）

```
fastboot flash boot_b magisk_patched_b.img
→ FAILED (remote: 'Flashing Lock Flag is locked. Please unlock it first!')
```

展锐 LK 的 flashing lock **独立于 BL 解锁态**；且 `fastboot flashing unlock` / `fastboot oem *` 在这台 LK 上全部 unknown cmd（被砍）。**结论：本机所有刷写只能走 BROM。**

### 4.4 BROM 写入 → 无限重启 → 排查弯路

- `flash_magisk_brom.bat`（BROM: `w boot_b magisk_patched_b.img` + `reset`）→ 开机**无限重启**。
- 弯路：怀疑 AVB 校验，做 `vbmeta_b_flags2.img`（flags=2 跳校验）走 `flash_magisk_noverify.bat` 补刷 → **依旧重启**。方向错了。
- 正确诊断：BROM `r uboot_log` 读出 4MB 真实启动日志（注意 spd_dump 的 r 忽略自定义名，固定存为 `uboot_log.bin`），实锤两行：
  - `androidboot.vbmeta.device_state=locked`
  - `avb_slot_verify.c:1605 not alllow verification error`
  → **locked 态禁止任何校验错误**，所以改 vbmeta 没用。

### 4.5 真因：miscdata 解锁 token 被冲成 0

- 复核 `read_miscdata_token.bat`：miscdata 偏移 8192 的 64 字节**全 00**。
- 元凶：此前 BROM 操作的**分区串位**——本机 spd_dump 有老毛病（`e userdata` 输出却显示 "Erase Part Done: persist"），`w misc` 实际写到 miscdata，把 token 冲零 → LK 每次启动读到 locked。
- **修复（免重跑六阶段解锁）**：`restore_miscdata_token.bat` → `w miscdata backup\miscdata.bin`（10-17 18:42 的备份，offset 8192 带有效 token）
- 效果一次到位：开机重新出现 "bootloader unlocked" 警告，`getprop ro.boot.vbmeta.device_state=unlocked` ✓ → **已被 AVB 拒的 Magisk boot 立刻能正常启动**

### 4.6 Root 激活

- 刷入后 `su` 仍 Permission denied —— 不是没 root，是 Magisk 首次授权：
  **Magisk App → 超级用户 → `[SharedUID] Shell` → 允许**
- 验证：`uid=0(root) gid=0(root) context=u:r:magisk:s0`，Magisk App 显示版本 30.7

## 5. 实际用到的工具（完整清单）

| 工具 | 来源/路径 | 在 root 过程中的作用 |
| --- | --- | --- |
| **spd_dump.exe**（v1.72） | TomKing062/CVE-2022-38694 release，`ums512_Umidigi_G1_Max.zip` 预编译包，位于仓库 `sprd-unlock/work/` | ★ 唯一刷写通道：写 `boot_b`、读 `uboot_log` 诊断、写回 `miscdata` 救 token |
| **Magisk v30.7**（APK） | 仓库 `gsi/Magisk-v30.7.apk`（GitHub，经 gh-proxy 下载） | ★ 手机端修补 boot 生成 magisk_patched img；root 管理中枢（授权/模块/DenyList） |
| **adb**（platform-tools） | Google 官方 platform-tools（随 Android SDK platform-tools 下载，不入库） | 装 APK、push/pull 镜像、全部 su/shell 操作与验证 |
| **fastboot**（platform-tools） | 同上 | 仅探测用——被 flashing lock 拒，反向证明必须走 BROM |
| **自制 bat 脚本** | 仓库 `sprd-unlock/work/` | `flash_magisk_brom.bat`（写 boot+reset）、`restore_boot_brom.bat`（回滚原厂 boot）、`flash_magisk_noverify.bat`（弯路：vbmeta flags2）、`read_uboot_log.bat`（诊断）、`read_miscdata_token.bat` / `restore_miscdata_token.bat`（救 token） |
| **BROM 备份资产** | `work\backup\`（boot_b.bin、miscdata.bin 等，解锁阶段产出） | ★ 修补源 + 救砖素材，root 阶段直接复用 |
| Git Bash + `MSYS_NO_PATHCONV=1` | 本机环境 | 防止 Git Bash 把 `adb shell` 里的 `/system/...` 路径转换成 Windows 路径搞坏命令 |
| 手机内：`su`/`pm`/`settings`/`mount` | 系统自带 | root 后全部运维（禁组件、改设置、模块挂载）零额外工具 |

> 说明：7-Zip/SPRD 驱动那套是**解锁阶段**的（见解锁文档 §4），root 阶段没有新增驱动或编译需求——全部工具均为现成预编译。AB/GSI 战役的工具清单见 §2.5。

## 6. Root 后固化成果（当晚 02:10–02:43）

| 成果 | 实现方式 | 状态 |
| --- | --- | --- |
| 智慧建议根治 | `pm disable com.pri.launcher3/.prize.smart.widget.SmartCardWidgetProvider` + 清空 `launcher_function_v1_sp.xml` 的 FUNCTION_MANAGER（备份 `/sdcard/fm_backup.xml`）+ hosts 屏蔽厂商/SDK 域名 | ✅ 三重保险 |
| 解锁弹窗广告 | FUNCTION_MANAGER 里的 `launcher_ad_show_type_unlock` 一并清掉 | ✅ |
| adblock 模块 | `/data/adb/modules/adblock/{module.prop, system/etc/hosts}`（穿山甲/快手/百度/趣盟/cooseatech 全域名→127.0.0.1） | ✅ 重启验证 ping 生效 |
| memtweak 模块 | swappiness 150→70。注意：**必须放模块根目录 `service.sh`**，模块内 `service.d/` 子目录 Magisk 不执行 | ✅ |
| 桌宠（哈士奇）移除 | `nopets` 模块：`post-fs-data.sh` 执行 `mount --bind /data/empty_pets /system/media/config/pets`（REPLACE 文件法失效，magic mount 会把 erofs 素材 bind 回来） | ✅ 重启验证 |
| 杂志锁屏 | `settings put system prize_magazine__kgwallpaper_switch 0`（SystemUI 内置功能，无独立包） | ✅ |

## 7. 踩坑记录

1. **spd_dump 分区串位（本机独有老毛病，最高危）**：`w misc` 实际落 miscdata 冲掉 token、`e userdata` 实际误擦 persist。**铁律：这台机上永远禁止 `w misc` 和任何 `e <分区>`**。交互命令必须逐条等输出完整再敲下一条。
2. **BL 解锁 ≠ fastboot 可刷**：展锐 LK 独立 flashing lock，所有刷写走 BROM。
3. **无 root 时 `dd` 读分区为 0 字节**：修补源只能用 BROM 全量备份的 boot_b.bin。
4. **vbmeta flags=2 救不了 device_state=locked**：先读 `uboot_log` 分区确认 device_state 再动手，别猜。
5. **su Permission denied ≠ 没 root**：Magisk 首次要给 `[SharedUID] Shell` 授权。
6. **Git Bash 路径转换**：`adb shell /system_ext/bin/...` 会被 MSYS 转换搞坏，前缀 `export MSYS_NO_PATHCONV=1`。
7. **adb push 不能直接写 `/data/adb`**（shell 无权限）：先推 `/data/local/tmp` 再 `su cp`。

## 8. 红线与待办

- **红线**：BROM 会话中禁跑 `w misc`、`e <分区>`（token 元凶）；改前必确认 `work\backup\` 完好。
- **待办（用户手动）**：装钉钉 → Magisk 开 **DenyList** 勾选钉钉 → 设置里开 **隐藏 Magisk 应用（随机包名）**。
- zram 配置在只读 vendor（erofs），root 也改不动，靠 swappiness=70 缓解已够。

## 9. 文件清单（root 相关；仓库 `sprd-unlock/work/` 与 `gsi/`）

```
sprd-unlock\work\   【入库】
├── flash_magisk_brom.bat      # ★ 刷 Magisk boot 主脚本
├── restore_boot_brom.bat      # ★ 一键回滚原厂 boot
├── restore_miscdata_token.bat # ★ 一键恢复解锁 token
├── read_uboot_log.bat / read_miscdata_token.bat / flash_magisk_noverify.bat
└── vbmeta_b_flags2.img        # 弯路产物（flags=2，未采用，留档）

gsi\   【入库】
├── Magisk-v30.7.apk           # ★ Magisk 安装包
└── vbmeta_flags2_rawpatch.img # LK 校验怪癖（容忍坏签名）的实证样例

--- 以下不入库（.gitignore 排除，原因见注）---
├── magisk_patched_b.img       # 64MB 修补 boot：对其他设备无用，按 §4 自己修补
├── backup\boot_b.bin          # ★ 原厂 boot 回滚源：设备唯一，用 step0b 自行备份
├── backup\miscdata.bin        # ★ 含解锁 token：设备唯一敏感数据，禁止分发
├── uboot_log.bin              # 启动日志：设备私有
└── super_gsi_full.img / super_gsi_official.img   # AB 战役产物 >100MB，GSI 已终审不可行
```

模块（手机内 `/data/adb/modules/`）：`adblock`（hosts 去广告）、`memtweak`（swappiness=70）、`nopets`（桌宠素材 bind 覆盖）。
