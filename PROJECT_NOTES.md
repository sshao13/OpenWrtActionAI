# 项目说明

基于官方 OpenWrt 25.12 x86-64 全源码编译，接入 daed（eBPF 透明代理）、
内核原生 BTF、BBR 拥塞控制、中文界面。另有一个独立的 `dev-fullcone`
实验分支，用于验证全锥形 NAT。

## 已确认可用的功能

- ✅ **daed / daed-e / luci-app-daede**：走 [kenzok8/openwrt-daede](https://github.com/kenzok8/openwrt-daede)
  源码 feed，编译成功并已在真实固件里确认存在
- ✅ **内核原生 BTF**（`CONFIG_KERNEL_DEBUG_INFO_BTF`）：daed 依赖的
  eBPF CO-RE 特性需要它，全源码编译直接打开内核开关，不用额外装
  补丁包
- ✅ **BBR 拥塞控制**（`kmod-tcp-bbr`，是 BBRv1/v2，不是 BBRv3——
  BBRv3 目前没进 Linux 主线内核，装不了）
- ✅ **中文界面**：`CONFIG_LUCI_LANG_zh_Hans` + 对应的
  `luci-i18n-*-zh-cn` 系列包，覆盖 base/firewall/package-manager 等
  多个模块
- ✅ **`dev-fullcone` 分支**：接入 [openwrt-sonic-fullcone](https://github.com/mufeng05/openwrt-sonic-fullcone)，
  已实测确认后端（`nft list ruleset | grep fullcone` 能搜到规则）
  和 LuCI 网页界面（防火墙区域设置里的 Fullcone NAT 选项，含中文
  翻译）都生效

## ⚠️ 注意事项

- **不要用"值守式系统升级"（Attended Sysupgrade）来更新固件**。
  这个功能默认连官方构建服务，不认识我们额外接的 daed feed、
  打开的内核 BTF、`dev-fullcone` 分支的补丁。真去搜索更新，大概率
  会拿到一个不含这些自定义内容的"纯官方"固件，刷上去等于把自定义
  功能全部升没，而且不会有任何提示。已经从软件包清单里删除，如果
  是老固件升级上来的、还残留着这个包，建议手动卸载：
  ```
  apk del luci-app-attendedsysupgrade luci-i18n-attendedsysupgrade-zh-cn attendedsysupgrade-common
  ```
  以后升级固件，回 GitHub Actions 重新触发一次构建、手动下载刷机。

- **`kmod-nft-fullcone`（NFT 全锥形 NAT 的独立内核模块）和 BCM 全锥形
  NAT 方案，主线（main）分支不装**：官方仓库压根没有这个包，
  硬写配置也是空占一行没有效果；BCM 方案是 Broadcom 硬件专用，
  x86-64 天生用不了。全锥形 NAT 相关功能只在 `dev-fullcone`
  这个独立分支里，通过打补丁的方式实现，跟主线完全隔离。

- **`dev-fullcone` 分支本身是实验性质**，依赖的
  openwrt-sonic-fullcone 项目自己写明"目前仅测试了 x86 平台的
  snapshot 版本"，不保证长期跟 openwrt-25.12 分支保持兼容。上游
  一旦有大版本更新，这个分支大概率需要重新排查兼容性问题，不是
  装一次就永远稳定。

- **中文语言包依赖的是别名机制**（`zh_Hans` 而不是原始翻译目录名
  `zh-cn`），如果以后 OpenWrt 上游改了这套命名规则，中文界面可能
  会重新消失，需要重新排查。

## 🙏 感谢

- [kenzok8](https://github.com/kenzok8)：`openwrt-daede`（daed 源码
  feed）、`vmlinux-btf`（BTF 补丁包，虽然最终这个项目走的是全源码
  编译打开原生 BTF，没有直接用到这个包，但排查过程中参考了它的
  技术思路）
- [QiuSimons](https://github.com/QiuSimons)：`luci-app-daed` 项目
  README 里给出的完整 eBPF/BTF 编译配置，直接解决了
  `CONFIG_BPF_TOOLCHAIN_HOST` 这个关键坑
- [mufeng05](https://github.com/mufeng05)：`openwrt-sonic-fullcone`，
  `dev-fullcone` 分支的全锥形 NAT 实现来源
- OpenWrt / LuCI 官方项目及其社区文档

---

本项目由 Claude 协助完成。
