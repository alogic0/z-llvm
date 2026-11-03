from pathlib import Path
import struct
import subprocess
import tempfile
import unittest
import os
import sys

from run_real_program import ROOT, Runner, object_contract
from run_upstream_c_program import require_observation


class ObjectContract(unittest.TestCase):
    def test_linker_repacking_preserves_code_data_symbols_and_relocations(self):
        (ROOT / "tmp").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT / "tmp") as directory:
            directory = Path(directory)
            source = directory / "probe.s"
            source.write_text('.text\n.globl probe\n.type probe,@function\nprobe:\n call external\n ret\n.size probe,.-probe\n.data\n.byte 7,8,9\n')
            original, repacked = directory / "probe.o", directory / "repacked.o"
            subprocess.run(["cc", "-c", source, "-o", original], check=True, capture_output=True)
            subprocess.run(["ld", "-r", original, "-o", repacked], check=True, capture_output=True)
            contract = object_contract(original)
            self.assertEqual(contract, object_contract(repacked))
            self.assertTrue(contract["relocations"])
            changed = directory / "changed.o"
            data = bytearray(original.read_bytes())
            table, = struct.unpack_from("<Q", data, 40)
            count, = struct.unpack_from("<H", data, 60)
            for index in range(count):
                section = struct.unpack_from("<IIQQQQIIQQ", data, table + index * 64)
                if section[2] & 4 and section[5]:
                    data[section[4]] ^= 1
                    break
            changed.write_bytes(data)
            self.assertNotEqual(contract, object_contract(changed))
            changed.write_bytes(original.read_bytes().replace(b"external\0", b"altered!\0"))
            self.assertNotEqual(contract, object_contract(changed))

    def test_wrong_object_kind_rejects(self):
        (ROOT / "tmp").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT / "tmp") as directory:
            path = Path(directory) / "bad.o"
            path.write_bytes(b"not an ELF object")
            with self.assertRaisesRegex(RuntimeError, "ELF relocatable"):
                object_contract(path)


class ProgramObservation(unittest.TestCase):
    def test_argument_dependent_output_and_failure_status_are_checked(self):
        (ROOT / "tmp").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT / "tmp") as temporary:
            directory = Path(temporary)
            runner = Runner(directory)
            case = {"argv": ["-c", "print('val=123')"], "stdout": "val=123\n", "exit_status": 0}
            require_observation(runner, sys.executable, case, directory / "matching", os.environ)
            for name, code in [("wrong-output", "print('val=456')"), ("nonzero", "raise SystemExit(1)"),
                               ("stderr", "import sys; print('val=123'); print('failure', file=sys.stderr)")]:
                changed = {**case, "argv": ["-c", code]}
                with self.assertRaisesRegex(RuntimeError, "observation differs"):
                    require_observation(runner, sys.executable, changed, directory / name, os.environ)


if __name__ == "__main__":
    unittest.main()
