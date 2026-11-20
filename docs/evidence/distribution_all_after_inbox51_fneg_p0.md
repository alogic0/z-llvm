# Distribution-All After INBOX-51 Scalar Fneg P0

schema_version: 1
directive: `INBOX-51 interrupt, immediate P0 acceptance`
target: `x86_64-linux-gnu`
status: pass

Standalone staged implementation tree identity before the run:
`30c201aed2c45bf782e548205a948193408b9310`. The preserved INBOX-51 select
changes were stashed and are not part of this tree.

Changed subsystem: x86_64 generic-CFG scalar FP selection and permanent
bit-exact executable coverage.

Tier-3 trigger: confirmed wrong-code. Composed scalar fneg used arithmetic
subtraction and changed NaN sign/signaling semantics. The accepted collateral
`__subsf3` row required exact re-proof.

Exact accepted command and log:

```text
zig build distribution-all --summary all > tmp/distribution_all_after_inbox51_fneg_p0.log 2>&1
```

Prior evidence cannot be reused because the accepted INBOX-50 gate predates
the bitwise composed-fneg repair and cannot validate corrected captured-row
object emission. The full run passes all 17 subgates.

```text
summary zig-integrated-object pipeline=postopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=146 executable_ok=146 local_fail=0
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 failed=0
summary distribution-all-timing subgates=17 total_duration_ms=2380478 cache_hit_subgates=3 cache_miss_subgates=0 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Timing is reported in both forms required by the INBOX-51 amendment:

- actual wall time: approximately 1,682 seconds (28m02s), measured from the
  Tier-3 preface timestamp to the final log timestamp;
- summed concurrent child duration: 2,380.478 seconds (39m40.478s).

The wall time is the throughput measure. The summed duration is diagnostic
telemetry and must not be presented as elapsed time. The wall result is
effectively unchanged from the accepted cached baseline of 1,678.60 seconds.

This accepts the standalone scalar-fneg correctness repair and restores the
accepted `compiler_rt.subsf3.__subsf3` emission through its 10-case exact row
proof. The compiler_rt report remains 443 selected / 272 emitting / 171
failing. No INBOX-51 select closure is accepted by this gate.

Artifacts:

- preface `tmp/inbox51_fneg_p0_tier3_preface.txt`, sha256
  `a0e358b219c7d6c5c9c7accfc3270386ecdaa80ade2d2630ee75cc8c819f798a`;
- accepted full log `tmp/distribution_all_after_inbox51_fneg_p0.log`, sha256
  `d676c9c28eb1377b55f0b7b26940128f7d899fb2f88b80a3003dbd7cd0453b43`.

Commit this isolated repair, restore the stashed INBOX-51 select work, and
resume focused Tier-2/native validation. Do not run another full gate until
the low-risk select pipeline reaches its cumulative acceptance boundary.
