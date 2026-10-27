# TouchBarBrightness

在 macOS 上控制 MacBook Pro Touch Bar 的背光亮度 —— 通过伪造环境光传感器读数实现。

macOS 没有公开的 Touch Bar 亮度接口，User-space 直接调背光的所有路径都被
entitlement / 内核挡死。本项目逆向出一条可用通道：CoreBrightness 的工程属性
`AABSensorOverride` 可以直接指定「当前环境光 lux」，系统会按这个值驱动 Touch Bar
背光（以及主屏自动亮度、键盘背光）。

## 原理

```
tbright / 菜单栏 App
      │ NSXPC
      ▼
corebrightnessd
      │ AABSensorOverride = N lux
      ▼
ALS → Touch Bar 背光曲线
```

- `AABSensorOverride = 50` → 系统认为环境光 50 lux
- `AABSensorOverride = -1` → 取消覆盖，交还真实传感器
- 有效范围约 **1–5000 lux**，更大的值会被钳到 5000
- 值存在 `corebrightnessd` 的内存里，跨进程/跨 App 退出都有效

## 构建

```sh
./build.sh
```

产物：

- `bin/tbright` — CLI
- `bin/TouchBarBrightness.app` — 菜单栏 App（☀️ 图标，LSUIElement）

## 命令行

```
tbright                 显示状态（当前 lux / 是否注入 / 记住的值）
tbright set <0-100>     按百分比设置（100 = 最亮）
tbright lux <value>     直接指定伪造的环境光 lux
tbright up / down [n]   调亮 / 调暗 n 个百分点（默认 10）
tbright clear | auto    取消注入，交还真实传感器
tbright restore         重新应用记住的值（LaunchAgent 用）
tbright max / min [n]   查看/设置映射范围（默认 5000 / 1）
```

## 菜单栏 App

```sh
open bin/TouchBarBrightness.app
```

- 滑块 0–100%，对数映射到 1–5000 lux（等距手感）
- 预设：最暗 / 暗 / 中 / 亮 / 最亮
- **恢复自动**：交还真实传感器
- 退出 App **不会**清掉设置（设置需要能活过 App 退出）

## 开机 / 重启后保持

```sh
./install-agent.sh            # 安装
./install-agent.sh --uninstall
```

装一个 `~/Library/LaunchAgents/com.dem0ns.TouchBarBrightness.agent.plist`：
登录时 + 每 60 秒执行一次 `tbright restore`，只在「记住过值」时才动作。
`tbright clear` 会一并清掉记住的值，agent 之后就不会再恢复。

## 坑（重要）

1. **绝对不要用 `setProperty:nil` 清空覆盖值。**
   `-[CBColorModuleShared setPropertyInternal:forKey:]` 内部是
   `[_dict setObject:forKey:]`，传 nil 直接抛异常 abort，
   **`corebrightnessd` 会崩溃**（launchd 重启后值丢失，看起来像"清空成功"）。
   正确的取消值是 **`-1`**。
2. 伪造的是**全局环境光**：如果主屏开了自动亮度、键盘有自动背光，它们会一起变。
3. 背光是渐变的，改完大约 1–2 秒才稳定，不是瞬间跳变。
4. 私有 API（`BrightnessSystemClient` / `AABSensorOverride`）：
   - App Store 不可能过审
   - App Extension（Widget / Control Center）强制沙盒，而
     `com.apple.backlightd` 只在少数系统进程的沙盒白名单里 →
     扩展里连不上这个 XPC，做不了

## 走过的死路

详细过程见 [`research/`](research/)，结论：

| 路径 | 结果 |
|---|---|
| `DFRBrightnessClient.dimToStep:`（`DFRBrightness.framework`） | 值能写进 CoreBrightness，但 `_DFRService` 在用户态**和** TouchBarServer 内部都是 NULL，对硬件无影响 |
| `DFRDisplaySetBrightness` | 真正的背光接口，但需要 TouchBarServer 独占的 display interface；用户态 `IsInterfacePresent` 恒为 0 |
| 私有 entitlement 签名（`com.apple.private.touchbar.*`） | AMFI 直接 SIGKILL |
| `DFRSetDimmingStep`（TouchBarServer MIG） | 返回成功，无效果 |
| HID ALS 事件注入（`IOHIDEventSystemClientDispatchEvent`） | 事件不广播给其它客户端，CoreBrightness 收不到 |
| `AppleARMBacklight` `IOServiceOpen` | `kIOReturnUnsupported` |

## 测试环境

MacBook Pro 17,1（M1, 2020, 13"）, macOS 27.2 (26B123)

不确定是否适用于 Intel / T2 机型：那两代 Touch Bar 的背光走 iBridge，
`AABSensorOverride` 是否存在、语义是否相同未验证。

## 免责声明

仅供学习与研究。使用私有 API，随时可能被系统更新破坏，风险自负。
