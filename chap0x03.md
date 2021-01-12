---
title: "移动互联网安全"
author: 黄玮
output: revealjs::revealjs_presentation
---

# 第三章 无线接入网入侵与防御

---

## 温故

* 无线网络全生命周期包括哪些阶段
* [Wireshark 的 802.11 PSK 解密功能](https://c4pr1c3.github.io/cuc-mis/chap0x02/exp.html#wireshark%E7%9A%8480211-psk%E8%A7%A3%E5%AF%86%E5%8A%9F%E8%83%BD)

---

## 知新

* SSID 隐藏与发现
* Evil Twin 攻击与防御
* 花式中间人攻击与防御
* WLAN 认证机制攻防
* 基于 Scapy 的无线网络编程实践

# 实战回顾无线网络全生命周期

---

* [本章演示使用到的 pcap 样例数据文件](exp/chap0x03/full-connect-public.pcap)

---

## 无线 AP 配置信息 {id="ap-configure-info"}

![](images/chap0x03/OpenWrt-Wireless-LuCI.png)

---

![](images/chap0x03/full-connect-1.png)

---

## 一个典型的无线网络完整生命周期

* 加入无线网络前
* 加入无线网络
* 加入无线网络后
* 上行有线接入网络通信

# 加入无线网络前 [WEAK-0-0]

---

> 悄无声息的「监听」模式

* 无加密的无线网络通信就是在“裸奔”
* 有加密的无线网络通信数据逃不过被获取原始通信数据的命运

# 加入无线网络前 [WEAK-0-1]

---

> SSID 信息泄露

---

## 回顾：SSID包含在哪些类型的802.11帧？

* Beacon Frame
* Probe Request
* Probe Response
* Association Request
* Re-Association Request （样例数据文件中不包含）

---

## Tshark 小技巧示范 {id="tshark-tricks-1"}

```bash
echo "SA\t\t\tEnc\tType\tESSID"
tshark -r full-connect-public.pcap -Y "wlan.fc.type_subtype==0x08 || wlan.fc.type_subtype==0x04 || wlan.fc.type_subtype==0x05 || wlan.fc.type_subtype==0" -T fields -e frame.number -e wlan.sa -e wlan.fixed.capabilities.privacy -e wlan.fc.type_subtype -e wlan.ssid | sort -u
# 3c:46:d8:59:e8:f4	1	5	OpenWrt
# 3c:46:d8:59:e8:f4	1	8	OpenWrt
# 76:73:c1:7d:ef:a1		4	OpenWrt
# 76:73:c1:7d:ef:a1	1	0	OpenWrt

# 包含中文的 ESSID 怎么办？
echo "SA.Addr\t\t\tEnc\tFC_TS\tESSID"
tshark -r utf8-ssid-full-beacons-public.pcap -Y "wlan.fc.type_subtype==0x08 || wlan.fc.type_subtype==0x04 || wlan.fc.type_subtype==0x05 || wlan.fc.type_subtype==0" -T fields -e wlan.sa -e wlan.fixed.capabilities.privacy -e wlan.fc.type_subtype -e wlan.ssid | sort -u
```

---

## Wireshark 中查看中文 ESSID {id="essid-in-wireshark"}

![](images/chap0x03/copy-as-escaped-string.png)

---

```bash
echo -e "\xe8\xae\xa9\xe6\x88\x91\xe5\xba\xb7\xe5\xba\xb7\xe4\xbd\xa0"
# 让我康康你
```

---

## 交给 Scapy 来自动化完成这个任务 {id="scapy-decode-essid"}

```python
#!/usr/bin/env python

import os
import sys
from scapy.all import Dot11Elt, rdpcap


pcap = sys.argv[1]

if not os.path.isfile(pcap):
    print('input file does not exist')
    exit(1)

pkts = rdpcap(pcap)

i = 0
output = {}

print("{:5} {:18} {:18} {:18}".format("No.", "SA", "Type", "ESSID"))
for pkt in pkts:
    i += 1
    if not pkt.haslayer(Dot11Elt) or pkt.info.decode('utf8').strip('\x00') == '':
        continue
    if pkt.subtype == 0:  # Association Req
        output["{:18} {:18} {:18}".format(pkt.addr2, "Assoc Req", pkt.info.decode('utf8'))] = "{:5} {:18} {:18} {:18}".format(i, pkt.addr2, "Assoc Req", pkt.info.decode('utf8'))
    if pkt.subtype == 4:  # Probe Req
        output["{:18} {:18} {:18}".format(pkt.addr2, "Probe Req", pkt.info.decode('utf8'))] = "{:5} {:18} {:18} {:18}".format(i, pkt.addr2, "Probe Req", pkt.info.decode('utf8'))
    if pkt.subtype == 5:  # Probe Resp
        output["{:18} {:18} {:18}".format(pkt.addr2, "Probe Resp", pkt.info.decode('utf8'))] = "{:5} {:18} {:18} {:18}".format(i, pkt.addr2, "Probe Rep", pkt.info.decode('utf8'))
    if pkt.subtype == 8:  # Beacon Frame
        output["{:18} {:18} {:18}".format(pkt.addr2, "Beacon", pkt.info.decode('utf8'))] = "{:5} {:18} {:18} {:18}".format(i, pkt.addr2, "Beacon", pkt.info.decode('utf8'))

for key in output.keys():
    print(output[key])
```

# 加入无线网络前 [WEAK-0-2] 

---

> STA Mac Address 信息泄露

---

## Probe Request 泄露你的行踪 {id="how-probe-req-leakage-happens"}

---

## Beacon Frame 暴露你家的位置 {id="how-beacon-leakage-happens"}

---

## 设备厂商在行动 {id="apple-against-weak2"}

* [iOS 8+ 设备在扫描 Wi-Fi 时系统会使用的 MAC 地址来防止设备被跟踪，只有在连接成功后才会使用物理网卡地址](https://support.apple.com/zh-cn/guide/security/secb9cb3140c/web)
* [iOS 14+ / iPadOS 14+ / watchOS 7+ 会在每个无线局域网中使用不同的 MAC 地址（私有地址）](https://support.apple.com/zh-cn/HT211227)


---

## 设备厂商在行动 {id="microsoft-against-weak2"}

---

## 设备厂商在行动 {id="android-against-weak2"}

# 加入无线网络前 [WEAK-0-3]

---

> SSID 滥用与 Evil SSID

# 加入无线网络 [WEAK-1-0]

---

> Evil Twin

* [公开资料最早见于 2001 年的技术白皮书：Wireless LAN Security](http://www.packetnexus.com/docs/wireless_LAN_security.pdf)
* 常见分类
    * [KARMA Attack - 2004~2006](http://theta44.org/karma/) | [Simple Karma Attack (Tool)](https://github.com/Leviathan36/SKA)
    * [MANA Attack - 2014](https://github.com/sensepost/hostapd-mana/wiki/KARMA---MANA-Attack-Theory)
    * [Lure10 Attack - 2017](https://census-labs.com/news/2017/05/11/lure10-exploiting-windows-automatic-association-algorithm/)
        * 影响 [Windows 10 version 1703 以前版本](https://support.microsoft.com/zh-cn/windows/在-windows-10-中连接到开放-wlan-热点-bcec4e8b-00e7-4930-d3ff-5349a3e70037)
    * [Known Beacon Attack - 2018](https://census-labs.com/news/2018/02/01/known-beacons-attack-34c3/)

# 加入无线网络 [WEAK-1-1]

---

> 破解认证凭据

* WPA/WPA2 PSK
* WPA/WPA2 EAP

# 加入无线网络 [WEAK-1-2]

---

> 绕过 AP 的 MAC 地址过滤

# 加入无线网络 [WEAK-1-3]

---

> 脆弱的 WPS 认证机制

* 离线破解认证凭据：WPS Pixie Dust Attack
* 在线破解认证凭据：WPS Brute Force Attck

# 加入无线网络 [WEAK-1-4]

---

> KRACK Attack against WPA/WPA2

# 加入无线网络后 [WEAK-2-0]

---

> 回顾 《网络安全》第 4 章 网络监听 一节提到的所有局域网攻防手段

* ARP 欺骗
* DNS 投毒
* SSL Stripping

# 加入无线网络后 [WEAK-2-1]

---

> Deauthentication Attack

# 加入无线网络后 [WEAK-2-2]

---

> 解密流量

* WPA/WPA2-PSK 在拿到 PSK 情况下直接解密历史和进行中通信数据
* [Hole196 Vulnerability - 2010](http://securedsolutions.com.my/pdf/WhitePapers/WPA2-Hole196-Vulnerability.pdf)

# 上行有线接入网络通信 [WEAK-3-1]

---

> Rogue AP

# 上行有线接入网络通信 [WEAK-3-2]

---

> 回顾 《网络安全》第 4 章 网络监听 一节提到的所有局域网攻防手段

> 对于企业级认证来说，可以对 Radius 协议进行『中间人攻击』

# WPA3 安全性初探 {id="wpa3-vulnerabilities"}

---

* [Dragonblood](https://wpa3.mathyvanhoef.com/)

