# Distribution-All After Module-Aware Constant Tables

schema_version: 1
directive: `INBOX-31`
cycle: `module-aware-constant-tables`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `7210a403` plus
staged source diff sha256
`6e5ae9c497da7ebaccc6ddc72dc3080417e90b4850a699c7ab19838e3066b160`.

Changed subsystem: the shared typed constant-table decoder, read-only module
context in composed x86_64 lowering, typed table-pointer value locations,
register-parametric RIP-relative address and scalar table-load forms, and ELF
constant-data serialization through the existing `.data`, symbol, and PC32
relocation paths.

Tier-3 trigger: INBOX-31 crosses the ELF object-writer and relocation boundary
named by `docs/validation_tiers.md`, and the new module-aware value shape flows
through shared selector, machine, verifier, encoder, and object-writer
surfaces.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox31_constant_tables.log 2>&1
```

Prior evidence cannot be reused because the accepted INBOX-30 Tier 3 predates
the read-only module context, shared constant decoder, typed table-pointer
location, register-parametric global LEA/load forms, serialized table objects,
and six newly reachable compiler-rt bodies. The Zig pin, target, corpus, and
pipeline arguments are unchanged; the relevant selector/object-writer source
state and expected-result contract are not.

The preface and implementation identity above were recorded before the single
required invocation. It passed all 17 subgates. Strict real-row gates remain
green at 100 rows in ReleaseFast, ReleaseSafe, and ReleaseSmall; the integrated
executable suite remains 5/5; release-source object inspection, native link,
and native-link compatibility remain 100/100.

```text
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 unsupported_relocation_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 local_object_codegen_failures=0 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 local_object_codegen_failures=0 failed=0
summary distribution-all-timing subgates=17 total_duration_ms=2283501 local_fail=0
ok distribution all gates
```

Log: `tmp/distribution_all_after_inbox31_constant_tables.log`, sha256
`4dd605d318d714f1c97b0e0416696b2f07c1b2fc7bdc8984d8dc215856f06615`.
