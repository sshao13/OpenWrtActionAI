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

# 防止原文件末尾没有换行符，导致下面第一次 >> 追加的内容跟原文件
# 最后一行粘在一起变成一行乱码（这就是上次 "Syntax error in
# feeds.conf.default, line 7" 的真正原因——不是内容写错了，是
# 两行内容被粘连成了一行，Kconfig 解析器认不出来）。
echo "" >> "$FEEDS_CONF"

if ! grep -q "openwrt-daede" "$FEEDS_CONF"; then
  echo "src-git daede https://github.com/kenzok8/openwrt-daede.git" >> "$FEEDS_CONF"
fi

# gSpotx2f 维护的三个状态插件：CPU 负载 / 温度 / 频率管理，
# 纯 Lua/JS 写的，没有 C 代码要编译，接成 feed 风险很低。

# einat-ebpf：纯 eBPF 实现的全锥形 NAT，不需要给 nftables/libnftnl
# 打补丁（跟 dev-fullcone 分支那套 sonic-fullcone 方案不是一回事，
# 风险低得多）。依赖内核 BPF+BTF 支持，我们前面为了 daed 已经
# 打开了 CONFIG_KERNEL_DEBUG_INFO_BTF + CONFIG_BPF_TOOLCHAIN_HOST，
# 正好现成能用，不用再额外解决一次。
# 项目地址：https://github.com/muink/openwrt-einat-ebpf
#           https://github.com/muink/luci-app-einat

# honk：dae 风格的 eBPF 透明代理（honk 核心 + Doona 网页界面 + luci-app-honk）。
# 核心和 Doona 都是预编译归档，编译时从 GitHub Releases 下载并校验，不需要 Rust 工具链。
# v2ray-geoip / v2ray-geosite 官方 packages feed 里就有，不需要再接 kenzok8/small。
if ! grep -q "openwrt-honk" "$FEEDS_CONF"; then
  echo "src-git honk https://github.com/kenzok8/openwrt-honk.git" >> "$FEEDS_CONF"
fi

# ---------------------------------------------------------
# 单包仓库（Makefile 直接在仓库根目录）：不能当 feed 用。
# feeds 只扫描子目录里的包，根目录就是包本身的仓库会被判成 "index missing"
# 整个跳过（实测 cpu_status/temp_status/cpu_perf/einat 全被跳过）。
# 正确做法是直接 clone 到 package/ 下，编译系统会递归扫描 package/。
# ---------------------------------------------------------
mkdir -p package/custom
clone_pkg() {
  local url="$1" dir="package/custom/$2"
  rm -rf "$dir"
  git clone --depth 1 "$url" "$dir"
}
clone_pkg https://github.com/gSpotx2f/luci-app-cpu-status.git luci-app-cpu-status
clone_pkg https://github.com/gSpotx2f/luci-app-temp-status.git luci-app-temp-status
clone_pkg https://github.com/gSpotx2f/luci-app-cpu-perf.git luci-app-cpu-perf
clone_pkg https://github.com/muink/openwrt-einat-ebpf.git openwrt-einat-ebpf
clone_pkg https://github.com/muink/luci-app-einat.git luci-app-einat
echo "==> package/custom 内容："
ls package/custom

echo "==> 追加后 $FEEDS_CONF 内容："
cat "$FEEDS_CONF"

# Go 版本问题（dae 要求 Go>=1.27）已在 build.yml 的"升级 Go 工具链"步骤处理，
# 这里不需要再改 feeds。
