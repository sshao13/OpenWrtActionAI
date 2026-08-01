# OpenWrt-25.12-x86-64-FullSource（精简版）

参照 [kenzok8/openwrt-daede](https://github.com/kenzok8/openwrt-daede) 提供的源码 feed，
用**官方 OpenWrt 25.12 全源码编译**（不是 ImageBuilder）构建 x86-64 固件，
目标是让 daed 不用再靠额外补丁包解决 BTF 问题——内核是自己编的，
直接在 `.config` 里开 `CONFIG_KERNEL_DEBUG_INFO_BTF=y` 就行。

## 和之前 ImageBuilder 版本的关键区别

| | ImageBuilder 版本 | 这个全源码版本 |
|---|---|---|
| 内核 BTF | 装第三方 `vmlinux-btf` 补丁包（还没验证成功） | 直接编译内核时打开开关，原生支持 |
| daed 安装方式 | 下载预编译 `.apk`，绕 apk 签名机制 | 当成正经 feed 源码编译 |
| 单次构建耗时 | 几分钟 | 一到两小时 |
| 全锥形 NAT / O3-LTO | 做不到（ImageBuilder 硬限制） | 理论上可以，但这份精简版没配 |

## 目前的实测进度

已经完整跑通"配置预检"（不是真正编译，是编译前几秒钟就能确认的
阶段），以下全部确认没问题：

- ✅ `dae` / `daed` / `luci-app-daede`（`kenzok8/openwrt-daede` 这个
  源码 feed 接进来没问题）
- ✅ 内核原生 BTF（`CONFIG_KERNEL_DEBUG_INFO` + `CONFIG_KERNEL_DEBUG_INFO_BTF`，
  依赖编译环境装 `dwarves` 提供 `pahole`，已在 `build.yml` 里装好）
- ✅ eBPF 编译工具链（`CONFIG_BPF_TOOLCHAIN_HOST`，用宿主机的 clang，
  不用 OpenWrt 自己再编一份）
- ✅ `kmod-tcp-bbr`
- ✅ 中文语言包（`CONFIG_LUCI_LANG_zh-cn` + `CONFIG_PACKAGE_luci-i18n-base-zh-cn`，
  这俩是一对，光装后者不够，前者是它依赖的上层"Translations"总开关）

而且已经有一次**完整编译成功**的记录，manifest 里确认 `dae`、`daed`、
`luci-app-daede` 都真的装进了固件（那次中文语言包还没修，所以固件
是英文界面；语言包的问题定位并修好之后还没有跑一次完整编译验证，
理论上应该没问题，但还是建议你实际跑一次确认）。

## 明确不做的：全锥形 NAT

`kmod-nft-fullcone` 对应的 [nft-fullcone](https://github.com/fullcone-nat-nftables/nft-fullcone)
项目已经**归档不再维护**，而且它不是装一个内核模块就行——需要同时
给 `nftables` 和 `libnftnl` 这两个网络核心组件打补丁才能用。风险是
可能把防火墙/NAT 功能编坏，不是"装不上就少个功能"这么简单，所以
已经决定**暂缓，不在这份精简版里做**。想要的话建议以后单独开一个
分支单独折腾，不要和这份主线混在一起，免得一个高风险改动拖累了
已经跑通的部分。

## 使用方法

1. Fork 本仓库，保持目录结构：

```
.
├── .github/workflows/build.yml
├── configs/x86_64.config      # 目标平台选择
└── scripts/
    ├── diy-feeds.sh           # feeds update 之前：追加第三方 feed
    └── diy-config.sh          # make defconfig 之前：追加插件开关
```

2. 手动触发一次 Actions（或等每周六的定时任务）。
3. 看"配置预检"这一步的输出确认关键开关都是 `[OK]`，然后等真正的
   编译（一到两小时）跑完。
4. 编译成功后固件在 Actions 的 Artifact 和 Release 里。

## 后续要加更多插件

参照 `scripts/diy-config.sh` 里的格式，去 OpenWrt 官方源码或对应
feed 里确认真实包名后追加 `CONFIG_PACKAGE_xxx=y` 就行；如果插件
来自 openwrt 官方 `feeds/packages` `feeds/luci` 之外的 feed，需要
先在 `scripts/diy-feeds.sh` 里加一行 `src-git`。
