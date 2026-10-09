# moc-rime-wubi86

面向普通内地用户的五笔86日常输入方案，以及添加个人词条的编码助手。两部分可分别使用。

Rime数据以 [极点86](https://github.com/KyleBing/rime-wubi86-jidian) 基础字词为底，配合 [白霜](https://github.com/gaboolic/rime-frost) 词组、英文和拼音数据，以及 [oh-my-rime](https://github.com/Mintimate/oh-my-rime) 来源的金额、农历工具。本项目在此基础上审核简体日常用字和冷门词，保留纯净／全功能两个入口、五笔补全和拼音反查，并提供独立的个人词库编码助手。

**`moc-rime-wubi86/` 是唯一项目入口。** 输入法数据、编码助手、来源说明、许可和维护资料都保存在这个文件夹内。

精简的对象是部署数据、重复词库和运行依赖。功能介绍、上游贡献与发展记录保留在项目中，方便使用者理解和后续维护。

| 内容 | 平台 | 用途 |
| --- | --- | --- |
| [Rime五笔数据](rime-wubi86-moc/README.md) | macOS、Windows、Linux的Rime前端 | 直接复制部署，提供纯净/全功能、补全提示和拼音反查 |
| [五笔编码助手](wubi-code-assistant/README.md) | macOS 13及以上 | 按五笔86规则生成编码，查重并确认后加入个人词库 |

## 下载

[Release下载页面](https://github.com/moc2216/Personal-repository/releases/tag/moc-rime-wubi86-2026.10.09)提供以下下载物，按平台和需要选择：

- [macOS 鼠须管数据ZIP](https://github.com/moc2216/Personal-repository/releases/download/moc-rime-wubi86-2026.10.09/moc-wubi86-macos-2026.10.09.zip)：包含输入法数据、默认蓝色遐想，optional另存两套完整外观。首次复制data内容后部署，以后换皮肤只替换外观文件并重新部署。
- [Windows／Linux 通用数据ZIP](https://github.com/moc2216/Personal-repository/releases/download/moc-rime-wubi86-2026.10.09/moc-wubi86-data-2026.10.09.zip)：包含双模式注册和 Control＋Shift＋0，沿用自己前端的外观。
- [macOS助手ZIP](https://github.com/moc2216/Personal-repository/releases/download/wubi-code-assistant-1.3.1/wubi-code-assistant-macos-1.3.1.zip)：Apple Silicon与Intel通用App，解压后运行。首次使用前按助手说明准备个人词库。

已有设置和个人词库须保留，复制前查看包内说明。

部署后，快捷键、每页候选数量和默认英文应用统一在 [moc_settings.yaml](rime-wubi86-moc/data/moc_settings.yaml) 修改，保存后重新部署即可。

本项目保存在Personal-repository的 `moc-rime-wubi86/` 目录。也可通过Code → Download ZIP获取源码，Rime数据在 `moc-rime-wubi86/rime-wubi86-moc/data/`；助手源码在 `moc-rime-wubi86/wubi-code-assistant/Source/`，需要macOS开发工具构建。macOS 用户希望一次复制包含外观时，使用上面的鼠须管数据ZIP。源码仓库不保存打包App、构建缓存或私人词库。

## 配合使用

先部署输入法方案，再用助手添加自己的专业词、姓名等。助手使用随App提供的固定单字编码表计算词组码；输入法基础、扩展词库的收录与排序不改变计算结果。添加前核对个人词库，以及最近选择方案实际加载的主词库；无法完成比对时明确提示。确认后备份、写入 `moc_wubi86_user.dict.yaml` 并请求鼠须管重新部署。

Rime数据同时提供首次使用的方案注册模板和空个人表模板；已有default.custom.yaml须保留并按数据说明合并两个模式。**已有同名个人词库时保留原文件，不用模板覆盖。** 关闭助手的最后一个窗口即退出程序。

## 功能与发展来源

- **日常五笔**：基础字词来自极点86；全功能模式补充白霜词组和英文，纯净模式保留基础范围。
- **不会完整编码时的辅助**：保留前缀补全与缺码提示；不会打单字时可用拼音反查，候选显示五笔编码。
- **常用工具**：日期、时间、计算、金额大写及农历转换。macOS 包附带两套外观，详见数据模块。
- **个人词库**：两种模式共用个人表；助手按规则计算编码，个人与方案词库只参与查重，确认后再添加。

项目沿着“上游数据整合 → 简体日常审核 → 双模式共用数据 → 冷门内容清理 → 与编码助手合并”发展。数据模块首页提供 [功能说明、来源分工和发展记录](rime-wubi86-moc/README.md#发展过程)，各来源的许可和固定核验版本见NOTICE。

当前源码提供定稿数据的检查、审核算法与打包工具，维护资料均在本项目内。当前流程不会从原始语料一键重建全部定稿数据。

## 范围与许可

数据支持三平台共用，当前实机验证为macOS；助手当前只提供macOS版，Intel构建未实机运行。助手内置6500个一级、二级规范字的编码，范围之外可手动填写；拆字图覆盖约3500常用字，缺图时显示完整码说明。

本仓库按GPL-3.0组合分发，具体来源、第三方Apache-2.0/MIT/Unicode许可分别保留在 [数据声明](rime-wubi86-moc/NOTICE.md) 和 [助手声明](wubi-code-assistant/NOTICE.md)。维护与验证见 [MAINTAIN.md](MAINTAIN.md)，交接见 [handoff.md](handoff.md)。
