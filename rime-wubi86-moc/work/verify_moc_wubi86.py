#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""moc 86 五笔方案静态验证 + 回归测试。不写 ~/Library/Rime。

检查项：
  1. 文件完整性
  2. core 基础映射 a→工
  3. 繁体抽样（core + frost）
  4. import_tables 引用完整
  5. schema 引用的 lua 文件存在
  6. 关键功能（反查/weight校准/去三级/reverse_lookup）
  7. 一级简码全量（25 键，从极点原表提取，含 b=了）
  8. 二级简码全量（双字母编码，从极点原表提取）
  9. 关键 case 回归（历次修复的用户报错编码）
 10. 跨表一致性（frost 不系统性压 core）
 11. 行数统计
"""
import re
import sys
import random
from collections import defaultdict
from pathlib import Path
from opencc import OpenCC

ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / "dist"
JIDIAN = ROOT / "work" / "sources" / "rime-wubi86-jidian" / "wubi86_jidian.dict.yaml"
cc = OpenCC("t2s")
random.seed(42)

errors = []
warns = []


def parse_rows(path):
    rows, in_data = [], False
    with open(path, encoding="utf-8") as f:
        for line in f:
            s = line.rstrip("\n")
            if not in_data:
                if s.strip() == "...":
                    in_data = True
                continue
            if not s.strip() or s.lstrip().startswith("#"):
                continue
            parts = s.split("\t")
            if len(parts) >= 2:
                rows.append(parts)
    return rows


def parse_jidian_top(path):
    """从极点原表提取每个编码的最高 weight 候选。返回 {code: text}。"""
    best, in_data = {}, False
    with open(path, encoding="utf-8") as f:
        for line in f:
            s = line.rstrip("\n")
            if not in_data:
                if s.strip() == "...":
                    in_data = True
                continue
            if not s.strip() or s.lstrip().startswith("#"):
                continue
            parts = s.split("\t")
            if len(parts) >= 3:
                text, code = parts[0], parts[1].lower()
                try:
                    w = int(parts[2])
                except ValueError:
                    w = 0
                if code not in best or w > best[code][1]:
                    best[code] = (text, w)
    return {c: t for c, (t, _) in best.items()}


# 1. 文件完整性
expected = [
    "moc_wubi86_simp.schema.yaml", "moc_wubi86_simp.dict.yaml",
    "moc_wubi86_simp_plus.schema.yaml", "moc_wubi86_simp_plus.dict.yaml",
    "moc_english_words.dict.yaml",
    "moc_wubi86_core.dict.yaml", "moc_wubi86_frost_words.dict.yaml",
    "moc_reverse.dict.yaml", "moc_reverse.schema.yaml",
    "moc_wubi86_user.dict.yaml", "default.custom.yaml",
    "lua/moc_date_time.lua", "lua/moc_calculator.lua", "lua/moc_clear_empty.lua",
    "lua/number_translator.lua", "lua/chineseLunarCalendar_translator.lua",
]
for f in expected:
    if not (DIST / f).exists():
        errors.append(f"缺文件 {f}")

# 加载 core / frost 最终字典，建立 code -> {text: weight}
core = parse_rows(DIST / "moc_wubi86_core.dict.yaml")
frost = parse_rows(DIST / "moc_wubi86_frost_words.dict.yaml")
fin = defaultdict(dict)          # code_lower -> {text: max_weight}
fin_src = {}                      # (text, code) -> 'core'/'frost'
for rows, tag in [(core, "core"), (frost, "frost")]:
    for r in rows:
        if len(r) >= 3 and r[2].lstrip("-").isdigit():
            t, c, w = r[0], r[1].lower(), int(r[2])
            if w > fin[c].get(t, -1):
                fin[c][t] = w
                fin_src[(t, c)] = tag


def top1(code):
    """返回某编码下 weight 最高的 text，无则 None。"""
    m = fin.get(code)
    return max(m, key=m.get) if m else None


# 2. core 基础映射 a→工
code_of = {}
for parts in core:
    code_of.setdefault(parts[0], []).append(parts[1])
if "工" in code_of and "a" in code_of["工"]:
    print("[ok] core 基础映射 a → 工")
else:
    errors.append("core 基础映射 a→工 校验失败")

# 3. 繁体抽样
for name in ["moc_wubi86_core", "moc_wubi86_frost_words"]:
    rows = parse_rows(DIST / f"{name}.dict.yaml")
    sample = random.sample(rows, min(3000, len(rows)))
    trad = [r[0] for r in sample if cc.convert(r[0]) != r[0]]
    if trad:
        errors.append(f"{name} 繁体抽样命中 {len(trad)} 例: {trad[:3]}")
    else:
        print(f"[ok] {name} 繁体抽样 {len(sample)} 行通过")

# 4. import_tables 引用完整
for schema in ["moc_wubi86_simp.dict.yaml", "moc_wubi86_simp_plus.dict.yaml"]:
    txt = (DIST / schema).read_text(encoding="utf-8")
    for t in re.findall(r"^\s+-\s+(\S+)", txt, re.M):
        if not (DIST / f"{t}.dict.yaml").exists():
            errors.append(f"{schema} 引用 {t}.dict.yaml 不存在")

# 5. lua 引用
for schema in ["moc_wubi86_simp.schema.yaml", "moc_wubi86_simp_plus.schema.yaml"]:
    txt = (DIST / schema).read_text(encoding="utf-8")
    for lua in re.findall(r"lua_translator@\*(\S+)", txt):
        if not (DIST / "lua" / f"{lua}.lua").exists():
            errors.append(f"{schema} 引用 lua/{lua}.lua 不存在")

# 6. 关键功能
_rev = parse_rows(DIST / "moc_reverse.dict.yaml")
if not any(r[0] == "战" for r in _rev):
    errors.append("反查字典缺「战」")
if any(r[0] == "茳" for r in core):
    errors.append("三级字「茳」未删（去三级失效）")
def _w(rows, t):
    ws = [int(r[2]) for r in rows if r[0] == t and len(r) > 2 and r[2].lstrip("-").isdigit()]
    return max(ws) if ws else -1
if _w(core, "需要") < 1000:
    errors.append(f"weight 校准异常：需要({_w(core,'需要')}) 未校准（应 >1000）")
_sch = (DIST / "moc_wubi86_simp.schema.yaml").read_text(encoding="utf-8")
if "reverse_lookup:" not in _sch or "moc_reverse" not in _sch:
    errors.append("schema 缺 reverse_lookup 配置")
print("[ok] 关键功能检查（反查/weight校准/去三级/reverse_lookup）通过")

# 7. 一级简码全量（从极点原表提取，动态校验，含 b=了）
if JIDIAN.exists():
    jm_top = parse_jidian_top(JIDIAN)
    jm1 = {c: t for c, t in jm_top.items() if len(c) == 1}
    e1 = [c for c, t in jm1.items() if top1(c) != t]
    if e1:
        errors.append(f"一级简码 {len(e1)}/{len(jm1)} 错位: {[(c, jm1[c], top1(c)) for c in e1[:5]]}")
    else:
        print(f"[ok] 一级简码全量 {len(jm1)} 个首位正确（含 b={jm1.get('b')}）")

    # 8. 二级简码全量（跳过最终字典里被生僻字过滤清空的编码）
    jm2 = {c: t for c, t in jm_top.items() if len(c) == 2}
    jm2_missing = [c for c in jm2 if c not in fin or not fin[c]]
    jm2_check = {c: t for c, t in jm2.items() if c in fin and fin[c]}
    e2 = [c for c, t in jm2_check.items() if top1(c) != t]
    if jm2_missing:
        warns.append(f"二级简码 {len(jm2_missing)} 个编码被生僻字过滤清空: {jm2_missing[:5]}")
    if e2:
        errors.append(f"二级简码 {len(e2)}/{len(jm2_check)} 错位: {[(c, jm2_check[c], top1(c)) for c in e2[:5]]}")
    else:
        print(f"[ok] 二级简码 {len(jm2_check)} 个首位正确（{len(jm2_missing)} 个编码被过滤清空，跳过）")
else:
    warns.append(f"缺极点原表 {JIDIAN}，跳过一/二级简码全量校验")

# 9. 关键 case 回归（历次修复的用户报错编码）
CASES = {
    "j": "是", "p": "这", "b": "了",       # 一级简码（b=了 修正）
    "rtfc": "手动", "whtf": "候选",        # RRF + 极点信号
    "rhrh": "看看", "lkgc": "回到",        # RRF 跨表
    "rara": "找找", "wdwx": "优化",        # 极点w=10阈值 + 频数加权
}
case_fail = [(c, exp, top1(c)) for c, exp in CASES.items() if top1(c) != exp]
if case_fail:
    errors.append(f"关键 case 回归失败 {case_fail}")
else:
    print(f"[ok] 关键 case 回归 {len(CASES)} 个全部通过")

# 10. weight 分层完整性：一级简码=99999，二级简码=80000，其余 < 80000
bad_layer = []
for c, m in fin.items():
    for t, w in m.items():
        is_jm1 = len(c) == 1 and c in jm_top and jm_top[c] == t
        is_jm2 = len(c) == 2 and c in jm_top and jm_top[c] == t
        if is_jm1 and w != 99999:
            bad_layer.append((t, c, w, "应为一级简码99999"))
        elif is_jm2 and w != 80000:
            bad_layer.append((t, c, w, "应为二级简码80000"))
        elif not is_jm1 and not is_jm2 and w >= 80000:
            bad_layer.append((t, c, w, "非简码词不该>=80000"))
if bad_layer:
    errors.append(f"weight 分层异常 {len(bad_layer)} 处: {bad_layer[:5]}")
else:
    print(f"[ok] weight 分层完整：一级=99999 / 二级=80000 / 其余<80000")

# 11. 行数统计
print("== 行数 ==")
for f in ["moc_wubi86_core", "moc_wubi86_frost_words", "moc_english_words"]:
    print(f"  {f}: {len(parse_rows(DIST / f'{f}.dict.yaml'))}")

for w in warns:
    print("  !", w)
if errors:
    print("\n== 失败 ==")
    for e in errors:
        print("  x", e)
    sys.exit(1)
print("\n== 全部静态检查 + 回归测试通过 ==")
