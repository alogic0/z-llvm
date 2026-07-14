# Distribution-All After INBOX-50 Comparison Pipeline

schema_version: 1
directive: `INBOX-50 comparison-RHS cumulative acceptance`
target: `x86_64-linux-gnu`
status: pass

Committed tree identity before the run:
`b55085f16351d6af65d686b262798374294525dc`.

Changed subsystem: x86_64 scalar icmp typed constant decoding, named i64
unsigned comparison lowering, and permanent comparison execution tests.

Tier-3 trigger: cumulative row-closure pipeline acceptance under
`docs/validation_tiers.md` for `__truncdfsf2` and `__truncdfhf2`. The i16
negative-literal cycle contributes two advances and zero closures.

Exact accepted command and log:

```text
zig build distribution-all --summary all > tmp/distribution_all_after_inbox50_comparison.log 2>&1
```

Prior evidence cannot be reused because the INBOX-50 Part 1 frame gate
predates both committed comparison capabilities and both provisional
truncation-row proofs. The full run passes all 17 subgates.

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
summary distribution-all-timing subgates=17 total_duration_ms=2387632 cache_hit_subgates=3 cache_miss_subgates=0 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

This accepts exact named i64 unsigned less-than and the bit-exact native
`__truncdfsf2`/`__truncdfhf2` proofs from `49267f91`. It also accepts the exact
i16 negative-literal comparison capability from `0f8e243a` without claiming
row closures for it. The compiler_rt report is now 443 selected / 272 emitting
/ 171 failing, two accepted closures over the prior 443 / 270 / 173 state,
with no collateral emission or new failure.

Artifacts:

- preface `tmp/inbox50_comparison_tier3_preface.txt`, sha256
  `c3f7239be9fafad9ba037004c310d756905a54da9285dd534a6b1faf112b7e57`;
- accepted full log `tmp/distribution_all_after_inbox50_comparison.log`,
  sha256
  `f8c486ae085570ec27f0d5e525fb29060db526891e3a244275f528a728dce539`.

INBOX-50 is complete. Stop for review: no third pipeline is authorized. The
newly exposed `__mulhf3` binary-width and `__addhf3` comparison frontiers, the
select-value pipeline, and the switch-PHI/EI program require later direction.
