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

# ---- 全锥形 NAT（第三方内核模块，openwrt/packages 里没有，
#      如果 feeds 里确实搜不到这个包，说明还需要单独加一个
#      nft-fullcone 的 feed，第一次跑大概率会在这里报缺失）----
CONFIG_PACKAGE_kmod-nft-fullcone=y

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
