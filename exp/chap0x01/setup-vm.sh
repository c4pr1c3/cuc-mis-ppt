#!/usr/bin/env bash

VER="19.07.5" # openwrt version
VDI_BASE="openwrt-x86-64-combined-squashfs.vdi"

shasum -c img.sha256.sum -q >/dev/null 2>&1
if [[ $? -ne 0 ]];then
  # 下载固件
  wget https://downloads.openwrt.org/releases/$VER/targets/x86/64/openwrt-$VER-x86-64-combined-squashfs.img.gz -O openwrt-x86-64-combined-squashfs.img.gz
  # 解压缩
  gunzip openwrt-x86-64-combined-squashfs.img.gz
fi

shasum -c vdi.sha256.sum -q >/dev/null 2>&1
if [[ $? -ne 0 ]];then
  # img 格式转换为 Virtualbox 虚拟硬盘格式 vdi
  VBoxManage convertfromraw --format VDI openwrt-x86-64-combined-squashfs.img "$VDI_BASE" 2>/dev/null
  # 新建虚拟机选择「类型」 Linux / 「版本」Linux 2.6 / 3.x / 4.x (64-bit)，填写有意义的虚拟机「名称」
  # 内存设置为 256 MB
  # 使用已有的虚拟硬盘文件 - 「注册」新虚拟硬盘文件选择刚才转换生成的 .vdi 文件

  if [[ $? -eq 1 ]];then
    # ref: https://openwrt.org/docs/guide-user/virtualization/virtualbox-vm#convert_openwrtimg_to_vbox_drive
    dd if=openwrt-x86-64-combined-squashfs.img of=openwrt-x86-64-combined-squashfs-padded.img bs=128000 conv=sync
    VBoxManage convertfromraw --format VDI openwrt-x86-64-combined-squashfs-padded.img "$VDI_BASE"
  fi
fi

# 创建虚拟机
VM="openwrt-$VER"
# VBoxManage list ostypes
if [[ $(VBoxManage list vms | cut -d ' ' -f 1 | grep -w "\"$VM\"" -c) -eq 0 ]];then
  echo "vm $VM not exsits, create it ..."
  VBoxManage createvm --name $VM --ostype "Linux26_64" --register --groups "/IoT"
  # 创建一个 SATA 控制器
  VBoxManage storagectl "$VM" --name "SATA" --add sata --controller IntelAHCI
  # 向该控制器安装一个「硬盘」
  ## --medium 指定本地的一个「多重加载」虚拟硬盘文件
  VBoxManage storageattach "$VM" --storagectl "SATA" --port 0 \
    --device 0 --type hdd --medium "$VDI_BASE"

  VBoxManage storagectl "$VM" --name "SATA" --remove

  # 将目标 vdi 修改为「多重加载」
  VBoxManage modifymedium disk --type multiattach "$VDI_BASE"
  # 虚拟磁盘扩容
  VBoxManage modifymedium disk --resize 10240 "$VDI_BASE"

  VBoxManage storagectl "$VM" --name "SATA" --add sata --controller IntelAHCI
  VBoxManage storageattach "$VM" --storagectl "SATA" --port 0 \
    --device 0 --type hdd --medium "$VDI_BASE"

  # 启用 USB 3.0 接口
  VBoxManage modifyvm "$VM" --usbxhci on
  # 修改虚拟机配置
  ## --memory 内存设置为 256MB
  ## --vram   显存设置为 16MB
  VBoxManage modifyvm "$VM" --memory 256 --vram 16

  # ref: https://docs.oracle.com/en/virtualization/virtualbox/6.1/user/settings-display.html
  # VMSVGA: Use this graphics controller to emulate a VMware SVGA graphics device. This is the default graphics controller for Linux guests.
  VBoxManage modifyvm "$VM" --graphicscontroller vmsvga

  # CAUTION: 虚拟机的 WAN 网卡对应的虚拟网络类型必须设置为 NAT 而不能使用 NatNetwork ，无线客户端连入无线网络后才可以正常上网
  ## 检查 NATNetwork 网络是否存在
  # natnetwork_name="NatNetwork"
  # natnetwork_count=$(VBoxManage natnetwork list | grep -c "$natnetwork_name")
  # if [[ $natnetwork_count -eq 0 ]];then
  #   VBoxManage natnetwork add --netname "$natnetwork_name" --network "10.0.2.0/24" --enable --dhcp on
  # fi

  ## 添加 Host-Only 网卡为第 1 块虚拟网卡
  ## --hostonlyadapter1 第 1 块网卡的界面名称为 vboxnet0
  ## --nictype1 第 1 块网卡的控制芯片为 Intel PRO/1000 MT 桌面 (82540EM)
  ## --nic2 nat 第 2 块网卡配置为 NAT 模式
  VBoxManage modifyvm "$VM" --nic1 "hostonly" --nictype1 "82540EM" --hostonlyadapter1 "vboxnet0"
  VBoxManage modifyvm "$VM" --nic2 nat 
fi

