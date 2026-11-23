#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
「就慢慢攒」公众号封面生产脚本

用法：
  1. 出纯净定稿双尺寸：           python3 make_cover.py
  2. 动态槽位加字（--slot）：      python3 make_cover.py --slot "第 40 天"
  3. 动态槽位加字（--slot-file）： python3 make_cover.py --slot-file 槽位文案.txt

依赖：pip install pillow

关键设计：
  · 所有资源（底图、字体、定稿）都按脚本所在目录解析，从任意目录调用都能跑
  · 带 --slot / --slot-file 时输出到「输出_带槽位/<槽位摘要>/」子目录，
    不会覆盖根目录的两张纯净定稿
  · 槽位支持三种手动换行写法（详见 封面制作说明书.md）：
    ① 文本里写字面 \n  ② 文本里写真回车（--slot-file 天然支持）
    ③ shell 用 ANSI-C 引号  $'...\n...'
  · 字符级贪心折行，标点不留行首；安全区横版 500px / 方版 900px
"""
import os
import re
import sys
import hashlib
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# ─── 路径 ────────────────────────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

def asset(name):
    """资源路径 = 脚本所在目录 + 文件名；找不到时给清晰报错而非栈崩。"""
    p = os.path.join(SCRIPT_DIR, name)
    if not os.path.exists(p):
        sys.exit(f'❌ 找不到资源：{p}\n'
                 f'   请确认 {name!r} 与 make_cover.py 在同一目录。')
    return p

SRC  = asset('封面资产_底图源文件.png')
FONT = asset('封面资产_字体_霞鹜文楷Medium.ttf')

# 根目录定稿文件名（纯净版）
WIDE_OUT   = '封面定稿_就慢慢攒_头条版_1280x544.jpg'
SQUARE_OUT = '封面定稿_就慢慢攒_方版_1080x1080.jpg'
SLOT_DIR   = 'out_slot'   # 带槽位时输出到此子目录
DEFAULT_SLOT_FILE = 'slot.txt'   # 无参数时默认读取这个文件

# ─── 视觉常量 ────────────────────────────────────────────────────
TITLE   = '就慢慢攒'
# 标题 4 字每字 (dx,dy) 微偏移，模拟手写错落感；OFFS 在 7 字内循环复用
OFFS    = [(0,0),(0,-3),(2,-1),(0,2),(-1,0),(1,-2),(0,1)]
TITLE_C = (247, 232, 196)   # 奶油黄
SLOT_C  = (232, 214, 184)   # 略浅奶油
GRAD_C  = (12, 16, 24)      # 暗色渐变底

# 槽位安全区（暗色渐变内的可读区）
WIDE_SLOT_MAX_W   = 500
SQUARE_SLOT_MAX_W = 900
SLOT_LINE_GAP     = 0.45     # 行距 = 字号 × (1 + GAP)

# ─── 绘制函数 ────────────────────────────────────────────────────
def draw_title(im, font_obj, x, y, spacing):
    """画「就慢慢攒」4 字 + 模糊投影；字符级 (dx,dy) 偏移制造手写感。"""
    sh = Image.new('RGBA', im.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(sh)
    sd.text((x+4, y+5), TITLE, font=font_obj, fill=(0, 0, 0, 150))
    sh = sh.filter(ImageFilter.GaussianBlur(4))
    im = Image.alpha_composite(im.convert('RGBA'), sh)
    d = ImageDraw.Draw(im)
    for i, ch in enumerate(TITLE):
        dx, dy = OFFS[i % len(OFFS)]
        d.text((x + i*spacing + dx, y + dy), ch,
               font=font_obj, fill=TITLE_C + (255,))
    return im, d

# ─── 换行逻辑 ────────────────────────────────────────────────────
_SEPARATORS = ' \u00b7\uff0c,\u3002\uff1b;/\uff5c|'

def _tokenize(text):
    """按分隔符切块，分隔符跟上一块（避免把「5 万」拆开）。"""
    tokens, buf = [], ''
    for ch in text:
        buf += ch
        if ch in _SEPARATORS:
            tokens.append(buf); buf = ''
    if buf:
        tokens.append(buf)
    return tokens

def wrap_text(font_obj, text, max_w):
    """\\n 显式换行（最强）；段内按分隔符贪心填行；单块超宽按字兜底。"""
    def w(s):
        bb = font_obj.getbbox(s)
        return bb[2] - bb[0]

    out = []
    for para in text.split('\n'):
        para = para.rstrip()
        if not para:
            out.append(''); continue
        if w(para) <= max_w:
            out.append(para); continue
        lines, cur = [], ''
        for tok in _tokenize(para):
            cand = cur + tok
            if w(cand.strip()) <= max_w:
                cur = cand
            else:
                if cur.strip():
                    lines.append(cur.strip()); cur = ''
                if w(tok.strip()) <= max_w:
                    cur = tok
                else:
                    buf = ''
                    for ch in tok:
                        if w(buf + ch) <= max_w:
                            buf += ch
                        else:
                            if buf: lines.append(buf.strip())
                            buf = ch
                    cur = buf
        if cur.strip():
            lines.append(cur.strip())
        out.extend(lines)
    return out

def normalize_slot(text):
    """归一化换行：字面 \\n / 字面 \\r\\n / 真实 \\r\\n / 真实 \\r → 真实 \\n。"""
    if not text: return text
    s = text.replace('\\r\\n', '\n').replace('\\n', '\n')
    return s.replace('\r\n', '\n').replace('\r', '\n')

def _slot_slug(text):
    """为带槽位输出生成安全子目录名：
    - 槽位去首尾空白
    - 非文件名安全字符与空白 → 下划线
    - 截前 24 字符
    - 超长则附 6 位 md5 后缀避免重名
    """
    if not text:
        return '空'
    s = re.sub(r'[\\/:*?"<>|\s]+', '_', text.strip())
    s = s[:24]
    if len(text.strip()) > 24:
        s = f'{s}_{hashlib.md5(text.encode("utf-8")).hexdigest()[:6]}'
    return s or '槽位'

def draw_slot(d, font_obj, x, y, max_w, text):
    """在 (x,y) 起始位置按 max_w 自动折行画多行槽位文字。"""
    font_size = font_obj.size
    line_h = int(font_size * (1 + SLOT_LINE_GAP))
    for i, line in enumerate(wrap_text(font_obj, text, max_w)):
        d.text((x+2, y + i*line_h + 3), line,
               font=font_obj, fill=(0, 0, 0, 130))
        d.text((x,   y + i*line_h),     line,
               font=font_obj, fill=SLOT_C + (255,))

# ─── 两版封面工厂 ────────────────────────────────────────────────
def make_wide(src, slot, out_dir):
    W, H = src.size
    th   = int(W / 2.353)
    top  = max(0, (H - th)//2 - 40)
    img  = src.crop((0, top, W, top + th)).resize((1280, 544), Image.LANCZOS)
    # 左侧 600px 横向暗渐变（保证标题/槽位可读）
    g  = Image.new('L', img.size, 0)
    gd = ImageDraw.Draw(g)
    for gx in range(600):
        gd.line([(gx, 0), (gx, img.height)],
                fill=int(170 * max(0, 1 - gx/600)**1.2))
    img = Image.composite(Image.new('RGBA', img.size, GRAD_C + (255,)),
                          img.convert('RGBA'), g)
    img, d = draw_title(img, ImageFont.truetype(FONT, 104), 90, 92, 112)
    if slot:
        draw_slot(d, ImageFont.truetype(FONT, 38),
                  92, 292, WIDE_SLOT_MAX_W, slot)
    img.convert('RGB').save(os.path.join(out_dir, WIDE_OUT), quality=93)

def make_square(src, slot, out_dir):
    W, H = src.size
    # 单独构图：不复用横版裁切，从底图右侧主体区取正方形
    sq = src.crop((W-96-1024, 0, W-96, 1024)) \
            .crop((0, 0, 1024, 940)) \
            .resize((1080, 1080), Image.LANCZOS)
    # 顶部 420px 纵向暗渐变
    g  = Image.new('L', sq.size, 0)
    gd = ImageDraw.Draw(g)
    for gy in range(420):
        gd.line([(0, gy), (sq.width, gy)],
                fill=int(160 * max(0, 1 - gy/420)**1.2))
    sq = Image.composite(Image.new('RGBA', sq.size, GRAD_C + (255,)),
                         sq.convert('RGBA'), g)
    sq, d = draw_title(sq, ImageFont.truetype(FONT, 92), 78, 66, 100)
    if slot:
        draw_slot(d, ImageFont.truetype(FONT, 34),
                  80, 180, SQUARE_SLOT_MAX_W, slot)
    sq.convert('RGB').save(os.path.join(out_dir, SQUARE_OUT), quality=93)

# ─── 入口 ────────────────────────────────────────────────────────
def _read_slot(args):
    if args.slot and args.slot_file:
        sys.exit('❌ --slot 和 --slot-file 只能二选一')
    if args.slot_file:
        with open(args.slot_file, 'r', encoding='utf-8') as f:
            return f.read().rstrip('\n')   # 去掉文件末尾空行
    return args.slot

if __name__ == '__main__':
    import argparse
    ap = argparse.ArgumentParser(
        description='生成「就慢慢攒」公众号封面（纯净定稿或带槽位版本）',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='不带参数时读取 slot.txt 并输出到 out_slot/<摘要>/；'
               '加 --clean 生成根目录的纯净定稿。')
    ap.add_argument('--slot', default=None,
                    help=r'动态槽位文字；用 \n 可手动强制换行')
    ap.add_argument('--slot-file', default=None,
                    help='从文件读取槽位文字（保留真实换行）')
    ap.add_argument('--clean', action='store_true',
                    help='忽略 slot.txt，生成根目录的纯净定稿')
    args = ap.parse_args()

    slot = normalize_slot(_read_slot(args))
    if slot is None and not args.clean:
        _p = os.path.join(SCRIPT_DIR, DEFAULT_SLOT_FILE)
        if os.path.exists(_p):
            with open(_p, encoding='utf-8') as _f:
                slot = normalize_slot(_f.read().rstrip())
    src  = Image.open(SRC).convert('RGB')

    if slot:
        out_dir = os.path.join(SCRIPT_DIR, SLOT_DIR, _slot_slug(slot))
        os.makedirs(out_dir, exist_ok=True)
        make_wide(src, slot, out_dir)
        make_square(src, slot, out_dir)
        print(f'✓ 带槽位版 → {out_dir}')
        print(f'  （根目录的纯净定稿未被修改）')
    else:
        make_wide(src, None, SCRIPT_DIR)
        make_square(src, None, SCRIPT_DIR)
        print(f'✓ 纯净定稿 → {SCRIPT_DIR}')