"""Checked semantic inputs for replaying the offline selector-v3 audit."""
import hashlib
import json
from pathlib import Path
import re

SCHEMA = "real-candidate-facts-v1"
MANIFEST_SCHEMA = "real-candidate-facts-manifest-v1"
TARGET = "x86_64-linux-gnu"
DESCRIPTOR_TARGETS = (TARGET, "x86_64-unknown-linux5.10.0-gnu2.31.0")
FACT_FIELDS = {"signature", "instructions", "calls", "global_refs", "runtime_refs", "undefined_result", "typed_sha256"}
SHA256 = re.compile(r"[0-9a-f]{64}\Z")


def rejection_count(audit):
    if "unstable_signatures_or_empty_bodies_count" in audit:
        return audit["unstable_signatures_or_empty_bodies_count"]
    return len(audit["unstable_signatures_or_empty_bodies"])


def rejection_digest(names):
    return hashlib.sha256(json.dumps(names, separators=(",", ":")).encode()).hexdigest()


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate fact key: {key}")
        result[key] = value
    return result


def validate(payload, mode, pin, descriptor_sha256):
    if (payload.get("schema") != SCHEMA or payload.get("source_pin") != pin or
            payload.get("mode") != mode or payload.get("target") != TARGET or
            payload.get("descriptor_sha256") != descriptor_sha256 or
            not isinstance(descriptor_sha256, str) or not SHA256.fullmatch(descriptor_sha256)):
        raise ValueError("candidate fact identity mismatch")
    functions = payload.get("functions")
    duplicates = payload.get("ambiguous_symbols_excluded")
    if not isinstance(functions, dict) or not isinstance(duplicates, list):
        raise ValueError("invalid candidate fact population")
    if (any(not isinstance(name, str) or not name for name in duplicates) or
            duplicates != sorted(set(duplicates)) or set(functions) & set(duplicates) or
            type(payload.get("unambiguous_functions")) is not int or
            payload["unambiguous_functions"] != len(functions)):
        raise ValueError("invalid candidate fact population")
    for name, fact in functions.items():
        if not isinstance(name, str) or not name or not isinstance(fact, dict) or set(fact) != FACT_FIELDS:
            raise ValueError("invalid candidate function facts")
        if not isinstance(fact["signature"], str) or not fact["signature"]:
            raise ValueError("invalid candidate signature")
        for field in ("instructions", "calls", "global_refs", "runtime_refs"):
            if type(fact[field]) is not int or fact[field] < 0:
                raise ValueError("invalid candidate effect count")
        if fact["calls"] > fact["instructions"] or fact["runtime_refs"] > fact["calls"]:
            raise ValueError("invalid candidate effect count")
        if type(fact["undefined_result"]) is not bool or not isinstance(fact["typed_sha256"], str) or not SHA256.fullmatch(fact["typed_sha256"]):
            raise ValueError("invalid candidate result or typed-body hash")
    return functions, duplicates


def write_facts(path, mode, pin, descriptor_sha256, functions, duplicates):
    payload = {"schema": SCHEMA, "source_pin": pin, "mode": mode, "target": TARGET,
               "descriptor_sha256": descriptor_sha256, "unambiguous_functions": len(functions),
               "ambiguous_symbols_excluded": duplicates, "functions": functions}
    validate(payload, mode, pin, descriptor_sha256)
    data = (json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n").encode()
    with Path(path).open("xb") as output:
        output.write(data)
    return hashlib.sha256(data).hexdigest()


def load_facts(path, mode, pin, expected_sha256, descriptor_sha256):
    data = Path(path).read_bytes()
    if not isinstance(expected_sha256, str) or not SHA256.fullmatch(expected_sha256) or hashlib.sha256(data).hexdigest() != expected_sha256:
        raise ValueError("candidate fact hash mismatch")
    payload = json.loads(data, object_pairs_hook=unique_object)
    if not isinstance(payload, dict):
        raise ValueError("invalid candidate fact payload")
    functions, duplicates = validate(payload, mode, pin, descriptor_sha256)
    return functions, duplicates
