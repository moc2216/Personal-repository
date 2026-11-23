# Personal-repository

个人使用的 Rime 五笔86 方案，以及配套的 macOS 编码助手。两者可分开使用。

## 内容

| 目录 | 说明 | 平台 |
| --- | --- | --- |
| [rime-wubi86-moc](rime-wubi86-moc/README.md) | 精简五笔86数据，纯净／全功能双模式、补全、拼音找字与日常工具 | macOS、Windows、Linux 的 Rime 前端 |
| [wubi-code-assistant](wubi-code-assistant/README.md) | 按五笔86规则生成编码、查重后写入个人词库的 App | macOS 13 及以上 |
| [wechat-covers](wechat-covers/README.md) | 「就慢慢攒」公众号封面生成：固定底图 + 动态槽位 | macOS（Python + Pillow） |

## 快速开始

**输入法数据**：从 [Releases](https://github.com/moc2216/Personal-repository/releases) 下载对应数据包，解压后把 `data/` 内容复制到 Rime 用户资料夹并重新部署。已有 `default.custom.yaml`、`squirrel.custom.yaml` 或个人词库时先保留合并，具体步骤见 [数据说明](rime-wubi86-moc/README.md)。

**编码助手**：下载助手 ZIP，解压运行 `Wubi Code Assistant.app`。它固定读写 `~/Library/Rime/moc_wubi86_user.dict.yaml`，使用前先部署输入法数据。详见 [助手说明](wubi-code-assistant/README.md)。

**封面生成**：进入 wechat-covers 目录运行 `python3 make_cover.py`，文案写在 `slot.txt`；输出在 `out_slot/`。详见 [项目说明](wechat-covers/README.md)。

## 版本

- Rime 数据：2026.10.15.1（方案 2026.10.15，字典 2026.10.09）
- 编码助手：1.3.3（build 7）

## 许可

GPL-3.0。第三方数据来源与许可见各目录的 `NOTICE.md`；数据目录另见 `licenses/`。

