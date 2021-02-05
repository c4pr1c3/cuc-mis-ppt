---
title: "移动互联网安全"
author: 黄玮
output: revealjs::revealjs_presentation
---

# 第六章 Android 系统访问控制策略与机制

---

## 温故

* 「开放」的 Android 生态
* 智能终端操作系统的安全问题与形势特点

---

## 知新

* 掌握 Android 平台安全设计思想
* 了解 Android 平台实现关键技术
* 掌握 Android 应用开发基本概念
* 了解 Hello World 程序编写

# Android 平台

---

## 平台包含的主要组件

* 设备硬件：智能手机、平板电脑、手表、汽车、智能电视、OTT 游戏盒和机顶盒等，不包含处理器
* Android 操作系统：来自 `AOSP` 和设备 `OEM` 厂商的定制修改
* Android 应用运行时
    * 预先安装的应用：来自 `AOSP`、`GMS` 和设备 `OEM` 厂商
    * 用户安装的应用

---

## Android 开发团队的「持续」安全改进措施 {id="continuous-devopssec-by-android"}

* 设计审核
* 渗透测试和代码审核
* 开放源代码和社区审核
* 事件响应
* [每月安全更新](https://source.android.com/security/bulletin/)
    * 2015 年 8 月开始
* [Android 各个版本的安全改进汇总](https://source.android.com/security/enhancements/?hl=en)

# Android 平台安全威胁概述 {id="android-platform-threats"}

---

[本章 Android 平台安全相关内容主要基于 Android 官方安全和隐私小组 2020 年 12 月更新的公开论文](https://arxiv.org/abs/1904.05572)

---

## 移动终端区别于 PC 平台的威胁来源 {id="different-threats-to-pc"}

* 物理设备遗失或被盗风险
* 连入不可信网络
* 更多隐私威胁
    * 随身携带的移动终端存储和处理更多用户个人隐私信息（例如位置信息、通讯录、通话和聊天记录历史等）

---

## 物理安全威胁内涵

* 丰富多样化的硬件设备形态：手机、可穿戴设备、物联网终端、汽车、电视等等
* 本课程所指的「物理接触风险」主要包括两种物理接触形式，并统一用 `P` 来指代物理安全相关风险
    * 直接接触： `physical` access ，可以直接通过肢体接触到目标设备
    * 靠近接触： `proximal` access ，距离上在设备开启的 `WPAN` 或 `WLAN` 有效信号覆盖范围内可以访问到目标设备。
        * 通过蜂窝网络 `伪基站` 技术访问到目标设备也属于此类接触类型

---

### 物理安全威胁分类定义 T.P1

* 屏幕处于锁定或解锁状态的设备，无法被 **直接接触**
    * 例如通过蓝牙方式攻击设备
        * [BlueBorne - 2017](https://www.armis.com/blueborne/)
        * [BadBluetooth - 2019 on NDSS](https://www.ndss-symposium.org/ndss-paper/badbluetooth-breaking-android-security-mechanisms-via-malicious-bluetooth-peripherals/)
        * [BlueFrag - CVE-2020-0022](https://insinuator.net/2020/02/critical-bluetooth-vulnerability-in-android-cve-2020-0022/)
        * [BlueRepli - on Blackhat USA 2020](https://i.blackhat.com/USA-20/Wednesday/us-20-Xu-Stealthily-Access-Your-Android-Phones-Bypass-The-Bluetooth-Authentication.pdf)
    * `NFC` 通信虽然传输距离通常很短，但也被归属于此类威胁类型

---

### 物理安全威胁分类定义 T.P2

* 已关机设备，被 **直接接触**
    * 通常需要非常高的攻击技术才能实现漏洞利用的场景
    * 例如：海关或边境安全检查

---

### 物理安全威胁分类定义 T.P3

* 已锁屏设备，被 **直接接触**
    * 例如被盗设备

---

### 物理安全威胁分类定义 T.P4

* 已屏幕解锁设备，被分享给非机主使用
    * 滥用风险

---

### 网络（接入）安全威胁分类 T.N1

* 被动监听和流量分析
    * 本课程第三章主要内容，例如 `Wi-Fi 嗅探`

---

### 网络（接入）安全威胁分类 T.N2

* 主动网络流量控制
    * 本课程第三章主要内容，例如 `Wi-Fi 中间人攻击`
    * 《网络安全》课程 `第四章 网络监听` 提到的 SSL/TLS 中间人劫持攻击
* 和 `T.P1` 的主要区别
    * `T.P1` 依赖于 **距离目标设备较近** ，`T.N2` 可以在目标设备 **通信链路中任意一个环节** 下手
    * `T.P1` 只影响 **目标设备** ，`T.N2` 可以影响通信链路上 **所有设备**

---

## 不可信代码执行

* 不同于 `iOS` 平台对 `App` 的管控机制：集中验证和封闭分发
    * 只要 **用户允许**，用户可以从任意应用分发渠道下载并安装应用（ **A**pplication ）
    * 不同应用分发渠道的应用审核标准和机制 **不统一** ：各自为政、良莠不齐

---

### 不可信代码执行威胁分类 T.A1

* 滥用 **操作系统提供** 的 API 来完成恶意用途
    * 例如：间谍软件

---

### 不可信代码执行威胁分类 T.A2

* 滥用设备上 **其他已安装应用提供** 的 API 来完成恶意用途

---

### 不可信代码执行威胁分类 T.A3

* Web 前端脚本代码执行未经用户明确授权
    * 例如 `JavaScript`

---

### 不可信代码执行威胁分类 T.A4

* 仿冒系统或第三方应用「用户界面」或「交互设计」进行钓鱼
    * 典型如套取用户的口令

---

### 不可信代码执行威胁分类 T.A5

* 通过「用户界面」读取系统或第三方应用中的（敏感）内容
    * 例如「截图应用」

---

### 不可信代码执行威胁分类 T.A6

* 模拟用户交互输入（点击、滑屏、输入等操作）控制系统软件或第三方应用程序的用户界面

---

### 不可信代码执行威胁分类 T.A7

* 系统漏洞利用程序
    * 例如利用操作系统内核、驱动或系统服务漏洞实现「提权」

---

### 不可信内容处理威胁分类 T.D1

* 滥用「唯一标识」用于定向攻击
    * 即使是在受信任网络内，依然可以通过关联手机号、电子邮件地址和位置信息等实现精准垃圾广告推送

---

### 不可信内容处理威胁分类 T.D2

* [操作系统或第三方应用在处理不可信内容时触发漏洞执行代码](https://www.kb.cert.org/vuls/id/924951)
    * 典型的漏洞利用方式是将 `攻击载荷` 嵌入在多媒体文件中，当存在漏洞的播放器打开该恶意多媒体文件时触发漏洞。此类威胁可能导致本地或远程代码执行漏洞
        * [2015 年报告的针对 Android 2.2 系统多媒体组件 StageFright 的漏洞利用](https://resources.infosecinstitute.com/topic/hack-android-devices-using-stagefright-vulnerability/)
        * [CVE-2019–2107 Android 7–9 的多媒体处理框架漏洞利用](https://medium.com/@marcinguy/android-7-9-media-framework-vulnerability-allows-mobile-hacking-6f023881c045)
        * [2019 年 2 月 Android 月度更新修复的 PNG 处理框架漏洞影响 Android 7-9](https://source.android.com/security/bulletin/2019-02-01.html)

# Android 平台安全模型设计 {id="android-platform-security-model-design"}

---

## 安全模型设计指导思想

> **平衡** 用户与应用、平台之间的安全和隐私需求

---

## 安全模型设计基本原则

1. 多方许可
2. 开放生态访问
3. 安全是一个兼容性需求
4. 出厂设置能保证恢复设备到安全状态
5. 应用程序安全为主

---

### 1. 多方许可 {id="multi-party-consent-1"}

* 多方：（终端）用户、（操作系统和硬件驱动）平台、（应用）开发者
    * 不同于传统 PC 平台访问控制的经典「主客体」模型
        * 以自由访问控制模型为例，`谁创建、谁有权限使用`
* 移动终端上的「多方参与」访问控制模型，以数据生命周期为例
    * 共享存储中的数据由用户管理访问（控制授权）
    * 应用私有目录和应用虚拟地址空间中的数据由应用管理访问（控制授权）
    * 在特殊系统目录中的数据由平台管理访问（控制授权）
        * 例如列举应用被授予的权限列表
* 多方许可意味着「任何数据访问行为均需要所有参与方许可授权」才可执行

---

### 1. 多方许可 {id="multi-party-consent-2"}

* 移动终端的「数据所有者」更偏重是一个 **法律** 概念
* 多方许可模型不是一个完备模型，存在多种应用场景违反多方许可原则
    * 数据备份场景中应用私有数据未经应用开发者许可即可被备份
    * VPN 应用可以监视和控制系统全局流量无需应用开发者许可
    * 企业管控场景可以通过定义 `Device Owner (DO)` 或者 `Profile Owner (PO)` 来限制用户在设备上安装和使用软件

---

### 2. 开放生态访问

* 用户和应用开发者可以自由使用不同渠道的应用商店下载安装应用和上传分发应用
* 不限制唯一的应用审核渠道
* 允许应用间的协同和互操作
* 开发者可以自由定义开放给其他应用的 API

---

### 3. 安全是一个兼容性需求

* Android 安全模型本身也是 Android 规范的组成内容
    * 定义包含在 [Compatibility Definition Document (CDD)](https://source.android.com/compatibility/cdd)
        * 例如 [Android 10 兼容性定义的第 9 章就是安全模型兼容性](https://source.android.com/compatibility/10/android-10-cdd#9_security_model_compatibility)
    * 由 Compatibility (CTS, Compatibility Test Suite), Vendor (VTS, Vendor Test Suite) 和其他测试规范来检验和确保兼容
* 不遵循 CDD 且未通过 CTS 的设备不能被称为 Android 
    * `root` 设备由于破坏了原有的沙盒隔离机制，因此不被认证为 Android
    * `booloader` 解锁设备和刷入自定义固件的设备也不被认证为 Android

---

### 4. 出厂设置能保证恢复设备到安全状态

* 为了应对系统被攻陷、篡改的风险，依赖于被保护分区的完整性保护机制，出厂设置就是清除或重新格式化可写数据分区
* 系统软件无需重新安装
* `验证启动` 机制将决定恢复出厂设置会还原设备到哪个“备份”状态

---

### 5. 应用程序安全为主

* 和传统 PC 平台应用是运行在「已登录用户」上下文环境
    * 勒索软件并不需要管理员权限即可感染当前登录用户有权限访问的所有应用和应用数据
* 移动终端应用默认没有获得完全用户授权
    * 沙盒化应用程序的进程间隔离、数据存储隔离等

# Android 平台安全模型实现 {id="android-platform-security-model-implementation"}

---

## 架构设计基本原则

1. 纵深防御 `defense in depth`
2. 设计安全 `safe by design`

---

## 纵深防御四大安全策略

1. 隔离和抑制 `isolation and containment`
2. 漏洞利用缓解 `exploit mitigation` 
3. 完整性（保护） `integrity` 
4. 补丁/更新 `patching/updates`

---

## 设计安全三大安全策略

1. 强制许可制 `enforced consent`
2. 用户认证 `user authentication` 
3. 缺省存储和传输加密 `by-default encryption at rest and in transit`

# SD.1 强制许可制

---

## 确保「易于理解」的许可

* 许可的表达方式应易于「三方」无歧义正确理解
* 两个例子
    * 在不同应用间共享数据
    * 变更移动网络运营商配置

# SD.2 用户认证

---

## 基本需求

* 对于移动终端来说，主要实现方式是系统内置的「锁屏」程序

# SD.3 数据加密

---

* 持久化存储数据加密
* 通信数据加密

# DiD.1 隔离和抑制

---

## 访问控制

* 自由访问控制 Discretionary Access Control (DAC)
    * 开发者许可
* 强制访问控制 Mandatory Access Control (MAC)
    * 平台许可
* Android 权限 [Android permissions](https://developer.android.com/guide/topics/permissions/overview)
    * 用户许可

---

### Android 权限 {id="android-permissions"}

* Audit-only permissions
* Runtime permissions
* Special Access permissions
* Privileged permissions
* Signaturepermissions

---

## 应用程序沙盒化改进历程 {id="app-sandbox-enhancements-1"}

| 引入版本 | 改进措施                      | **拟解决** 的威胁                            |
| :-       | :-                            | :-                                           |
| ≤ 4.3    | 进程隔离$^0$                  | [T.A3] 导致的 [T.N1][T.A2][T.A5][T.A6][T.A7] |
| 5.x      | SELinux$^1$                   | [T.A7][T.D2]                                 |
| 5.x      | 允许 Webview 组件代码独立更新 | [T.A3]                                       |

* $^0$ `UID 沙盒` 是历史最悠久、最基础的应用沙盒安全技术，是实现用户进程间隔离的最基础访问控制技术，不足之处已经通过后续版本的 SELinux 规则更新逐步完善加固
* $^1$ 用户空间应用程序全部默认启用 SELinux 规则，大幅度改善了用户进程和系统进程的隔离性。用户进程间隔离还是依赖于 UID 沙盒。SELinux 的主要优点在于 `可审计` 和 `可测试` ，从而可以大幅度增加安全需求兼容性测试项目数量

---

## 应用程序沙盒化改进历程 {id="app-sandbox-enhancements-2"}

| 引入版本 | 改进措施                                     | **拟解决** 的威胁 |
| :-       | :-                                           | :-                |
| 6.x      | 允许运行时用户授权                           | [T.A1]            |
| 6.x      | 基于 SELinux 的多用户支持                    | [T.P4]            |
| 6.x      | 应用私有目录缺省目录权限变更 0755 -> 0700    | [T.A2]            |
| 6.x      | 针对 ioctl 增加 SELinux 规则缓解内核漏洞利用 | [T.A7][T.D2]      |
| 6.x      | 移除应用访问 debugfs 权限缓解内核漏洞利用    | [T.A7][T.D2]      |
| 6.x      | 特殊权限类别定义范围变更$^2$                 | [T.A1][T.A4]      |

* $^2$ SYSTEM_ALERT_WINDOW, WRITE_SETTINGS, CHANGE_NETWORK_STATE 变更为特殊权限类别

---

## 应用程序沙盒化改进历程 {id="app-sandbox-enhancements-3"}

| 引入版本 | 改进措施                                                | **拟解决** 的威胁 |
| :-       | :-                                                      | :-                |
| 7.x      | 移除 /proc/<pid> 支持减少侧信道信息泄露                 | [T.A4]            |
| 7.x      | perf事件加固缓解内核漏洞利用                            | [T.A7]            |
| 7.x      | /proc 文件系统缺省访问规则改进                          | [T.A1][T.A4]      |
| 7.x      | OPA/MITM 方式更新加入的证书缺省不被信任                 | [T.N2]            |
| 8.x      | /sys 文件系统缺省访问规则改进                           | [T.A1][T.A4]      |
| 8.x      | 所有用户进程使用相同的 seccomp 过滤规则以缓解内核攻击面 | [T.A7][T.D2]      |
| 8.x      | 所有用户进程使用的 Webview 组件被移入独立进程           | [T.A3]            |
| 8.x      | 应用使用明文网络通信协议需用户知情同意                  | [T.N1]            |

---

## 应用程序沙盒化改进历程 {id="app-sandbox-enhancements-4"}

| 引入版本 | 改进措施                                                             | **拟解决** 的威胁        |
| :-       | :-                                                                   | :-                       |
| 9.0      | 应用可以单独设置独立的 SELinux 沙盒                                  | [T.A2][T.A4]             |
| 10       | 原则上只允许应用在可见活动窗口中启动新Activity且加入到前台“后退堆栈” | [T.A2][T.A3][T.A4][T.A7] |
| 10       | 外部存储上的文件访问仅限于应用拥有的文件                             | [T.A1][T.A2]             |
| 10       | 只有当前输入焦点应用或默认输入法应用才能读取剪贴板数据               | [T.A5]                   |
| 10       | /proc/net 访问控制进一步严格以缓解侧信道攻击                         | [T.A1]                   |
| 11       | 不再支持传统模式下的应用访问外部存储上的其他应用文件                 | [T.A1][T.A2]             |

---

## 系统进程沙盒化改进历程 {id="system-sandboxing-1"}

![](images/chap0x06/changes-to-mediaserver-from6to10.png)

拟解决 [T.D2] 威胁

---

## 系统进程沙盒化改进历程 {id="system-sandboxing-2"}

| 引入版本 | 改进措施                                           | **拟解决** 的威胁  |
| :-       | :-                                                 | :-                 |
| 4.4      | 强制模式的 SELinux$^0$ 被应用于 4 个 root 权限进程 | [T.A1][T.A7][T.D2] |
| 5.x      | 用户态所有进程基于 SELinux 的 `MAC`                | [T.A1][T.A7]       |
| 6.x      | 所有进程基于 SELinux 的 `MAC`                      | [T.A1][T.A7]       |
| 7.x      | 架构层面解耦 `mediaserver` 服务                    | [T.A1][T.A7][T.D2] |
| 7.x      | 系统组件访问 `ioctl` 系统调用被限制                | [T.A1][T.A7][T.D2] |
| 8.x      | `Treble` 架构结构解耦$^1$                          | [T.A1][T.A7][T.D2] |

* $^0$ 4 个 root 权限进程被设置了 `强制访问控制（MAC, Mandatory Access Control）` 规则：installd, netd, vold, zygote
* $^1$ `HAL((Hardware Abstraction Layer)` 组件被拆分为独立进程，减少授权，限制访问硬件驱动

---

## 系统进程沙盒化改进历程 {id="system-sandboxing-2"}

| 引入版本 | 改进措施                                         | **拟解决** 的威胁 |
| :-       | :-                                               | :-                |
| 10       | 多媒体软件编解码器被移入到一个受限制沙盒         | [T.A7][T.D2]      |
| 10       | 引入 `BoundSan`$^2$ ，预防数组越界访问引起的漏洞 | [T.A7][T.D2]      |

* $^2$ [BoundsSanitizer(`BoundSan`)](https://source.android.com/devices/tech/debug/bounds-sanitizer) 将插桩添加到二进制文件，以插入对数组访问的边界检查。如果编译器在 **编译时** 无法证明访问将会是安全的，并且在运行时将会知道数组的大小，便会添加这些检查，以便对数组访问进行检查。Android 10 在蓝牙和编解码器中部署了 `BoundSan`。`BoundSan` 由编译器提供，在整个平台的各个组件中默认启用。

---

## 系统进程沙盒化改进历程 {id="system-sandboxing-3"}

| 引入版本 | 改进措施                                         | **拟解决** 的威胁 |
| :-       | :-                                               | :-                |
| 10       | 引入 `IntSan`$^3$                                | [T.A7][T.D2]      |
| 10       | 引入 `Scudo`$^4$                                 | [T.A7][T.D2]      |

* $^3$ [IntSan](https://source.android.com/devices/tech/debug/intsan) ，Android 7.0 中添加了 Clang 的 UndefinedBehaviorSanitizer (UBSan) 有符号和无符号整数溢出排错程序，以增强媒体框架。在 Android 9 中， UBSan 被扩展为涵盖更多组件，并改进了对它的编译系统支持。
* $^4$ [Scudo](https://source.android.com/devices/tech/debug/scudo)，是一个动态的用户模式内存分配器（也称为堆分配器），旨在抵御与堆相关的漏洞（如[基于堆的缓冲区溢出](https://cwe.mitre.org/data/definitions/122.html)、[释放后再使用](https://cwe.mitre.org/data/definitions/416.html)和[重复释放](https://cwe.mitre.org/data/definitions/415.html)），同时保持性能良好

---

## 系统内核沙盒化改进历程 {id="kernel-sandboxing-1"}

* 绝大多数内核漏洞利用的都是系统芯片上运行的硬件驱动程序缺陷
* 现有的内核漏洞缓解和加固措施集中在减少用户态进程访问内核驱动的机会
* 由于 Linux 内核是一个「宏内核」（`monolithic kernel `）架构，因此无法实现内核沙盒化
* 已有的缓解措施总结见下一页课件

---

## 系统内核沙盒化改进历程 {id="kernel-sandboxing-2"}

| 引入版本 | 改进措施                                                      | **拟解决** 的威胁 |
| :-       | :-                                                            | :-                |
| 5.x      | 引入 `PXN`$^0$ 机制                                           | [T.A7][T.D2]      |
| 6.x      | 内核线程被设置为SELinux强制执行模式，限制从内核访问用户态文件 | [T.A7][T.D2]      |
| 8.x      | 引入 `PAN`$^1$ 和 `PAN` 模拟机制                              | [T.A7][T.D2]      |
| 9.0      | 引入 `CFI`$^2$                                                | [T.A7][T.D2]      |
| 10       | 引入 `SCS`$^3$                                                | [T.A7][T.D2]      |

* $^0$ `PXN`, Privileged eXecute Never，内核态进程禁止执行用户态代码，预防 `ret2usr` 形式的漏洞利用技巧
* $^1$ `PAN`, Privileged Access Never，内核态进程访问用户态内存受到限制，仅允许通过 `copy-*-user()` 系列函数
* $^2$ `CFI`, [Control Flow Integrity](https://source.android.com/devices/tech/debug/cfi)，基于控制流「白名单」的函数调用限制
* $^3$ `SCS`, [Shadow Call Stack](https://source.android.com/devices/tech/debug/shadow-call-stack)，通过保护返回地址来实现调用堆栈深度回溯保护

---

## 内核层以下的沙盒化改进历程 {id="sandboxing-below-the-kernel-1"}

* 要解决的主要安全威胁（假设）：存在内核零日漏洞导致内核态保护隔离机制被攻陷
* 涉及到内核层以下的一些组件
    * TCB, Trusted Computing Base 可信计算基
    * TEE, Trusted Execution Environment 可信执行环境
    * 硬件驱动
    * 用户态组件 init, ueventd, and vold

---

## 内核层以下的沙盒化改进历程 {id="sandboxing-below-the-kernel-2"}

* Keymaster 重要密钥存储在 TEE 
* Strongbox Android 9.0 开始引入的 `防篡改硬件（TRH, Tamper Resistant Hardware）` 被用来存储重要密钥，属于 TEE 的「纵深防御」补充沙盒防御措施
* Gatekeeper 基于 TEE 或 TRH 实现锁屏解锁后访问 Keymaster 中存储的重要密钥
* Protected Confirmation Android 9.0 引入，部分缓解 [T.A4] 和 [T.A6]

# DiD.2 漏洞利用缓解技术

---

* Anrdoid 平台历史上 85% 的漏洞是由于不安全的内存访问引起

# DiD.3 系统完整性保护

---

* 操作系统和硬件设备层面需要确保自身完整性
* 典型实现方式： `验证启动` (`Verified Boot`)
    * Android KitKat 首次实现，Nougat 开始作为缺省强制启用特性

# DiD.4 补丁/更新

---

* 定期发布补丁和打补丁
    * Android 设备碎片化给补丁管理带来巨大挑战


