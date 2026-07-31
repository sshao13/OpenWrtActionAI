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

第一次实跑（配置预检阶段）已经确认：

- ✅ `CONFIG_PACKAGE_dae`、`CONFIG_PACKAGE_daed`、`CONFIG_PACKAGE_luci-app-daede`
  包名是对的，`kenzok8/openwrt-daede` 这个 feed 接进来没问题
- ✅ `CONFIG_PACKAGE_kmod-tcp-bbr` 没问题
- ❌ `CONFIG_KERNEL_DEBUG_INFO_BTF` 缺失——**已定位原因**：这个内核选项
  依赖编译环境里有 `pahole`（由 `dwarves` 这个 apt 包提供），CI 环境
  之前没装，导致 `make defconfig` 阶段被静默清掉。已经在
  `.github/workflows/build.yml` 里加上 `dwarves`，但这个修复本身
  还没有实际跑一次验证过。

还没验证过的地方：

1. Go 版本是否够新（如果 dae 编译阶段报 golang 相关错误，需要启用
   `diy-feeds.sh` 里注释掉的社区 golang feed）
2. `kmod-nft-fullcone`——官方 feed 里没有，还没接第三方源，大概率
   还是会在配置预检阶段显示缺失（不影响其它包，只是这个功能装不上，
   之前 ImageBuilder 版本已经验证过官方源确实没有这个包）
3. 真正完整编译能不能跑通（目前只跑到配置预检这一步，还没进入
   一两个小时的正式编译阶段）

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
3. **重点看"配置预检"这一步的输出**——这一步只要几秒钟，会告诉你
   `daed`、BTF、BBR 这几个关键开关有没有真的生效。如果有 `[缺失]`，
   不用等后面一两个小时的编译，直接把这一步的日志发我，我们照
   之前处理 ImageBuilder 版本的节奏，一个个排查解决。
4. 编译成功后固件在 Actions 的 Artifact 和 Release 里。

## 后续要加更多插件

参照 `scripts/diy-config.sh` 里的格式，去 OpenWrt 官方源码或对应
feed 里确认真实包名后追加 `CONFIG_PACKAGE_xxx=y` 就行；如果插件
来自 openwrt 官方 `feeds/packages` `feeds/luci` 之外的 feed，需要
先在 `scripts/diy-feeds.sh` 里加一行 `src-git`。
