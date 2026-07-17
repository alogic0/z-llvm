# INBOX-134 — dormant scalar-immediate actions

Status: implementation complete; stopped for Supervisor/Reviewer review.
This slice adds only the two authorized dormant scalar-immediate
authorities, their focused tests, transaction integration, source-guard
extensions, and this evidence. Production lowering and dispatch remain
byte-identical.

## Frozen basis and scope

```text
authorization_commit=aa9eee4cd6a9ba0f90c5bb4364d77d75365a4096
accepted_cast_wiring=3d829cd4+08bb2251
ratchet=166 (unchanged)
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7 (untouched)
performance_run=none
tier3=not_run
```

`ImmediateRhsScalarAction` and `ImmediateLhsScalarAction` contain only the
result identity, `ir.BinaryOp`, integer `ir.Type`, and inline `i128`
literal. The action leaf derives a private closed plan. No request exposes a
physical register, source home, displacement policy, staging phase, or fake
literal binding. Exactly one named operand is registered: lhs for
rhs-immediate forms and rhs for lhs-immediate forms.

The classifiers are pure IR-form predicates. They explicitly reject L00
(`sub i128 0, pair`) and all rhs-immediate i128 pair forms. The production
exact-EI check and dispatch position are untouched.

## Closed plan table

| ID | semantic form | result/lifecycle | accepted staging and writes |
|---|---|---|---|
| R00 | `sdiv i32 named, 2` | EAX session | clobber RCX; prepare; lhs→EAX; EAX→ECX; `shr`/`add`/`sar` |
| R01 | `lshr i16/i32/i64 named, imm` | scratch, or i64 spill-through-RAX session | named→chosen scratch then `shr`; accumulator fallback only when no scratch plan exists |
| R02 | `shl <=i32/i64 named, imm` | EAX/RAX session, except scratch32 write-back | accepted live-accumulator preamble; scratch32 source uses EAX transiently and writes back to the same scratch |
| R03 | `ashr <=i32/i64 named, imm` | EAX session or durable RCX scratch | narrow source→EAX then `sar`; i64 source→RCX, `sar`, durable bind and accepted spill |
| R04 | narrow `and/or/add/sub/xor named, imm` | EAX session | accepted preamble/preparation; exact immediate or RCX-xor sequence |
| R05 | wide `and/or/xor` and non-i32 `add` | RAX session | prepare/materialize RAX; optional RCX literal; exact `.write` |
| R06 | wide i32-encodable `add/sub` | durable RCX scratch, sessionless | named→RCX; `add imm32` (negated for sub); durable bind |
| L01 | `sub imm, named` at <=32/64 | EAX/RAX session | named→RCX before prepare; literal→accumulator; sub; narrow mask |
| L02 | `shl imm, named` at i16/i32 | EAX session | count→RCX before prepare; literal→EAX; `shl %cl`; i16 mask |
| L03 | `lshr imm, named` at <=32/64 | EAX/RAX session | count→RCX before prepare; literal→accumulator; logical `shr %cl` |

Every EFLAGS-changing arithmetic/shift instruction is appended through the
EFLAGS authority as incidental `.write` at the accepted point. Sessionless
results use `ownActionIdentity` immediately before their rollback-owned
durable binding. Accumulator forms open a subordinate session internally
from the private plan; the outer value-use transaction remains the sole
snapshot, rollback, and commit authority.

Seal-time physical-write planning is plan-specific rather than
conservative: it declares only the derived RCX, EAX/RAX, or selected scratch
destinations. The i64 R01 scratch selection order matches the accepted
planned-scratch, free-scratch, reusable-source, spill-source, then
spill-through-RAX order.

## Focused proof and guards

`scalar_arithmetic_immediate_tests.zig` records the explicit ten-row plan
table and proves:

- direction-specific classification and explicit L00/i128 negatives;
- representative execution for every R00–R06/L01–L03 row;
- exact R00 and all three immediate-lhs instruction streams;
- exact R01 no-scratch spill-through-RAX fallback, R02 scratch32
  in-place/write-back, and narrow R03 accumulator streams;
- exact EFLAGS write counts and durable result lookup after teardown;
- the complete 1,260-cell declared-type × binding-class × physical-home
  diagnostic table, plus real wide-binding low-view admission and
  fail-closed incompatible pair-home paths;
- request provenance for named-operand failures, and literal/form rejection
  before a request or selector mutation;
- rollback restoring instructions, bindings, spills/counters, accumulator
  domain, and EFLAGS after preservation, scratch selection, RCX staging,
  accumulator preparation, EAX/RAX staging, every partial multi-instruction
  boundary, identity ownership, definition, and finalization.

The source guard now freezes both semantic-only intent layouts, the exact
facade additions, leaf visibility, the single accumulator-session
construction core, and complete dormancy. Negative fixtures reject a
physical destination in either intent and reject either action, use form,
classifier, or test hook from production consumers.

```text
facade_manifest=docs/evidence/inbox128_o2_r1_facade_manifest.tsv
facade_manifest_sha256=68db09931f2916753f2fd257da06ee78ab7aac851efe855ab9b32e280b9e9966
scalar_arithmetic_lines=1368
scalar_arithmetic_ceiling=2000
```

## Production and ratchet proof

```text
composed_selector_scalar_sha256=78452e32276f9968e22f938d52ea758f36845af08fa883c98ae78a509fff5c3c
head_composed_selector_scalar_sha256=78452e32276f9968e22f938d52ea758f36845af08fa883c98ae78a509fff5c3c
composed_selector_impl_sha256=630e58e31798fdd6fc27859aeaba19724a9919d10909862997d7be3a8cbc0dae
bypass_inventory=docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv
bypass_inventory_sha256=5b3ac6b5a98184ed0562a2685c82ca8e1e7b5f33be0018b6d24255071c9f34ad
bypass_occurrences=166
```

No production scalar, icmp, call, memory, or dispatch source changed. The
future wiring claim remains conditional: 166→153 only if all twelve
gateways land, L00 remains, and the last
`tryLowerLshr64SpillThroughRax`/`resolveValue` owner disappears.

## Immutable validation

Every retained gate log is paired with its exact command.

### Source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig > tmp/inbox134_o2_immediate_dormant/validation/source_guard.log 2>&1
result=39/39
log=tmp/inbox134_o2_immediate_dormant/validation/source_guard.log
log_sha256=c3800b2efa50cff78095fbaa6304c392e1ec401a4c258683c1dce854dfca7f40
```

### Full unit gate

```text
command=/home/oleg/bin/zig build test --summary all > tmp/inbox134_o2_immediate_dormant/validation/full_unit.log 2>&1
result=7/7_steps,1309/1309_tests
log=tmp/inbox134_o2_immediate_dormant/validation/full_unit.log
log_sha256=7ac2abd1cf2375d983c9a3f7433ef720b9f204908a42cd11a3ee55d0f43d04df
```

### Required plain-path ABI differential

```text
command=/home/oleg/bin/zig build abi-differential > tmp/inbox134_o2_immediate_dormant/validation/abi_differential.log 2>&1
result=60/60_cases,30/30_real_functions
log=tmp/inbox134_o2_immediate_dormant/validation/abi_differential.log
log_sha256=0ce583dc4019b90c2ebfaf0158ad6b0278e594d67ebab1d6ddfcda23b0c807be
```

### Frozen report

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox134_o2_immediate_dormant/validation/fresh_full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
```

### Accepted object and owner projection

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox134_o2_immediate_dormant/validation/accepted.o 2> tmp/inbox134_o2_immediate_dormant/validation/accepted.stderr
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
stderr_bytes=0

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox134_o2_immediate_dormant/validation/owner_manifest.tsv 2> tmp/inbox134_o2_immediate_dormant/validation/owner_manifest.stderr
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
owner_ledger=167/17/101
stderr_bytes=0
```

No performance command and no Tier 3 command were run.
