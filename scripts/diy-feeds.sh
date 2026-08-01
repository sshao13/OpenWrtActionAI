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

echo "==> 追加后 $FEEDS_CONF 内容："
cat "$FEEDS_CONF"

# ---------------------------------------------------------
# 备用：如果实测发现官方 golang 包版本编译 dae 报错，取消下面
# 这段注释，换成社区维护的更新版 golang feed。
# 参考：https://github.com/sbwml/packages_lang_golang
# ---------------------------------------------------------
# echo "src-git golang https://github.com/sbwml/packages_lang_golang.git;24.x" >> "$FEEDS_CONF"

# =========================================================
# 【开发分支专用 / 实验性】全锥形 NAT —— openwrt-sonic-fullcone
#
# 这个分支专门用来单独验证这一个高风险改动，跟主线（main）
# 完全隔离。原理上比 nft-fullcone 那条路线更安全一些：不需要
# 新增内核模块，也不需要给 nftables/libnftnl 打补丁支持新语法，
# 是直接把 fullcone 逻辑编进 OpenWrt 本来就会编译的
# nft_masq.ko / xt_MASQUERADE.ko 里。
#
# 但依然是给源码树打补丁，依然有风险：
#   - 该项目明确写着"目前仅测试了 x86 平台的 snapshot 版本"，
#     不保证跟我们用的 openwrt-25.12 分支 100%兼容
#   - 补丁应用失败/内核版本对不上，可能导致后面 feeds/编译
#     直接报错（这种情况下重新触发一次干净的 workflow 就行，
#     不会污染其它分支）
#
# 项目地址：https://github.com/mufeng05/openwrt-sonic-fullcone
# =========================================================
echo ""
echo "==> 【实验性】应用 openwrt-sonic-fullcone 补丁"
SONIC_SCRIPT_URL="https://raw.githubusercontent.com/mufeng05/openwrt-sonic-fullcone/master/add_sonic_fullcone.sh"
SONIC_SCRIPT="/tmp/add_sonic_fullcone.sh"

if curl -fsSL "$SONIC_SCRIPT_URL" -o "$SONIC_SCRIPT"; then
  chmod +x "$SONIC_SCRIPT"
  echo "==> 下载成功，开始应用补丁（这一步会自动检测内核版本、复制补丁到对应位置）"
  bash "$SONIC_SCRIPT"
  echo "==> sonic-fullcone 补丁应用完成"
else
  echo "::error::下载 sonic-fullcone 安装脚本失败，这条实验性功能这次跑不了"
  exit 1
fi
