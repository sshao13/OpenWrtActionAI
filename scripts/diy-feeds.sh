#!/bin/bash
# =========================================================
# diy-feeds.sh
# 在 ./scripts/feeds update 之前执行，往 feeds.conf.default
# 追加第三方 feed，并规避 CRLF/行末缺换行导致的语法报错。
# =========================================================

set -eu

cd /builder/openwrt

FEEDS_CONF="feeds.conf.default"

echo "==> 追加前 $FEEDS_CONF 内容（带行号）："
nl -ba "$FEEDS_CONF"

# 1. 清理可能存在的 Windows CRLF 回车符
sed -i 's/\r$//' "$FEEDS_CONF"

# 2. 仅当文件非空且最后一个字节不是换行符时，补一个换行，避免行粘连
if [ -s "$FEEDS_CONF" ] && [ "$(tail -c 1 "$FEEDS_CONF" | od -An -tx1 | tr -d ' \n')" != "0a" ]; then
  printf '\n' >> "$FEEDS_CONF"
fi

add_feed() {
  local name="$1"
  local url="$2"
  local pattern="$3"

  if ! grep -qE "$pattern" "$FEEDS_CONF"; then
    printf 'src-git %s %s\n' "$name" "$url" >> "$FEEDS_CONF"
  fi
}

# dae / daed
add_feed "daede" "https://github.com/kenzok8/openwrt-daede.git" "openwrt-daede"

# gSpotx2f 状态插件（CPU 负载 / 温度 / 频率管理）
add_feed "cpu-status" "https://github.com/gSpotx2f/luci-app-cpu-status.git" "luci-app-cpu-status([[:space:]]|$)"
add_feed "temp-status" "https://github.com/gSpotx2f/luci-app-temp-status" "luci-app-temp-status"
add_feed "cpu-perf" "https://github.com/gSpotx2f/luci-app-cpu-perf.git" "luci-app-cpu-perf"

# einat-ebpf 全锥形 NAT（依赖 BPF + BTF）
add_feed "einat_ebpf" "https://github.com/muink/openwrt-einat-ebpf.git" "openwrt-einat-ebpf"
add_feed "luci_app_einat" "https://github.com/muink/luci-app-einat.git" "luci-app-einat"

# honk eBPF 透明代理
add_feed "honk" "https://github.com/kenzok8/openwrt-honk.git" "openwrt-honk"

echo "==> 追加后 $FEEDS_CONF 内容（带行号）："
nl -ba "$FEEDS_CONF"
