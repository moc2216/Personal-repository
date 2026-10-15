import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class CapsLockTests(unittest.TestCase):
    def test_capslox_is_opt_in_and_shared_by_both_modes(self):
        settings = (ROOT / 'data/moc_settings.yaml').read_text()
        schema = (ROOT / 'data/moc_wubi86_simp_plus.schema.yaml').read_text()
        self.assertIn('capslox_compat: false', settings)
        self.assertIn('__include: moc_settings:/moc_capslock', schema)

    def test_processor_runs_before_ascii_composer_in_shared_schema(self):
        schema = (ROOT / 'data/moc_wubi86_simp_plus.schema.yaml').read_text()
        processors = schema.split('  processors:\n', 1)[1].split('  segmentors:', 1)[0]
        self.assertIn('lua_processor@*moc_capslock', processors)
        self.assertLess(processors.index('lua_processor@*moc_capslock'),
                        processors.index('- ascii_composer'))
        self.assertIn('Caps_Lock: clear', schema)
        self.assertIn('good_old_caps_lock: true', schema)

    @unittest.skipUnless(shutil.which('lua'), 'Optional Lua interpreter unavailable')
    def test_pending_letters_commit_uppercase_and_other_keys_pass_through(self):
        self.assertTrue((ROOT / 'data/lua/moc_capslock.lua').is_file(),
                        'CapsLock uppercase processor is missing')
        result = subprocess.run(['lua', str(ROOT / 'tests/capslock.lua'),
                                 str(ROOT / 'data/lua/moc_capslock.lua')],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('26 cases passed', result.stdout)
        self.assertIn('Capslox cases passed', result.stdout)


if __name__ == '__main__':
    unittest.main()
