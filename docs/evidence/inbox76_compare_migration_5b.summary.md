# INBOX-76 O1 Commit 5B — Compare Producer Migration

schema_version: 1
directive: `INBOX-76`
target: `x86_64-linux-gnu`
status: delivered; review requested
accepted_5a: `70943507`
validated_parent: `7d7c826f`

INBOX-76 is acknowledged by id. Slice 5B migrates only compare/icmp and the
single compare-like call producer through the accumulator transaction and the
5A emission-time EFLAGS authority. Slice 5C, scalar arithmetic, and Tier 3 were
not started.

## Pre-Edit Producer Inventory

The inventory was frozen before production edits in
`tmp/inbox76_compare_producer_inventory.md` against the accepted 5A tree and
the lossless INBOX-74 reference (`466be30c`; preserved patch SHA-256
`bfc0a2a3fe25290d543077852213d3b0f1c962cc7eed131321c01bc42c06b888`).

Physical accumulator definitions migrated:

- all admitted simple integer and pointer `lowerIcmp` forms ending in setcc;
- accumulator-resident equality/relational forms, including multiple logical
  aliases of the same EAX/RAX location;
- sign-extraction and masked-sign forms;
- exact-EI narrow comparisons;
- the i128-assisted equality form, whose pair remains input-only;
- `lowerI128Compare`, the sole compare-like call producer, whose existing pair
  inputs and multi-label control flow produce a scalar EAX result.

There are no alias-only or accumulator-temporary compare result producers.
Every migrated physical result declares the typed displacement policy
`.spill_live`; there is no default. The i1 icmp result uses
`.zeroExtending(1)`, and the i128 compare-call result uses
`.zeroExtending(32)`.

Every overflow, saturating-arithmetic, ctlz/ctpop, fp-abs, byte-size, and
pointer-adjustment call hunk was classified as arithmetic and left unchanged
for 5C. `composed_selector_scalar.zig` is absent from the commit diff. No form
was deferred and no alias, pair, PHI, CFG-aware-EFLAGS, or per-flag authority
was added.

## EFLAGS and Transaction Semantics

Compare instructions emit through the 5A authority as `.definition`; setcc and
conditional branches emit as `.use`; masks, sign normalization, and result
shaping that incidentally write flags emit as `.write`. The authority validates
the semantic effect before appending, so rejection cannot partially emit.

`lowerIcmp` begins one transaction and lazily prepares it with explicit
`.spill_live` displacement at the accepted instruction-order seam. A read-only
`isPrepared` query prevents duplicate preparation. Result definition and commit
replace the former direct EAX binding. The multi-label i128 compare-call path
uses the existing EFLAGS snapshot/restore mechanism for its already-existing
high-difference and low-difference paths; pair ownership and allocation do not
change.

The 5A source guard remains green: its raw EFLAGS inventories only shrink or
hold. In `composed_selector_calls.zig`, the commit changes only
`lowerI128Compare`; no arithmetic producer is touched.

## Coverage

The new focused test exercises two live logical names sharing physical EAX
through an accumulator-resident comparison and verifies that both aliases are
preserved separately while the result commits to EAX. Existing production
coverage now exercises the migrated paths for:

- compare/setcc results crossing condbr and PHI edges;
- signed i16 and other sign-extraction comparison forms;
- exact signed and unsigned multi-label i128 compare calls, including their
  executable boundary matrix;
- compare -> incidental write -> setcc rejection before append;
- a second definition before its consumer rejected by the production API;
- EFLAGS rejection after transaction preparation/materialization restoring
  instructions, bindings, spills, counters, accumulator domain, flags, and
  semantic-record length.

## Validation

Formatting and `git diff --check` passed.

Full unit suite plus mandatory ABI differential:

```text
Build Summary: 7/7 steps succeeded; 1069/1069 tests passed
abi_diff_cases_attempted=60
abi_diff_cases_matched=60
abi_diff_real_functions_matched=30
result=pass
```

- log: `tmp/inbox76_unit.log`
- log SHA-256:
  `a9ab0a19fe0a973aa5b0189d8d8a371f95e3e7e7bd2cfd912ce0b7ce9c4dc9be`

The directly invoked procedural canary step passed both canaries and all 35
executable cases:

```text
Build Summary: 2/2 steps succeeded
summary focused-codegen-canaries target=x86_64-linux-gnu canaries=2 execution_cases=35 local_fail=0
```

- log: `tmp/inbox76_focused_canaries.log`
- log SHA-256:
  `2bf6f68ae7cec068253218a52e4d89d17d0b193396c31e3bca2feb72744e40f8`

The decisive whole-capture report remains byte-identical:

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=285 failed_functions=158 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```

- report: `tmp/inbox76_full_capture_report.log`
- report SHA-256:
  `49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`
- accepted object SHA-256:
  `061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be`
- owner manifest SHA-256:
  `5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d`
- live owner ledger: `167 / 17 / 101` composed / legacy / fallback.

The restored standard integrated-executable runner passed its seven cases:

```text
summary zig-integrated-exe total=7 build_ok=7 run_ok=7 stdout_ok=7 exit_ok=7 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 compiler_rt_fma_rows=1 setcc_predicate_rows=1 aggregate_sse_return_rows=1 local_fail=0
```

- log: `tmp/inbox76_integrated_exe.log`
- log SHA-256:
  `c0b9678666690672de4f3ba705a6b128c295a9bbc715f2d9a5a3c7386ff2e42e`

Strengthened Tier 2 passed:

```text
Build Summary: 28/28 steps succeeded; 1077/1077 tests passed
```

- log: `tmp/inbox76_tier2.log`
- log SHA-256:
  `255a8bc9a0179f5d6d356e9797982d7b9cdcc475f1b08ec248d4a9e63b9e4333`

Frozen identities are exact: `49a19f04` / `443-285-158-truncl` /
`061a64e4` / `5d91960e` / `167-17-101`. No Tier 3 was run. Stop for
Supervisor/Reviewer acceptance before INBOX-77 or any scalar-arithmetic
migration.
