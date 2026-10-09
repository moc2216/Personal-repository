import re
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
SKINS=('optional/macos/squirrel.custom.yaml',
       'optional/macos/blue-reverie/squirrel.custom.yaml')
ENGLISH_APPS={'com.apple.Terminal','org.electerm.electerm',
              'com.jetbrains.pycharm','com.apple.SecurityAgent',
              'com.apple.LocalAuthenticationRemoteService','com.apple.AuthenticationServices.Helper'}


class PreferenceTests(unittest.TestCase):
    def test_original_scheme_menu_shortcut_is_preserved(self):
        config=(ROOT/'data/moc_settings.yaml').read_text(encoding='utf-8')
        self.assertRegex(config,r'hotkeys:\s*\n\s*- "Shift\+Control\+0"')

    def test_switching_skin_preserves_all_default_english_scenarios(self):
        settings=(ROOT/'data/moc_settings.yaml').read_text(encoding='utf-8')
        enabled=set(re.findall(r'^  ([\w.]+):\n    ascii_mode: true$', settings, re.MULTILINE))
        self.assertEqual(enabled,ENGLISH_APPS)
        for relative in SKINS + ('data/squirrel.custom.yaml',):
            with self.subTest(skin=relative):
                config=(ROOT/relative).read_text(encoding='utf-8')
                self.assertIn('app_options:\n    __include: moc_settings:/app_options',config)
                self.assertIn('[candidate] [comment]',config)
                self.assertIn('candidate_list_layout: linear',config)
        self.assertEqual((ROOT/'data/squirrel.custom.yaml').read_bytes(),(ROOT/SKINS[1]).read_bytes())

    def test_shared_settings_are_consumed_by_both_schemas(self):
        settings=(ROOT/'data/moc_settings.yaml').read_text(encoding='utf-8')
        self.assertIn('page_size: 6',settings)
        self.assertIn('__include: moc_settings:/menu',(ROOT/'data/moc_wubi86_simp_plus.schema.yaml').read_text())
        self.assertIn('__include: moc_settings:/switcher/hotkeys',(ROOT/'data/default.custom.yaml').read_text())

    def test_each_skin_selects_existing_light_and_dark_palettes(self):
        for relative,light,dark in [
            (SKINS[0],'roseo_maple','roseo_maple_dark'),
            (SKINS[1],'blue_reverie','blue_reverie_dark')]:
            with self.subTest(skin=relative):
                config=(ROOT/relative).read_text(encoding='utf-8')
                self.assertIn('    color_scheme: '+light+'\n',config)
                self.assertIn('    color_scheme_dark: '+dark+'\n',config)
                self.assertIn('    '+light+':\n',config)
                self.assertIn('    '+dark+':\n',config)


if __name__=='__main__':unittest.main()
