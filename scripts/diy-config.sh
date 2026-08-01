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
# CONFIG_LUCI_LANG_zh-cn 这个总开关先打开（源码里 luci.mk 生成的
# 每个语言包都写着 default LUCI_LANG_<lang>||(ALL&&m)，光写目标包
# 本身的 =y 不够，跟之前 BTF 需要先开 CONFIG_KERNEL_DEBUG_INFO 是
# 同一种"漏写前置依赖"的坑）。
CONFIG_LUCI_LANG_zh-cn=y
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

# ---- 全锥形 NAT：暂不做 ----
# 对应的 fullcone-nat-nftables/nft-fullcone 项目已归档不再维护，
# 而且不是装一个内核模块就行——需要同时给 nftables 和 libnftnl
# 这两个用户态核心组件打补丁才能用，风险是可能把防火墙/NAT
# 功能编坏，不是"装不上就少个功能"这么简单。已决定暂缓，
# 不在主线里做，需要的话以后单独开分支尝试。

# ---- 常用工具 ----
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_wget-ssl=y
CONFIG_PACKAGE_nano=y
CONFIG_PACKAGE_htop=y

# ---- 在线 OTA 升级 ----
CONFIG_PACKAGE_luci-app-attendedsysupgrade=y

# ---- Intel 显卡 / HDMI ----
CONFIG_PACKAGE_kmod-drm-i915=y

# ---- RTC ----
CONFIG_PACKAGE_kmod-rtc-pcf8563=y
EOF

echo "==> 已追加插件/优化开关，追加后的行数：$(wc -l < .config)"
