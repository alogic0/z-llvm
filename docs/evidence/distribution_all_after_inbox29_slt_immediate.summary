# Distribution-All After Signed-Less-Than Immediate Lowering

schema_version: 1
directive: `INBOX-29` pre-authorized successor
cycle: `scalar-slt-immediate`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `43061785` plus
staged source diff sha256
`ed760d52b771b9a9cc1e902ecbf7871db5e4469d3ae2e8c7f506239e7a1ebda4`.

Changed subsystem: the composed selector's typed scalar `icmp slt` lowering
for i32/i64 immediate right operands and the x86_64 machine, verifier,
assembly, and encoding support for materializing the signed-less-than result.

Tier-3 trigger: the refreshed compiler-rt report closes four directed log
rows, making this an evidence-backed row-closure milestone. The implementation
also changes the shared machine/encoder instruction surface. Both triggers
require Tier 3 under `docs/validation_tiers.md`.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox29_slt_immediate.log 2>&1
```

Prior evidence cannot be reused because the INBOX-29 integer-to-FP Tier 3
predates the new comparison lowering, `setl` instruction support, four newly
emitting directed row bodies, and the exact native closure contract for those
rows.

The single recorded invocation passed. The strict real-row prefix remains
green in all three enforced modes, the permanent executable suite remains
5/5, and all release-source-owned objects pass inspection, native link, and
the compatibility probe:

```text
summary distribution-real-rows mode=ReleaseFast limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 first_failing_real_row=- first_failing_stage=- local_fail=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 unsupported_relocation_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 local_object_codegen_failures=0 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 local_object_codegen_failures=0 failed=0
ok distribution boundary gates
```

Log: `tmp/distribution_all_after_inbox29_slt_immediate.log`, sha256
`795d277649df5388f5ed88fe82c650e16b432a54bb8b8000ac85dbe780b2d722`.
