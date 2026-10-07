# 来源、许可与修改声明

本数据包包含白霜派生词库、本项目自写Lua及上游组件，组合分发按根 `LICENSE` 中的 GPL-3.0 提供。Apache-2.0、MIT、Unicode 来源的声明继续保留在 `licenses/`；不能将整包只标为 MIT。

- 本项目自写配置和Lua保留MIT署名与条款，见 `licenses/MIT.txt`。
- 极点86五笔字表来源：[KyleBing/rime-wubi86-jidian](https://github.com/KyleBing/rime-wubi86-jidian/tree/513954b197907cb6c5892e6ca2c548c164f8caac)，[上游 Apache-2.0](https://github.com/KyleBing/rime-wubi86-jidian/blob/513954b197907cb6c5892e6ca2c548c164f8caac/LICENSE)。
- 白霜词组、英文、拼音数据与中文词频参考：[gaboolic/rime-frost](https://github.com/gaboolic/rime-frost/tree/4a5457badafbdc733b09a350aeb3e8b076f025d8)，[上游 GPL-3.0](https://github.com/gaboolic/rime-frost/blob/4a5457badafbdc733b09a350aeb3e8b076f025d8/LICENSE)。
- 金额与农历Lua来自 [Mintimate/oh-my-rime](https://github.com/Mintimate/oh-my-rime)，随数据包提供并更名以避免冲突。金额文件保留 [yanhuacuo/98wubi-tables](https://github.com/yanhuacuo/98wubi-tables) 来源，农历文件保留 [boomker/rime-fast-xhup](https://github.com/boomker/rime-fast-xhup) 来源。最初导入时的oh-my-rime提交未确认，不编造固定版本。日期时间、计算器、无候选提交Lua为本项目自写组件。
- 规范字审核依据：[Unicode 16.0 Unihan](https://www.unicode.org/Public/16.0.0/ucd/Unihan.zip) 的 kTGH 字段，名单核对参考 [general_standard_chinese](https://github.com/ben-hua/general_standard_chinese)。Unicode许可保留在 `licenses/Unicode.txt`。
- 英文审核排名：[first20hours/google-10000-english/20k.txt](https://github.com/first20hours/google-10000-english/blob/cb727a8ef0932d7d9519e8fe3973ad0a9600170d/20k.txt)，原始字节摘要和词频尺度见源码 `reports/frequency_sources.json`。

**版本依据**：定稿数据在 `data/`，当前记录摘要在源码 `tests/expected.json`，清理前后摘要与原记录在 `reports/cleanup_summary.json`、`reports/removed.tsv`。极点、白霜和英文固定版本用于核验、补码或审核参考，不表示所有记录都在本轮由这些版本重新生成。早期整理曾使用未分发的《现代汉语常用词表》作为排序参考，本版不包含该版权词表，也不要求使用者下载它。来源、许可和维护证据均随本项目保存。

**本次修改（2026-10-06）**：沿用此前审核的简体日常词库；基础字词独立保存，额外词组与英文合并为扩展字典；删除无内容的尾部 stem 列分隔符，保留有效 stem与保留记录的顺序、编码及权重。另按普通内地用户及本科工科用途审核清理1234条主记录及21条反查；删除理由和原记录保存在源码仓库reports/removed.tsv。恢复纯净与全功能两个方案，纯净复用通用配置，仅加载个人表和基础字词，全功能额外加载扩展字典；将反查设为两个方案的编译依赖。保留空个人表和必要 Lua，平台皮肤单独可选。词频只作分来源、分词长的相对排名证据，不混用原始数值；缺失未知，语义分类是本项目用途判断。原个人词条不公开，原始上游基线未改。

YAML 字典、方案和 Lua 都是可编辑源文件，数据包随附完整许可。没有二进制词库、私人数据库或运行缓存。后续再分发请保留许可、来源和修改声明。
