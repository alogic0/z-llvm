from pathlib import Path
import struct
import subprocess
import tempfile
import unittest

from run_real_program import ROOT, object_contract


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


if __name__ == "__main__":
    unittest.main()
