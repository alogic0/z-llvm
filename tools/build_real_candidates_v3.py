#!/usr/bin/env python3
"""Derive a mode-stable compiler-core population from pinned, framed AIR exports."""

import argparse
import csv
import hashlib
import io
import json
import mmap
from pathlib import Path
import re

import real_candidate_facts as facts


ROOT = Path(__file__).resolve().parents[1]
FIELDS = "rank source function instruction_count signature_class call_class global_refs runtime_refs determinism harnessable_reason".split()
MODES = ("ReleaseFast", "ReleaseSafe", "ReleaseSmall")
OPCODE = re.compile(rb"(?m)^typed_inst\|[0-9]+\|([^|]+)\|")
GLOBAL = re.compile(rb"@[A-Za-z_]")
RUNTIME = (b"compiler_rt", b"__ubsan", b"__zig", b"panic", b"defaultPanic", b"memcpy", b"memset", b"memmove", b"libc")


class Descriptor:
    def __init__(self, data):
        self.data = data
        self.position = 0

    def line(self):
        if self.position == len(self.data):
            return b""
        end = self.data.find(b"\n", self.position)
        if end < 0:
            raise ValueError("truncated descriptor line")
        value = self.data[self.position:end]
        self.position = end + 1
        return value

    def nonempty(self):
        value = self.line()
        while not value and self.position < len(self.data):
            value = self.line()
        return value

    def value(self, key):
        line = self.line()
        prefix = key.encode() + b"="
        if not line.startswith(prefix):
            raise ValueError(f"expected {key}, found {line[:100]!r}")
        return line[len(prefix):]

    def frame(self, key, copy=True):
        return self.frame_size(int(self.value(key)), copy)

    def frame_size(self, size, copy=True):
        end = self.position + size
        if size < 0 or end >= len(self.data) or self.data[end:end+1] != b"\n":
            raise ValueError("invalid descriptor byte frame")
        value = self.data[self.position:end] if copy else None
        self.position = end + 1
        return value


def scan(path, mode, pin):
    metadata = dict(line.split("=", 1) for line in path.with_suffix(".meta").read_text().splitlines() if "=" in line)
    if metadata.get("schema") != "3" or metadata.get("ziglang_pin") != pin or metadata.get("mode") != mode:
        raise ValueError(f"descriptor identity mismatch: {path}")
    functions = {}
    duplicates = set()
    with path.open("rb") as file, mmap.mmap(file.fileno(), 0, access=mmap.ACCESS_READ) as data:
        if hashlib.sha256(data).hexdigest() != metadata["descriptor_sha256"]:
            raise ValueError(f"descriptor hash mismatch: {path}")
        reader = Descriptor(data)
        if reader.line() != b"zllvm-air-export-v1":
            raise ValueError("unknown descriptor contract")
        header = {key: reader.value(key).decode() for key in ("contract_version", "payload", "producer", "root_source", "wrapper", "mode", "target", "function_count", "global_count")}
        if (header["mode"] != mode or header["contract_version"] != "1" or
                header["root_source"] != "main.zig" or header["target"] not in facts.DESCRIPTOR_TARGETS):
            raise ValueError("incorrect descriptor header")
        for _ in range(int(header["global_count"])):
            if reader.nonempty() != b"global_begin":
                raise ValueError("missing global frame")
            reader.frame("name_bytes", False)
            reader.frame("type_bytes", False)
            reader.value("thread_local")
            reader.value("constant")
            reader.frame("initializer_bytes", False)
            if reader.nonempty() != b"global_end":
                raise ValueError("missing global end")
        next_line = reader.nonempty()
        while next_line.startswith((b"aggregate_layout_facts_bytes=", b"error_union_call_facts_bytes=")):
            reader.frame_size(int(next_line.split(b"=", 1)[1]), False)
            next_line = reader.nonempty()
        for _ in range(int(header["function_count"])):
            if next_line != b"function_begin":
                raise ValueError("missing function frame")
            name = reader.frame("name_bytes").decode()
            signature = reader.frame("type_bytes").decode()
            count = int(reader.value("instruction_count"))
            reader.value("main_body_count")
            reader.value("liveness")
            reader.frame("air_bytes", False)
            reader.frame("structured_air_bytes", False)
            typed = reader.frame("structured_air_v2_bytes")
            if reader.nonempty() != b"function_end":
                raise ValueError("missing function end")
            opcodes = OPCODE.findall(typed)
            if len(opcodes) != count:
                raise ValueError(f"incomplete typed body: {name}")
            if name in functions:
                duplicates.add(name)
            call_lines = [line for line in typed.splitlines() if line.startswith(b"typed_inst|") and line.split(b"|", 3)[2].startswith(b"call")]
            undefined_result = any(line.startswith(b"typed_inst|") and line.split(b"|", 3)[2] in (b"ret", b"ret_safe") and b"undefined>" in line for line in typed.splitlines())
            functions[name] = {"signature": signature, "instructions": count,
                               "calls": sum(op.startswith(b"call") for op in opcodes),
                               "global_refs": len(GLOBAL.findall(typed)),
                               "runtime_refs": sum(any(marker in line for marker in RUNTIME) for line in call_lines),
                               "undefined_result": undefined_result,
                               "typed_sha256": hashlib.sha256(typed).hexdigest()}
            next_line = reader.nonempty()
        if next_line not in (b"", b"air_export_end", b"export_end"):
            raise ValueError(f"unexpected export terminator: {next_line!r}")
        if data[reader.position:].strip():
            raise ValueError("trailing descriptor data")
    for name in duplicates:
        del functions[name]
    return functions, metadata["descriptor_sha256"], sorted(duplicates)


def derive(modes, inventory):
    names = set.intersection(*(set(items) for items in modes.values()))
    rows, rejected = [], []
    for name in names:
        variants = [modes[mode][name] for mode in MODES]
        if len({item["signature"] for item in variants}) != 1 or any(item["instructions"] == 0 for item in variants):
            rejected.append(name)
            continue
        instructions = max(item["instructions"] for item in variants)
        calls = max(item["calls"] for item in variants)
        runtime = max(item["runtime_refs"] for item in variants)
        globals_ = max(item["global_refs"] for item in variants)
        signature = variants[0]["signature"]
        if not signature.startswith("fn ("):
            rejected.append(name)
            continue
        classification = inventory[name]
        reason = classification["harnessable_reason"]
        if any(item["undefined_result"] for item in variants):
            reason = "proven_unharnessable:undefined-result"
        if not reason.startswith("proven_unharnessable:"):
            reason = "not_yet_analyzed:global_refs" if globals_ else "not_yet_analyzed:callee_closure" if calls else reason
        rows.append({"source": "../ziglang/src/main.zig", "function": name, "instruction_count": instructions,
                     "signature_class": classification["signature_class"],
                     "call_class": "external" if calls else "leaf", "global_refs": globals_, "runtime_refs": runtime,
                     "determinism": "assumed_nondeterministic", "harnessable_reason": reason})
    rows.sort(key=lambda row: (500 if row["harnessable_reason"].startswith("proven_unharnessable:") else 200 if row["global_refs"] else 100 if row["call_class"] != "leaf" else 0,
                               row["instruction_count"], row["function"]))
    for rank, row in enumerate(rows, 1):
        row["rank"] = rank
    return rows, sorted(rejected)


def render_rows(rows):
    output = io.StringIO(newline="")
    writer = csv.DictWriter(output, fieldnames=FIELDS, delimiter="\t", lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return output.getvalue().encode()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for mode in MODES:
        parser.add_argument(f"--{mode.lower()}-air", type=Path)
    parser.add_argument("--facts-manifest", type=Path, help="checked semantic facts replacing the historical raw audit inputs")
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--audit", required=True, type=Path)
    parser.add_argument("--releasefast-inventory", required=True, type=Path, help="fresh typed-opcode/type inventory of the same ReleaseFast export")
    parser.add_argument("--previous", type=Path, default=ROOT / "docs/evidence/real_candidates_release_v2.tsv")
    args = parser.parse_args()
    pin = (ROOT / "docs/evidence/ziglang_pin.txt").read_text().strip()
    paths = [getattr(args, f"{mode.lower()}_air") for mode in MODES]
    if args.facts_manifest:
        if any(paths):
            parser.error("choose either the fact manifest or all three raw AIR inputs")
        manifest = json.loads(args.facts_manifest.read_text(), object_pairs_hook=facts.unique_object)
        if (manifest.get("schema") != facts.MANIFEST_SCHEMA or manifest.get("source_pin") != pin or
                manifest.get("target") != facts.TARGET or set(manifest.get("inputs", {})) != set(MODES) or
                manifest.get("releasefast_inventory_sha256") != hashlib.sha256(args.releasefast_inventory.read_bytes()).hexdigest()):
            raise ValueError("candidate fact manifest identity mismatch")
        authority_path = ROOT / "docs/evidence/real_candidates_release_v3_migration.json"
        authority = json.loads(authority_path.read_text())
        if (manifest.get("historical_audit_sha256") != hashlib.sha256(authority_path.read_bytes()).hexdigest() or
                authority["source_pin"] != pin or manifest.get("candidate_sha256") != authority["candidate_sha256"] or
                manifest.get("rows") != authority["rows"] or manifest.get("selected_rows") != authority["selected_rows"] or
                manifest.get("rejected_count") != facts.rejection_count(authority)):
            raise ValueError("candidate fact manifest differs from the frozen audit")
    elif not all(paths):
        parser.error("all three raw AIR inputs or a fact manifest are required")
    modes, inputs = {}, {}
    for mode in MODES:
        if args.facts_manifest:
            entry = manifest["inputs"][mode]
            if entry["descriptor_sha256"] != authority["inputs"][mode]["sha256"]:
                raise ValueError("candidate fact raw parent differs from the frozen audit")
            path = ROOT / entry["path"]
            modes[mode], duplicates = facts.load_facts(path, mode, pin, entry["sha256"], entry["descriptor_sha256"])
            if len(modes[mode]) != entry["unambiguous_functions"] or duplicates != entry["ambiguous_symbols_excluded"]:
                raise ValueError("candidate fact manifest population mismatch")
            inputs[mode] = {"path": entry["path"], "sha256": entry["sha256"], "descriptor_sha256": entry["descriptor_sha256"], "format": facts.SCHEMA}
        else:
            path = getattr(args, f"{mode.lower()}_air")
            modes[mode], digest, duplicates = scan(path, mode, pin)
            inputs[mode] = {"path": str(path), "sha256": digest}
        inputs[mode].update(unambiguous_functions=len(modes[mode]), ambiguous_symbols_excluded=duplicates)
    with args.releasefast_inventory.open() as source:
        inventory = {row["function"]: row for row in csv.DictReader(source, delimiter="\t")}
    if not set(modes["ReleaseFast"]).issubset(inventory):
        raise ValueError("inventory does not cover the current ReleaseFast export")
    rows, rejected = derive(modes, inventory)
    required = {"link.MachO.CodeSignature.Requirements.size", "link.MachO.CodeSignature.Requirements.slotType", "link.MachO.CodeSignature.Signature.size", "link.MachO.CodeSignature.Signature.slotType"}
    if len(rows) < 100 or not required.issubset({row["function"] for row in rows[:100]}):
        raise ValueError("the fixed 100-row population must contain all four execution cohort members")
    if args.facts_manifest:
        selected_facts = [{**row, "modes": {mode: modes[mode][row["function"]] for mode in MODES}} for row in rows[:100]]
        if (selected_facts != authority["selected"] or len(rejected) != facts.rejection_count(authority) or
                facts.rejection_digest(rejected) != manifest.get("rejected_names_sha256")):
            raise ValueError("candidate fact replay changed a frozen audit decision")
    rendered = render_rows(rows)
    if args.facts_manifest and hashlib.sha256(rendered).hexdigest() != manifest.get("candidate_sha256"):
        raise ValueError("candidate fact replay changed the frozen table")
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_bytes(rendered)
    with args.previous.open() as previous:
        old = list(csv.DictReader(previous, delimiter="\t"))[:100]
    selected = rows[:100]
    old_names = {row["function"] for row in old}
    selected_names = {row["function"] for row in selected}
    retired = []
    for row in old:
        name = row["function"]
        if name in selected_names:
            continue
        missing = [mode for mode in MODES if name not in modes[mode]]
        retired.append({"function": name, "old_rank": int(row["rank"]), "reason": "absent from current runtime AIR" if missing else "current signature/body facts changed deterministic rank", "missing_modes": missing})
    audit = {"schema": "real-candidate-migration-v3", "source_pin": pin, "selector_version": "real-candidate-selector-v3",
             "criteria": "Present unambiguously in all release modes with an identical signature and complete nonempty typed bodies. Preserve the fresh static typed-opcode/type inventory classification; undefined return results have no defined-result oracle and rank as unharnessable. Order by eligibility, maximum memory/call effects, maximum instruction count, then symbol. No lowering or codegen outcome is an input.",
             "releasefast_inventory": {"path": str(args.releasefast_inventory), "sha256": hashlib.sha256(args.releasefast_inventory.read_bytes()).hexdigest()},
             "inputs": inputs, "candidate_sha256": hashlib.sha256(args.out.read_bytes()).hexdigest(), "rows": len(rows),
             "selected_rows": len(selected), "retained_previous_prefix": sorted(old_names & selected_names),
             "retired_previous_prefix": retired, "replacement_prefix": [row for row in selected if row["function"] not in old_names],
             "unstable_signatures_or_empty_bodies": rejected,
             "selected": [{**row, "modes": {mode: modes[mode][row["function"]] for mode in MODES}} for row in selected]}
    args.audit.parent.mkdir(parents=True, exist_ok=True)
    args.audit.write_text(json.dumps(audit, indent=2) + "\n")
    print(json.dumps({"rows": len(rows), "selected": len(selected), "retained": len(old_names & selected_names), "sha256": audit["candidate_sha256"]}))


if __name__ == "__main__":
    main()
