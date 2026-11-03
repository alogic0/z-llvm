import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from build_real_candidates_v3 import ROOT, scan
import real_candidate_facts as facts
import test_real_candidates_v3 as raw_tests


class Facts(unittest.TestCase):
    def fixture(self, directory):
        raw = raw_tests.Candidates().fixture(directory, [raw_tests.function("unique"), raw_tests.function("ambiguous"), raw_tests.function("ambiguous")])
        functions, descriptor, duplicates = scan(raw, "ReleaseFast", "test")
        path = Path(directory) / "facts.json"
        digest = facts.write_facts(path, "ReleaseFast", "test", descriptor, functions, duplicates)
        return path, digest, descriptor, functions, duplicates

    def load(self, path, digest, descriptor):
        return facts.load_facts(path, "ReleaseFast", "test", digest, descriptor)

    def mutate(self, path, payload):
        data = json.dumps(payload).encode()
        path.write_bytes(data)
        return hashlib.sha256(data).hexdigest()

    def test_every_fact_and_ambiguity_survives_raw_roundtrip(self):
        with tempfile.TemporaryDirectory() as directory:
            path, digest, descriptor, original, excluded = self.fixture(directory)
            self.assertEqual(self.load(path, digest, descriptor), (original, excluded))
            self.assertEqual(excluded, ["ambiguous"])
            with self.assertRaises(FileExistsError):
                facts.write_facts(path, "ReleaseFast", "test", descriptor, original, excluded)

    def test_payload_tampering_rejects_before_parsing(self):
        with tempfile.TemporaryDirectory() as directory:
            path, digest, descriptor, _, _ = self.fixture(directory)
            path.write_bytes(path.read_bytes() + b"changed")
            with self.assertRaisesRegex(ValueError, "hash mismatch"):
                self.load(path, digest, descriptor)

    def test_pin_mode_target_schema_and_raw_parent_must_match(self):
        with tempfile.TemporaryDirectory() as directory:
            path, _, descriptor, _, _ = self.fixture(directory)
            original = json.loads(path.read_text())
            for field, value in [("schema", "other"), ("source_pin", "other"), ("mode", "ReleaseSafe"),
                                 ("target", "aarch64-linux-gnu"), ("descriptor_sha256", "0" * 64)]:
                with self.subTest(field=field):
                    digest = self.mutate(path, {**original, field: value})
                    with self.assertRaisesRegex(ValueError, "identity mismatch"):
                        self.load(path, digest, descriptor)

    def test_population_and_effect_shapes_reject(self):
        with tempfile.TemporaryDirectory() as directory:
            path, _, descriptor, _, _ = self.fixture(directory)
            original = json.loads(path.read_text())
            changes = [{"unambiguous_functions": 2}, {"ambiguous_symbols_excluded": ["unique"]},
                       {"ambiguous_symbols_excluded": ["ambiguous", "ambiguous"]}]
            for change in changes:
                digest = self.mutate(path, {**original, **change})
                with self.assertRaises(ValueError):
                    self.load(path, digest, descriptor)
            for field, value in [("instructions", True), ("calls", -1), ("calls", 2), ("runtime_refs", 1),
                                 ("global_refs", 0.5), ("undefined_result", 0), ("typed_sha256", "unproved")]:
                with self.subTest(field=field):
                    payload = {**original, "functions": {"unique": {**original["functions"]["unique"], field: value}}}
                    digest = self.mutate(path, payload)
                    with self.assertRaises(ValueError):
                        self.load(path, digest, descriptor)

    def test_duplicate_json_keys_reject_even_with_matching_file_hash(self):
        with tempfile.TemporaryDirectory() as directory:
            path, _, descriptor, _, _ = self.fixture(directory)
            data = path.read_bytes().replace(b'"functions":{', b'"functions":{},"functions":{')
            path.write_bytes(data)
            with self.assertRaisesRegex(ValueError, "duplicate fact key"):
                self.load(path, hashlib.sha256(data).hexdigest(), descriptor)

    def test_builder_requires_one_complete_input_authority(self):
        with tempfile.TemporaryDirectory() as directory:
            args = [sys.executable, ROOT / "tools/build_real_candidates_v3.py", "--out", Path(directory) / "out.tsv",
                    "--audit", Path(directory) / "audit.json", "--releasefast-inventory", "unused"]
            for extra in ([], ["--facts-manifest", "unused", "--releasefast-air", "unused"]):
                result = subprocess.run([*args, *extra], capture_output=True, text=True)
                self.assertEqual(result.returncode, 2)
                self.assertIn("required" if not extra else "choose either", result.stderr)

    def test_historical_count_and_generated_rejection_list_share_a_contract(self):
        names = ["empty", "unstable"]
        self.assertEqual(facts.rejection_count({"unstable_signatures_or_empty_bodies_count": 2}), 2)
        self.assertEqual(facts.rejection_count({"unstable_signatures_or_empty_bodies": names}), 2)
        self.assertNotEqual(facts.rejection_digest(names), facts.rejection_digest(["other", "unstable"]))


if __name__ == "__main__":
    unittest.main()
