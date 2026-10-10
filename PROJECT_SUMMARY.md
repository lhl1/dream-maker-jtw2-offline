# 《造梦西游2》离线便携化与全自动真实验收项目全景总结

本项目旨在将经典的 Flash 网页游戏《造梦西游2》改造成**真正独立、离线可运行、数据物理便携、原汁原味还原原版规则**的桌面绿色单机版，并建立**零人工干预的全自动端到端真实验收体系**。

---

## 一、整个项目的演进过程 (Project Evolution)

整个项目由浅入深，经历了 **五个关键里程碑阶段**：

```
[ 阶段 1: 静态逆向与解密 ] ──> 提取 20+ 外部 SWF，逆向 aloader.as 解密流，实现离线自给自足
          │
[ 阶段 2: 运行时故障排查 ] ──> 修复“新的开始”无响应、固化 Config.isHideDebug 消除开发标注、修复大地图锁定
          │
[ 阶段 3: 存档持久化架构变革 ] ──> 彻底抛弃全局 SharedObject，构建纯 Winsock 本地 Socket 便携存档桥接器
          │
[ 阶段 4: 全自动真机闭环验收 ] ──> 告别 Python 模拟器“假阳性”，建立 Windows 前台键鼠真实 16 步物理闭环
          │
[ 阶段 5: 便携包交付与编码自律 ] ──> 组装 Zaomeng2_Standalone，排查参数转义引号与 EOL 时间炸弹，双轨编码规范落盘
```

### 1. 阶段 1：静态逆向、资产完整性审计与解密
- **背景与挑战**：原版游戏由 4399 平台加载器分片分发，关卡、角色、材质、音效分散在 20 多个外部 SWF（`1_v6.swf`, `Common_v7.swf`, `OtherMat_v10.swf`, `Role_v6.swf`, `backpack_v5.swf` 等）中，且关键包体经过了混淆与动态解密流程。
- **攻关举措**：
  - 梳理并补齐了原版分散在网络上的 20 多个依赖 SWF 资源；
  - 逆向分析主加载器 `aloader.as` 的解密流水线，打通 5 大核心资源包的本地秒级自适应解密机制，确保资源脱机自给自足。

### 2. 阶段 2：深层逻辑故障排查与原版规则复原
- **背景与挑战**：历史修改版本遗留了严重逻辑偏离：
  1. 点击“新的开始”无任何反应；
  2. 大地图全解锁，且战斗场景出现“此处出怪”等显眼的开发调试文字；
  3. 存档界面永久卡死在“处理中…”灰色弹窗；
  4. 部分诊断版在某些环境发生闪退。
- **攻关举措**：
  - **清除开发标注**：反编译 AVM2 字节码，将 `config.Config.isHideDebug` 强制固化为 `true`，彻底抹除鬼门关等场景遗留的“此处出怪”等显眼开发文字，恢复原版关卡锁定状态（初始仅开放九幽地狱/鬼门关）；
  - **打通新游戏事件链**：修复 `GameMenu` 按钮点击到 `newGameClick`、`getServerTime`、`showSelectName` 的事件分发链条，彻底解决点击“新的开始”无响应的故障。

### 3. 阶段 3：存档持久化架构变革（从全局 SharedObject 到本地便携桥接）
- **背景与挑战**：Flash 原生 `SharedObject.getLocal()` 强制写向 `%APPDATA%\Macromedia\Flash Player\...`，无法指定相对路径随游戏文件夹拷走；且 Flash SA 播放器的 HTTP 请求强制走 WinINet，在存在系统代理（`127.0.0.1:7897`）时会抛出 12029 错误。
- **攻关举措**：
  - 彻底抛弃 SharedObject 方案，在 ActionScript 3 核心中嵌入基于底层纯 Winsock 的 TCP Socket 客户端（监听本地高位端口 `127.0.0.1:8766`）；
  - 研发专属轻量级本地存档桥接器 `PortableSaveBridge`，物理绑定主 SWF 同级目录 `./save/`，支持 AMF3 原生对象序列化、原子写入（`fsync` + `os.replace`）与自动版本备份。

### 4. 阶段 4：安全红线与“真机全自动验收体系”建立
- **背景与挑战**：早期测试框架存在“用 Python 模拟器断言 Python 逻辑”的假阳性风险，导致自动化报告虽显示 100% PASS 但实际运行依然报错；同时必须严格保护宿主网络代理（Clash Verge 7897）与旧 SOL 存档。
- **攻关举措**：
  - 坚决贯彻“**绝不让用户承担任何手动测试**”的原则；
  - 全面拥抱 Windows 前台真实环境，利用 Win32 API 消息注入与取证，实现从拉起播放器、主菜单、角色创建、第一关战斗 D/K/J/U 动作序列、保存、杀进程、全新冷启动二次读取 `./save` 恢复的 **16 步端到端真实物理闭环**；
  - 设立只读网络安全守护闸门，确保宿主 Clash Verge 7897 端口全程 0 占用、0 篡改，旧 SOL 存档受物理保护零触碰。

### 5. 阶段 5：绿色独立交付包组装与双轨编码自律
- **背景与挑战**：交付便携包时遇到 PowerShell 参数转义导致 Flash Player 路径末尾带双引号 `...zm2_core.swf"` 引发打开失败白屏，以及官方 Flash 32 EOL 时间炸弹、Windows 控制台中文代码页冲突等问题。
- **攻关举措**：
  - 严格执行 Windows 脚本双轨编码铁律：BAT 强制纯 ASCII（0x00~0x7F），严禁 UTF-8 BOM；PowerShell 脚本严格使用 UTF-8 WITH BOM 并通过 `Write-Host` 原生宽字符输出；
  - 攻克参数转义缺陷，改用纯数组参数 `@($SwfPath)` 传递，彻底根除 Flash 打开路径末尾引号；
  - 锁定使用稳定、无时间炸弹的发布版独立播放器环境，输出结构自洽、自包含的便携包 `Zaomeng2_Standalone`。

---

## 二、关键技术路线与架构选型 (Technical Architecture)

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Zaomeng2_Standalone 架构体系                    │
└────────────────────────────────────────────────────────────────────────┘

    [ 用户启动入口 ] ──> Start_Game.bat (纯 ASCII 编码，0x00-0x7F)
                               │
                               ▼
    [ 生命周期管理 ] ──> tools/launcher.ps1 (UTF-8 WITH BOM，PowerShell 5.1)
                               │
              ┌────────────────┴────────────────┐
              ▼                                 ▼
   [ 后台桥接服务进程 ]                [ 独立播放器容器 ]
  portable_save_bridge.py             flashplayer_32_sa.exe
  (Winsock TCP 127.0.0.1:8766)        (加载 zm2_core.swf / _start_.swf)
              │                                 │
              │  Flash Policy & TCP Stream      │ (避开 WinINet / 零代理干扰)
              │◄────────────────────────────────┤
              │                                 │
              │  SaveEvent.SAVE_LIST            │
              │  SaveEvent.SAVE_GET (AMF3)      │
              │  SaveEvent.SAVE_SUCCESS         │
              ▼                                 ▼
   [ 真实物理落盘目录 ]               [ 游戏资源自适应加载 ]
   ./save/slot_0.dat (二进制 AMF3)     1_v6.swf, Common_v7.swf,
   ./save/slot_0.meta.json            OtherMat_v10.swf, Role_v6.swf...
   ./save/system.dat                  (同级目录脱机秒级解密载入)
   ./save/backups/
```

| 技术模块 | 选型方案 | 核心价值与裁决原因 |
| :--- | :--- | :--- |
| **反编译与字节码补丁** | **FFDec 命令行 + AVM2 脚本打补丁** | 精确修补 `GMain.as` 与 `MemoryClass.as`，保留原版所有素材符号与元件图层，不引入非必要重构。 |
| **本地进程间通信 (IPC)** | **纯 Winsock TCP Socket (`127.0.0.1:8766`)** | **彻底绕开 WinINet 协议栈**。Flash 在 Windows 下发起 HTTP 请求强制走 WinINet，在存在系统代理（`127.0.0.1:7897`）时会抛出 12029 失败；纯 Winsock 套接字完全不受系统代理影响，保障零代理干扰。 |
| **对象序列化与落盘** | **原生 AMF3 二进制流 + 原子文件替换** | 利用 ActionScript 原生 `ByteArray.writeObject()` / `readObject()` 保持对象图完整性；服务端通过写入 `.tmp` + `fsync` 刷盘 + `os.replace` 原子替换，兼备版本自动备份。 |
| **全自动真实验收** | **Win32 API + GDI 内存映射 + 真实键鼠注入** | 使用 `PostMessage` 模拟真实用户的键鼠事件流，通过真实的 Windows 句柄和进程树验证，拒绝任何基于 Mock 的自嗨测试。 |
| **脚本执行与交付** | **Windows 双轨编码规范** | BAT 强制纯 ASCII，PS1 强制 UTF-8 WITH BOM，彻底根绝中文乱码与代码页崩溃。 |

---

## 三、四大核心技术难点与攻坚突破 (Key Breakthroughs)

### 1. WinINet 系统代理穿透与 Clash Verge 7897 端口冲突
- **难点**：宿主机运行着 Clash Verge，开启了系统级全局代理（`127.0.0.1:7897`）。Flash SA 播放器的 HTTP 请求强制走 WinINet，导致任何本地 HTTP 通信都会被代理拦截或抛出 `12029 (ERROR_INTERNET_CANNOT_CONNECT)` 错误。
- **攻坚**：果断从 HTTP 切换至纯 Winsock TCP Socket。底层的 `flash.net.Socket` 绕过 WinINet 注册表配置和系统代理栈，不仅彻底解决了通信失败，且恪守了“绝对不触碰、不修改宿主网络代理配置”的最高安全红线。

### 2. ActionScript 3 事件流断裂与“处理中…”卡死弹窗
- **难点**：脱机环境下点击“保存游戏”界面，中央一直显示“处理中…”灰色弹窗且无法移除；
- **攻坚**：
  - 反编译追踪发现，`DealingAlert` 是通过监听 `SaveEvent.SAVE_LIST` 和 `SAVE_GET` 事件后由 `gc.dealAlert.parent.removeChild()` 自动销毁的，脱机后服务端未回包导致事件未派发；
  - 保存时 `storage.MemoryClass.as` 在角色名称获取时存在空指针阻断（`hero1 == null`）。
  - **突破**：在 Socket 桥接中精确模拟事件时序，并在 `MemoryClass.as` 加入防御式回退：当 `hero1 == null` 时自动从 `player1.roleid` 映射出真实角色名（如 `1 -> "孙悟空"`），彻底根治保存中断。

### 3. 测试假阳性与“真物理隔离”的认知重塑
- **难点**：中期曾出现自动化测试报告“100% PASS”，但用户实际双击运行依然故障的严重脱节。根源在于测试脚本仅仅在 Python 内存中“模拟”了保存逻辑，甚至误以为环境变量 `ZM2_PROVEN_PHYSICAL_SANDBOX_DIR` 就等于真实物理隔离。
- **攻坚**：坚决推行**物理闭环铁律**：启动真实的 Flash 播放器、注入真实的屏幕点击、生成磁盘上真实可见的 `slot_0.dat` 二进制文件与 SHA-256 哈希、冷启动全新独立第二进程二次读档比对，不通过物理闭环决不宣称成功。

### 4. 启动器参数转义双引号与 EOL 时间炸弹陷阱
- **难点**：用户运行启动器时出现白屏，展开菜单发现历史第一项末尾多出一个双引号 `...zm2_core.swf"`。
- **攻坚**：
  - 查明根因：PowerShell 5.1 使用 `Start-Process -ArgumentList "`"$SwfPath`""` 时，参数字符串内插双引号导致 Win32 命令行转义异常，末尾被解析出字面量双引号 `"`，导致 Flash Player 打开失败；
  - 查明官方 Flash Player 32 (32.0.0.465) 植入了自 2021 年 1 月 12 日起生效的 EOL 时间炸弹，在 2026 年环境下如果未做处理会触发自毁阻止；
  - **突破**：改用纯规范的参数数组传递（`@($SwfPath)`），并提供纯 ASCII 的原生 CMD 批处理，彻底根除引号转义；锁定使用稳定、无时间炸弹的发布版独立播放器环境，实现秒级拉起、稳定渲染。

---

## 四、工程领悟与经验哲学 (Key Engineering Insights)

1. **软件测试的第一铁律：绝不能用“模拟器”自证“模拟器”**
   - 软件工程中最容易产生的幻觉，就是为一段代码写一个 Mock 测试，Mock 给出了预期结果，便以为现实世界运转良好。
   - 真实的测试必须直接作用于真实目标物理环境，以终端用户肉眼可见的 UI 响应、磁盘上的真实文件、操作系统的真实进程树为唯一的验收标准。

2. **面对底层系统冲突时，“架构降维解耦”远胜于“局部打补丁”**
   - 在解决 Flash 与宿主代理 Clash Verge 的冲突时，如果试图去动态 Hook 播放器、修改系统代理注册表、或者劫持 WinINet，都会面临权限不足、污染用户环境、甚至导致用户断网的巨大风险。
   - 选择**切换到纯 Winsock Socket**，是从网络层面上将整个数据链路与系统的 HTTP 代理栈彻底解耦。这种架构级的优雅旁路，比任何复杂的局部 Hack 都更为可靠、干净。

3. **微小的细节决定了交付的生死线**
   - 一个简单的字符串拼接错误（反斜杠转义多出一个双引号），就能让包含 20 多个逆向模块、上万行代码的庞大工程在最终用户面前退化成一个不可用的“白屏”；
   - 一个文件编码的疏忽（UTF-8 缺少 BOM 或 BAT 文件混入非 ASCII 字符），就会直接导致 Windows PowerShell 5.1 解析崩溃或 CMD 乱码报错。
   - **真正专业级的软件工程交付，必须对每一个字节、每一个换行符（CRLF）、每一层命令行转义保持极致的敬畏与严谨。**

4. **真正的便携与绿色：自包含与零污染**
   - 一个优秀的离线改造项目，不仅要把功能做对，还要给用户提供极简、绿色的体验：
   - **自包含（Self-contained）**：所有依赖、播放器、资源包均置于同一目录树下，无需任何复杂的外部环境；
   - **便携性（Portability）**：存档物理跟随目录，随拔随走；
   - **零污染（Zero-pollution）**：不写入任何外部系统目录，不修改注册表全局配置，运行结束自动优雅收尾，进程 0 残留。

---

## 五、项目最终交付成果物清单

- **便携式独立游戏包**：`D:\3DS_MAX\20261009_zaomeng\Zaomeng2_Standalone\`
  - 核心游戏 SWF（`zm2_core.swf`，SHA-256: `8784ae7f...`）
  - 本地物理便携存档（`Zaomeng2_Standalone\save\slot_0.dat`）
  - 双击一键启动器（`Start_Game.bat`，纯 ASCII 编码）
- **测试目录启动器**：`D:\3DS_MAX\20261009_zaomeng\20261009_zaomeng_test\Start_Game.bat`
  - 使用 `Data\flashplayer_32_sa.exe` 打开同级 `Data\_start_.swf`，纯 ASCII 编码，CRLF 换行，规范稳定。
- **全自动真实验收报告与证据**：
  - `Zaomeng2_Standalone\STANDALONE_VERIFICATION_REPORT.md` (16/16 ALL PASS)
  - `Zaomeng2_Standalone\evidence_screenshots\` (包含 9 张全流程高清取证截图)
