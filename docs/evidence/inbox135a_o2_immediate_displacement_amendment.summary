# INBOX-135 Step A2 — immediate displacement amendment

Status: implementation complete; stopped for Supervisor/Reviewer review.
This is the authorized dormant amendment only. The preserved Step B2 wiring
patch was not applied, production lowering/dispatch is untouched, the bypass
ratchet remains 166, and no performance or Tier 3 command was run.

## Frozen basis and worktree boundary

```text
source_head=143aef237f98e963c1b4ac3c9746f4605888c909
accepted_dormant_immediates=b2189cdc
ratchet=166 (unchanged)
scalar_arithmetic_lines=1374
scalar_arithmetic_ceiling=2000
preserved_wiring_patch=tmp/inbox135_immediate_wiring/inbox135_immediate_wiring_hard_stop.patch
preserved_wiring_patch_sha256=39aa6d5331a0d404bc1b8aca6372e3927314e1044c5b56788c01a1bd86c1dba5
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7 (untouched)
performance_run=none
tier3=not_run
```

The diff is limited to the dormant scalar-arithmetic action, its co-located
focused tests, the source-guard policy/tests, and this evidence. In
particular, `composed_selector_scalar.zig` and all production dispatch sites
are byte-for-byte unchanged:

```text
composed_selector_scalar_sha256=78452e32276f9968e22f938d52ea758f36845af08fa883c98ae78a509fff5c3c
head_composed_selector_scalar_sha256=78452e32276f9968e22f938d52ea758f36845af08fa883c98ae78a509fff5c3c
bypass_inventory=docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv
bypass_inventory_sha256=5b3ac6b5a98184ed0562a2685c82ca8e1e7b5f33be0018b6d24255071c9f34ad
```

## Exact amendment

`immediateSourceDisplacement` is now the dormant analogue of the accepted
arithmetic authority:

- a named source canonically in EAX/RAX uses `.reuse_source` only when
  `valueIsLiveAfterCurrent(name)` is false;
- a named EAX/RAX source live after the instruction uses the plan-supplied
  fallback (normally `.spill_live`);
- every other source uses the existing fallback;
- liveness/address-dependency errors propagate through the transaction
  authority;
- session materialization resolves the source again after preparation, so a
  spill is followed by a canonical reload rather than a retained pre-spill
  location.

The boundary is deliberately `.after_current`, not `.at_or_after_current`.
A source whose interval ends at the current instruction is therefore
reusable, matching the legacy arithmetic stream.

`scalarCastSourceDisplacement` was not changed. Named EAX/RAX cast sources
continue to use the accepted location-derived reuse policy without an
arithmetic liveness query; C52-0 remains the separately reviewed hardcoded
`.spill_live` exception.

## Focused proof and guard

The new focused tests prove:

- a live-after RAX source emits exactly
  `spill_rax_rsp slot0; reload_rsp_rax slot0; shl_rax_imm6 32`;
- a RAX source dying at the current instruction emits only
  `shl_rax_imm6 32`;
- a non-accumulator source and an immediate-LHS literal/count control retain
  their exact streams;
- malformed dependency metadata raises
  `AddressDependencyMissingOwnerPlanEntry` and automatic rollback restores
  instructions, bindings, spill/vreg counters, accumulator-domain state,
  dependency metadata, EFLAGS, and semantic-record length.

The source guard freezes the intentional two-authority distinction. It
requires exactly one `valueIsLiveAfterCurrent` query in
`immediateSourceDisplacement`, rejects the at-or-after boundary there, and
rejects adding either liveness boundary to `scalarCastSourceDisplacement`.
Negative fixtures prove both failures.

## Design note — remaining scalar displacement authorities

These are closed per-form assignments for future slices, not a common
"destructive scalar" policy. A future action must preserve the named
authority for its form.

| future slice/form | exact legacy authority | category and required preservation |
|---|---|---|
| slice 3: ordinary named/named scalar binary, including accumulator aliases and commutative source selection | `accumulatorArithmeticDisplacement(source, fallback)` | **liveness-aware arithmetic**: named EAX/RAX reuses only when not live after current; otherwise use the branch fallback |
| slice 3: boolean i1 `and/or` and variable i16/i32/exact-EI-narrow shifts | `accumulatorDirectMaterializationDisplacement(lhs, .spill_live)` | **form-table**: accepted location-derived EAX/RAX reuse; no arithmetic liveness query |
| slice 3: wide/exact-EI variable shifts and wide exact-EI binary forms | `accumulatorPreserveCurrentDisplacement(lhs, .spill_live)` | **form-table**: first protect the current live accumulator with `.spill_source`; otherwise named EAX/RAX reuses |
| slice 3: exact i52 named shift | `accumulatorPreserveCurrentDisplacement(lhs, .spill_live)` | **form-table**: the same preserve-current authority, followed by the fixed RCX count staging and i52 mask; do not replace it with arithmetic liveness |
| slice 4: scalar multiply at widths through 32 | `accumulatorArithmeticDisplacement(lhs, .scratch_preferred)` | **liveness-aware arithmetic** with the accepted scratch-preferred fallback |
| slice 4: ordinary i64 multiply | accepted scratch/in-place destination selection in `lowerMul64` | **form-table**: source-home and planned-scratch choice remain authoritative; no blanket accumulator policy |
| slice 4: i64 multiply spill-lhs-through-RAX | `session.prepare(.preserve, .spill_live)` | **hardcoded policy**: unconditional spill-live at the accepted fixed path |
| slice 5: quotient-producing `udiv` | `accumulatorDirectMaterializationDisplacement(lhs, .spill_live)` with the existing rhs-accumulator staging split | **form-table**: location-derived reuse plus the exact RCX/RDX fixed-register order; do not generalize to arithmetic liveness |
| retained exclusion: `urem` RDX result | direct fixed-register path | excluded RDX-result ownership; not an accumulator-result action |

The immediate actions amended here are specifically in the
**liveness-aware arithmetic** category. Casts remain their closed
cast-plan/form-table category. Multiply spill-through and other explicitly
hardcoded paths remain hardcoded. No category may infer another category's
policy.

## Validation

Every retained log below is paired with its exact command.

### Focused source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig > tmp/inbox135a_o2_immediate_displacement/validation/source_guard.log 2>&1
result=pass
log=tmp/inbox135a_o2_immediate_displacement/validation/source_guard.log
log_sha256=1341f1d4b3cc579f15e51ed3600dbdb720cee99e11146aa3dff99b05506e1b1e
```

### Full unit gate

```text
command=/home/oleg/bin/zig build test --summary all > tmp/inbox135a_o2_immediate_displacement/validation/full_unit.log 2>&1
result=7/7_steps,1313/1313_tests
log=tmp/inbox135a_o2_immediate_displacement/validation/full_unit.log
log_sha256=1c3c4d59693a9406ce455095730372a09c8e9424ced566f732b8eab897ea01ad
```

### Required plain-path ABI differential

```text
command=/home/oleg/bin/zig build abi-differential > tmp/inbox135a_o2_immediate_displacement/validation/abi_differential.log 2>&1
result=60/60_cases,30/30_real_functions
log=tmp/inbox135a_o2_immediate_displacement/validation/abi_differential.log
log_sha256=de83b04f7def65408c71de496066947faee5d097711047c3c3924cb20e1468d3
```

### Frozen report

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox135a_o2_immediate_displacement/validation/fresh_full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
```

### Accepted object and owner projection

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox135a_o2_immediate_displacement/validation/accepted.o 2> tmp/inbox135a_o2_immediate_displacement/validation/accepted.stderr
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
stderr_bytes=0

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox135a_o2_immediate_displacement/validation/owner_manifest.tsv 2> tmp/inbox135a_o2_immediate_displacement/validation/owner_manifest.stderr
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
owner_ledger=167/17/101
stderr_bytes=0
```

No performance command and no Tier 3 command were run.
