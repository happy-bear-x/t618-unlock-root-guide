# GOFLY 红鲨 6P（UNISOC T618 / ums512）BL 解锁 + Root 全记录

两篇实战复盘 + 全套可复用工具（预编译，即取即用）。

## 这是什么

- **机型**：GOFLY 红鲨 6P（Hongsha 6P，展锐虎贲 T618 / ums512，Android 12，Virtual A/B 双槽）
- **解锁**：常规路径全被堵死（OEM 开关弹回、fastboot 命令被阉割），最终基于 **CVE-2022-38694** 展锐 BROM 漏洞（DHTB 只验哈希不验 RSA）解锁
- **Root**：Magisk 修补 boot + BROM 刷入。注意：本机 **BL 解锁后 fastboot flash 仍被拒**（展锐 LK 有独立的 flashing lock flag），所有刷写只能走 BROM
- **重要结论**：通用 GSI（phh A14 / A12L、Google 官方 A12）在本机**一律 init 早期挂死**——展锐私有 vendor（keymaster/TEE/ICE inlinecrypt）兼容墙，AB 双槽 GSI 路线不可行。文档里有完整的 6 次实验矩阵

## 背景：为什么要折腾这台机器

### 1. 原生 ROM 内嵌大量广告，卡到没法用

这台机（白牌方案商 `ro.odm.manufacturer=prize` / `cust=coosea`，build 29109，2026-07-20）出厂就带了一整套商业化组件：

- **原厂桌面 launcher 内置 4 家广告 SDK**（穿山甲/快手/百度/趣盟），云端下发广告位：解锁弹窗广告、智慧建议、文件夹个性化推荐、信息流、弹幕窗口（`ro.odm.barrage_window=1`）
- **20+ 个捆绑推广包**：安全中心（全是广告）、应用中心、游戏中心、红包助手、信息流、好看视频、百度搜索框……
- **AI 桌宠**（`ro.odm.ai_pets=yes`）、**杂志锁屏**（`ro.odm.magazine_lock_wallpaper=1`）、AI 通话摘要（监听名单里连钉钉/腾讯会议/Zoom 都在，`ro.odm.record_ai_packages`）
- 后果：**真实 4GB 内存被常驻捆绑挤到空闲可用约 200MB**，日常使用明显卡顿、杀后台、误触广告（冻结 20+ 包后回到约 486MB，见 Root 记录 §6）

### 2. 更离谱的：硬件参数全面虚标（ROM 层实锤）

厂商把假参数直接做进了 prop，甚至留了自曝字段（`real_*` 是真实值、`modify_*` 是上报值），还藏了一个拨号暗码 `*#8888#` 用来显示真实参数，并用一堆 `show_*=0` 开关把真参数从设置里藏掉：

| 项目 | ROM 显示 / 上报 | 实测真实值 | 证据 prop |
| --- | --- | --- | --- |
| 运行内存 | **10GB**（内核 `/proc/meminfo` 被伪造成 `MemTotal: 10485760 kB`，设置同显） | **4GB** | `ro.odm.real_ram=4` / `modify_ram=10` |
| 存储 | **256GB** | **128GB**（userdata 可用约 101GB） | `ro.odm.real_rom=128` / `modify_rom=256` |
| CPU 型号 | **MTK P60**（联发科） | **展锐虎贲 T618 / ums512** | `ro.odm.cpumodel=MTK P60`，而 `factory_board=SD` |
| 屏幕分辨率 | **2560×1440（2K）** | **720×1600** | `lcm_real_width/height=720/1600` vs `lcm_modify_*=2560/1440` |
| 电池容量 | 10000mAh（设置里被 `show_battery_capacity=0` 藏掉实测值） | 未标定 | `ro.odm.battery_capacity=10000` |

> 注：本机为无摄像头设计，ROM 里的 `back/front_camera_size` 等相机 prop 是方案商模板残留，无参考价值，不列入对比。

> 物理不可能的铁证：开机后 `/proc/meminfo` 自报 `MemAvailable: 5741332 kB`（约 5.6GB"可用"）——**比 4GB 的物理内存还大**。整个内存水位全是按假 10GB 编的，这也从根上解释了为什么这台机"卡且杀后台异常"：内核内存管理建立在不存在的 10GB 上。

**假内存 + 全家桶广告叠加，就是这份记录里解锁 → root → 冻结去广告整套操作的全部动机。**

## 文档导航

| 文档 | 内容 |
| --- | --- |
| [T618-BL解锁全记录.md](T618-BL解锁全记录.md) | 常规解锁为何被堵死 → CVE 原理 → 驱动攻坚（Zadig 失败 → SPRD 官方 WHQL 驱动）→ BROM 时序铁律 → 六阶段解锁脚本 → 9 条踩坑 |
| [T618-Root全记录.md](T618-Root全记录.md) | **为什么最终是 root 而不是 AB 双槽**（GSI 穷尽失败时间线）→ Magisk 修补流程 → bootloop 排查（miscdata token 被冲零）→ 工具清单 → 去广告/去桌宠固化成果 |
| [T618-禁用应用清单.md](T618-禁用应用清单.md) | 本机已禁用 **29 个** OEM 捆绑 / 广告 / 不必要系统包清单（含包名、类别、原因、禁用手段），附恢复方法与权衡（FotaApp→无 OTA、百度辅助定位→室内定位退化等） |
| [T618-内存假标诊断.md](T618-内存假标诊断.md) | 假 10GB 内存诊断：`/proc/iomem` 物理真实 4GB 铁证、伪造元凶 emem 内核组件、回收策略实际按真实 4GB、顺带修复 swappiness 被厂商覆盖回 150 的 bug（已改 70），并给出"是否动内核根治"的取舍 |

## 目录结构

```
.
├── README.md
├── T618-BL解锁全记录.md
├── T618-Root全记录.md
├── T618-禁用应用清单.md    # 已禁用的 29 个 OEM/广告/系统包清单（包名+原因+手段）
├── T618-内存假标诊断.md    # 假 10GB 内存诊断：物理 4GB 铁证 + emem 元凶 + swappiness 修复
├── sprd-unlock/           # 解锁 + 刷写全套（预编译）
│   ├── work/              # spd_dump.exe、fdl、解锁六阶段 bat、刷 boot bat、LP 头补丁
│   ├── driver/            # SPRD 官方 WHQL 驱动（sprdvcom.inf，覆盖 VID_1782&PID_4D00）
│   ├── sprd_driver.7z     # 驱动原始包（解压密码 1111）
│   ├── 7zr.exe            # 解压上面 7z 用（官方独立版）
│   ├── zadig.exe          # （弃用留档：WinUSB 自签证书被拒）
│   ├── ums512_g1max.zip   # TomKing release 1.72 的 ums512 工具包（工具原始来源）
│   └── tomking/           # （不入库）TomKing062 项目源码，见下方致谢链接
└── gsi/                   # Magisk APK + vbmeta 样例 + avbtool/lp_patch 工具脚本
```

## 未入库的大文件 / 敏感文件（见 `.gitignore`）

| 文件 | 原因 | 替代获取 |
| --- | --- | --- |
| `sprd-unlock/work/backup/` | 7.3GB **设备唯一**全量分区备份，含 NV/射频校准，禁止分发 | 对**自己的**设备跑 `work/step0b_backup_key.bat` |
| `sprd-unlock/work/miscdata.bin` | 含本机解锁 token，设备唯一敏感数据 | 解锁流程会在你手机上自动生成 |
| `sprd-unlock/work/magisk_patched_b.img` | 本机修补的 boot，对其他设备无意义 | 按文档 §4 用 Magisk 修补**自己的** boot |
| `gsi/` 下 GSI 镜像 | 单文件 >100MB（GitHub 硬限），且实测不可用 | phh: `TrebleDroid/treble_experimentations` releases；官方 GSI: Android 开发者网站 |
| `sprd-unlock/tomking/` | 内嵌 git 仓库无法随仓库分发 | [TomKing062/CVE-2022-38694_unlock_bootloader](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader) |
| `gsi/avb_test.pem` | AB 战役 vbmeta 自签用的一次性测试私钥（私钥不入库，哪怕只是 test key） | 按 Root 记录 §2.5 用 avbtool + openssl 自己生成 |

## 致谢 / 来源

- [TomKing062/CVE-2022-38694_unlock_bootloader](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader) —— spd_dump 与解锁方法论
- [topjohnwu/Magisk](https://github.com/topjohnwu/Magisk) —— root 方案
- LineageOS `android_external_avb`（avbtool）—— AB 战役中的 vbmeta 自签
- phh / TrebleDroid GSI、Google 官方 GSI
- gh-proxy.com —— GitHub 下载镜像（本记录全程依赖）

## ⚠️ 免责声明

1. BROM 底层刷写有**变砖风险**。本记录是单台设备的实战过程，同型号不同批次也请先跑 step0b 做全量备份再动手。
2. 解锁 bootloader 失去保修；root 会触发部分金融/企业应用（如钉钉企业版）风控——文中用 Magisk DenyList + 随机包名缓解，**并非 100% 可靠**，工作机请自行权衡。
3. 工具版权归原作者所有，仓库仅存档预编译产物以便复现；请仅用于**自有设备**的学习研究。
4. `e metadata` / miscdata 等操作会清除数据，操作前务必备份手机数据。
