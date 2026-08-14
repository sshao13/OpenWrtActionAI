#!/bin/bash
# =========================================================
# diy-feeds.sh
# 在 ./scripts/feeds update 之前执行
# =========================================================

set -eu

cd "$(pwd)"   # 这里的 $PWD 就是 /builder/openwrt

FEEDS_CONF="feeds.conf.default"

echo "==> 追加前 $FEEDS_CONF 内容："
cat "$FEEDS_CONF"

# 确保换行
echo "" >> "$FEEDS_CONF"

# 1. 追加合集 Feed (daede)
if ! grep -q "openwrt-daede" "$FEEDS_CONF"; then
  echo "src-git daede https://github.com/kenzok8/openwrt-daede.git" >> "$FEEDS_CONF"
fi

echo "==> 追加后 $FEEDS_CONF 内容："
cat "$FEEDS_CONF"

# ---------------------------------------------------------
# 2. 单个软件包（直接 clone 到 package/ 目录）
# ---------------------------------------------------------
echo "==> 开始克隆独立软件包到 package/ 目录..."

# einat-ebpf 及其 LuCI 界面
rm -rf package/einat-ebpf package/luci-app-einat
git clone --depth=1 https://github.com/muink/openwrt-einat-ebpf.git package/einat-ebpf
git clone --depth=1 https://github.com/muink/luci-app-einat.git package/luci-app-einat

# gSpotx2f 状态组件
rm -rf package/luci-app-cpu-status package/luci-app-temp-status package/luci-app-cpu-perf
git clone --depth=1 https://github.com/gSpotx2f/luci-app-cpu-status.git package/luci-app-cpu-status
git clone --depth=1 https://github.com/gSpotx2f/luci-app-temp-status.git package/luci-app-temp-status
git clone --depth=1 https://github.com/gSpotx2f/luci-app-cpu-perf.git package/luci-app-cpu-perf

# MoMo 代理界面
rm -rf package/luci-app-momo
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-momo.git package/luci-app-momo

# HomeProxy (修正为 immortalwrt 的有效地址)
rm -rf package/luci-app-homeproxy
git clone --depth=1 https://github.com/immortalwrt/homeproxy.git package/luci-app-homeproxy

echo "==> 独立软件包拉取完毕。"
