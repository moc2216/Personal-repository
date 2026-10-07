import importlib.util
import re
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
    def test_macos_package_copies_default_skin_and_keeps_switchable_backup(self):
        with tempfile.TemporaryDirectory() as tmp:
            generic=pack.archive(Path(tmp)/'generic.zip')
            macos=pack.archive(Path(tmp)/'macos.zip',macos=True)
            with zipfile.ZipFile(generic) as common, zipfile.ZipFile(macos) as mac:
                self.assertEqual(set(mac.namelist())-set(common.namelist()),
                    {'data/squirrel.custom.yaml','optional/macos/blue-reverie/squirrel.custom.yaml'})
                for name in common.namelist():
                    self.assertEqual(common.read(name),mac.read(name))
                self.assertEqual(mac.read('data/squirrel.custom.yaml'),
                    (ROOT/'optional/macos/squirrel.custom.yaml').read_bytes())
                self.assertEqual(mac.read('optional/macos/blue-reverie/squirrel.custom.yaml'),
                    (ROOT/'optional/macos/blue-reverie/squirrel.custom.yaml').read_bytes())
                self.assertEqual(len(mac.namelist()),23)
                self.assertNotEqual(mac.getinfo('data/squirrel.custom.yaml').date_time,
                    mac.getinfo('optional/macos/blue-reverie/squirrel.custom.yaml').date_time)
                self.assertFalse(any(Path(n).suffix in ['.py','.sh','.command','.cmd','.bin'] for n in mac.namelist()))

    def test_macos_private_frontend_configuration_stops_packaging(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)/'repo'
            shutil.copytree(ROOT/'data',root/'data')
            shutil.copytree(ROOT/'optional',root/'optional')
            for relative in pack.SUPPORT_FILES:
                p=root/relative;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/relative,p)
            skin=root/'optional/macos/squirrel.custom.yaml'
            with skin.open('a',encoding='utf-8') as f:
                f.write('\n# private path fixture: /Users/example/private\n')
            with self.assertRaises(ValueError):pack.payload(root,macos=True)

    def test_copy_only_package_registers_both_modes_with_pure_first(self):
        with tempfile.TemporaryDirectory() as tmp:
            path=pack.archive(Path(tmp)/'data.zip')
            with zipfile.ZipFile(path) as z:
                config=z.read('data/default.custom.yaml').decode('utf-8')
                self.assertEqual(re.findall(r'^\s+- schema: (\S+)$',config,re.MULTILINE),
                                 ['moc_wubi86_simp','moc_wubi86_simp_plus'])
                self.assertIn('\n  schema_list:\n',config)
                self.assertNotIn('schema_list/+:',config)

    def test_zip_only_contains_deploy_data_and_necessary_notices(self):
        with tempfile.TemporaryDirectory() as tmp:
            path=pack.archive(Path(tmp)/'data.zip')
            with zipfile.ZipFile(path) as z:
                names=set(z.namelist())
                self.assertEqual(names,{'data/'+n for n in pack.DATA_FILES}|set(pack.SUPPORT_FILES))
                self.assertEqual(set(pack.DATA_FILES),FILES)
                self.assertEqual(len(names),21)
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
