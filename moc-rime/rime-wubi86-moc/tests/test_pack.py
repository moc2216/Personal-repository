import importlib.util
import shutil
import tempfile
import unittest
import zipfile
from pathlib import Path
from test_data import FILES
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('pack',ROOT/'tools/pack.py')
pack=importlib.util.module_from_spec(spec);spec.loader.exec_module(pack)

class PackageTests(unittest.TestCase):
    def test_zip_only_contains_deploy_data_and_necessary_notices(self):
        with tempfile.TemporaryDirectory() as tmp:
            path=pack.archive(Path(tmp)/'data.zip')
            with zipfile.ZipFile(path) as z:
                names=set(z.namelist())
                self.assertEqual(names,{'data/'+n for n in pack.DATA_FILES}|set(pack.SUPPORT_FILES))
                self.assertEqual(set(pack.DATA_FILES),FILES)
                self.assertEqual(len(names),20)
                self.assertFalse(any(Path(n).suffix in ['.py','.sh','.command','.cmd','.bin'] for n in names))
                self.assertFalse(any(n.startswith(('tools/','tests/','optional/','vendor/')) for n in names))

    def test_accidental_private_data_or_extra_files_stop_packaging(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)/'repo'
            shutil.copytree(ROOT/'data',root/'data')
            for relative in pack.SUPPORT_FILES:
                p=root/relative;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/relative,p)
            user=root/'data/moc_wubi86_user.dict.yaml'
            original=user.read_bytes();user.write_bytes(original+b'private fixture\taaaa\t1\n')
            with self.assertRaises(ValueError):pack.payload(root)
            user.write_bytes(original)
            (root/'data/user.yaml').write_text('private state',encoding='utf-8')
            with self.assertRaises(ValueError):pack.payload(root)
