#!/bin/bash
# =========================================================
# diy-fullcone-luci.sh
# 【开发分支专用 / 实验性】
#
# 在 ./scripts/feeds update -a && ./scripts/feeds install -a
# 跑完之后执行 —— 这是关键，必须在这个时间点才行。
#
# 之前把这一步放在 feeds 装之前，结果是：主源码树自带的那几个
# 包（firewall / firewall4 / nftables / libnftnl / iptables）
# 补丁能生效（已实测确认，SSH 上 `nft list ruleset | grep
# fullcone` 能搜到规则），但 LuCI 网页界面那部分没有变化——
# 因为 feeds/luci/applications/luci-app-firewall/ 这个目录
# 只有 feeds 装完之后才存在，装之前脚本想改这个目录下的文件，
# 目标压根不存在，改动被静默跳过，不会报错，所以之前一直
# 没发现。这次挪到 feeds 装完之后执行，同时满足两边的前提
# 条件，理论上这次网页界面也能正确改到。
#
# 项目地址：https://github.com/mufeng05/openwrt-sonic-fullcone
#
# 风险提示（跟之前一样，没有变化）：
#   - 该项目明确写着"目前仅测试了 x86 平台的 snapshot 版本"，
#     不保证跟我们用的 openwrt-25.12 分支 100% 兼容
#   - 主源码树部分的补丁这次是重复执行（第二次跑在同一份
#     已经 clone 好的源码树上）——如果安装脚本本身没有做
#     "已经打过的补丁就跳过"这种幂等处理，重复跑同一个补丁
#     可能会报错。如果这次运行在这一步报错，大概率就是这个
#     原因，需要看看能不能只单独摘出它处理 LuCI 那部分的逻辑
#     单独跑，而不是整个脚本重跑一遍。
# =========================================================

set -eu

cd "$(pwd)"   # 这里的 $PWD 就是 /builder/openwrt（build.yml 里已经 cd 过）

echo "==> 【实验性】在 feeds 装完之后，重新应用 openwrt-sonic-fullcone 安装脚本"
echo "    （这次主要是为了让它能正确改到 feeds/luci/applications/luci-app-firewall/）"

SONIC_SCRIPT_URL="https://raw.githubusercontent.com/mufeng05/openwrt-sonic-fullcone/master/add_sonic_fullcone.sh"
SONIC_SCRIPT="/tmp/add_sonic_fullcone.sh"

if curl -fsSL "$SONIC_SCRIPT_URL" -o "$SONIC_SCRIPT"; then
  chmod +x "$SONIC_SCRIPT"
  echo "==> 下载成功，开始应用（如果主源码树部分报"已经打过"之类的错，说明这个脚本
      不是幂等的，需要单独想办法只跑 LuCI 那部分，把完整报错发出来看）"
  bash "$SONIC_SCRIPT" || echo "::warning::安装脚本这次执行有非零退出码，请看上面的完整输出判断是部分成功还是彻底失败"
else
  echo "::error::下载 sonic-fullcone 安装脚本失败"
  exit 1
fi

echo ""
echo "==== 确认 luci-app-firewall 里有没有真的出现 fullcone 相关改动 ===="
if [ -d feeds/luci/applications/luci-app-firewall ]; then
  echo "  luci-app-firewall 目录存在，搜索 fullcone 关键字："
  grep -rl "fullcone" feeds/luci/applications/luci-app-firewall 2>/dev/null || echo "  没搜到，说明这次还是没改到"
else
  echo "  feeds/luci/applications/luci-app-firewall 目录不存在！"
  echo "  说明 feeds/luci 这个 feed 本身可能没装上，需要往前查 feeds install 那一步的日志"
fi
