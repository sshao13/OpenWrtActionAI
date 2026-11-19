#!/bin/bash
# =========================================================
# diy-config.sh
# 在 .config 已经从 configs/x86_64.config 复制过来之后、
# make defconfig 之前执行，追加插件和内核优化开关。
# =========================================================

set -eu

cat >> .config << 'EOF'
# ---- LuCI 基础 ----
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-ssl=y
# CONFIG_PACKAGE_luci-i18n-base-zh-cn 依赖上层的 "Translations" 菜单里
# 一个总开关先打开。诊断已确认 LUCI_LANG_zh-cn / LUCI_LANG_zh_cn
# 这两种写法在源码里根本不存在——luci.mk 用的是"别名"机制，简体
# 中文的顶层开关真正的符号名大概率是 zh_Hans（大写 H），不是
# 原始翻译目录名 zh-cn。四种写法都留着，不管哪个是真的都能命中，
# Kconfig 对不认识的符号只会忽略，不会因为多写报错。
CONFIG_LUCI_LANG_zh-cn=y
CONFIG_LUCI_LANG_zh_cn=y
CONFIG_LUCI_LANG_zh_Hans=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y

# ---- daed（走 kenzok8/openwrt-daede 源码 feed）----
# 包名如果实测对不上，看 package/feeds/daede/ 目录下的真实目录名再改
CONFIG_PACKAGE_dae=y
CONFIG_PACKAGE_daed=y
CONFIG_PACKAGE_luci-app-daede=y

# ---- 内核原生 BTF + eBPF 工具链 ----
# 这一整段是照抄 daed 前端项目 QiuSimons/luci-app-daed 官方 README
# 给出的必需配置（https://github.com/QiuSimons/luci-app-daed），
# 之前只写了 BTF 相关几行，漏了 CONFIG_BPF_TOOLCHAIN_HOST=y——
# 这一行的作用是告诉 OpenWrt "编译 eBPF 代码时直接用宿主机已经装好
# 的 clang（build.yml 里 apt 装的那个），不要自己再从源码编译一份
# 专用工具链"。没写这行时默认走的是另一条路径，会在编译 eBPF 相关
# 包时报 "LLVM/clang version too old" 或找不到 clang 可执行文件。
CONFIG_DEVEL=y
CONFIG_KERNEL_DEBUG_INFO=y
# CONFIG_KERNEL_DEBUG_INFO_REDUCED is not set
CONFIG_KERNEL_DEBUG_INFO_BTF=y
CONFIG_KERNEL_DEBUG_INFO_BTF_MODULES=y
CONFIG_KERNEL_CGROUPS=y
CONFIG_KERNEL_CGROUP_BPF=y
CONFIG_KERNEL_BPF_EVENTS=y
CONFIG_BPF_TOOLCHAIN_HOST=y
CONFIG_KERNEL_XDP_SOCKETS=y
CONFIG_PACKAGE_kmod-xdp-sockets-diag=y

# ---- BBR 拥塞控制 ----
CONFIG_PACKAGE_kmod-tcp-bbr=y

# ---- 全锥形 NAT：einat-ebpf（纯 eBPF，不打补丁）----
# fullcone-nat-nftables/nft-fullcone 那条路线（给 nftables/libnftnl
# 打补丁）已归档不维护，风险也高，主线不用，只留在 dev-fullcone
# 分支单独验证。这里换成 einat-ebpf：纯 eBPF 实现，不碰任何核心
# 网络组件源码，依赖内核 BPF+BTF（前面已经为了 daed 开好了，
# 现成能用）。包名如果实测对不上，看
# package/feeds/einat_ebpf(/luci_app_einat)/ 目录下的真实目录名再改。
CONFIG_PACKAGE_einat-ebpf=y
CONFIG_PACKAGE_luci-app-einat=y

# ---- honk（eBPF 透明代理，走 kenzok8/openwrt-honk feed）----
# 内核侧的 BPF/BTF/cgroup 开关上面已经为 daed 开好了；honk 另外要 nft queue。
# 注意：honk 和 dae/daed 都要占根 cgroup 的 BPF 槽位，两个不能同时启用，
# 用哪个就把另一个在 LuCI 里停掉并禁用开机自启。
CONFIG_PACKAGE_honk=y
CONFIG_PACKAGE_luci-app-honk=y
CONFIG_PACKAGE_kmod-nft-queue=y
CONFIG_PACKAGE_kmod-veth=y
CONFIG_PACKAGE_kmod-sched-bpf=y

# ---- 常用内核模块（kmod）----
# 自编内核的 kmod 哈希和官方源不一样，刷机后再 apk add kmod-xxx 是装不上的，
# 所以常用的内核模块必须在编译时就选进固件。名字写错的话 Kconfig 会静默忽略，
# build.yml 的"kmod 预检"会把没进 .config 的列出来。
# -- 虚拟网卡 / VPN / 隧道 --
CONFIG_PACKAGE_kmod-tun=y
CONFIG_PACKAGE_kmod-wireguard=y
CONFIG_PACKAGE_kmod-macvlan=y
CONFIG_PACKAGE_kmod-dummy=y
CONFIG_PACKAGE_kmod-ifb=y
CONFIG_PACKAGE_kmod-gre=y
CONFIG_PACKAGE_kmod-ipip=y
CONFIG_PACKAGE_kmod-sit=y
CONFIG_PACKAGE_kmod-ip6-tunnel=y
CONFIG_PACKAGE_kmod-vxlan=y
CONFIG_PACKAGE_kmod-br-netfilter=y
# -- 透明代理 / 防火墙（OpenClash、Passwall、sing-box 一类常用）--
CONFIG_PACKAGE_kmod-nft-tproxy=y
CONFIG_PACKAGE_kmod-nft-socket=y
CONFIG_PACKAGE_kmod-nft-compat=y
CONFIG_PACKAGE_kmod-nf-conntrack-netlink=y
# -- 流控 / QoS --
CONFIG_PACKAGE_kmod-sched-cake=y
# -- 存储：U 盘 / 硬盘 / NVMe / 文件系统 --
CONFIG_PACKAGE_kmod-ata-ahci=y
CONFIG_PACKAGE_kmod-nvme=y
CONFIG_PACKAGE_kmod-usb-core=y
CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-usb-storage-uas=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-exfat=y
CONFIG_PACKAGE_kmod-fs-ntfs3=y
# -- USB 网卡 / 手机共享网络 --
CONFIG_PACKAGE_kmod-usb-net-cdc-ether=y
CONFIG_PACKAGE_kmod-usb-net-rndis=y
CONFIG_PACKAGE_kmod-usb-net-rtl8152=y
CONFIG_PACKAGE_kmod-usb-net-asix-ax88179=y
# -- 温度传感器（给 luci-app-temp-status 读 CPU 温度；Wyse 5070 是 Intel 用 coretemp）--
CONFIG_PACKAGE_kmod-hwmon-coretemp=y
CONFIG_PACKAGE_kmod-hwmon-k10temp=y

# ---- 常用工具 ----
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_wget-ssl=y
CONFIG_PACKAGE_nano=y
CONFIG_PACKAGE_htop=y

# ---- 在线 OTA 升级：不装 ----
# luci-app-attendedsysupgrade 已删除。这个功能默认连的是官方
# 构建服务，只认官方原版包/feed，不知道我们额外接的 daed/daede、
# 打开的内核 BTF 等自定义配置。真去点"搜索固件更新"，大概率会
# 拿到一个不含这些自定义内容的"纯官方"固件，刷上去等于悄悄把
# 自定义功能全部升没，自己还没意识到。以后升级固件老老实实回
# GitHub Actions 重新构建、手动下载刷机，别用这个功能。

# ---- Intel 显卡 / HDMI ----
CONFIG_PACKAGE_kmod-drm-i915=y

# ---- RTC ----
CONFIG_PACKAGE_kmod-rtc-pcf8563=y

# ---- CPU 负载 / 温度 / 频率管理（gSpotx2f 维护，走 feed 编译）----
# 包名如果实测对不上，看 package/feeds/cpu-status(/temp-status/cpu-perf)/
# 目录下的真实目录名再改。这三个插件没有确认过有没有官方中文翻译，
# 先不装 i18n 包，装完看界面语言，需要的话再补。
CONFIG_PACKAGE_luci-app-cpu-status=y
CONFIG_PACKAGE_luci-app-temp-status=y
CONFIG_PACKAGE_luci-app-cpu-perf=y
EOF

echo "==> 已追加插件/优化开关，追加后的行数：$(wc -l < .config)"
