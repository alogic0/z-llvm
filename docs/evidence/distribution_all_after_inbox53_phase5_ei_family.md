# Distribution-All After INBOX-53 Phase 5 EI Family

schema_version: 1
directive: `INBOX-53 continuation, Phase 5 cumulative family acceptance`
target: `x86_64-linux-gnu`
status: pass

Committed implementation identity:

- commit `9e3f78fee0557093cc99b5937f0153c7d86ea2a5`;
- tree `97a7aa9451443a8a27f1e6850708991c9f39e243`.

Changed subsystem: x86_64 generic-CFG stage-two allocation/forward-value
planning, readonly memory, odd-width scalar selection, integer-to-FP leaves,
and exact row coverage.

Tier-3 trigger: cumulative acceptance of six provisional row closures plus
shared CFG planning and value-location changes.

Exact command and log:

```text
zig build distribution-all --summary all > tmp/distribution_all_after_inbox53_phase5_ei_family.log 2>&1
```

The accepted `17e01194` P0 gate cannot be reused because it explicitly
excluded `9e3f78fe` and therefore does not prove the new forward-value plan,
odd-width default bodies, or the six provisional EI closures. All 17
subgates pass:

```text
summary zig-integrated-object pipeline=postopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=146 executable_ok=146 local_fail=0
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=6 build_ok=6 run_ok=6 stdout_ok=6 exit_ok=6 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 failed=0
summary distribution-all-timing subgates=17 total_duration_ms=2113769 cache_hit_subgates=3 cache_miss_subgates=0 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Actual wall time was approximately 1,411.936 seconds (23m31.936s), measured
from 22:36:42.900 to 23:00:14.836. Summed child duration was 2,113.769
seconds and is not wall time.

This accepts the exact six-row EI family at 443 selected / 284 emitting / 159
failing. The six closures and their 78/78 native proof are recorded in
`docs/evidence/std_debug_hello_inbox53_phase4_ei_default_bodies.md`.
The separate `__udivei5`/`__umodei4` semantic invalidation remains open and
is not affected by this gate.

## Refreshed Fma Frontier

`compiler_rt.fma.fma` remains failing at `stage2-switch-phi-edge`. Phase 2
proved its captured multiway scalar PHI destinations, but the exact EI switch
admission deliberately does not include fma's i11/i32 switch populations.
The frozen census also records later `ctlz.i52`, copysign, and vector forms,
so switch admission alone has zero honest expected closure. Fma remains the
next program-specific candidate, but it requires a bounded switch-contract
review before implementation rather than routine continuation.

Artifacts:

- preface `tmp/inbox53_phase5_ei_family_tier3_preface.txt`, sha256
  `1398b1f7c70d527da8e5a5d30ce3fc06be62e0ce0f3489ec62e1822eac50a253`;
- accepted log `tmp/distribution_all_after_inbox53_phase5_ei_family.log`,
  sha256
  `fd4422c3bfb536cbc0fb706ccde3ad5f95068b2f58eb85fecfc3d0d8bf80f54b`.
