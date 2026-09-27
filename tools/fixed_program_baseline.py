#!/usr/bin/env python3
"""Standalone, non-gating measurement of the frozen architecture-plan matrix."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import signal
import statistics
import struct
import subprocess
import sys
import time


ROOT = Path(__file__).resolve().parents[1]
ROUTES = ("direct", "release-o3", "llvm-O3")
WARMUPS = 2
SAMPLES = 9


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")


def snapshot():
    paths = subprocess.check_output(
        ["git", "ls-files", "src", "build.zig", ".zigversion"], cwd=ROOT
    ).decode().splitlines()
    return {p: sha(ROOT / p) for p in paths}


def stats(values):
    median = statistics.median(values)
    return {"median": median, "min": min(values), "max": max(values),
            "mad": statistics.median(abs(x - median) for x in values)}


def executable_bytes(path):
    """Sum ELF64 section sizes with SHF_EXECINSTR, excluding harness/link output."""
    data = path.read_bytes()
    if data[:6] != b"\x7fELF\x02\x01":
        raise RuntimeError("expected little-endian ELF64")
    offset = struct.unpack_from("<Q", data, 40)[0]
    entry_size, count = struct.unpack_from("<HH", data, 58)
    if entry_size != 64 or count == 0:
        raise RuntimeError("unsupported ELF section table")
    return sum(struct.unpack_from("<Q", data, offset + i * 64 + 32)[0]
               for i in range(count)
               if struct.unpack_from("<Q", data, offset + i * 64 + 8)[0] & 4)


class Runner:
    def __init__(self, output):
        self.output = output
        self.commands = []

    def run(self, argv, stem, stdout_file=None, check=True):
        argv = [str(a) for a in argv]
        output_path = stdout_file or Path(str(stem) + ".stdout")
        with output_path.open("wb") as out, Path(str(stem) + ".stderr").open("wb") as err:
            start = time.perf_counter_ns()
            # Blocking waitpid avoids the polling/rounding overhead of Python's
            # timeout wait loop, which would dominate short compiler processes.
            result = subprocess.run(argv, cwd=ROOT, stdout=out, stderr=err)
            elapsed = time.perf_counter_ns() - start
        self.commands.append({"argv": argv, "stdout": str(output_path),
                              "stderr": str(stem) + ".stderr", "returncode": result.returncode,
                              "wall_ns": elapsed})
        write_json(self.output / "commands.json", self.commands)
        if check and result.returncode:
            raise RuntimeError(f"command failed ({result.returncode}): {argv}; see {stem}.stderr")
        return result.returncode, elapsed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--compiler", required=True, type=Path, help="prebuilt ReleaseFast z_llvm")
    parser.add_argument("--zig", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path, help="new evidence directory")
    parser.add_argument("--cpu", required=True, type=int, help="allowed logical CPU for serial execution")
    args = parser.parse_args()
    os.chdir(ROOT)
    if args.cpu not in os.sched_getaffinity(0):
        parser.error("CPU is outside the process affinity set")
    os.sched_setaffinity(0, {args.cpu})
    args.compiler = args.compiler.resolve(strict=True)
    args.zig = args.zig.resolve(strict=True)
    args.output = args.output.resolve()
    args.output.mkdir(parents=True, exist_ok=False)
    runner = Runner(args.output)
    tools = {"z_llvm": args.compiler, "zig": args.zig}
    for name in ("clang-22", "opt-22", "readelf"):
        located = shutil.which(name)
        if not located:
            raise RuntimeError(f"missing required tool: {name}")
        tools[name] = Path(located).resolve()
    versions = {}
    for name in ("zig", "clang-22", "opt-22", "readelf"):
        stem = args.output / (name + "-version")
        runner.run([tools[name], "version" if name == "zig" else "--version"], stem)
        versions[name] = Path(str(stem) + ".stdout").read_text().strip()
    if versions["zig"] != "0.16.0":
        raise RuntimeError("Zig 0.16.0 required")
    frozen = json.loads((ROOT / "test/behavioral/performance_manifest.json").read_text())
    for path, expected in frozen["inputs_sha256"].items():
        if sha(ROOT / path) != expected:
            raise RuntimeError(f"frozen input changed: {path}")
    source_state = snapshot()
    metadata = {
        "schema": 1, "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "invocation": [sys.executable, *sys.argv], "cwd": str(ROOT),
        "git_head": subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip(),
        "git_status": subprocess.check_output(["git", "status", "--short"]).decode(),
        "source_sha256": source_state, "frozen_manifest": frozen,
        "runner_sha256": sha(__file__), "manifest_sha256": sha(ROOT / "test/behavioral/performance_manifest.json"),
        "tools": {name: {"path": str(path), "sha256": sha(path), "version": versions.get(name)} for name, path in tools.items()},
        "compiler_build": "zig 0.16.0 build -Doptimize=ReleaseFast --prefix OUTPUT/compiler (outside measurement)",
        "platform": platform.platform(), "cpu_affinity": sorted(os.sched_getaffinity(0)),
        "cpuinfo": Path("/proc/cpuinfo").read_text(), "warmups": WARMUPS, "samples": SAMPLES,
        "target": "x86_64-unknown-linux-gnu", "harness": "ReleaseFast x86_64-linux-gnu baseline CPU, no LTO",
        "cache": "warm OS page cache; no cache flush; fresh compiler processes; no compiler result cache",
        "timing": "perf_counter_ns subprocess wall time; IR-to-object excludes build/link/verify/hash; runtime includes process startup and driver",
    }
    cpu_root = Path(f"/sys/devices/system/cpu/cpu{args.cpu}/cpufreq")
    metadata["frequency_policy"] = {name: (cpu_root / name).read_text().strip()
                                    for name in ("scaling_governor", "scaling_driver", "scaling_min_freq", "scaling_max_freq")
                                    if (cpu_root / name).exists()}
    write_json(args.output / "metadata.json", metadata)
    rows = []
    for workload in frozen["workloads"]:
        case = workload["id"]
        case_dir = args.output / case
        case_dir.mkdir()
        original = case_dir / "input.ll"
        sources = [Path(p).read_bytes() for p in workload["sources"]]
        source = sources[0]
        if len(sources) == 2:
            source += b"\n" + sources[1][sources[1].index(b"define "):]
        original.write_bytes(source)
        runner.run([tools["opt-22"], "-passes=verify", "-disable-output", original], case_dir / "verify-original")
        prepared = {}
        # Independent LLVM always consumes the original source, never local optimized IR.
        for route in ("llvm-O3", "direct", "release-o3"):
            directory = case_dir / route
            directory.mkdir()
            obj = directory / "program.o"
            row = {"workload": case, "route": route, "input_sha256": sha(original),
                   "status": "supported", "compile_samples": [], "runtime_ns": []}
            input_ir = original
            stages = []
            if route == "release-o3":
                input_ir = directory / "optimized.ll"
                stages.append(("optimizer", [args.compiler, "--passes=release-o3", original], input_ir))
                code, _ = runner.run(stages[0][1], directory / "prepare-optimizer", input_ir, check=False)
                if code:
                    diagnostic = (directory / "prepare-optimizer.stderr").read_text()
                    expected = frozen["unsupported"].get(case + "/" + route)
                    if expected != {"stage": "optimizer", "returncode": code, "stderr": diagnostic}:
                        raise RuntimeError(f"unexpected optimizer failure: {directory}")
                    row.update(status="unsupported", stage="optimizer", diagnostic=diagnostic)
                    rows.append(row)
                    continue
                runner.run([tools["opt-22"], "-passes=verify", "-disable-output", input_ir], directory / "verify-optimized")
            if route == "llvm-O3":
                stages.append(("codegen", [tools["clang-22"], "--target=x86_64-unknown-linux-gnu", "-march=x86-64", "-Wno-override-module", "-O3", "-c", original, "-o", obj], None))
            else:
                base = [args.compiler, "--target=x86_64-unknown-linux-gnu", "--generic-cfg-selector"]
                stages.append(("codegen", [*base, "--emit=obj", input_ir], obj))
            code, _ = runner.run(stages[-1][1], directory / "prepare-codegen", stages[-1][2], check=False)
            if code:
                diagnostic = (directory / "prepare-codegen.stderr").read_text()
                expected = frozen["unsupported"].get(case + "/" + route)
                if expected != {"stage": "codegen", "returncode": code, "stderr": diagnostic}:
                    raise RuntimeError(f"unexpected compile failure: {directory}")
                row.update(status="unsupported", stage="codegen", diagnostic=diagnostic)
                rows.append(row)
                continue
            if case + "/" + route in frozen["unsupported"]:
                raise RuntimeError("support changed; revise the versioned protocol before measuring")
            if route != "llvm-O3":
                owners = directory / "owners.tsv"
                runner.run([*base, "--emit=selection-owner-manifest", input_ir], directory / "ownership", owners)
                lines = owners.read_text().splitlines()
                if not lines or lines[0] != "row_identity\tselection_owner":
                    raise RuntimeError("invalid owner header")
                expected_functions = re.findall(r"^define\s.*?@(?:\"([^\"]+)\"|([^\s(]+))\(", input_ir.read_text(), re.M)
                expected_names = {a or b for a, b in expected_functions}
                ownership = dict(line.split("\t") for line in lines[1:])
                if set(ownership) != expected_names or len(lines) - 1 != len(expected_names) or not all(v in ("composed_block", "composed_cfg") for v in ownership.values()):
                    raise RuntimeError(f"missing, duplicate, or non-composed ownership: {owners}")
                row["ownership"] = ownership
            row["object_sha256"] = sha(obj)
            row["object_bytes"] = obj.stat().st_size
            row["executable_section_bytes"] = executable_bytes(obj)
            runner.run([tools["readelf"], "-SW", obj], directory / "sections")
            runner.run([tools["readelf"], "-Ws", obj], directory / "symbols")
            row["undefined_symbols"] = [line.split()[-1] for line in (directory / "symbols.stdout").read_text().splitlines() if " UND " in line and len(line.split()) == 8]
            for kind, driver in (("semantic", workload["semantic_driver"]), ("runtime", workload["runtime_driver"])):
                exe = directory / kind
                runner.run([args.zig, "build-exe", driver, obj, "-O", "ReleaseFast", "-target", "x86_64-linux-gnu", "-mcpu=baseline", "-femit-bin=" + str(exe)], directory / ("link-" + kind))
                runner.run([exe], directory / ("check-" + kind))
                actual = (directory / ("check-" + kind + ".stdout")).read_bytes()
                if (directory / ("check-" + kind + ".stderr")).stat().st_size:
                    raise RuntimeError("unexpected driver stderr")
                if route != "llvm-O3" and actual != (case_dir / "llvm-O3" / ("check-" + kind + ".stdout")).read_bytes():
                    raise RuntimeError(f"semantic mismatch: {directory} {kind}")
                if kind == "semantic":
                    if case == "memset":
                        if not actual.startswith(b"memset observations=1442 "):
                            raise RuntimeError("missing memset observations")
                        for trap in ("checked", "ssp"):
                            code, _ = runner.run([exe, trap], directory / ("trap-" + trap), check=False)
                            if code != -signal.SIGILL:
                                raise RuntimeError("missing bounds trap")
                    elif len(actual.splitlines()) != 272:
                        raise RuntimeError("missing scalar observations")
            row["semantic_stdout_sha256"] = sha(directory / "check-semantic.stdout")
            row["runtime_stdout_sha256"] = sha(directory / "check-runtime.stdout")
            row["runtime_executable_sha256"] = sha(directory / "runtime")
            row["linked_harness_bytes"] = (directory / "runtime").stat().st_size
            row["stage_input_sha256"] = sha(input_ir)
            prepared[route] = (directory, obj, input_ir, stages, row)
            rows.append(row)
        # Warm each path, then rotate route order to reduce systematic order bias.
        for sample in range(-WARMUPS, SAMPLES):
            order = ROUTES[sample % 3:] + ROUTES[:sample % 3]
            for route in order:
                if route not in prepared:
                    continue
                directory, obj, input_ir, stages, row = prepared[route]
                durations = {}
                for stage, argv, output in stages:
                    _, elapsed = runner.run(argv, directory / f"compile-{sample}-{stage}", output)
                    durations[stage + "_ns"] = elapsed
                if sha(obj) != row["object_sha256"] or sha(input_ir) != row["stage_input_sha256"]:
                    raise RuntimeError("nondeterministic compilation")
                durations["total_ns"] = sum(durations.values())
                if sample >= 0:
                    row["compile_samples"].append(durations)
            for route in order:
                if route not in prepared:
                    continue
                directory, _, _, _, row = prepared[route]
                stem = directory / f"runtime-{sample}"
                _, elapsed = runner.run([directory / "runtime"], stem)
                if sha(Path(str(stem) + ".stdout")) != row["runtime_stdout_sha256"] or Path(str(stem) + ".stderr").stat().st_size:
                    raise RuntimeError("runtime sample semantic mismatch")
                if sample >= 0:
                    row["runtime_ns"].append(elapsed)
        for route, (_, _, _, _, row) in prepared.items():
            row["compile_stats_ns"] = {key: stats([s[key] for s in row["compile_samples"]]) for key in row["compile_samples"][0]}
            row["runtime_stats_ns"] = stats(row["runtime_ns"])
            print(f"{case} {route}: compile={row['compile_stats_ns']['total_ns']['median']/1e6:.3f}ms runtime={row['runtime_stats_ns']['median']/1e6:.3f}ms object={row['object_bytes']} code={row['executable_section_bytes']}", flush=True)
        write_json(args.output / "results.json", {"schema": 1, "complete": False, "rows": rows})
    if source_state != snapshot() or any(sha(path) != frozen["inputs_sha256"][path] for path in frozen["inputs_sha256"]):
        raise RuntimeError("source/input changed during measurement")
    if sha(__file__) != metadata["runner_sha256"] or sha(ROOT / "test/behavioral/performance_manifest.json") != metadata["manifest_sha256"]:
        raise RuntimeError("measurement procedure changed during execution")
    if any(sha(path) != metadata["tools"][name]["sha256"] for name, path in tools.items()):
        raise RuntimeError("compiler/tool changed during measurement")
    write_json(args.output / "results.json", {"schema": 1, "complete": True, "rows": rows})


if __name__ == "__main__":
    main()
