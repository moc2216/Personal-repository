# 助手来源、许可与修改

本助手与随附数据按GPL-3.0分发，完整条款在LICENSE。App对应源码、资源与构建脚本在同版本源码仓库的wubi-code-assistant/Source，不依赖私人材料。

- 单字表主体来源：[极点86五笔](https://github.com/KyleBing/rime-wubi86-jidian/blob/513954b197907cb6c5892e6ca2c548c164f8caac/wubi86_jidian.dict.yaml)，Apache-2.0。只提取6500个一级二级规范字，每字选最长码，等长采用上游较优排序项及编码字序确定；没有词组和运行时频率数据。
- 其中8个缺字编码沿用固定 [白霜版本](https://github.com/gaboolic/rime-frost/tree/4a5457badafbdc733b09a350aeb3e8b076f025d8) 的已核对补充，GPL-3.0：㤘、㧐、㧟、㸆、䁖、䏝、䥽、䦃；另3字𠳐、𥻗、𬉼沿用此前交叉核验记录，出处在tests/character-data.json。不是全Unicode字表。
- 字符范围来自Unicode16.0 Unihan的kTGH 2013:0001..6500字段，Unicode许可保留。
- 拆字图来自86wubi项目，原MIT署名Chengke及完整许可在Source/Resources/ThirdParty/86wubi-LICENSE.txt；保持原图，缺图不伪造。

2026-10-07修改：生成编码改为独立单字表和组词规则；基础、扩展、个人既有整词不再覆盖规则码。新增按最近选择方案的主字典引用查重，个人同词同码阻止、内置同词同码明确提示再确认；保留拆字说明、手动编码与权重、安全备份/原子写入/回滚和重新部署。保留关窗退出，构建通用macOS App。

参考Rime记录选择的上游实现：[librime Switcher](https://github.com/rime/librime/blob/f81c971f45209550c4daa5491226545072e19e2f/src/rime/switcher.cc)。比对读取持久化记录与已部署文件，无法完成时不当作零结果。上游来源与本地隔离运行相互核验。

Apache-2.0、Unicode、MIT条款随源码与App的ThirdParty目录保留，GPL完整条款随下载包提供。未分发真实用户词库、数据库或备份。
