# Distribution-All After INBOX-56 Fma Acceptance

schema_version: 1
directive: `INBOX-56`
target: `x86_64-linux-gnu`
status: pass

Staged implementation tree identity before the run:
`e98b75f9d65e1b799cde4a7e5a70ec92d0922a1c`. The implementation starts from
the accepted `21aaf111` lineage; HEAD also contained the accepted read-only
INBOX-55 contract commit `272bf1d8`.

Changed subsystem: exact generic-CFG frexp switch-to-PHI edge routing,
normalized i52 scalar selection, pinned ctlz.i52 call-envelope validation,
LLVM short raw-hex f64 decoding, and the exact compiler_rt fma executable.

Tier-3 trigger: final acceptance of the two-phase capability pipeline and the
`compiler_rt.fma.fma` milestone. Per the Supervisor/Reviewer amendment, this
is the pipeline's only Tier 3; Phase 1 used strengthened Tier 2 and remained
provisional until this run.

Exact command and log:

```text
zig build distribution-all --summary all 2>&1 | tee tmp/inbox56_distribution_all.log
```

All 17 subgates pass:

```text
summary zig-integrated-object pipeline=postopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=146 executable_ok=146 local_fail=0
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=7 build_ok=7 run_ok=7 stdout_ok=7 exit_ok=7 compiler_rt_fma_rows=1 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 undefined_import_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 failed=0
summary distribution-all-gate-inventory subgates=17 local_fail=0
summary distribution-all-timing subgates=17 total_duration_ms=2075148 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Actual wall time was approximately 1,379 seconds (22m59s), measured from the
log birth and final modification timestamps. Summed child duration was
2,075.148 seconds and is not wall time.

This cumulative gate accepts exactly one new compiler_rt row:
`compiler_rt.fma.fma`, moving the frozen report from 443 selected / 284
emitting / 159 failing to 443 / 285 / 158. The permanent native executable
checks 25 exact fma results, directly exercises both frozen internal helper
bodies, permits no host/compiler-rt fallback, and passes object dependency and
recursive-relocation inspection. `fmal`, `fmaq`, `__fixdfei`, x87, and fp128
rows remain outside the claim.

Artifact: accepted log `tmp/inbox56_distribution_all.log`, sha256
`ebd59d9ed6c15f9efec6ef0e85a95236379f1bbf9fd7a164ea6730277871812b`.

INBOX-56 is acknowledged. No preopt-sharding implementation is included.
Stop at fma acceptance and request review.
