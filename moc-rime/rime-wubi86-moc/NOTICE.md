# 来源、许可与修改声明

本数据包包含白霜派生词库和 Lua，组合分发按根 `LICENSE` 中的 GPL-3.0 提供。Apache-2.0、MIT、Unicode 来源的声明继续保留在 `licenses/`；不能将整包只标为 MIT。

- 原 moc 数据：[Personal-repository/rime-wubi86-moc](https://github.com/moc2216/Personal-repository/tree/a21d6894e03ea01c5af04fbfa1248e552b9d8132/rime-wubi86-moc)，原项目 MIT 声明保留。
- 极点86五笔字表来源：[KyleBing/rime-wubi86-jidian](https://github.com/KyleBing/rime-wubi86-jidian/tree/513954b197907cb6c5892e6ca2c548c164f8caac)，[上游 Apache-2.0](https://github.com/KyleBing/rime-wubi86-jidian/blob/513954b197907cb6c5892e6ca2c548c164f8caac/LICENSE)。
- 白霜词组、英文与相关组件：[gaboolic/rime-frost](https://github.com/gaboolic/rime-frost/tree/4a5457badafbdc733b09a350aeb3e8b076f025d8)，[上游 GPL-3.0](https://github.com/gaboolic/rime-frost/blob/4a5457badafbdc733b09a350aeb3e8b076f025d8/LICENSE)。Lua 内保留其进一步来源引用。
- 规范字审核依据：[Unicode 16.0 Unihan](https://www.unicode.org/Public/16.0.0/ucd/Unihan.zip) 的 kTGH 字段，名单核对参考 [general_standard_chinese](https://github.com/ben-hua/general_standard_chinese)。Unicode许可保留在 `licenses/Unicode.txt`。

**本次修改（2026-10-06）**：沿用此前审核的简体日常词库；基础字词独立保存，额外词组与英文合并为扩展字典；删除无内容的尾部 stem 列分隔符，保留有效 stem与保留记录的顺序、编码及权重。另按普通内地用户及本科工科用途审核清理1234条主记录及21条反查；删除理由和原记录保存在源码仓库reports/removed.tsv。恢复纯净与全功能两个方案，纯净复用通用配置，仅加载个人表和基础字词，全功能额外加载扩展字典；将反查设为两个方案的编译依赖。保留空个人表和必要 Lua，平台皮肤单独可选。词频只作分来源、分词长的相对排名证据，不混用原始数值；缺失未知，语义分类是本项目用途判断。原个人词条不公开，原始上游基线未改。

YAML 字典、方案和 Lua 都是可编辑源文件，数据包随附完整许可。没有二进制词库、私人数据库或运行缓存。后续再分发请保留许可、来源和修改声明。
