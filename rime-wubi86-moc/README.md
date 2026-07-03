# rime-wubi86-moc

个人 86 五笔 Rime 输入法方案，从 3 个上游仓库从头生成，纯简体中文，双方案（纯净/丰富）+ 中英混输 + 拼音反查。日常使用见 [USAGE.md](USAGE.md)。

## 特性

- **纯简五笔**：极点 core（字+词）+ 白霜词组，去繁体/异体、去生僻字（通用规范汉字表三级字默认删）
- **中英混输**：英文按 google 频率 top8000 精选，打英文拼写直接出英文候选，中文优先、英文靠后
- **词频校准（RRF 双信号）**：知乎/维基频加权融合 + 极点原表经验，按编码内 RRF 排名融合校准 weight；一/二级简码从极点原表动态提取保护。候选顺序反映实际打字频率，修多源 weight scale 不一致致的乱序
- **工具齐全**：日期 `/rq`、时间 `/sj`、计算器 `/calc1+2`、金额大写 `R123`、农历 `N20240115`
- **无候选不卡**：词表外词（如 `openclaw`）打全后空格上屏原文；打错码按 Esc 清空
- **拼音反查**：按反引号键再打拼音（如 反引号+zhan）出候选字，注释显示五笔编码——不会打的字一查就知
- **玫枫皮肤**：亮 / 暗双皮肤随系统切换
- **Shift 切中英**：Caps Lock 保留系统大写锁定，Shift 切中 / 英模式

## 两个方案

| 方案 | 字典组成 | 适用 |
|---|---|---|
| `moc_wubi86_simp` | 纯 core（极点字+词） | 简单纯净，无英文/补充词混入 |
| `moc_wubi86_simp_plus` | core + **frost 5.3万词组** + 英文 | 丰富全功能，中英混输 |

simp 是纯极点五笔（无英文混输，候选最干净）；simp_plus 含 frost 5.3万词组 + 中英混输，日常最省心。

## 快速部署

```bash
bash install.sh
```

`install.sh` 一键完成：清空 `~/Library/Rime` → 拷贝 dist 全量数据 → 自动探测 Squirrel 路径编译字典（找不到则重启 Squirrel 触发自动编译）。完成后选 `moc_wubi86_simp` 或 `moc_wubi86_simp_plus`。

> ⚠ 会清空整个 `~/Library/Rime`，若里面有手填的 `moc_wubi86_user.dict.yaml` 或其他方案，请先备份。

详细步骤见 [`dist/INSTALL.md`](dist/INSTALL.md)。

## 数据源

### 上游仓库（build 时自动 clone）

- [KyleBing/rime-wubi86-jidian](https://github.com/KyleBing/rime-wubi86-jidian) — 极点 core（字+词）
- [gaboolic/rime-frost](https://github.com/gaboolic/rime-frost) — 白霜词组 + 英文 + 农历/金额 lua
- [Mintimate/oh-my-rime](https://github.com/Mintimate/oh-my-rime) — 金额 / 农历 lua 上游

### 规范词表（`work/data/`）

- 《通用规范汉字表》一级 + 二级（白名单）/ 三级（参考）— 来自 [ben-hua/general_standard_chinese](https://github.com/ben-hua/general_standard_chinese)
- [first20hours/google-10000-english](https://github.com/first20hours/google-10000-english) — 英文频率（已入库）
- **《现代汉语常用词表（第2版）》— 版权词表，不入库**，请从 [Favsum/chinese-words](https://github.com/Favsum/chinese-words) 下载 `现代汉语常用词表（第2版）.txt`，放到 `work/data/xdhycyc.txt`

## 从源构建

依赖：Python 3 + [opencc-python-reimplemented](https://pypi.org/project/opencc-python-reimplemented/) + git

```bash
git clone <本仓库> && cd rime-wubi86-moc
pip install opencc-python-reimplemented
# 手动放入版权词表（上节）
python3 work/build_moc_wubi86.py    # clone 上游 + 生成 dist/
python3 work/verify_moc_wubi86.py   # 静态校验
```

build 脚本从 `work/sources/`（3 个上游，已 .gitignore）读取，生成 `dist/`。

## 自定义

编辑 `work/build_moc_wubi86.py` 顶部常量，重跑即可：

| 常量 | 作用 |
|---|---|
| `ENGLISH_TOP_N` | 英文保留 top N（google 频率） |
| `FROST_THRESHOLD` | frost 词组权重阈值 |
| `PROTECT_CHARS_FILE` | 三级字保护名单文件（人名 / 专业用字） |

**生僻字保护**：编辑 `work/data/protect_chars.txt`，一行一个字，加要保留的三级字（如 `镕`、`喆`），重跑即保留。

**手填个人词条**：编辑 `~/Library/Rime/moc_wubi86_user.dict.yaml`，格式 `文本<Tab>编码<Tab>权重<Tab>`。

## 项目结构

```
rime-wubi86-moc/
├── work/
│   ├── build_moc_wubi86.py     # 生成脚本
│   ├── verify_moc_wubi86.py    # 静态校验
│   ├── sources/                # 3 上游 clone（gitignore）
│   └── data/                   # 规范词表数据
│       ├── gb_level12.txt      # 通用规范汉字表 一级+二级（白名单）
│       ├── gb_level3.txt       # 三级字表（参考）
│       ├── protect_chars.txt   # 用户保留的三级字
│       ├── google_20k.txt      # 英文频率（入库）
│       └── xdhycyc.txt         # 现代汉语常用词表（gitignore，版权）
├── dist/                       # 生成产物（可直接部署）
└── tests/cases.tsv             # 测试用例
```

## 致谢

感谢上述上游仓库的维护者。本方案站在巨人的肩膀上。

## 许可

- 本项目代码（build / verify 脚本、自写 lua、schema 模板）以 **MIT** 许可发布
- 上游数据（字典 / lua / 词表）遵循各自原始许可
- 《现代汉语常用词表》版权归原编纂方，**本项目不含该数据**，需用户自行下载
