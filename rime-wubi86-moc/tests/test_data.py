import hashlib
import json
import re
import unittest
import unicodedata
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'data'
EXPECTED=json.loads((ROOT/'tests/expected.json').read_text(encoding='utf-8'))
FILES={'moc_settings.yaml','squirrel.custom.yaml','default.custom.yaml','moc_wubi86_simp.schema.yaml','moc_wubi86_simp.dict.yaml',
       'moc_wubi86_simp_plus.schema.yaml','moc_wubi86_simp_plus.dict.yaml',
       'moc_reverse.schema.yaml','moc_reverse.dict.yaml','moc_wubi86_user.dict.yaml',
       'moc_wubi86_core.dict.yaml','moc_wubi86_extra.dict.yaml'} | {'lua/'+n for n in EXPECTED['lua_sha256']}

def rows(name):
    body=(DATA/(name+'.dict.yaml')).read_text(encoding='utf-8').split('\n...\n',1)[1]
    return [line.split('\t') for line in body.splitlines() if line.strip() and not line.startswith('#')]

def digest_records(data):
    normalized=[]
    for row in data:
        text,code,weight,*stem=row
        normalized.append(f'{text}\t{code}\t{weight}\t{stem[0] if stem else ""}\n')
    return hashlib.sha256(''.join(normalized).encode('utf-8')).hexdigest()

def main_rows():
    return rows('moc_wubi86_core')+rows('moc_wubi86_extra')

class DataTests(unittest.TestCase):
    def test_only_required_data_files(self):
        actual={p.relative_to(DATA).as_posix() for p in DATA.rglob('*') if p.is_file()}
        self.assertEqual(actual,FILES)

    def test_merged_records_preserve_text_code_weight_and_stem(self):
        data=main_rows()
        self.assertEqual(len(data),EXPECTED['main_records'])
        self.assertEqual(digest_records(data),EXPECTED['main_records_sha256'])
        self.assertTrue(all(3<=len(r)<=4 and r[2].isdigit() for r in data))
        self.assertFalse(any(len(r)==4 and not r[3] for r in data))

    def test_core_and_extra_preserve_original_mode_boundaries(self):
        for part in ['core','extra']:
            data=rows('moc_wubi86_'+part)
            self.assertEqual(len(data),EXPECTED[part+'_records'])
            self.assertEqual(digest_records(data),EXPECTED[part+'_records_sha256'])
        self.assertIn('我们',{r[0] for r in rows('moc_wubi86_core')})
        self.assertIn('hello',{r[0] for r in rows('moc_wubi86_extra')})
        self.assertFalse(any(r[0].isascii() for r in rows('moc_wubi86_core')))

    def test_reverse_records_unchanged(self):
        data=rows('moc_reverse')
        self.assertEqual(len(data),EXPECTED['reverse_records'])
        self.assertEqual(digest_records(data),EXPECTED['reverse_records_sha256'])

    def test_charset_and_precise_single_exclusions(self):
        allowed=set((ROOT/'tests/charset.txt').read_text(encoding='utf-8').splitlines())
        self.assertEqual(len(allowed),6500)
        data=main_rows()
        singles={r[0] for r in data if len(r[0])==1 and 'CJK' in unicodedata.name(r[0],'')}
        self.assertEqual(singles,allowed-set(EXPECTED['excluded_single_chars']))
        for name in ['moc_wubi86_core','moc_wubi86_extra','moc_reverse']:
            for r in rows(name):
                self.assertFalse(any(('CJK' in unicodedata.name(c,'') or c=='〇') and c not in allowed for c in r[0]))
                self.assertNotIn(r[0],EXPECTED['excluded_single_chars'])

    def test_useful_words_and_old_rare_exclusions(self):
        texts={r[0] for r in main_rows()}
        self.assertTrue({'我们','优化','人工智能','电路','算法','电压','溧阳','溧水','情愫','矗','乾','薹','蒜薹','乾坤','宫商角徵羽'}<=texts)
        self.assertFalse({'优游卒岁','岛瘦郊寒','秦楼楚馆','鼠窃狗盗'} & texts)

    def test_schema_completion_keys_and_dependencies(self):
        schema=(DATA/'moc_wubi86_simp_plus.schema.yaml').read_text(encoding='utf-8')
        translator=schema.split('\ntranslator:\n',1)[1].split('\n\n',1)[0]
        self.assertIn('  enable_completion: true',translator)
        self.assertIn('  enable_charset_filter: false',translator)
        self.assertIn('  enable_user_dict: false',translator)
        self.assertIn('  dependencies:\n    - moc_reverse',schema)
        self.assertIn('  prefix: "`"',schema)
        for key in ['semicolon','apostrophe','bracketleft','bracketright']:
            self.assertIn('accept: '+key,schema)
        refs=re.findall(r'lua_(?:processor|translator)@\*([\w]+)',schema)
        self.assertEqual({n+'.lua' for n in refs},set(EXPECTED['lua_sha256']))

    def test_pure_schema_reuses_common_configuration_but_selects_pure_dictionary(self):
        schema=(DATA/'moc_wubi86_simp.schema.yaml').read_text(encoding='utf-8')
        self.assertIn('__include: moc_wubi86_simp_plus.schema:/',schema)
        self.assertIn('  schema_id: moc_wubi86_simp\n',schema)
        self.assertIn('  name: "moc 极点86五笔-纯净"',schema)
        self.assertIn('  dictionary: moc_wubi86_simp\n',schema)
        self.assertNotIn('\nengine:',schema)

    def test_personal_template_empty_and_loaded_first(self):
        self.assertEqual(rows('moc_wubi86_user'),[])
        for name,parts in [('moc_wubi86_simp',['moc_wubi86_user','moc_wubi86_core']),
                           ('moc_wubi86_simp_plus',['moc_wubi86_user','moc_wubi86_core','moc_wubi86_extra'])]:
            header=(DATA/(name+'.dict.yaml')).read_text(encoding='utf-8').split('\n...\n',1)[0]
            imports=header.split('import_tables:\n',1)[1]
            self.assertEqual(imports.strip(),'\n  '.join('- '+p for p in parts))
            self.assertEqual(rows(name),[])

    def test_lua_implementations_match_reviewed_digests(self):
        for n,digest in EXPECTED['lua_sha256'].items():
            self.assertEqual(hashlib.sha256((DATA/'lua'/n).read_bytes()).hexdigest(),digest)
