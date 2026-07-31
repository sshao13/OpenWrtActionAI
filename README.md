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

## ⚠️ 请务必知道：这一版还没有实测跑通过

和之前 ImageBuilder 版本不一样，**这份全源码编译配置目前还没有经过真实
GitHub Actions 运行验证**——全源码编译一次要一两个小时，我没有条件在
给你之前先跑一遍确认，所以下面这几处是我基于公开资料尽量配对、但
没有 100% 把握的地方，第一次跑很可能会在这几个点上报错：

1. **`package/feeds/daede/` 下的真实包名**：`scripts/diy-config.sh` 里
   写的是 `CONFIG_PACKAGE_dae` `CONFIG_PACKAGE_daed`
   `CONFIG_PACKAGE_luci-app-daede`，这是根据 kenzok8/openwrt-daede
   项目介绍推断的，如果 `./scripts/feeds install` 之后这几个包名
   对不上，`make defconfig` 阶段会静默把它们清掉——**这就是为什么
   workflow 里加了一步"配置预检"**，会在真正开始编译（花一两个
   小时）之前先检查这几个包有没有真的留在 `.config` 里，第一时间
   告诉你缺了哪个，不用干等编译完才发现。
2. **Go 版本**：dae 需要 Go >= 1.24，官方 `feeds/packages` 自带的
   golang 版本可能不够新，编译时如果报 golang 相关错误，需要启用
   `diy-feeds.sh` 里注释掉的那一行，换成社区维护的更新版 golang feed。
3. **`kmod-nft-fullcone`**：这是第三方内核模块，官方 `openwrt/packages`
   feed 里本来就没有，配置预检那一步大概率会提示缺失，到时候需要
   再单独加一个提供这个包的 feed（之前 ImageBuilder 版本已经验证过
   官方源里确实没有这个包，这个结论在全源码编译下同样成立）。

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
