#!/usr/bin/env python3
"""把已构建App与使用说明打包，普通用户无需运行此工具。"""
import hashlib
import plistlib
import subprocess
import zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
APP=ROOT/'Source/output/Wubi Code Assistant.app'

def main():
    subprocess.run(['codesign','--verify','--deep','--strict',str(APP)],check=True)
    info=plistlib.loads((APP/'Contents/Info.plist').read_bytes())
    version=info['CFBundleShortVersionString']
    if not (APP/'Contents/Resources/RimeWubiAssistant_RimeWubiCore.bundle/Contents/Resources/wubi86.tsv').exists():
        raise ValueError('缺少独立单字表')
    out=ROOT/'releases';out.mkdir(exist_ok=True)
    archive=out/('wubi-code-assistant-macos-'+version+'.zip')
    files=sorted(f for f in APP.rglob('*') if f.is_file())
    files.extend(ROOT/n for n in ['README.md','NOTICE.md','LICENSE'])
    with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for f in files:
            if f.is_symlink() or f.name=='.DS_Store':raise ValueError('App包含未审核项')
            relative=f.relative_to(APP.parent) if APP in f.parents else f.relative_to(ROOT)
            entry=zipfile.ZipInfo(relative.as_posix(),date_time=(2026,10,7,0,0,0))
            entry.create_system=3;entry.external_attr=f.stat().st_mode<<16
            z.writestr(entry,f.read_bytes(),compress_type=zipfile.ZIP_DEFLATED,compresslevel=9)
    digest=hashlib.sha256(archive.read_bytes()).hexdigest()
    (out/'SHA256SUMS').write_text(digest+'  '+archive.name+'\n')
    print(archive.name+': '+str(archive.stat().st_size)+'字节')

if __name__=='__main__':main()
