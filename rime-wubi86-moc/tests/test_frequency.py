import importlib.util
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('review_frequency',ROOT/'tools/review_frequency.py')
frequency=importlib.util.module_from_spec(spec);spec.loader.exec_module(frequency)

class FrequencyTests(unittest.TestCase):
    def test_independent_source_rescaling_does_not_change_relative_rarity(self):
        a={'常用':100,'一般':20,'冷门':1,'未知':8}
        b={'常用':900,'一般':30,'冷门':2}
        original=frequency.relative_rarity({'a':a,'b':b},set(a)|set(b))
        scaled=frequency.relative_rarity({'a':{t:c*1000000 for t,c in a.items()},'b':b},set(a)|set(b))
        self.assertEqual(original,scaled)
        self.assertLess(original['常用']['a'],original['冷门']['a'])

    def test_missing_is_unknown_not_zero_and_reference_is_shared(self):
        result=frequency.relative_rarity({'a':{'常用':10,'未收':3},'b':{'常用':10}}, {'常用','未收','缺失'})
        self.assertIsNone(result['未收']['b'])
        self.assertIsNone(result['缺失']['a'])
        self.assertEqual(result['常用']['a'],result['常用']['b'])

    def test_equal_frequency_has_equal_rank_and_word_lengths_are_separate(self):
        source={'常用':100,'一般':5,'冷门':5,'长词条甲':1,'长词条乙':1,'字':1000}
        out=frequency.relative_rarity({'a':source,'b':source},set(source))
        self.assertEqual(out['一般']['a'],out['冷门']['a'])
        self.assertEqual(out['长词条甲']['a'],.5)
        self.assertEqual(out['字']['a'],.5)

    def test_english_does_not_mix_with_chinese_frequency(self):
        out=frequency.relative_rarity({'a':{'中文':1,'hello':100},'b':{'中文':2,'hello':3}},{'中文','hello'})
        self.assertNotIn('hello',out)

    def test_invalid_or_negative_frequency_fails_instead_of_silently_using_it(self):
        with self.assertRaises(ValueError):
            frequency.relative_rarity({'a':{'中文':-1},'b':{'中文':2}},{'中文'})
