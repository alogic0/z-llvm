import hashlib
from pathlib import Path
import tempfile
import unittest

from build_real_candidates_v3 import MODES, derive, scan


def framed(key, value):
    value = value.encode()
    return f"{key}={len(value)}\n".encode() + value + b"\n"


def function(name, count=1):
    return (b"function_begin\n" + framed("name_bytes", name) + framed("type_bytes", "fn () u32") +
            f"instruction_count={count}\nmain_body_count=1\nliveness=present\n".encode() +
            framed("air_bytes", "") + framed("structured_air_bytes", "") +
            framed("structured_air_v2_bytes", "structured_air-v2\ntyped_inst|0|ret|8|noreturn|un_op|0\nstructured_air_v2_end\n") + b"function_end\n")


class Candidates(unittest.TestCase):
    def fixture(self, directory, functions, mode="ReleaseFast"):
        path = Path(directory) / "input.air"
        data = (f"zllvm-air-export-v1\ncontract_version=1\npayload=zig-air-print-v1\nproducer=test\nroot_source=main.zig\nwrapper=main.zig\nmode={mode}\ntarget=x86_64-linux-gnu\nfunction_count={len(functions)}\nglobal_count=0\n".encode() + b"".join(functions))
        path.write_bytes(data)
        path.with_suffix(".meta").write_text(f"schema=3\nziglang_pin=test\nmode={mode}\ndescriptor_sha256={hashlib.sha256(data).hexdigest()}\n")
        return path

    def test_ambiguous_symbols_are_excluded(self):
        with tempfile.TemporaryDirectory() as directory:
            path = self.fixture(directory, [function("overload"), function("unique"), function("overload")])
            functions, _, duplicates = scan(path, "ReleaseFast", "test")
            self.assertEqual(set(functions), {"unique"})
            self.assertEqual(duplicates, ["overload"])

    def test_incomplete_body_rejects(self):
        with tempfile.TemporaryDirectory() as directory:
            path = self.fixture(directory, [function("broken", count=2)])
            with self.assertRaisesRegex(ValueError, "incomplete typed body"):
                scan(path, "ReleaseFast", "test")

    def test_hash_and_mode_drift_reject(self):
        with tempfile.TemporaryDirectory() as directory:
            path = self.fixture(directory, [function("probe")])
            with self.assertRaisesRegex(ValueError, "identity mismatch"):
                scan(path, "ReleaseSafe", "test")
            with path.open("ab") as output:
                output.write(b"changed")
            with self.assertRaisesRegex(ValueError, "hash mismatch"):
                scan(path, "ReleaseFast", "test")

    def test_mode_stability_and_defined_results_control_selection(self):
        base = {"signature": "fn () u32", "instructions": 2, "calls": 0, "global_refs": 0, "runtime_refs": 0, "undefined_result": False, "typed_sha256": "test"}
        modes = {mode: {"defined": dict(base), "undefined": {**base, "instructions": 1, "undefined_result": True}, "unstable": dict(base)} for mode in MODES}
        modes["ReleaseSafe"]["unstable"]["signature"] = "fn () u64"
        inventory = {name: {"signature_class": "internal-callable", "harnessable_reason": "harnessable:leaf_no_refs_supported"} for name in modes["ReleaseFast"]}
        rows, rejected = derive(modes, inventory)
        self.assertEqual([row["function"] for row in rows], ["defined", "undefined"])
        self.assertEqual(rejected, ["unstable"])
        self.assertEqual(rows[1]["harnessable_reason"], "proven_unharnessable:undefined-result")
        modes["ReleaseFast"] = dict(reversed(list(modes["ReleaseFast"].items())))
        self.assertEqual(rows, derive(modes, inventory)[0])


if __name__ == "__main__":
    unittest.main()
