# Distribution-All After INBOX-49 Pipeline

schema_version: 1
directive: `INBOX-49 cumulative acceptance`
target: `x86_64-linux-gnu`
status: pass

Committed tree identity before the run:
`af36078479ed29e91040c24e9c6f4239a7143db7`.

Changed subsystem: x86_64 composed-selector vector extraction, intrinsic
range-metadata admission, pair-spill frame reservation, scalar software
popcount machine encoding/assembly/verifier, and permanent executable tests.

Tier-3 trigger: cumulative row-closure pipeline acceptance under
`docs/validation_tiers.md` for `__divdc3`, `__popcountdi2`, and
`__popcountti2`.

Exact accepted command and log:

```text
zig build distribution-all --summary all > tmp/distribution_all_after_inbox49_pipeline.log 2>&1
```

Prior evidence cannot be reused because the immediate P0 gate at `76831275`
predates the committed range-attributed i64/i128 capability, and the last
capability gate predates both INBOX-49 provisional closure commits. The full
run passes all 17 subgates.

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
summary distribution-all-timing subgates=17 total_duration_ms=2335387 cache_hit_subgates=3 cache_miss_subgates=0 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

This accepts the exact i64x2 extraction and five-edge native `__divdc3`
proof from `778b13aa`, the standalone baseline-safe popcount P0 at
`76831275`, and the exact range-attributed software popcount capability and
native `__popcountdi2`/`__popcountti2` proofs from `af360784`. The accepted
compiler_rt report is now 443 selected / 267 emitting / 176 failing, for
three accepted closures over the prior 443 / 264 / 179 state. No collateral
emission or new failure occurred.

Artifacts:

- preface `tmp/inbox49_pipeline_tier3_preface.txt`, sha256
  `4ccbeb6f8f591396814739e55b790b8053bb9fbe073721429bd9bf00f7c9a437`;
- accepted full log `tmp/distribution_all_after_inbox49_pipeline.log`, sha256
  `662ea20a51add3a19c7a1efc74dddbd249d7810dd1d2c747f626acf61c52fed7`.

INBOX-49 is complete. Stop for the periodic review required by the directive;
do not begin the switch-PHI/EI endgame population or another capability.
