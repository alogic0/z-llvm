# INBOX-138 B4-pre — production-faithful immediate fixtures

Status: implementation complete; stopped for Supervisor/Reviewer review.
This slice changes only nine production-path fixtures and this evidence
record. Production lowering, the value-use transaction/model/actions, source
guards, diagnostics, inventories, and build roots are unchanged. The immediate
wiring remains unapplied and the bypass ratchet remains 166.

## Frozen basis and preservation

```text
working_head=578886e163e1067df74bf394a7e5264e5bdb25e3
working_tree=0f9dd91785d658039a0951df1327274ee7b2ae21
accepted_lifetime_authority=e7ddb36c
ratchet=166 (unchanged)
b4_partial_fixture_patch_sha256=f1a613f594592f61764c3869f8e57251fe05e371603f766b66a4d431e5845a34
b4_stopped_state_patch_sha256=f2b29a6064cd864a717952e73b0f573ac96516a8f701e6ed26527664f6e7a7a6
b4_carrier_sha256=3f3e46ff0fd9b92a40287840716853c1dda70a3f90220107d3301598051f035d
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7 (untouched)
performance=not_run
tier2=not_run
tier3=not_run
```

## Nine-row fixture manifest

Every named scalar source now uses the real `SelectorAllocationPlan`
`interval_ends` representation. These scalar fixtures own no derived address,
so their canonical `AddressDependencyDomain` is genuinely empty; no invented
dependency edge or test-only lifetime bypass is present.

| # | test | source identity | current position | installed interval end | intended lifetime |
|---:|---|---|---:|---:|---|
| 1 | `generic cfg selector masks reloaded i64 spill low half` | `wide_lo` | 0 | 0 | The spilled low half is consumed by this mask and has no later use; end-at-current makes it available for Q1 without granting survival. |
| 2 | `generic cfg selector preserves live rax before another i64 low-half mask` | `right` | 4 | 4 | `right` is consumed by the current mask only. The independent `left_masked` occupant retains its existing end 10 and therefore remains the value that must be preserved. |
| 3 | `generic cfg selector immediate i64 siblings preserve a current accumulator source at final use` | `source` | 0 | 0 | Each large i64 `and`/`or`/`add`/`xor` consumes `source` for the final time, but this closed form uses the inclusive `accumulatorPreserveCurrentDisplacement` authority. The real interval therefore intentionally produces spill → reload → immediate → binary, leaves `source` in the spill, and defines `result` in RAX. |
| 4 | `generic cfg selector lshr64 avoids live scalar scratch values` | `source` | 4 | 4 | The R8 source is consumed by this shift and not used afterward; the separate RCX occupant remains live through end 10. |
| 5 | `generic cfg selector lshr64 reloads spilled source through rax when scratch registers are live` | `source` | 4 | 4 | The slot10 source is consumed now and does not survive; the explicitly named register occupants retain end 10 and drive the accepted spill-through-RAX path. |
| 6 | `generic cfg selector lowers i64 immediate-left variable lshr` | `amount` | 0 | 0 | The named shift amount is used exactly by this instruction and has no subsequent use. |
| 7 | `generic cfg selector lowers exact i16 and i32 immediate-left variable shl` | `amount` | 0 | 0 | In each width instance the named shift amount is consumed once by the current shift. |
| 8 | `generic cfg selector lowers i64 immediate xor` | `value` | 0 | 0 | The named value is consumed by this XOR and does not survive the instruction. |
| 9 | `generic cfg selector lowers i32 arithmetic-right shifts` | `value` | 0 | 0 | The named value is consumed by each admitted ASHR form at the current instruction; the named-amount loop arm remains a legacy named/named path. |

The reviewed row-3 correction is intentionally not generalized. The dormant
test `value-use immediate scalar displacement distinguishes live-after from
dies-at-current RAX` remains the strict-after control proving that
liveness-aware immediate forms legitimately reuse a source ending at current.
Row 3 instead freezes the separate inclusive preserve-current policy used by
the large i64 siblings.

## Validation

Every retained log is paired with its exact command.

### Focused selector tests

```text
command=/home/oleg/bin/zig test src/tests.zig --test-filter "generic cfg selector" 2>&1 | tee tmp/inbox138_o2_fixture_alignment/validation/focused_scalar_tests.log
result=351/351
log_sha256=8392fdd780ce19331f53896be8347b356cd700ae88cf4b36090bee5868fa2833
```

### Full unit gate

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox138_o2_fixture_alignment/validation/full_unit.log
result=7/7_steps,1320/1320_tests
log_sha256=50111421ff73827bde7ed0aee55c28ad3a2f7f4ec5693f901ac1b6c91c471569
```

### Frozen report

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox138_o2_fixture_alignment/validation/fresh_full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
```

### Accepted object and owner projection

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox138_o2_fixture_alignment/validation/accepted.o 2> tmp/inbox138_o2_fixture_alignment/validation/accepted.stderr
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
stderr_bytes=0

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox138_o2_fixture_alignment/validation/owner_manifest.tsv 2> tmp/inbox138_o2_fixture_alignment/validation/owner_manifest.stderr
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
owner_ledger=167/17/101
stderr_bytes=0
```

No performance, strengthened Tier 2, or Tier 3 command was run. B4 remains
unauthorized until this fixture-only checkpoint is accepted.
