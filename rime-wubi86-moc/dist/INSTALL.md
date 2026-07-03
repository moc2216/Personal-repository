# moc 86 五笔方案 — 部署指南

纯简 86 五笔，双方案（simp 纯净 / simp_plus 丰富）+ 中英混输 + 拼音反查 + 玫枫皮肤。

## 一键部署（项目根）

```bash
bash install.sh
```

清空 `~/Library/Rime` → 全量拷贝 dist → 自动编译字典（含反查 prism）→ 切换到 `moc_wubi86_simp` 或 `moc_wubi86_simp_plus` 即可。

⚠ 手填的 `moc_wubi86_user.dict.yaml` 会被清空重置，需保留先备份。

## 文件清单

| 文件 | 作用 |
|---|---|
| `moc_wubi86_core.dict.yaml` | 极点核心 字+词（简体+去三级+weight校准） |
| `moc_wubi86_frost_words.dict.yaml` | 白霜词组（simp_plus） |
| `moc_english_words.dict.yaml` | 英文词（simp_plus 混输） |
| `moc_reverse.dict.yaml` | 拼音反查字典（反引号+拼音出字+五笔编码） |
| `moc_wubi86_simp.schema/dict.yaml` | 简单：纯 core |
| `moc_wubi86_simp_plus.schema/dict.yaml` | 丰富：core + frost + 英文 |
| `moc_wubi86_user.dict.yaml` | 个人词条空壳（手填） |
| `lua/*.lua` | 日期/计算器/金额/农历/无候选上屏 |
| `squirrel.custom.yaml` | 玫枫皮肤 + app 默认英文（全局） |
| `default.custom.yaml` | 方案注册 + 键位（分号选2/方括号翻页/Shift切中英） |

## 手填个人词条

编辑 `~/Library/Rime/moc_wubi86_user.dict.yaml`，格式 `文本<Tab>编码<Tab>权重<Tab>`。

## 说明
- `squirrel.custom.yaml` 是 Squirrel 前端全局配置，影响所有方案（不止 moc）。
- 字典不学习（enable_user_dict 等 false）。
