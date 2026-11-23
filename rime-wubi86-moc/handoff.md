# 数据交接 · 2026-10-09

目标：已有Rime直接复制部署的简体五笔86数据；保留纯净/全功能、补全、反查和个人优先。

当前版本2026.10.09。data17文件；通用ZIP16数据+6说明共22，macOS17数据+optional两皮肤+6说明共25。常用设置唯一入口moc_settings.yaml，默认Control＋Shift＋0、每页6项和英文应用。data蓝色，optional蓝色和玫枫。

本轮：顿号直输、金额两大写、删除/fh、三列个人模板。主词库、反查记录及权重和有效stem未动。27项自动检查及隔离部署、集中设置、皮肤往返、工具和临时个人优先通过，见tests/native-20261009.json；历史证据保持原日期。

补全原因、实验和取舍见reports/completion-ranking.md，正式排序未改。trw中我们纯净第8、全功能第31；trwu均首选。不能将检查文案修改当成首屏排序修复。

卡点无。安全密码框默认英文需人工确认；Windows/Linux未实测。下一步按具体反馈维护，补全重排需先验证性能。

坑：标点先include再patch，列表和commit直接合并会部署失败。两套皮肤时间差2秒，蓝色相同副本同时间。已有default、squirrel、moc_settings及个人表保留合并；不写真实Rime，不恢复被删个人表。命令见MAINTAIN，Python只用于维护。
