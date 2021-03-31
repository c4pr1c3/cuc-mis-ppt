---
title: "移动互联网安全"
author: 黄玮
output: revealjs::revealjs_presentation
---

# 第七章 移动终端应用逆向分析

---

## 温故

* Android 应用开发基本概念
    * 清单文件 `AndroidManifest.xml`
    * 四大组件
* ADB 的典型使用场景

---

## 知新

* 静态分析
* 动态分析
* 通信协议逆向分析基础

# 静态分析基础

---

## 概述

静态分析是指在 **不运⾏代码** 的情况下，采用 `词法分析`、`语法分析` 等各种技术⼿段对 `程序⽂件` 进⾏扫描从⽽⽣成程序的 `逆向代码`（包括 `反汇编代码` 或 `反编译代码`），然后阅读 `逆向代码` 来掌握程序功能和理解程序原理的⼀种技术。

---

## 复习：正向工程

[![Android 应用构建流程](images/chap0x06/build-process.png)](images/chap0x06/build-process_2x.png)

---

## 逆向工程

[![Android 应用逆向工程流程](images/chap0x07/re-process.png)](images/chap0x07/re-process_2x.png)

---

## 反编译 vs. 反汇编 {id="disassemble-vs-decompile"}

|                    | 高级语言源代码 | 汇编代码 | 机器指令代码 |
| :-                 | :-             | :-       | :-           |
| 汇编 assemble      | -              | 源代码   | 目标代码     |
| 反汇编 disassemble | -              | 目标代码 | 源代码       |
| 编译 compile       | 源代码         | -        | 目标代码     |
| 反编译 decompile   | 目标代码       | -        | 源代码       |

---

## Android 平台中的源代码和目标代码 {id="android-src-and-exe"}

* 高级语言源代码 `Java` / `Kotlin` / `C/C++`
* 汇编代码 `Smali`
    * `smali` 是面向 `人类阅读` 的文本格式代码
* 机器指令代码 `DEX 字节码`，也称为 `Dalvik 字节码`
    * `Dalvik 字节码` 是面向 `机器执行` 的二进制格式代码

---

> 以第六章的 `Hello World v2` 应用为例

# APK 文件 {id="what-is-apk"}

---

## APK 内容 {id="apk-internals"}

* APK: Android package ，使用 `JAR 格式` ，是一种特殊的 `ZIP 格式`
    * AndroidManifest.xml
    * classes.dex
    * res/
    * META-INF
    * resources.arsc
    * lib/ (有的应用会用到)

---

## 复习 [AndroidManifest.xml](https://developer.android.com/guide/topics/manifest/manifest-intro)

* 位于应用代码目录的根目录下
* 声明应用中的所有组件
* 声明组件功能
	* 配合 `IntentFilter` 声明
* 声明应用要求
	* 确定应用需要的任何用户权限，如互联网访问权限或对用户联系人的读取权限
	* 根据应用使用的 API，声明应用所需的最低 API 级别
	* 声明应用使用或需要的硬件和软件功能，如相机、蓝牙服务或多点触摸屏幕
	* 声明应用需要链接的 API 库（Android 框架 API 除外），如 Google 地图库

---

## classes.dex

* Java 源代码编译后得到的 `Dalvik 字节码`（也称为 `Dex 字节码`） 文件
* [ART 和 Dalvik 是运行 Dex 字节码的兼容运行时](https://source.android.com/devices/tech/dalvik/)
    * `ART`（`Android runtime`）是 `Dalvik` 的后续升级版本，自 `Android 5.0 (API level 21)` 引入

---

## res/

* 所有资源文件所在目录
    * 反编译出来的 `.xml` 是二进制格式，无法直接阅读

---

## resources.arsc

* 预编译后的二进制资源文件汇总，定义了 Java 类、属性与 xml 文件和静态资源之间的映射关系

```bash
# aapt 位于 $ANDROID_HOME/build-tools/$platform_version/aapt
# aapt: Android Asset Packaging Tool

# 查看 aapt 的使用帮助
aapt

# 列举 APK 内所有资源文件的路径
aapt l app-release.apk

# -a print Android-specific data (resources, manifest) when listing
# aapt list -v app-release.apk 等价于 unzip -l -v app-release.apk

aapt d xmltree app-release.apk AndroidManifest.xml
aapt d xmltree app-release.apk res/layout/activity_main.xml
aapt d xmltree app-release.apk res/layout/activity_display_message.xml
```

---

## lib/

* 平台（例如按照 CPU 指令集区分）相关的编译后文件
* 典型子目录
    * armeabi-v7a
    * arm64-v8a
    * x86
    * x86_64

---

## META-INF

* proguard 配置文件
* 签名信息
    * 压缩包内文件真实性（身份验证和文件完整性）校验

# 深入浅出 Android 应用签名 {id="dive-into-apksign"}

---

## [签名格式规范](https://source.android.com/security/apksigning)

* v1 方案：基于 JAR 签名
    * 在 `META-INF/` 下产生 `CERT.SF` 和 `CERT.RSA` ，并在 `MANIFEST.MF` 中记录所有源代码文件的散列值
* [v2 方案](https://source.android.com/security/apksigning/v2)：APK 签名方案 v2（在 Android 7.0 中引入），签名信息嵌入在 `ZIP 文件头`
* [v3 方案](https://source.android.com/security/apksigning/v3)：APK 签名方案 v3（在 Android 9 引入）
    * Android 9 支持 APK  `密钥轮替`，这使应用能够在 APK 更新过程中更改其签名密钥
    * v3 APK 签名分块的格式与 v2 相同
* [v4 方案](https://source.android.com/security/apksigning/v4)：APK 签名方法 v4（在 Android 11 引入）
    * 与 `流式传输兼容` 的签名方案

---

### V1 版签名算法的已知缺陷 {id="CVE-2017-13156"}

* [`Janus` 漏洞（CVE-2017-13156）](https://www.guardsquare.com/en/blog/new-android-vulnerability-allows-attackers-modify-apps-without-affecting-their-signatures): 篡改 APK 文件的同时可以通过系统的签名校验
    * 攻击者将植入恶意代码的仿冒 App 投放到安卓商店等第三方应用市场后可以覆盖更新正版 App

---

### 简述 Janus 漏洞原理

* 攻击者将攻击代码嵌入到一个 `DEX` 文件，并将正常 `APK` 文件追加在该 `DEX` 文件尾部
* APK 在被安装到系统时，没有先根据「文件头部魔术字符串」判断文件类型，而是直接按照 ZIP 文件格式读取机制从文件末尾开始扫描后，解压缩得到签名相关文件，并进行签名验证发现「压缩包内文件均真实可信」，因此，包含攻击代码的拼接后 `APK` 文件被成功安装到系统里
    * ZIP 文件格式读取机制：从文件末尾开始扫描，通过 `End of Central Directory` 标记定位 `Central Directory` 范围，从而确定压缩包内所有文件的起始位置
* 受害者启动该 `APK` 文件时，ART 从文件头部开始搜索魔术字符串：发现是 `dex` 则认为当前是一个 `DEX` 文件，可以直接运行

---

### 识别目标 APK 使用的签名算法 {id="check-sign-ver-1"}

* v2/v3: 检查 APK 文件中是否包含魔术字符串 `APK Sig Block 42`
* v2: 签名信息保存在 `ID=0x7109871a` （大端序）的键值对区块中
* v3: 签名信息保存在 `ID=0xf05368c0` （大端序）的键值对区块中
* v4: 签名保存在一个独立文件 `<apk name>.apk.idsig`
    * v3 签名也会生成一个 `<apk name>.apk.idsig`

---

### 识别目标 APK 使用的签名算法 {id="check-sign-ver-2"}

```bash
# 验证目标 APK 使用的签名算法
apksigner verify --verbose app-release.apk
# Verifies
# Verified using v1 scheme (JAR signing): true
# Verified using v2 scheme (APK Signature Scheme v2): true
# Verified using v3 scheme (APK Signature Scheme v3): false
# Verified using v4 scheme (APK Signature Scheme v4): false
# Verified for SourceStamp: false
# Number of signers: 1

# 在 APK 文件中搜索 0x1a870971（小端序）
xxd -p app-release.apk | tr -d '\n' | grep '1a870971' -c
# 1

# 仅使用 v2 签名算法，未使用 v1 签名算法时
apksigner verify --verbose app-release.apk | head -n 10
# DOES NOT VERIFY
# ERROR: No JAR signatures

# 手动创建一个使用 v3 签名的 APK
# ref: https://stackoverflow.com/questions/59248088/how-can-i-sign-my-app-with-apk-signature-scheme-v3
# 0. 使用 29.0.2+ 的 SDK build-tools
# 1. 在 Android Studio 中 Build-> Build Bundles(s)/APK(s)-> Build APK(s) 生成一个未签名版的 APK 文件
# 2. 对齐未签名 APK 文件 app-debug.apk 为 app-debug-unsigned.apk
zipalign -v -p 4 app-debug.apk app-debug-unsigned.apk
# 3. 使用证书签发应用
apksigner sign --ks <path/to/keystore.jks> --out app-release-v3.apk app-debug-unsigned.apk
# 验证目标 APK 使用的签名算法
apksigner verify --verbose app-release.apk
# Verifies
# Verified using v1 scheme (JAR signing): true
# Verified using v2 scheme (APK Signature Scheme v2): true
# Verified using v3 scheme (APK Signature Scheme v3): true
# Verified using v4 scheme (APK Signature Scheme v4): false
# Verified for SourceStamp: false
# Number of signers: 1

# 在 APK 文件中搜索 0xc06853f0（小端序）
xxd -p app-release-v3.apk | tr -d '\n' | grep 'c06853f0' -c
# 1
xxd -p app-release-v3.apk | tr -d '\n' | grep '1a870971' -c
# 1
```

---

## MANIFEST.MF

* V1 版签名算法中，高级语言源代码项目中的所有文件的散列值清单（首次散列）

```bash
# MANIFEST.MF 中资源文件 SHA-256 计算方法
openssl dgst -binary -sha256 classes.dex | openssl base64
# mRATF5pAo8YStNMeTVazJ0lY8tk07WrU+7kE37Ilezo=

grep classes.dex META-INF/MANIFEST.MF -A 1
# Name: classes.dex
# SHA-256-Digest: mRATF5pAo8YStNMeTVazJ0lY8tk07WrU+7kE37Ilezo=
```

---

## CERT.SF {id="cert.sf-1"}

* V1 版签名算法中，高级语言源代码项目中的所有文件的再散列值清单（二次散列）
* 清单文件上每个文件的校验和计算方法
    * 由 `MANIFEST.MF` 文件中对应的部分（包含空行）先 `SHA-256` 再 `BASE64` 处理后的结果
    * 注意不能漏了：每行结尾的 `0d0a0d0a`

---

## CERT.SF {id="cert.sf-2"}

```bash
head -n 4 CERT.SF
# Signature-Version: 1.0
# Created-By: 1.0 (Android)
# SHA-256-Digest-Manifest: RJvtXkwFOU6I8baArGxnClXjXbJeUIA6vVoxwARCMPk=
# X-Android-APK-Signed: 2
# 上述 X-Android-APK-Signed 说明该 APK 同时使用了 v1 和 v2 版签名算法

openssl dgst -binary -sha256 META-INF/MANIFEST.MF| openssl base64
# RJvtXkwFOU6I8baArGxnClXjXbJeUIA6vVoxwARCMPk=

head -n 3 META-INF/CERT.SF
# Signature-Version: 1.0
# Created-By: 1.0 (Android)
# SHA-256-Digest-Manifest: RJvtXkwFOU6I8baArGxnClXjXbJeUIA6vVoxwARCMPk=

# 计算指定文件在 CERT.SF 中的散列值
cat MANIFEST.MF| grep -A 2 classes.dex > classes.dex.mainfest
openssl dgst -binary -sha256 classes.dex.mainfest| openssl base64
# 5rt4DAeW33qpit8mZ7+2uVsk+INcHQc48nzP4aeRTrM=

grep classes.dex -A 2 CERT.SF
# Name: classes.dex
# SHA-256-Digest: 5rt4DAeW33qpit8mZ7+2uVsk+INcHQc48nzP4aeRTrM=
```

---

## CERT.RSA

```bash
# 用 ASN.1 语法解析 CERT.RSA
openssl asn1parse -in CERT.RSA -inform DER -i -dump

# 用 pkcs7 语法解析 CERT.RSA
openssl pkcs7 -in CERT.RSA -inform der -print_certs -text
```

# 逆向工具

---

## 逆向目标

* 反汇编 `.apk` 文件
* 反编译 `.apk` 文件

---

### 反汇编工具 {id="decompile-into-smali"}

* [Apktool](https://ibotpeaches.github.io/Apktool/) - 反汇编瑞士军刀
* Android Studio 内置的 [APK Analyzer](https://developer.android.com/studio/build/apk-analyzer.html)
* 解包：将二进制格式的 `Dalvik 字节码` 反汇编为 `smali` 代码
    * `baksmali`（解包）: .dex --> .smali
* 打包：将文本格式的 `smali` 代码汇编为 `Dalvik 字节码`
    *  `smali` （打包）: .smali --> .dex

---

### 反编译工具 {id="decompile-into-java"}

1. `zip` 格式解压缩工具，例如: `unzip`，解压缩 `.apk` ，提取出 `classes.dex`
2. 将 `dex` 格式文件转换回 `jar` 格式文件 - [dex2jar](https://github.com/pxb1988/dex2jar)
3. `Java` 字节码反编译工具 
    * [JD-GUI](https://github.com/java-decompiler/jd-gui)
    * [jadx](https://github.com/skylot/jadx)

# 定位关键代码的方法

---

## 典型方法分类

* 顺序查看法（静态分析）
* 信息反馈法（黑盒动态）
* 特征函数法（灰盒动态）
* 代码注入法（灰盒动态调试和分析）
* 栈跟踪法（灰盒动态调试和分析）

---

## 动态分析基本概念

软件逆向分析中的动态分析指的是在 **不依赖于** 软件源代码的情况下，将目标程序 `运行起来`，在运行中分析程序执行行为和结果。

---

## 黑白灰盒分析

* 如果在有源代码或对应符号文件的条件下进行动态分析，则被称为 `白盒动态分析` 。这种条件下的动态分析体验和正向开发过程中的 `单步调试` 体验基本一致。
* 如果缺少源代码或对应符号文件，但可以通过静态分析手段得到反汇编或反编译代码，则被称为 `灰盒动态分析`。
* 如果既没有反汇编也没有反编译代码，则该动态分析手段被称为 `黑盒动态分析`。

---

## 逆向工程思路

* 动静态分析手段是可以结合使用的
* 源代码、符号文件、反编译代码、反汇编代码等对于动态分析方向的指引价值逐步递减，但都强于黑盒动态分析


# 顺序查看法

---

顺序查看法通常是从 `用户界面主入口 Activity` 或其他启动代码入手分析，逐行向下分析，掌握软件的执行流程。

> 这种分析方法在病毒分析时经常用到：大多数病毒都会实现开机自启动或随常用应用软件的启动而自动加载执行。

---

## 定位 `用户界面主入口 Activity` {id="find-main-activity-1"}

如果未对应用的 `Activity` 之一声明 [MAIN 操作](https://developer.android.com/reference/android/content/Intent.html?hl=zh-cn#ACTION_MAIN) 或 [LAUNCHER 类别](https://developer.android.com/reference/android/content/Intent.html?hl=zh-cn#CATEGORY_LAUNCHER)，那么 **应用图标将不会出现在应用的主屏幕列表中** 。

```xml
<activity android:name=".MainActivity" android:label="@string/app_name">
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>
</activity>
```

---

## 定位 `用户界面主入口 Activity` {id="find-main-activity-2"}

根据 `AndroidManifest.xml` 中的 `package` 定义，即可定位完整的 `主 Activity` 类名。

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:versionCode="2"
    android:versionName="10.0"
    android:compileSdkVersion="30"
    android:compileSdkVersionCodename="11"
    package="cn.edu.cuc.misdemo"
    platformBuildVersionCode="2"
    platformBuildVersionName="1092616192.000000">

    <!-- ... -->

</manifest>
```

# 信息反馈法

---

* 基于运行时程序的交互提示信息输出中寻找 `关键信息`
    * 通常是 `字符串` 形式，也可能是 `图片` 文件等
* 在 `源代码` 或 `逆向代码` 中搜索可能的硬编码上述 `关键信息`

---

## Android 应用中的信息反馈法实践举例 {id="android-strings-re"}

* Android 程序中用到的字符串会存储在 `strings.xml` 文件或者硬编码到程序代码中
    * 如果是前者的话，字符串在程序中会以 `id` 的形式访问，只需要在反汇编代码中搜索字符串 `id` 值即可找到调用代码处
    * 如果是后者的话，在反汇编代码中直接搜索字符串即可定位到关键代码附近

---

## 动手实践时间 {id="dvahw-1"}

以 [Deliberately Vulnerable Android Hello World](https://github.com/c4pr1c3/DVAHW) 为例。

# 特征函数法

---

## 概述 {id="special-func-intro"}

* 本方法和信息反馈法基本原理相似：观察法
* 区别之处在于： **特征函数法** 侧重于从消息的 `UI` 和 `UE` 实现技术原理推测用到了 `Android SDK` 中提供的哪些相关 `API 函数`

---

## 实例

* 弹出 `注册失败` 错误提示信息可能是调用的 `Toast.MakeText().Show()` 方法，在反汇编代码中直接搜索 `Toast` 应该很快能定位相关调用代码
* 如果 `Toast` 在程序中被多次调用的话，可能需要分析人员逐个阅读核对

---

## 动手实践时间 {id="dvahw-2"}

以 [Deliberately Vulnerable Android Hello World](https://github.com/c4pr1c3/DVAHW) 为例。

# 代码注入法

---

* 代码注入法属于动态调试方法，基本原理是修改 `apk` 文件的 `smali 反汇编代码`，加入打印语句输出，然后重新打包回 `apk` 文件安装运行，配合 `LogCat` 查看程序执行到特定点时的（变量和关键数据结构）状态数据
* 这种方法在解密程序数据时经常使用，具体的例子可以查阅[本章实验](https://c4pr1c3.github.io/cuc-mis/chap0x07/exp.html)
* 这种方法又被称为 `插桩` 分析技术 
    * `插桩` `instrumentation`

---

## 动手实践时间 {id="dvahw-3"}

以 [Deliberately Vulnerable Android Hello World](https://github.com/c4pr1c3/DVAHW) 为例。

# 栈跟踪法

---

## 概述 {id="stack-trace-intro"}

* `栈跟踪法` 是一种特殊的 `代码注入法` ，同时也属于 `插桩` 分析技术
* 用 `栈跟踪信息输出` 方法调用代替上述例子中使用的 `打印语句` 注入到目标程序的 `反汇编代码`
* 栈跟踪法只需要知道大概的代码注入点
* 注入代码后的反馈信息比 `打印语句` 注入要详细地多

---

## 示例

```java
// Java 调用栈跟踪方法
new Exception("print trace").printStackTrace();
```

```smali
# 对应上述 Java 代码的 smali 反汇编代码
new-instance v0, Ljava/lang/Exception;
const-string v1, "print trace";
invoke-direct {v0, v1}, Ljava/lang/Exception;-><init>(Ljava/lang/String;)V
invoke-virtual {v0}, Ljava/lang/Exception;->printStackTrace()V
```

---

## 分析思路

* 栈跟踪信息记录了程序从启动到 `printStackTrace()` 被执行期间所有被调用过的方法
* 从下往上查看栈跟踪信息，很容易就可以找到在打印栈跟踪信息之前的完整函数调用链，这样函数的执行流程就一清二楚了

# 通信协议逆向分析

---

* 模拟器
* 物理真机
* 针对 HTTP 协议通信监听与逆向分析
* 监听蓝牙协议通信数据



