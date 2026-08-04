#!/bin/bash
# =========================================================
# diy-feeds.sh
# 在 ./scripts/feeds update 之前执行，往 feeds.conf.default
# 追加第三方 feed。
#
# 不确定项，第一次跑大概率要根据实际报错调整（我没有条件真的
# 跑一次全源码编译来验证，只能基于公开资料尽量往对了配）：
#   1. kenzok8/openwrt-daede 这个 feed 里 Makefile 声明的具体
#      包名是不是真的叫 "dae" "daed" "luci-app-daede"，需要
#      实际 feeds install 之后看 package/feeds/daede/ 目录下
#      真实的目录名才能 100% 确认。
#   2. dae 是 Go 写的，官方 feeds 自带的 golang 版本可能太旧
#      编译不过，如果报 golang 版本相关的错，需要换成社区常用的
#      sbwml/packages_lang_golang 这个更新过的 golang feed。
# =========================================================

set -eu

cd "$(pwd)"   # 这里的 $PWD 就是 /builder/openwrt（build.yml 里已经 cd 过）

FEEDS_CONF="feeds.conf.default"

echo "==> 追加前 $FEEDS_CONF 内容："
cat "$FEEDS_CONF"

if ! grep -q "openwrt-daede" "$FEEDS_CONF"; then
  echo "src-git daede https://github.com/kenzok8/openwrt-daede.git" >> "$FEEDS_CONF"
fi

# gSpotx2f 维护的三个状态插件：CPU 负载 / 温度 / 频率管理，
# 纯 Lua/JS 写的，没有 C 代码要编译，接成 feed 风险很低。
if ! grep -q "luci-app-cpu-status\b" "$FEEDS_CONF"; then
  echo "src-git cpu-status https://github.com/gSpotx2f/luci-app-cpu-status.git" >> "$FEEDS_CONF"
fi
if ! grep -q "luci-app-temp-status" "$FEEDS_CONF"; then
  echo "src-git temp-status https://github.com/gSpotx2f/luci-app-temp-status.git" >> "$FEEDS_CONF"
fi
if ! grep -q "luci-app-cpu-perf" "$FEEDS_CONF"; then
  echo "src-git cpu-perf https://github.com/gSpotx2f/luci-app-cpu-perf.git" >> "$FEEDS_CONF"
fi

echo "==> 追加后 $FEEDS_CONF 内容："
cat "$FEEDS_CONF"

# ---------------------------------------------------------
# 备用：如果实测发现官方 golang 包版本编译 dae 报错，取消下面
# 这段注释，换成社区维护的更新版 golang feed。
# 参考：https://github.com/sbwml/packages_lang_golang
# ---------------------------------------------------------
# echo "src-git golang https://github.com/sbwml/packages_lang_golang.git;24.x" >> "$FEEDS_CONF"

# 注意：openwrt-sonic-fullcone 补丁的应用已经挪到
# scripts/diy-fullcone-luci.sh 里，在 feeds update/install 之后
# 才执行——因为它同时要改主源码树（这里没问题）和
# feeds/luci/applications/luci-app-firewall/（这个只有 feeds
# 装完之后才存在），放在这里执行会导致 LuCI 那部分改动因为
# 目标目录还不存在而被静默跳过（已实测确认：后台 fullcone 功能
# 生效了，但网页界面没变化，就是这个时序问题导致的）。
