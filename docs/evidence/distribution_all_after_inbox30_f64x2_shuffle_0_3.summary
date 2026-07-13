# Distribution-All After Exact F64x2 Two-Source Shuffle

schema_version: 1
directive: `INBOX-30` pre-authorized successor
cycle: `f64x2-shuffle-0-3`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `f510d241` plus
staged source diff sha256
`262340598f2b7604965805da64daa809600b79a8089eacd0fcfe4249f1a3c20a`.

Changed subsystem: the typed f64x2 shuffle classifier, composed packed-vector
selector, and one fixed x86_64 `shufpd $2` machine/assembly/encoding/verifier
form for LLVM mask `<0, 3>`, with static A0/B1 defined-lane propagation.

Tier-3 trigger: the fresh report and executable native row proof close
`compiler_rt.log10.log10` through shared selector and machine surfaces. This
is an evidence-backed row-closure milestone under
`docs/validation_tiers.md`.

Exact command and log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox30_f64x2_shuffle_0_3.log 2>&1
```

Prior evidence cannot be reused because the INBOX-30 half-zero Tier 3 predates
the f64x2 two-source value flow, fixed `shufpd` instruction, and newly emitting
`compiler_rt.log10.log10` body. The Zig pin, target, corpus, and pipeline are
unchanged; the relevant selector and expected-result contract are not.

The single recorded invocation passed all 17 subgates. Strict real-row gates
remain green at 100 rows in ReleaseFast, ReleaseSafe, and ReleaseSmall; the
integrated executable suite remains 5/5; release-source object inspection,
native link, and the native-link compatibility probe remain 100/100.

```text
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 unsupported_relocation_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 local_object_codegen_failures=0 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 local_object_codegen_failures=0 failed=0
summary distribution-all-timing subgates=17 total_duration_ms=2290039 local_fail=0
ok distribution all gates
```

Log: `tmp/distribution_all_after_inbox30_f64x2_shuffle_0_3.log`, sha256
`75c0783b67d07e0e8f49d2ceea84db6e9fd03f8f96625c66b32fc31bdb5a3d79`.
