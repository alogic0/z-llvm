#!/usr/bin/env python3
"""Run an unchanged pinned upstream Zig program through both compiler routes."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shlex
import shutil
import signal
import subprocess
import struct
import sys
import time


ROOT = Path(__file__).resolve().parents[1]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")


def object_contract(path):
    """Compare the hook object through Zig's relocatable linker repacking."""
    data = path.read_bytes()
    if data[:6] != b"\x7fELF\x02\x01" or struct.unpack_from("<HH", data, 16) != (1, 62):
        raise RuntimeError("expected an x86_64 little-endian ELF relocatable object")
    offset, = struct.unpack_from("<Q", data, 40)
    entry_size, count, string_index = struct.unpack_from("<HHH", data, 58)
    if entry_size != 64 or count == 0 or string_index >= count:
        raise RuntimeError("unsupported ELF section table")
    sections = [struct.unpack_from("<IIQQQQIIQQ", data, offset + i * 64) for i in range(count)]

    def payload(section):
        return data[section[4]:section[4] + section[5]]

    def string(table, start):
        end = table.index(0, start)
        return table[start:end].decode("utf-8")

    names = [string(payload(sections[string_index]), section[0]) for section in sections]
    allocated = []
    symbols = {}
    defined = []
    for index, section in enumerate(sections):
        if section[2] & 2:
            content = b"" if section[1] == 8 else payload(section)
            allocated.append((names[index], section[1], section[2], section[5], hashlib.sha256(content).hexdigest()))
        if section[1] != 2:
            continue
        if section[9] != 24:
            raise RuntimeError("unsupported ELF symbol size")
        table = payload(sections[section[6]])
        entries = []
        for position in range(section[4], section[4] + section[5], 24):
            name, info, other, owner, value, size = struct.unpack_from("<IBBHQQ", data, position)
            kind = info & 15
            symbol = string(table, name) if kind != 3 else names[owner]
            entries.append(symbol)
            if symbol and kind != 3:
                defined.append((symbol, info, other, names[owner] if owner < count else owner, value, size))
        symbols[index] = entries
    relocations = []
    for section in sections:
        if section[1] == 9:
            raise RuntimeError("unsupported ELF REL relocation")
        if section[1] != 4:
            continue
        if section[9] != 24:
            raise RuntimeError("unsupported ELF relocation size")
        for position in range(section[4], section[4] + section[5], 24):
            location, info, addend = struct.unpack_from("<QQq", data, position)
            relocations.append((names[section[7]], location, info & 0xffffffff, symbols[section[6]][info >> 32], addend))
    return {"allocated_sections": sorted(allocated), "symbols": sorted(defined), "relocations": sorted(relocations)}


def capture_zllvm():
    """Preserve the hook's small inputs/streams before Zig removes temp files."""
    directory = Path(os.environ["ZLLVM_CAPTURE_DIR"])
    executable = Path(os.environ["ZLLVM_CAPTURE_EXE"])
    argv = sys.argv[2:]
    is_object = "--emit=obj" in argv
    stem = "object" if is_object else "optimize"
    shutil.copyfile(ROOT / argv[-1], directory / ("object-input.ll" if is_object else "preopt.ll"))
    stdout_path = directory / ("local.o" if is_object else "optimized.ll")
    stderr_path = directory / f"{stem}.stderr"
    start = time.perf_counter_ns()
    with stdout_path.open("wb") as stdout, stderr_path.open("wb") as stderr:
        process = subprocess.run([executable, *argv], stdout=stdout, stderr=stderr)
    write_json(directory / f"{stem}-command.json", {"argv": [str(executable), *argv], "returncode": process.returncode,
                                                   "wall_ns": time.perf_counter_ns() - start})
    with stdout_path.open("rb") as stdout, stderr_path.open("rb") as stderr:
        shutil.copyfileobj(stdout, sys.stdout.buffer)
        shutil.copyfileobj(stderr, sys.stderr.buffer)
    sys.stdout.buffer.flush()
    sys.stderr.buffer.flush()
    if process.returncode < 0:
        signal.signal(-process.returncode, signal.SIG_DFL)
        os.kill(os.getpid(), -process.returncode)
    return process.returncode


class Runner:
    def __init__(self, output):
        self.output = output
        self.commands = []

    def run(self, argv, stem, env, timeout=120):
        argv = [str(arg) for arg in argv]
        with stem.with_suffix(".stdout").open("wb") as stdout, stem.with_suffix(".stderr").open("wb") as stderr:
            start = time.perf_counter_ns()
            try:
                code = subprocess.run(argv, cwd=ROOT, env=env, stdout=stdout, stderr=stderr, timeout=timeout).returncode
            except subprocess.TimeoutExpired:
                code = 124
            except OSError as error:
                stderr.write(str(error).encode())
                code = 127
        self.commands.append({"argv": argv, "returncode": code, "wall_ns": time.perf_counter_ns() - start,
                              "stdout": str(stem.with_suffix(".stdout")), "stderr": str(stem.with_suffix(".stderr"))})
        write_json(self.output / "commands.json", self.commands)
        return code


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-root", required=True, type=Path, help="new evidence directory inside this project")
    parser.add_argument("--zig-source", type=Path, default=ROOT.parent / "ziglang")
    parser.add_argument("--zig-emitter", type=Path)
    parser.add_argument("--zllvm", type=Path, default=ROOT / "zig-out/bin/z_llvm")
    parser.add_argument("--linker", default="cc")
    args = parser.parse_args()
    output = args.output_root.resolve()
    if not output.is_relative_to(ROOT) or output == ROOT:
        parser.error("evidence must be kept in a new directory inside this project")
    output.mkdir(parents=True, exist_ok=False)
    runner = Runner(output)
    report = {"schema": "real-program-v1", "population": "unchanged-upstream-zig-program",
              "status": "failed", "local_executions": 0, "reference_executions": 0,
              "matched_program_modes": 0, "rows": []}
    try:
        if platform.system() != "Linux" or platform.machine() != "x86_64":
            raise RuntimeError("this bounded gate requires x86_64 Linux")
        manifest = json.loads((ROOT / "test/real_programs/hello_libc.json").read_text())
        zig_source = args.zig_source.resolve()
        zig = (args.zig_emitter or zig_source / "build/stage4/bin/zig").resolve()
        zllvm = args.zllvm.resolve()
        pin = (ROOT / "docs/evidence/ziglang_pin.txt").read_text().strip()
        identity = dict(re.findall(r"^(ABI_DIFF_\w+)='([^']+)'$", (ROOT / "test/abi_diff/reference_identity.env").read_text(), re.M))
        if identity["ABI_DIFF_SOURCE_REVISION"] != pin:
            raise RuntimeError("reference identity contract differs from the tracked Zig pin")
        if subprocess.check_output(["git", "-C", zig_source, "rev-parse", "HEAD"], text=True).strip() != pin:
            raise RuntimeError("Zig source revision differs from the tracked pin")
        if subprocess.check_output([zig, "version"], text=True).strip() != identity["ABI_DIFF_REFERENCE_VERSION"]:
            raise RuntimeError("Zig emitter identity differs from the reference contract")
        source = zig_source / manifest["source"]
        if digest(source) != manifest["source_sha256"]:
            raise RuntimeError("upstream program source hash changed; audit the manifest before running")
        if source.read_bytes() != subprocess.check_output(["git", "-C", zig_source, "show", f"{pin}:{manifest['source']}"]):
            raise RuntimeError("upstream program has local modifications")
        report.update({"source": str(source), "source_sha256": digest(source), "zig_revision": pin,
                       "zllvm_sha256": digest(zllvm), "source_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
                       "target": manifest["target"], "cpu": manifest["cpu"], "pipeline": manifest["local_pipeline"],
                       "remaining_dependencies": manifest["remaining_dependencies"], "programs": 1, "program_modes": len(manifest["modes"])})
        base_env = {key: value for key, value in os.environ.items()
                    if not key.startswith(("ZLLVM_", "ZIG_USE_ZLLVM"))}
        global_cache = output / "global-cache"
        for mode in manifest["modes"]:
            directory = output / mode
            directory.mkdir()
            row = {"mode": mode, "status": "failed", "failure_stage": "reference-compile", "local_executions": 0}
            report["rows"].append(row)
            common = [zig, "build-obj", source, "-lc", f"-O{mode}", "-target", manifest["target"],
                      f"-mcpu={manifest['cpu']}", "-fllvm", "-flibllvm", "-fno-lto", "-fno-stack-protector",
                      "-fno-unwind-tables", "--global-cache-dir", global_cache]
            reference = directory / "reference.o"
            if runner.run([*common, "--cache-dir", directory / "reference-cache", f"-femit-bin={reference}"], directory / "reference-compile", base_env):
                continue
            if runner.run([args.linker, "-no-pie", reference, "-o", directory / "reference"], directory / "reference-link", base_env):
                row["failure_stage"] = "reference-link"
                continue
            report["reference_executions"] += 1
            status = runner.run([directory / "reference"], directory / "reference-run", base_env, timeout=5)
            stdout = directory / "reference-run.stdout"
            if status != manifest["exit_status"] or stdout.read_bytes() != manifest["stdout"].encode() or (directory / "reference-run.stderr").stat().st_size:
                row["failure_stage"] = "reference-execution"
                continue
            candidate = directory / "candidate.o"
            marker = directory / "candidate.marker"
            capture = directory / "capture"
            capture.mkdir()
            proxy = directory / "capture-zllvm"
            proxy.write_text(f"#!/bin/sh\nexec python3 {shlex.quote(str(Path(__file__).resolve()))} --capture-zllvm \"$@\"\n")
            proxy.chmod(0o755)
            local_env = {**base_env, "ZIG_USE_ZLLVM_OBJECT": "1", "ZLLVM_PIPELINE": manifest["local_pipeline"],
                         "ZLLVM_EXE": str(proxy), "ZLLVM_CAPTURE_EXE": str(zllvm), "ZLLVM_CAPTURE_DIR": str(capture),
                         "ZLLVM_ZIG_MODE": mode, "ZLLVM_GENERIC_CFG_SELECTOR": "1", "ZLLVM_MARKER_PATH": str(marker)}
            if runner.run([*common, "--cache-dir", directory / "candidate-cache", f"-femit-bin={candidate}"], directory / "local-compile", local_env):
                diagnostic = (directory / "local-compile.stderr").read_text(errors="replace")
                stage = re.search(r"failure_category=(\w+)", diagnostic)
                row.update({"failure_stage": stage.group(1) if stage else "local-compile", "diagnostic": diagnostic[-8192:]})
                # The Zig hook reports the failed stage but can omit the child
                # compiler's diagnostic. Replay only that captured object input.
                if row["failure_stage"] == "object":
                    object_input = capture / "object-input.ll"
                    if object_input.is_file():
                        runner.run([zllvm, "--report-all-codegen-failures", "--generic-cfg-selector", "--emit=obj",
                                    "--target=x86_64-unknown-linux-gnu", "--input-limit=67108864", object_input], directory / "codegen-failures", base_env)
                        row["codegen_diagnostic"] = (directory / "codegen-failures.stderr").read_text(errors="replace")[-8192:]
                continue
            fields = dict(re.findall(r"(\w+)=([^\s]+)", marker.read_text()))
            if fields.get("pipeline") != "preopt" or fields.get("mode") != mode:
                raise RuntimeError("local hook marker does not prove the selected optimizer route")
            captured = (ROOT / fields["ir"]).resolve()
            hook_object = (ROOT / fields["object"]).resolve()
            optimized = capture / "object-input.ll"
            if not captured.is_relative_to(directory) or not optimized.is_relative_to(directory) or not hook_object.is_relative_to(directory):
                raise RuntimeError("hook artifacts escaped the runner-owned directory")
            if fields.get("zllvm_passes") != {"ReleaseFast": "zig-release-fast-accepted", "ReleaseSafe": "zig-release-safe-accepted", "ReleaseSmall": "zig-release-small-accepted"}[mode]:
                raise RuntimeError("local hook marker does not identify the accepted mode pipeline")
            if not optimized.is_file():
                raise RuntimeError("local optimized IR is missing")
            hook_contract = object_contract(capture / "local.o")
            if hook_contract != object_contract(candidate):
                raise RuntimeError("linked candidate changed hook sections, symbols or relocations")
            write_json(directory / "object-contract.json", hook_contract)
            row["hook_object_sha256"] = digest(capture / "local.o")
            owners = directory / "owners"
            if runner.run([zllvm, "--emit=selection-owner-manifest", "--generic-cfg-selector", "--target=x86_64-unknown-linux-gnu", "--input-limit=67108864", optimized], owners, base_env):
                row["failure_stage"] = "selection-owner-manifest"
                continue
            owner_lines = owners.with_suffix(".stdout").read_text().splitlines()[1:]
            owner_counts = {}
            for line in owner_lines:
                owner = line.split("\t")[1]
                owner_counts[owner] = owner_counts.get(owner, 0) + 1
            row.update({"selector_owners": owner_counts, "object_bytes": candidate.stat().st_size, "object_sha256": digest(candidate)})
            if runner.run([args.linker, "-no-pie", candidate, "-o", directory / "candidate"], directory / "local-link", base_env):
                row["failure_stage"] = "local-link"
                continue
            row["local_executions"] += 1
            report["local_executions"] += 1
            status = runner.run([directory / "candidate"], directory / "local-run", base_env, timeout=5)
            if status != manifest["exit_status"] or (directory / "local-run.stdout").read_bytes() != stdout.read_bytes() or (directory / "local-run.stderr").stat().st_size:
                row["failure_stage"] = "local-execution"
                continue
            row.update({"status": "matched", "failure_stage": None})
            report["matched_program_modes"] += 1
        report["status"] = "passed" if report["matched_program_modes"] == len(manifest["modes"]) else "blocked"
    except (KeyError, OSError, RuntimeError, subprocess.SubprocessError, ValueError) as error:
        report["error"] = str(error)
    finally:
        write_json(output / "report.json", report)
        print(f"summary real-program schema=real-program-v1 programs=1 program_modes=3 reference_executions={report['reference_executions']} local_executions={report['local_executions']} matched_program_modes={report['matched_program_modes']} local_fail={int(report['status'] != 'passed')}")
        print(json.dumps({key: report[key] for key in ("status", "local_executions", "reference_executions", "matched_program_modes")}, sort_keys=True))
        print(f"evidence: {output / 'report.json'}")
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(capture_zllvm() if sys.argv[1:2] == ["--capture-zllvm"] else main())
