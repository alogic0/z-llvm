#!/usr/bin/env python3
"""Retain exactly the semantic facts consumed by the historical v3 audit."""
import argparse
import csv
import datetime
import hashlib
import json
from pathlib import Path
import subprocess

from build_real_candidates_v3 import ROOT, MODES, derive, render_rows, scan
import real_candidate_facts as facts


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--audit", type=Path, default=ROOT / "docs/evidence/real_candidates_release_v3_migration.json")
    parser.add_argument("--candidates", type=Path, default=ROOT / "docs/evidence/real_candidates_release_v3.tsv")
    parser.add_argument("--output-root", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--proof", required=True, type=Path)
    args = parser.parse_args()
    for path in (args.output_root, args.manifest, args.proof):
        if not path.resolve().is_relative_to(ROOT) or path.resolve() == ROOT:
            parser.error("new facts and evidence must stay inside this project")
    if args.output_root.exists() or args.manifest.exists() or args.proof.exists():
        parser.error("fact outputs and evidence must be new paths")
    audit = json.loads(args.audit.read_text())
    pin = (ROOT / "docs/evidence/ziglang_pin.txt").read_text().strip()
    if audit["source_pin"] != pin or audit["schema"] != "real-candidate-migration-v3":
        raise ValueError("historical audit identity mismatch")
    inventory_path = ROOT / audit["releasefast_inventory"]["path"]
    if digest(inventory_path) != audit["releasefast_inventory"]["sha256"]:
        raise ValueError("historical classification inventory changed")
    with inventory_path.open() as source:
        inventory = {row["function"]: row for row in csv.DictReader(source, delimiter="\t")}
    args.output_root.mkdir(parents=True)
    raw_modes, compact_modes, entries, originals = {}, {}, {}, []
    for mode in MODES:
        parent = audit["inputs"][mode]
        path = ROOT / parent["path"]
        before = path.stat()
        with path.open("rb") as source:
            header = [source.readline().decode().strip() for _ in range(10)]
            descriptor_target = next(line.split("=", 1)[1] for line in header if line.startswith("target="))
        functions, descriptor_hash, duplicates = scan(path, mode, pin)
        if (descriptor_hash != parent["sha256"] or len(functions) != parent["unambiguous_functions"] or
                duplicates != parent["ambiguous_symbols_excluded"]):
            raise ValueError("historical raw audit facts changed")
        after = path.stat()
        if (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns) != (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns):
            raise ValueError("raw descriptor changed during fact extraction")
        output = args.output_root / (mode + ".facts.json")
        fact_hash = facts.write_facts(output, mode, pin, descriptor_hash, functions, duplicates)
        reloaded, excluded = facts.load_facts(output, mode, pin, fact_hash, descriptor_hash)
        if reloaded != functions or excluded != duplicates:
            raise ValueError("compacted facts differ from the raw scan")
        raw_modes[mode] = functions
        compact_modes[mode] = reloaded
        entries[mode] = {"path": str(output.resolve().relative_to(ROOT)), "sha256": fact_hash,
                         "bytes": output.stat().st_size, "descriptor_sha256": descriptor_hash,
                         "descriptor_target": descriptor_target,
                         "unambiguous_functions": len(functions), "ambiguous_symbols_excluded": duplicates}
        originals.append({"path": parent["path"], "sha256": descriptor_hash, "device": before.st_dev,
                          "inode": before.st_ino, "links": before.st_nlink, "bytes": before.st_size,
                          "allocated_bytes": before.st_blocks * 512, "metadata_path": str(path.with_suffix(".meta").relative_to(ROOT)),
                          "metadata_sha256": digest(path.with_suffix(".meta"))})
        print(json.dumps({"mode": mode, "functions": len(functions), "raw_bytes": before.st_size,
                          "fact_bytes": output.stat().st_size, "every_fact_equal": True}), flush=True)
    raw_rows, raw_rejected = derive(raw_modes, inventory)
    rows, rejected = derive(compact_modes, inventory)
    rendered = render_rows(rows)
    if (rows != raw_rows or rejected != raw_rejected or rendered != args.candidates.read_bytes() or
            hashlib.sha256(rendered).hexdigest() != audit["candidate_sha256"] or len(rows) != audit["rows"]):
        raise ValueError("fact replay changed the candidate population")
    selected = [{**row, "modes": {mode: compact_modes[mode][row["function"]] for mode in MODES}} for row in rows[:100]]
    if selected != audit["selected"] or len(rejected) != facts.rejection_count(audit):
        raise ValueError("fact replay changed a historical audit decision")
    proof = {"schema": 1, "created_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
             "source_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
             "tool_sha256": {str(Path(__file__).resolve().relative_to(ROOT)): digest(__file__),
                             "tools/build_real_candidates_v3.py": digest(ROOT / "tools/build_real_candidates_v3.py"),
                             "tools/real_candidate_facts.py": digest(ROOT / "tools/real_candidate_facts.py")},
             "historical_audit": str(args.audit.resolve().relative_to(ROOT)), "historical_audit_sha256": digest(args.audit),
             "static_inventory": audit["releasefast_inventory"], "originals": originals, "facts": entries,
             "candidate_sha256": audit["candidate_sha256"], "rows": len(rows), "selected_rows": 100,
             "all_function_facts_equal": True, "entire_candidate_table_byte_identical": True,
             "every_selected_audit_field_equal": True, "all_rejection_decisions_equal": True,
             "historical_rejection_count": facts.rejection_count(audit), "raw_and_fact_rejected_names": rejected,
             "rejected_names_sha256": facts.rejection_digest(rejected),
             "raw_bytes": sum(item["bytes"] for item in originals),
             "fact_bytes": sum(item["bytes"] for item in entries.values()), "archives_created": 0}
    args.proof.parent.mkdir(parents=True, exist_ok=True)
    args.proof.write_text(json.dumps(proof, indent=2) + "\n")
    manifest = {"schema": facts.MANIFEST_SCHEMA, "source_pin": pin, "target": facts.TARGET,
                "candidate_sha256": audit["candidate_sha256"], "rows": len(rows), "selected_rows": 100,
                "rejected_count": len(rejected), "rejected_names_sha256": facts.rejection_digest(rejected),
                "releasefast_inventory_sha256": audit["releasefast_inventory"]["sha256"],
                "historical_audit_sha256": digest(args.audit), "inputs": entries,
                "verification": {"path": str(args.proof.resolve().relative_to(ROOT)), "sha256": digest(args.proof)},
                "scope": "Exact semantic inputs to offline v3 membership derivation, including typed-body hashes; no raw bodies or executable data. Current production AIR remains separate.",
                "archives_created": 0}
    args.manifest.parent.mkdir(parents=True, exist_ok=True)
    args.manifest.write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps({"rows": len(rows), "selected": 100, "candidate_sha256": audit["candidate_sha256"],
                      "raw_bytes": proof["raw_bytes"], "fact_bytes": proof["fact_bytes"], "raw_inputs_deleted": False}), flush=True)


if __name__ == "__main__":
    main()
