import pathlib
import sys
from unittest import TestCase

sys.path.append(str(pathlib.Path(__file__).parent.parent))

from funnel_hash import FunnelHashTable


class TestFunnelHashTable(TestCase):
    def test_funnel_hash_normal(self):
        fh = FunnelHashTable(100)

        fh["foo"] = 1
        fh["bar"] = 2
        fh["baz"] = 3

    def test_funnel_hash_overflow(self):
        fh = FunnelHashTable(100)

        with self.assertRaises(RuntimeError):
            for i in range(101):
                fh[f"foo{i}"] = i

    def test_funnel_hash_get(self):
        fh = FunnelHashTable(100)

        fh["foo"] = 1
        fh["bar"] = 2
        fh["baz"] = 3

        self.assertEqual(fh["foo"], 1)
        self.assertEqual(fh.get("bar"), 2)
        self.assertEqual(fh.get("something else", None), None)

        with self.assertRaises(KeyError):
            fh.get("something else")

        with self.assertRaises(KeyError):
            fh["something else"]

    def test_funnel_hash_contains(self):
        fh = FunnelHashTable(100)

        fh["foo"] = 1
        fh["bar"] = 2
        fh["baz"] = 3

        self.assertIn("foo", fh)
        self.assertIn("bar", fh)
        self.assertIn("baz", fh)

        self.assertNotIn("something else", fh)

    def test_funnel_hash_del(self):
        fh = FunnelHashTable(100)

        fh["foo"] = 1
        fh["bar"] = 2
        fh["baz"] = 3

        del fh["foo"]
        del fh["bar"]
        del fh["baz"]

        self.assertNotIn("foo", fh)
        self.assertNotIn("bar", fh)
        self.assertNotIn("baz", fh)

        with self.assertRaises(KeyError):
            fh["foo"]

        with self.assertRaises(KeyError):
            fh["bar"]

        with self.assertRaises(KeyError):
            fh["baz"]

    def test_funnel_hash_pop(self):
        fh = FunnelHashTable(100)

        fh["foo"] = 1
        fh["bar"] = 2
        fh["baz"] = 3

        self.assertEqual(fh.pop("foo"), 1)
        self.assertEqual(fh.pop("bar"), 2)
        self.assertEqual(fh.pop("baz"), 3)

        with self.assertRaises(KeyError):
            fh.pop("foo")

        with self.assertRaises(KeyError):
            fh.pop("bar")

        with self.assertRaises(KeyError):
            fh.pop("baz")

    def test_funnel_hash_clear(self):
        fh = FunnelHashTable(100)

        fh["foo"] = 1
        fh["bar"] = 2
        fh["baz"] = 3

        fh.clear()

        self.assertNotIn("foo", fh)
        self.assertNotIn("bar", fh)
        self.assertNotIn("baz", fh)

    def test_funnel_hash_free(self):
        fh = FunnelHashTable(10)

        fh["foo1"] = 1

        for i in range(2, 100, 1):
            fh[f"foo{i}"] = i
            del fh[f"foo{i-1}"]

        self.assertEqual(len(fh), 1)

    def test_funnel_hash_data(self):
        data = [
            (0, 1),
            (1, 2),
            (2, 3),
            (3, 4),
            (4, 5),
            (5, 6),
            (6, 7),
            (7, 8),
            (8, 9),
            (9, 10),
            (10, 11),
        ]

        fh = FunnelHashTable(100, data)

        self.assertEqual(len(fh), 11)
        self.assertEqual(fh[0], 1)
        self.assertEqual(fh[1], 2)
        self.assertEqual(fh[2], 3)
        self.assertEqual(fh[3], 4)
        self.assertEqual(fh[4], 5)
        self.assertEqual(fh[5], 6)
        self.assertEqual(fh[6], 7)
        self.assertEqual(fh[7], 8)
        self.assertEqual(fh[8], 9)
        self.assertEqual(fh[9], 10)
        self.assertEqual(fh[10], 11)
