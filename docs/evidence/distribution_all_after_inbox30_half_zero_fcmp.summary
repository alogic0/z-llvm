# Distribution-All After Half Zero Comparison

schema_version: 1
directive: `INBOX-30`
cycle: `half-oeq-zero`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `095264f1` plus
staged source diff sha256
`85205dde34969dd6536174b9c38f7f2fe2687198a0ce93971aec75e4db83a092`.

Changed subsystem: the composed selector's exact typed `fcmp oeq half`
against a literal zero, shared selector inspection/preflight admission, and a
correctness repair that gives scalar FP phi results stable allocator-owned
spill destinations in functions that already have a frame.

Tier-3 trigger: the refreshed compiler-rt report closes three directed half
log rows, making this a row-closure milestone. Executable row proof also found
and repaired stale FP phi-edge writes through the shared composed CFG and frame
surfaces. Both triggers require Tier 3 under `docs/validation_tiers.md`.

Exact command and log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox30_half_zero_fcmp.log 2>&1
```

Prior evidence cannot be reused because the accepted INBOX-29 Tier 3 predates
the half-zero bit-test admission, the three newly emitting directed row bodies,
and the stable framed scalar-FP phi destination rule required for those bodies
to execute correctly.

The single recorded invocation passed all 17 subgates. Strict real-row gates
remain green at 100 rows in ReleaseFast, ReleaseSafe, and ReleaseSmall; the
integrated executable suite remains 5/5; release-source object inspection,
native link, and the native-link compatibility probe all remain 100/100.

```text
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 local_fail=0
summary native-link-object-inspection inspected=100 elf64_rel=100 unsupported_relocation_rows=0 local_fail=0
summary distribution-native-link total=100 executable_abi_proof_rows=100 local_object_codegen_failures=0 local_fail=0
summary native-link-probe accepted=100 local_object_codegen_failures=0 failed=0
summary distribution-all-timing subgates=17 total_duration_ms=2301764 local_fail=0
ok distribution boundary gates
```

After the run, the P0 repair was separated into standalone commit `70c63cc4`:
its executable regression moved from the FP test module to the CFG test module,
and one exploratory immediate-left structural assertion was removed. Production
source was unchanged from the recorded Tier-3 implementation; the original
staged identity remains the exact tree used by the invocation.

Log: `tmp/distribution_all_after_inbox30_half_zero_fcmp.log`, sha256
`39c1863f05efdf83cc33e52189347bbfb874735953a671359b898f5e154890bf`.
