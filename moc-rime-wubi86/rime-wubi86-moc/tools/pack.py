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
DATA_FILES=('default.custom.yaml','moc_wubi86_simp.schema.yaml','moc_wubi86_simp.dict.yaml',
            'moc_wubi86_simp_plus.schema.yaml','moc_wubi86_simp_plus.dict.yaml',
            'moc_wubi86_core.dict.yaml','moc_wubi86_extra.dict.yaml',
            'moc_reverse.schema.yaml','moc_reverse.dict.yaml',
            'moc_wubi86_user.dict.yaml','lua/moc_date_time.lua','lua/moc_calculator.lua',
            'lua/moc_clear_empty.lua','lua/moc_number_translator.lua',
            'lua/moc_chineseLunarCalendar_translator.lua')
SUPPORT_FILES=('README.md','NOTICE.md','LICENSE','licenses/Apache-2.0.txt',
               'licenses/MIT.txt','licenses/Unicode.txt')


def payload(root=ROOT, *, macos=False):
    files={'data/'+n:root/'data'/n for n in DATA_FILES}
    files.update({n:root/n for n in SUPPORT_FILES})
    if macos:
        files['data/squirrel.custom.yaml']=root/'optional/macos/squirrel.custom.yaml'
        files['optional/macos/blue-reverie/squirrel.custom.yaml']=root/'optional/macos/blue-reverie/squirrel.custom.yaml'
    actual={p.relative_to(root/'data').as_posix() for p in (root/'data').rglob('*') if p.is_file()}
    if actual != set(DATA_FILES): raise ValueError('data文件集合不是审核后的15文件')
    for p in files.values():
        if p.is_symlink() or not p.is_file(): raise ValueError('缺少源文件或发现符号链接：'+p.name)
        text=p.read_text(encoding='utf-8-sig')
        if re.search(r'/Users/[^/\s]+/|/var/folders/|backups/Rime-',text):
            raise ValueError('文件包含私人路径：'+p.name)
    user=(root/'data/moc_wubi86_user.dict.yaml').read_text(encoding='utf-8').split('\n...\n',1)[1]
    if any(x.strip() and not x.lstrip().startswith('#') for x in user.splitlines()):
        raise ValueError('个人表必须为空模板')
    return files


def archive(output, root=ROOT, *, macos=False):
    files=payload(root,macos=macos)
    with zipfile.ZipFile(output,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for name,p in sorted(files.items()):
            entry=zipfile.ZipInfo(name,date_time=(2026,10,8,0,0,0))
            # Rime按文件时间检测配置变化；备用皮肤需与默认皮肤不同。
            if name=='optional/macos/blue-reverie/squirrel.custom.yaml':
                entry.date_time=(2026,10,8,0,0,2)
            entry.create_system=3; entry.external_attr=(0o100644<<16)
            z.writestr(entry,p.read_bytes(),compress_type=zipfile.ZIP_DEFLATED,compresslevel=9)
    return output


def main():
    subprocess.run([sys.executable,'-m','unittest','discover','-s','tests','-p','test_*.py'],
                   cwd=ROOT,check=True,env={**os.environ,'PYTHONDONTWRITEBYTECODE':'1'})
    out=ROOT/'releases';out.mkdir(exist_ok=True)
    paths=[archive(out/'moc-wubi86-data-2026.10.08.zip'),
           archive(out/'moc-wubi86-macos-2026.10.08.zip',macos=True)]
    (out/'SHA256SUMS').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name+'\n' for p in paths),encoding='utf-8')
    for path in paths:
        with zipfile.ZipFile(path) as z:count=len(z.namelist())
        print(f'完成：{path.name}，{path.stat().st_size}字节，{count}文件。')

if __name__=='__main__':main()
