#!/usr/bin/env python3
"""Execute Zig's unchanged C compiler fixture through local optimizer/codegen."""
import argparse
import json
import os
import platform
from pathlib import Path
import re
import subprocess
import sys

from run_real_program import ROOT, Runner, digest, object_contract, write_json


PIPELINES = {"ReleaseFast": "zig-release-fast-accepted", "ReleaseSafe": "zig-release-safe-accepted",
             "ReleaseSmall": "zig-release-small-accepted"}
LLVM_OPT = {"ReleaseFast": "-O3", "ReleaseSafe": "-O2", "ReleaseSmall": "-Oz"}


def require_observation(runner, executable, case, stem, environment):
    status = runner.run([executable, *case["argv"]], stem, environment, timeout=5)
    if status != case["exit_status"] or stem.with_suffix(".stdout").read_bytes() != case["stdout"].encode() or stem.with_suffix(".stderr").read_bytes():
        raise RuntimeError(f"program observation differs: {stem.name}")


def run_variadic_canary(runner, directory, zllvm, environment):
    fixture = ROOT / "test/real_programs/variadic_integer.ll"
    optimized = directory / "varargs-optimized.ll"
    stem = directory / "varargs-optimize"
    if runner.run([zllvm, "--passes=verify,instcombine,dce,verify", fixture], stem, environment):
        raise RuntimeError("integer-varargs optimizer failed")
    optimized.write_bytes(stem.with_suffix(".stdout").read_bytes())
    stem = directory / "varargs-object"
    if runner.run([zllvm, "--generic-cfg-selector", "--emit=obj", "--target=x86_64-unknown-linux-gnu", optimized], stem, environment):
        raise RuntimeError("integer-varargs object emission failed")
    obj = directory / "varargs.o"
    obj.write_bytes(stem.with_suffix(".stdout").read_bytes())
    driver = ROOT / "test/real_programs/variadic_integer_driver.c"
    shim = ROOT / "test/real_programs/variadic_integer_shim.S"
    executable = directory / "varargs-canary"
    if runner.run(["cc", "-O2", "-no-pie", driver, shim, obj, "-o", executable], directory / "varargs-link", environment):
        raise RuntimeError("integer-varargs native canary link failed")
    expected = {"argv": [], "exit_status": 0, "stdout": "integer-call-canary varargs_cases=16 heap_cases=6 al=0 pointers=preserved live=preserved\n"}
    require_observation(runner, executable, expected, directory / "varargs-run", environment)
    return 22


MEMORY_CANARIES = {
    "global_addresses": {
        "prefix": "global-addresses", "fixture": "global_addresses",
        "functions": {"global_object_address", "global_payload_address", "global_bits_address", "global_live_offset"},
        "observations": 32,
        "stdout": "global-addresses observations=32 layout=pointers=alignment=live=preserved\n",
    },
    "global_memory": {
        "prefix": "global-memory", "fixture": "global_memory",
        "functions": {"global_copy_destination", "global_copy_source", "global_copy2", "global_copy12", "global_copy16", "global_copy80", "global_store_scalars"},
        "observations": 40,
        "stdout": "global-memory observations=40 lengths=2,12,16,80 stores=8,16,32 pointers=live=guards=preserved\n",
    },
    "type_layout_padding": {
        "prefix": "type-layout-padding", "fixture": "type_layout_padding",
        "functions": {"layout_i24_field", "layout_fp80_field", "layout_nested_field", "layout_array_field"},
        "observations": 128,
        "stdout": "type-layout-padding observations=128 scalar=nested=array=preserved\n",
    },
    "word_pair": {
        "prefix": "word-pair", "fixture": "word_pair_memory",
        "functions": {"word_pair_copy", "word_pair_extract"}, "observations": 64,
        "stdout": "word-pair-memory observations=64 copy=independent pointers=preserved guards=preserved\n",
    },
    "signed_nonnegative": {
        "prefix": "signed-nonnegative", "fixture": "signed_nonnegative",
        "functions": {"nonnegative_i32", "nonnegative_i64", "nonnegative_returned", "nonnegative_spilled"},
        "observations": 256,
        "stdout": "signed-nonnegative observations=256 signed=preserved live=preserved guards=preserved\n",
    },
    "integer_pointer": {
        "prefix": "integer-pointer", "fixture": "integer_pointer",
        "functions": {"integer_pointer_roundtrip", "integer_pointer_spilled", "integer_pointer_returned", "integer_pointer_identity"},
        "observations": 256,
        "stdout": "integer-pointer-casts observations=256 bits=preserved live=preserved guards=preserved\n",
    },
    "scalar_stack": {
        "prefix": "scalar-stack", "fixture": "scalar_stack_memory",
        "functions": {"scalar_stack_roundtrip", "scalar_stack_constants", "scalar_stack_null"},
        "observations": 81,
        "stdout": "scalar-stack-memory observations=81 full-width=preserved null=preserved guards=preserved\n",
    },
    "pointer_stack": {
        "prefix": "pointer-stack", "fixture": "runtime_pointer_stack",
        "functions": {"pointer_stack_roundtrip", "pointer_stack_pressure", "pointer_stack_returned", "pointer_stack_object_address"},
        "observations": 128,
        "stdout": "pointer-stack-memory observations=128 pointers=preserved live=preserved guards=preserved\n",
    },
}


def run_memory_canary(runner, directory, zllvm, environment, mode, report, population):
    canary = MEMORY_CANARIES[population]
    prefix = canary["prefix"]
    fixture = ROOT / "test/real_programs" / (canary["fixture"] + ".ll")
    driver = ROOT / "test/real_programs" / (canary["fixture"] + "_driver.c")
    expected = {"argv": [], "exit_status": 0, "stdout": canary["stdout"]}
    reference = directory / (prefix + "-reference.o")
    if runner.run(["clang-22", "-x", "ir", LLVM_OPT[mode], "-c", fixture, "-o", reference], directory / (prefix + "-reference-object"), environment):
        raise RuntimeError(prefix + " LLVM reference object failed")
    executable = directory / (prefix + "-reference")
    if runner.run(["cc", "-O2", "-no-pie", "-Wl,-z,noexecstack", driver, reference, "-o", executable], directory / (prefix + "-reference-link"), environment):
        raise RuntimeError(prefix + " LLVM reference link failed")
    require_observation(runner, executable, expected, directory / (prefix + "-reference-run"), environment)
    report[population + "_reference_observations"] += canary["observations"]
    for route in ("direct", "release"):
        source = fixture
        if route == "release":
            stem = directory / (prefix + "-optimize")
            if runner.run([zllvm, "--pipeline=" + PIPELINES[mode], fixture], stem, environment):
                raise RuntimeError(prefix + " local optimizer failed")
            source = directory / (prefix + "-optimized.ll")
            source.write_bytes(stem.with_suffix(".stdout").read_bytes())
        stem = directory / (prefix + "-" + route + "-object")
        arguments = ["--generic-cfg-selector", "--target=x86_64-unknown-linux-gnu", source]
        if runner.run([zllvm, "--emit=obj", *arguments], stem, environment):
            raise RuntimeError(prefix + " local object failed")
        obj = directory / (prefix + "-" + route + ".o")
        obj.write_bytes(stem.with_suffix(".stdout").read_bytes())
        stem = directory / (prefix + "-" + route + "-owners")
        if runner.run([zllvm, "--emit=selection-owner-manifest", *arguments], stem, environment):
            raise RuntimeError(prefix + " ownership inspection failed")
        owners = stem.with_suffix(".stdout").read_text().splitlines()
        if len(owners) != len(canary["functions"]) + 1 or {line.split("\t")[0] for line in owners[1:]} != canary["functions"] or any(line.split("\t")[-1] not in {"composed_block", "composed_cfg"} for line in owners[1:]):
            raise RuntimeError(prefix + " canary escaped composed lowering")
        executable = directory / (prefix + "-" + route)
        if runner.run(["cc", "-O2", "-no-pie", "-Wl,-z,noexecstack", driver, obj, "-o", executable], directory / (prefix + "-" + route + "-link"), environment):
            raise RuntimeError(prefix + " local link failed")
        require_observation(runner, executable, expected, directory / (prefix + "-" + route + "-run"), environment)
        report[population + "_local_observations"] += canary["observations"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-root", required=True, type=Path)
    parser.add_argument("--zig-source", type=Path, default=ROOT.parent / "ziglang")
    parser.add_argument("--zig-emitter", type=Path)
    parser.add_argument("--zllvm", type=Path, default=ROOT / "zig-out/bin/z_llvm")
    parser.add_argument("--mode", choices=tuple(PIPELINES))
    args = parser.parse_args()
    output = args.output_root.resolve()
    if not output.is_relative_to(ROOT) or output == ROOT:
        parser.error("output must be a new runner-owned directory inside the project")
    output.mkdir(parents=True, exist_ok=False)
    runner = Runner(output)
    report = {"schema": "upstream-c-program-v1", "program": "zig-c-compiler-fixture", "language": "C",
              "status": "failed", "programs": 1, "matched_program_modes": 0,
              "reference_case_executions": 0, "local_case_executions": 0, "integer_variadic_observations": 0,
              "heap_call_observations": 0, "native_call_observations": 0,
              "word_pair_local_observations": 0, "word_pair_reference_observations": 0,
              "pointer_stack_local_observations": 0, "pointer_stack_reference_observations": 0,
              "scalar_stack_local_observations": 0, "scalar_stack_reference_observations": 0,
              "integer_pointer_local_observations": 0, "integer_pointer_reference_observations": 0,
              "signed_nonnegative_local_observations": 0, "signed_nonnegative_reference_observations": 0,
              "type_layout_padding_local_observations": 0, "type_layout_padding_reference_observations": 0,
              "global_addresses_local_observations": 0, "global_addresses_reference_observations": 0,
              "global_memory_local_observations": 0, "global_memory_reference_observations": 0, "rows": []}
    try:
        if platform.system() != "Linux" or platform.machine() != "x86_64":
            raise RuntimeError("this bounded gate requires x86_64 Linux")
        manifest_path = ROOT / "test/real_programs/c_compiler.json"
        manifest = json.loads(manifest_path.read_text())
        modes = [args.mode] if args.mode else manifest["modes"]
        report["program_modes"] = len(modes)
        source_root = args.zig_source.resolve()
        zig = (args.zig_emitter or source_root / "build/stage4/bin/zig").resolve()
        zllvm = args.zllvm.resolve()
        pin = (ROOT / "docs/evidence/ziglang_pin.txt").read_text().strip()
        source = source_root / manifest["source"]
        if subprocess.check_output(["git", "-C", source_root, "rev-parse", "HEAD"], text=True).strip() != pin:
            raise RuntimeError("upstream revision differs from the tracked pin")
        if digest(source) != manifest["source_sha256"] or source.read_bytes() != subprocess.check_output(["git", "-C", source_root, "show", f"{pin}:{manifest['source']}"]):
            raise RuntimeError("upstream C source differs from the unchanged pinned fixture")
        identity = dict(re.findall(r"^(ABI_DIFF_\w+)='([^']+)'$", (ROOT / "test/abi_diff/reference_identity.env").read_text(), re.M))
        if pin != identity["ABI_DIFF_SOURCE_REVISION"] or subprocess.check_output([zig, "version"], text=True).strip() != identity["ABI_DIFF_REFERENCE_VERSION"]:
            raise RuntimeError("pinned Zig frontend identity differs")
        if digest(zig) != manifest["zig_emitter_sha256"]:
            raise RuntimeError("pinned Zig frontend binary hash differs")
        if subprocess.check_output(["git", "-C", source_root, "status", "--porcelain", "--untracked-files=no"], text=True):
            raise RuntimeError("upstream checkout has tracked modifications")
        report.update({"source": str(source), "source_sha256": digest(source), "source_pin": pin,
                       "zig_sha256": digest(zig), "zllvm_sha256": digest(zllvm),
                       "target": manifest["target"], "remaining_dependencies": manifest["remaining_dependencies"],
                       "mode_scope": "Local release pipelines; C assertions stay enabled, C sanitizers are disabled.",
                       "source_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
                       "runner_sha256": digest(Path(__file__)),
                       "fixture_sha256": {name: digest(ROOT / "test/real_programs" / name) for name in (
                           "c_compiler.json", "variadic_integer.ll", "variadic_integer_driver.c", "variadic_integer_shim.S",
                           "word_pair_memory.ll", "word_pair_memory_driver.c",
                           "runtime_pointer_stack.ll", "runtime_pointer_stack_driver.c",
                           "scalar_stack_memory.ll", "scalar_stack_memory_driver.c",
                           "integer_pointer.ll", "integer_pointer_driver.c",
                           "signed_nonnegative.ll", "signed_nonnegative_driver.c",
                           "type_layout_padding.ll", "type_layout_padding_driver.c",
                           "global_addresses.ll", "global_addresses_driver.c",
                           "global_memory.ll", "global_memory_driver.c")}})
        environment = {k: v for k, v in os.environ.items() if not k.startswith(("ZLLVM_", "ZIG_USE_ZLLVM"))}
        environment.update({"ZIG_LOCAL_CACHE_DIR": str(output / "frontend-cache"),
                            "ZIG_GLOBAL_CACHE_DIR": str(output / "global-cache")})
        if runner.run(["clang-22", "--version"], output / "reference-identity", environment):
            raise RuntimeError("LLVM reference identity command failed")
        if "clang version 22." not in (output / "reference-identity.stdout").read_text():
            raise RuntimeError("LLVM reference must be Clang 22")
        raw = output / "preopt.ll"
        frontend = [zig, "cc", "-target", manifest["target"], "-O0", "-Xclang", "-disable-O0-optnone",
                    "-S", "-emit-llvm", "-g0", "-fno-sanitize=all", "-fno-stack-protector",
                    "-fno-asynchronous-unwind-tables", "-fno-builtin", source, "-o", raw]
        if runner.run(frontend, output / "frontend", environment):
            raise RuntimeError("unchanged C frontend failed")
        report["preopt_sha256"] = digest(raw)
        for mode in modes:
            directory = output / mode
            directory.mkdir()
            row = {"mode": mode, "status": "failed", "local_cases": 0, "reference_cases": 0}
            report["rows"].append(row)
            reference = directory / "reference.o"
            if runner.run(["clang-22", "-x", "ir", LLVM_OPT[mode], "-c", raw, "-o", reference], directory / "reference-compile", environment):
                raise RuntimeError("LLVM reference object failed")
            if runner.run(["cc", "-no-pie", reference, "-o", directory / "reference"], directory / "reference-link", environment):
                raise RuntimeError("LLVM reference link failed")
            for case in manifest["cases"]:
                require_observation(runner, directory / "reference", case, directory / ("reference-" + case["id"]), environment)
                report["reference_case_executions"] += 1
                row["reference_cases"] += 1
            memory = directory / "memory.ll"
            stem = directory / "memory-optimize"
            if runner.run([zllvm, "--pipeline=memory-foundation", raw], stem, environment):
                raise RuntimeError("local memory pipeline failed")
            memory.write_bytes(stem.with_suffix(".stdout").read_bytes())
            optimized = directory / "optimized.ll"
            stem = directory / "release-optimize"
            if runner.run([zllvm, "--pipeline=" + PIPELINES[mode], memory], stem, environment):
                raise RuntimeError("local accepted release pipeline failed")
            optimized.write_bytes(stem.with_suffix(".stdout").read_bytes())
            stem = directory / "local-object"
            if runner.run([zllvm, "--generic-cfg-selector", "--emit=obj", "--target=x86_64-unknown-linux-gnu", optimized], stem, environment):
                raise RuntimeError("local C object emission failed")
            local = directory / "local.o"
            local.write_bytes(stem.with_suffix(".stdout").read_bytes())
            write_json(directory / "object-contract.json", object_contract(local))
            stem = directory / "owners"
            if runner.run([zllvm, "--generic-cfg-selector", "--emit=selection-owner-manifest", "--target=x86_64-unknown-linux-gnu", optimized], stem, environment):
                raise RuntimeError("local C ownership inspection failed")
            row["owners"] = stem.with_suffix(".stdout").read_text().splitlines()[1:]
            row["local_object_sha256"] = digest(local)
            if runner.run(["cc", "-no-pie", local, "-o", directory / "local"], directory / "local-link", environment):
                raise RuntimeError("local C link failed")
            for case in manifest["cases"]:
                require_observation(runner, directory / "local", case, directory / ("local-" + case["id"]), environment)
                report["local_case_executions"] += 1
                row["local_cases"] += 1
            if digest(local) != row["local_object_sha256"]:
                raise RuntimeError("local object changed during execution")
            report["native_call_observations"] += run_variadic_canary(runner, directory, zllvm, environment)
            report["integer_variadic_observations"] += 16
            report["heap_call_observations"] += 6
            for population in MEMORY_CANARIES:
                run_memory_canary(runner, directory, zllvm, environment, mode, report, population)
            row["status"] = "matched"
            report["matched_program_modes"] += 1
        if digest(source) != report["source_sha256"]:
            raise RuntimeError("upstream C source changed during execution")
        report["status"] = "passed"
    except (KeyError, OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        report["error"] = str(error)
    finally:
        write_json(output / "report.json", report)
        print(f"summary upstream-c-program schema=upstream-c-program-v1 programs=1 program_modes={report.get('program_modes', 0)} matched_program_modes={report['matched_program_modes']} reference_case_executions={report['reference_case_executions']} local_case_executions={report['local_case_executions']} integer_variadic_observations={report['integer_variadic_observations']} heap_call_observations={report['heap_call_observations']} native_call_observations={report['native_call_observations']} local_fail={int(report['status'] != 'passed')}")
        print(f"summary word-pair-memory population=standalone-two-word-stack-memory routes=direct,release modes={report.get('program_modes', 0)} local_observations={report['word_pair_local_observations']} reference_observations={report['word_pair_reference_observations']} reference_reused_per_route=true local_fail={int(report['status'] != 'passed')}")
        print(f"summary pointer-stack-memory population=standalone-runtime-pointer-stack routes=direct,release modes={report.get('program_modes', 0)} local_observations={report['pointer_stack_local_observations']} reference_observations={report['pointer_stack_reference_observations']} reference_reused_per_route=true local_fail={int(report['status'] != 'passed')}")
        print(f"summary scalar-stack-memory population=standalone-scalar-stack routes=direct,release modes={report.get('program_modes', 0)} local_observations={report['scalar_stack_local_observations']} reference_observations={report['scalar_stack_reference_observations']} reference_reused_per_route=true local_fail={int(report['status'] != 'passed')}")
        print(f"summary integer-pointer-casts population=standalone-integer-pointer-casts routes=direct,release modes={report.get('program_modes', 0)} local_observations={report['integer_pointer_local_observations']} reference_observations={report['integer_pointer_reference_observations']} reference_reused_per_route=true local_fail={int(report['status'] != 'passed')}")
        print(f"summary signed-nonnegative population=standalone-signed-nonnegative routes=direct,release modes={report.get('program_modes', 0)} local_observations={report['signed_nonnegative_local_observations']} reference_observations={report['signed_nonnegative_reference_observations']} reference_reused_per_route=true local_fail={int(report['status'] != 'passed')}")
        print(f"summary type-layout-padding population=standalone-type-allocation-padding routes=direct,release modes={report.get('program_modes', 0)} local_observations={report['type_layout_padding_local_observations']} reference_observations={report['type_layout_padding_reference_observations']} reference_reused_per_route=true local_fail={int(report['status'] != 'passed')}")
        for population in ("global_addresses", "global_memory"):
            print(f"summary {population.replace('_', '-')} population=standalone-{population.replace('_', '-')} routes=direct,release modes={report.get('program_modes', 0)} local_observations={report[population + '_local_observations']} reference_observations={report[population + '_reference_observations']} reference_reused_per_route=true local_fail={int(report['status'] != 'passed')}")
        print(f"evidence: {output / 'report.json'}")
        if "error" in report:
            print(report["error"], file=sys.stderr)
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())
