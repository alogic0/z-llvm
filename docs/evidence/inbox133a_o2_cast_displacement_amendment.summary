# INBOX-133 Step A — dormant scalar-cast displacement amendment

Status: complete; stopped for Supervisor/Reviewer review. This commit changes
only the dormant scalar-cast action, its tests, and the source guard. No
production cast consumer is wired.

## Frozen basis and scope

```text
authorization_head=c8ce4a2d
accepted_cast_placement=3750d62b
production_wiring=none
ratchet=172
performance_run=none
tier3=not_run
```

The preserved Step-B wiring carrier remains:

```text
path=tmp/inbox133_cast_wiring/inbox133_cast_wiring_hard_stop.patch
sha256=a2f934be12e4f2d8850a06a88feff65d0c66edc23543a63c458c3b7744442281
applied_in_step_a=no
```

`stash@{0}` remains untouched at
`7985c6d01040a6e47e4ce5b918866d0e89517ac7`.

## Closed displacement plan

The action derives a private `AccumulatorScalarCastPlan` solely from the
validated semantic operation and widths. No consumer hint, physical home, or
function/family predicate enters the plan.

| Plan | Semantic form | Displacement |
|---|---|---|
| C04 | exact-EI `zext`, source width above 32 | existing source-dependent policy |
| C05 | ordinary narrow `zext` | existing source-dependent policy |
| C52-0 | `trunc i64` to `i52` | always `.spill_live` |
| C52-1 | `zext i6` to `i52` | existing source-dependent policy |
| C52-2 | `zext i52` to `i64` | existing source-dependent policy |
| C52-3 | `trunc i52` to `i6` or `i32` | existing source-dependent policy |

Only C52-0 bypasses `scalarCastSourceDisplacement`. The other five plans
retain the prior immediate/accumulator-home behavior: immediates and
non-accumulator homes use `.spill_live`; canonical EAX/RAX homes use
`.reuse_source`.

The byte-exact live-RAX C52-0 proof is:

```text
spill_rax_rsp slot0
reload_rsp_rax slot0
mov_imm_rcx 0x000f_ffff_ffff_ffff
binary_arg_rax and,rcx
```

The table-driven test also pins live accumulator-resident controls for C04,
C05, and C52-1 through C52-3. C04 remains source-dependent despite its
destructive mask.

## Rollback and guard proof

The C52-0 rollback test stops at both action boundaries:

1. immediately after `session.prepare` emitted the spill;
2. immediately after `session.materialize` re-resolved and reloaded the
   spilled source.

Both failures restore the original source binding, empty spill map,
`next_spill_slot`, virtual-register counter, accumulator domain, EFLAGS
snapshot and semantic-record length, result absence, and zero instruction
length. The retained instruction backing storage proves the spill and reload
had actually occurred before rollback.

The source guard freezes all six plan variants, requires the C52-0-only
unconditional `.spill_live` branch, retains source-dependent EAX/RAX reuse
for every other plan, and forbids transaction, selector, prepared-view, or
physical-home inspection in the semantic plan. Its negative fixture proves
that moving unconditional spill policy to C04 is rejected.

## Dormancy and frozen contracts

```text
composed_selector_scalar_sha256=971533d068ae1c9767c2f1049076e8d9f8541d961cb61220a3305b1285654104
value_use_model_sha256=10268b88b3ed9beea32887e548cbbb911f337a8fd7b6a756e5e01635060e0f0a
value_use_core_sha256=6d802e509acff778e620773d0e8548af972026af32061da6fbf5ab323d0194e5
bypass_inventory_sha256=6e570be808d2aea9275809471f53846af7f54afdd908ab73e51218579ca8112d
ratchet=172
```

The production scalar lowering is byte-identical to the accepted placement
tree. The model, facade/core dispatch, bypass inventory, and every production
consumer are unchanged.

## Immutable validation

Every retained log is paired with its exact command.

### Focused source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig > tmp/inbox133a_cast_displacement/validation/source_guard.log 2>&1
result=37/37
log_sha256=52470686609d37f4980c16fec834c2e930fcaa24c78a39fa05b63698734da53c
```

### Full unit gate

```text
command=/home/oleg/bin/zig build test --summary all > tmp/inbox133a_cast_displacement/validation/full_unit.log 2>&1
result=7/7_steps,1295/1295_tests
log_sha256=1eac60b291fd3961bdeed9db552f76fb62809acb1e8568120652f468edada546
```

### Plain-path ABI differential

```text
command=/home/oleg/bin/zig build abi-differential > tmp/inbox133a_cast_displacement/validation/abi_differential.log 2>&1
result=60/60_cases,30/30_real_functions
log_sha256=4f3ce21f5304ab150b02e9ff64eb217e0dfdf9277d06e8a6fba3284d507adb1a
```

### Frozen full report

The report's expected process status was `1`.

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox133a_cast_displacement/validation/fresh_full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
```

### Accepted object and owner projection

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox133a_cast_displacement/validation/accepted.o 2> tmp/inbox133a_cast_displacement/validation/accepted.stderr
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
stderr_bytes=0

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox133a_cast_displacement/validation/owner_manifest.tsv 2> tmp/inbox133a_cast_displacement/validation/owner_manifest.stderr
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
owner_ledger=167/17/101
stderr_bytes=0
```

No performance or Tier-3 command was run.
