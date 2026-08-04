#!/bin/bash
# =========================================================
# diy-feeds.sh
# =========================================================

set -eu

FEEDS_CONF="feeds.conf.default"

echo "==> 清理换行符 & 过滤隐形字符..."
# 彻底消除 CRLF 导致的 Syntax error
if [ -f "$FEEDS_CONF" ]; then
  sed -i 's/\r$//' "$FEEDS_CONF"
fi

echo "==> 追加前 $FEEDS_CONF 内容："
cat "$FEEDS_CONF"

# 1. 针对标准的 Feed 仓库追加到 feeds.conf.default
# (只有包含 OpenWrt Feed 结构的仓库才能写进 feeds.conf)

# 2. 针对非 Feed 结构的独立插件（daede, cpu-status, temp-status, cpu-perf），
#    直接 clone 到 package/ 目录下，最稳定、绝对不会破坏 feeds.conf !
mkdir -p package/custom-pkgs

if [ ! -d "package/custom-pkgs/openwrt-daede" ]; then
  echo "--> 正在 Clone openwrt-daede 到 package 目录..."
  git clone --depth 1 https://github.com/kenzok8/openwrt-daede.git package/custom-pkgs/openwrt-daede
fi

if [ ! -d "package/custom-pkgs/luci-app-cpu-status" ]; then
  echo "--> 正在 Clone luci-app-cpu-status 到 package 目录..."
  git clone --depth 1 https://github.com/gSpotx2f/luci-app-cpu-status.git package/custom-pkgs/luci-app-cpu-status
fi

if [ ! -d "package/custom-pkgs/luci-app-temp-status" ]; then
  echo "--> 正在 Clone luci-app-temp-status 到 package 目录..."
  git clone --depth 1 https://github.com/gSpotx2f/luci-app-temp-status.git package/custom-pkgs/luci-app-temp-status
fi

if [ ! -d "package/custom-pkgs/luci-app-cpu-perf" ]; then
  echo "--> 正在 Clone luci-app-cpu-perf 到 package 目录..."
  git clone --depth 1 https://github.com/gSpotx2f/luci-app-cpu-perf.git package/custom-pkgs/luci-app-cpu-perf
fi

echo "==> 处理完成后的 $FEEDS_CONF 内容："
cat "$FEEDS_CONF"
