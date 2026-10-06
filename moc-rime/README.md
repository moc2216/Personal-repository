# moc-rime

面向普通内地用户的五笔86日常输入方案，以及添加个人词条的编码助手。两部分可分别使用。

| 内容 | 平台 | 用途 |
| --- | --- | --- |
| [Rime五笔数据](rime-wubi86-moc/README.md) | macOS、Windows、Linux的Rime前端 | 直接复制部署，提供纯净/全功能、补全提示和拼音反查 |
| [五笔编码助手](wubi-code-assistant/README.md) | macOS 13及以上 | 按五笔86规则生成编码，查重并确认后加入个人词库 |

## 下载

[Release下载页面](https://github.com/moc2216/Personal-repository/releases/tag/moc-rime-2026.10.07)分别提供两个下载物，按需要选择：

- [Rime数据ZIP](https://github.com/moc2216/Personal-repository/releases/download/moc-rime-2026.10.07/moc-wubi86-data-2026.10.06.zip)：输入法数据，解压后按其README复制data、注册方案并重新部署。
- [macOS助手ZIP](https://github.com/moc2216/Personal-repository/releases/download/moc-rime-2026.10.07/wubi-code-assistant-macos-1.2.zip)：Apple Silicon与Intel通用App，解压后运行。首次使用前按助手说明准备个人词库。

本项目保存在Personal-repository的 `moc-rime/` 目录。也可通过Code → Download ZIP获取源码，Rime数据在 `moc-rime/rime-wubi86-moc/data/`；助手源码在 `moc-rime/wubi-code-assistant/Source/`，需要macOS开发工具构建。源码仓库不保存打包App、构建缓存或私人词库。

## 配合使用

先部署输入法方案，再用助手添加自己的专业词、姓名等。助手使用随App提供的固定单字编码表计算词组码；输入法基础、扩展词库的收录与排序不改变计算结果。添加前核对个人词库，以及最近选择方案实际加载的主词库；无法完成比对时明确提示。确认后备份、写入 `moc_wubi86_user.dict.yaml` 并请求鼠须管重新部署。

Rime数据包含空个人表模板。**已有同名个人词库时保留原文件，不用模板覆盖。** 关闭助手的最后一个窗口即退出程序。

## 范围与许可

数据支持三平台共用，当前实机验证为macOS；助手当前只提供macOS版，Intel构建未实机运行。助手内置6500个一级、二级规范字的编码，范围之外可手动填写；拆字图覆盖约3500常用字，缺图时显示完整码说明。

本仓库按GPL-3.0组合分发，具体来源、第三方Apache-2.0/MIT/Unicode许可分别保留在 [数据声明](rime-wubi86-moc/NOTICE.md) 和 [助手声明](wubi-code-assistant/NOTICE.md)。维护与验证见 [MAINTAIN.md](MAINTAIN.md)，交接见 [handoff.md](handoff.md)。
