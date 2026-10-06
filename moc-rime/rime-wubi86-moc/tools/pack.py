#!/usr/bin/env python3
"""仅为维护者生成直接部署的数据ZIP，无第三方依赖。"""
import hashlib
import os
import re
import subprocess
import sys
import zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
DATA_FILES=('moc_wubi86_simp.schema.yaml','moc_wubi86_simp.dict.yaml',
            'moc_wubi86_simp_plus.schema.yaml','moc_wubi86_simp_plus.dict.yaml',
            'moc_wubi86_core.dict.yaml','moc_wubi86_extra.dict.yaml',
            'moc_reverse.schema.yaml','moc_reverse.dict.yaml',
            'moc_wubi86_user.dict.yaml','lua/moc_date_time.lua','lua/moc_calculator.lua',
            'lua/moc_clear_empty.lua','lua/moc_number_translator.lua',
            'lua/moc_chineseLunarCalendar_translator.lua')
SUPPORT_FILES=('README.md','NOTICE.md','LICENSE','licenses/Apache-2.0.txt',
               'licenses/MIT.txt','licenses/Unicode.txt')


def payload(root=ROOT):
    files=[root/'data'/n for n in DATA_FILES]+[root/n for n in SUPPORT_FILES]
    actual={p.relative_to(root/'data').as_posix() for p in (root/'data').rglob('*') if p.is_file()}
    if actual != set(DATA_FILES): raise ValueError('data文件集合不是审核后的14文件')
    for p in files:
        if p.is_symlink() or not p.is_file(): raise ValueError('缺少源文件或发现符号链接：'+p.name)
        text=p.read_text(encoding='utf-8-sig')
        if re.search(r'/Users/[^/\s]+/|/var/folders/|backups/Rime-',text):
            raise ValueError('文件包含私人路径：'+p.name)
    user=(root/'data/moc_wubi86_user.dict.yaml').read_text(encoding='utf-8').split('\n...\n',1)[1]
    if any(x.strip() and not x.lstrip().startswith('#') for x in user.splitlines()):
        raise ValueError('个人表必须为空模板')
    return files


def archive(output, root=ROOT):
    files=payload(root)
    with zipfile.ZipFile(output,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for p in sorted(files):
            entry=zipfile.ZipInfo(p.relative_to(root).as_posix(),date_time=(2026,10,6,0,0,0))
            entry.create_system=3; entry.external_attr=(0o100644<<16)
            z.writestr(entry,p.read_bytes(),compress_type=zipfile.ZIP_DEFLATED,compresslevel=9)
    return output


def main():
    subprocess.run([sys.executable,'-m','unittest','discover','-s','tests','-p','test_*.py'],
                   cwd=ROOT,check=True,env={**os.environ,'PYTHONDONTWRITEBYTECODE':'1'})
    out=ROOT/'releases';out.mkdir(exist_ok=True)
    path=archive(out/'moc-wubi86-data-2026.10.06.zip')
    digest=hashlib.sha256(path.read_bytes()).hexdigest()
    (out/'SHA256SUMS').write_text(digest+'  '+path.name+'\n',encoding='utf-8')
    print(f'完成：{path.name}，{path.stat().st_size}字节，20文件（14数据+6说明许可）。')

if __name__=='__main__':main()
