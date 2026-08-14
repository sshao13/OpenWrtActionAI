#!/bin/bash
# =========================================================
# diy-config.sh
# 在 .config 已经从 configs/x86_64.config 复制过来之后、
# make defconfig 之前执行，追加插件和内核优化开关。
# =========================================================

set -eu

cat >> .config << 'EOF'
# ---- LuCI 基础与简体中文 ----
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-ssl=y

# 中文语言支持（兼容 25.12 APK 新架构与传统 ipk 架构）
CONFIG_LUCI_LANG_zh-cn=y
CONFIG_LUCI_LANG_zh_cn=y
CONFIG_LUCI_LANG_zh_Hans=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-i18n-base-zh-hans=y
CONFIG_PACKAGE_luci-i18n-opkg-zh-cn=y

# ---- daed (走 kenzok8/openwrt-daede 源码 feed) ----
CONFIG_PACKAGE_dae=y
CONFIG_PACKAGE_daed=y
CONFIG_PACKAGE_luci-app-daede=y
CONFIG_PACKAGE_luci-i18n-daede-zh-cn=y

# ---- 内核原生 BTF + eBPF 工具链 (daed & einat 必需) ----
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

# ---- 追加 luci-app-momo ----
CONFIG_PACKAGE_luci-app-momo=y
# 如果需要简体中文语言包，可以同时加入：
CONFIG_PACKAGE_luci-i18n-momo-zh-cn=y
# ---- HomeProxy ----
CONFIG_PACKAGE_luci-app-homeproxy=y
CONFIG_PACKAGE_luci-i18n-homeproxy-zh-cn=y

# 增强 eBPF / daed 网络接口支持
CONFIG_PACKAGE_kmod-veth=y
CONFIG_PACKAGE_kmod-tun=y

# ---- 全锥形 NAT：einat-ebpf (直接拉取到 package/ 目录) ----
CONFIG_PACKAGE_einat-ebpf=y
CONFIG_PACKAGE_luci-app-einat=y

# ---- BBR 拥塞控制 ----
CONFIG_PACKAGE_kmod-tcp-bbr=y

# ---- 常用工具 ----
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_wget-ssl=y
CONFIG_PACKAGE_nano=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_pciutils=y
CONFIG_PACKAGE_usbutils=y

# ---- Intel 显卡 / HDMI 支持 (Dell Wyse 5070 硬件) ----
CONFIG_PACKAGE_kmod-drm-i915=y

# ---- RTC 硬件时钟 ----
CONFIG_PACKAGE_kmod-rtc-pcf8563=y

# ---- CPU 负载 / 温度 / 频率管理 (gSpotx2f 插件，直接克隆至 package/) ----
CONFIG_PACKAGE_luci-app-cpu-status=y
CONFIG_PACKAGE_luci-app-temp-status=y
CONFIG_PACKAGE_luci-app-cpu-perf=y
EOF

echo "==> 已追加插件/优化开关，追加后的行数：$(wc -l < .config)"
