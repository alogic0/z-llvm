# INBOX-135 Step A3 — plan-derived immediate accumulator preamble

Status: implementation complete; stopped for Supervisor/Reviewer review.
This is the authorized dormant A3 amendment only. Production dispatch is
untouched, the bypass ratchet remains 166, neither preserved wiring patch was
applied, and no performance or Tier 3 command was run.

## Frozen basis and preservation

```text
working_head=07f00619c52668d422a7183c86ca2fd573be9b23
accepted_A2=49fcc04dde83f947513e6869cf4556f3b4155524
working_head_tree_before_A3=07f1d601589e090f78eb7b4442ff35bf6028c7a9
ratchet=166 (unchanged)
scalar_arithmetic_lines=1485
scalar_arithmetic_ceiling=2000
original_wiring_patch=tmp/inbox135_immediate_wiring/inbox135_immediate_wiring_hard_stop.patch
original_wiring_patch_sha256=39aa6d5331a0d404bc1b8aca6372e3927314e1044c5b56788c01a1bd86c1dba5
complete_stopped_patch=tmp/inbox135_immediate_wiring/inbox135_b2_second_hard_stop.patch
complete_stopped_patch_sha256=8ab26a97f2337790338025fcee0c8f296430abdf7320ae03588ca6fdff60b9ef
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7 (untouched)
performance_run=none
tier3=not_run
```

The production lowering remains byte-for-byte unchanged:

```text
composed_selector_scalar_sha256=78452e32276f9968e22f938d52ea758f36845af08fa883c98ae78a509fff5c3c
HEAD_composed_selector_scalar_sha256=78452e32276f9968e22f938d52ea758f36845af08fa883c98ae78a509fff5c3c
bypass_inventory_sha256=5b3ac6b5a98184ed0562a2685c82ca8e1e7b5f33be0018b6d24255071c9f34ad
HEAD_bypass_inventory_sha256=5b3ac6b5a98184ed0562a2685c82ca8e1e7b5f33be0018b6d24255071c9f34ad
```

## Closed-plan behavior

`ImmediateAccumulatorPreamble` is private. The closed semantic plan and
width select one of `none`, `scratch_preferred`, or `spill_source`; no
consumer supplies a home, liveness result, destination, or phase hint.

For plans with a destructive accumulator write, the action now:

1. validates the named source;
2. searches canonical bindings for an EAX/RAX occupant other than the
   semantic source that is live strictly **after** the instruction;
3. preserves the physical accumulator value once using the plan's accepted
   scratch-preferred or spill-source authority;
4. redirects every logical EAX/RAX alias, including the semantic source, to
   that single preserved home;
5. rebuilds and revalidates the source prepared record from canonical state;
6. verifies that preservation changed neither EFLAGS nor semantic-record
   length; and
7. enters the existing plan executor, where A2's unchanged
   `immediateSourceDisplacement` makes the source-liveness decision.

When the wide source itself occupies RAX, `spill_source` keys the single
spill to that full-width semantic source, then redirects the unrelated alias
to the same slot. When the source is elsewhere, the live accumulator
occupant is preserved directly. This prevents width loss while retaining one
physical move for all aliases.

A dying accumulator source with no live unrelated alias never enters the
preamble and retains its existing reuse stream. A source that is itself live
but has no unrelated alias is handled solely by A2, as before.

## R00–R06 / L01–L03 first-write table

| plan | first destructive accumulator write | A3 preamble |
|---|---|---|
| R00 signed divide by two | subordinate session materializes the source into EAX | none; the session's liveness-aware arithmetic displacement remains authoritative |
| R01 logical shift right | scratch forms have no accumulator write; spill fallback reloads RAX | none; scratch selection or the fallback session remains authoritative |
| R02 shift left | session materializes EAX/RAX; the scratch32 write-back arm stages EAX | `scratch_preferred` for widths at most 32; `spill_source` for i64 |
| R03 arithmetic shift right | accumulator arm materializes EAX; scratch64 arm has no accumulator write | `scratch_preferred` for the narrow accumulator arm; none for scratch64 |
| R04 narrow and/or/add/sub/xor | subordinate session materializes the source into EAX | `scratch_preferred` |
| R05 wide and/or/add/xor | subordinate session materializes the source into RAX | `spill_source` |
| R06 wide scratch add/sub | none; the result remains in RCX | none |
| L01 reverse subtract | post-prepare literal materialization into EAX/RAX | none; the session's hardcoded `spill_live` remains authoritative |
| L02 variable shift left | post-prepare literal materialization into EAX | none; the session's hardcoded `spill_live` remains authoritative |
| L03 variable logical shift right | post-prepare literal materialization into EAX/RAX | none; the session's hardcoded `spill_live` remains authoritative |

The same table is frozen in the co-located Zig test plan. The source guard
also rejects changing R05 to `none`, replacing the exact after-current
liveness boundary, or ceasing to exclude only the semantic source identity.

## Focused proof

The co-located tests cover:

- the exact `__multi3` R05 case:
  `spill_rax_rsp slot0; reload_rsp_rax slot0; and_eax_imm32 -1`;
- a no-alias R05 control with only `and_eax_imm32 -1`;
- the existing A2 source-itself-live and dies-at-current controls;
- two unrelated live aliases sharing RAX, all redirected by exactly one
  spill and one reload;
- malformed address-dependency liveness failing closed before preservation;
- EFLAGS preservation: the two preamble moves add no semantic record and
  the AND remains the sole incidental `.write`;
- automatic rollback immediately after preservation and immediately after
  canonical refresh, restoring instructions, bindings, spill map/counter,
  vreg counter, accumulator domain, dependency metadata, EFLAGS, and
  semantic-record length.

The source guard has a dedicated negative fixture for both plan widening and
loss of semantic-source exclusion.

## Validation

Every retained gate log below records the result of the exact command shown.

### Focused source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig > tmp/inbox135b_o2_immediate_preamble/validation/source_guard.log 2>&1
result=41/41_tests_passed
log_sha256=88eb6b11dd3621ddb392170f631a60f6f3647917f6d78c763d2a7beec6ca78b5
```

### Full unit gate

```text
command=/home/oleg/bin/zig build test --summary all > tmp/inbox135b_o2_immediate_preamble/validation/full_unit.log 2>&1
result=7/7_steps,1318/1318_tests
log_sha256=db46f7941da5c6f8d1d627f76adf8a177a95cc72fd4013def56b117828b9d619
```

### Required plain-path ABI differential

```text
command=/home/oleg/bin/zig build abi-differential > tmp/inbox135b_o2_immediate_preamble/validation/abi_differential.log 2>&1
result=60/60_cases,30/30_real_functions
log_sha256=9bafa88bcdcb10f2a0f5eea262d0680d750f1251576c44cb6be9801e88cc9963
```

### Frozen report

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox135b_o2_immediate_preamble/validation/fresh_full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
```

The report command exits nonzero by design because `--report-all-codegen-failures`
sets `local_fail=1`; its frozen report and summary are exact.

### Accepted object and owner projection

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox135b_o2_immediate_preamble/validation/accepted.o 2> tmp/inbox135b_o2_immediate_preamble/validation/accepted.stderr
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
stderr_bytes=0

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox135b_o2_immediate_preamble/validation/owner_manifest.tsv 2> tmp/inbox135b_o2_immediate_preamble/validation/owner_manifest.stderr
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
owner_ledger=167/17/101
stderr_bytes=0
```

No performance command and no Tier 3 command were run.
