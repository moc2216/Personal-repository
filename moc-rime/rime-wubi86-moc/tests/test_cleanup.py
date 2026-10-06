import csv
import json
import unittest
from pathlib import Path
from test_data import rows,digest_records

ROOT=Path(__file__).resolve().parents[1]

class CleanupTests(unittest.TestCase):
    def test_approved_cold_content_absent_but_useful_low_frequency_words_preserved(self):
        data=rows('moc_wubi86_core')+rows('moc_wubi86_extra');texts={r[0] for r in data}
        self.assertFalse({'俟河之清','叨陪末座','黼','台甫','奥达曼','CHDBits','iPhone 3GS'} & texts)
        self.assertTrue({'我们','优化','人工智能','电路','电压','光耦','反熵','焊盘','误码','量规','台钳','表笔','锰钢','一石两鸟','一团漆黑','娓娓动听','王永民','hello','IEPL','Grand Central Dispatch'}<=texts)
        self.assertFalse({'黼','觚','庑'} & {r[0] for r in rows('moc_reverse')})

    def test_deletion_ledger_reconstructs_the_exact_before_data(self):
        summary=json.loads((ROOT/'reports/cleanup_summary.json').read_text())
        with (ROOT/'reports/removed.tsv').open() as f:removed=list(csv.DictReader(f,delimiter='\t'))
        self.assertEqual(summary['status'],'applied')
        self.assertTrue(removed)
        restored={}
        for part in ['core','extra','reverse']:
            name='moc_reverse' if part=='reverse' else 'moc_wubi86_'+part
            table=[r for r in removed if r['table']==name]
            self.assertTrue(all(r['reason'] for r in table))
            data=rows(name)
            for r in sorted(table,key=lambda r:int(r['position'])):
                old=[r['text'],r['code'],r['weight']]
                if r['stem']:old.append(r['stem'])
                data.insert(int(r['position']),old)
            self.assertEqual(len(data),summary['before_records'][part])
            self.assertEqual(digest_records(data),summary['before_sha256'][part])
            restored[part]=data
            if part!='reverse':self.assertFalse(any(len(r['code'])<=2 for r in table))
        self.assertEqual(digest_records(restored['core']+restored['extra']),summary['before_main_sha256'])

    def test_missing_frequency_evidence_is_explicit_not_invented_zero(self):
        with (ROOT/'reports/removed.tsv').open() as f:removed=list(csv.DictReader(f,delimiter='\t'))
        self.assertTrue(any(r['zhihu_value']=='unknown' for r in removed))
        for r in removed:
            for source in ['zhihu','wiki']:
                if r[source+'_value']=='unknown':self.assertEqual(r[source+'_rarity'],'unknown')
                else:self.assertTrue(0<=float(r[source+'_rarity'])<=1)
