# INBOX-103 — O2-3L-A dormant memory-load action set and audit

Status: complete and validated; delivered for Supervisor/Reviewer review. Stop
here. No load consumer is wired by this slice, and none of the three proposed
production subfamilies is authorized by this delivery.

## Frozen source and scope

The accepted C1 code parent is
`d5fb34292641299d8471034430025f2f15b8780a` (tree
`057d250ab063db068b05a8e057906c1964f45985`). The working branch included
Supervisor documentation-only descendants through
`99874e0aa73ff1546003dc17c6c2eac0e7a86063` (tree
`7d26bd4eaa81242b57a8e1b1bff3649534e2674b`). No rebase or reset was used.
`stash@{0}` remains the untouched `INBOX-93 preserve B2B wiring plus five
diagnosis tests` entry.

The production diff is confined to the dormant
`composed_selector_value_use_transaction.zig` authority. The other code
changes are focused tests and source-guard tests. There is no diff in
`composed_selector_memory.zig`, any other consumer, a mandatory runner, the
frozen bypass inventory, or the production ratchet. Its count remains 221.

## Complete branch matrix

`inbox103_o2_memory_load_matrix.tsv` contains 28 branch rows and 13 checked
columns. It enumerates every accepted and rejected branch of `lowerLoad`,
`lowerReadOnlyPointerIntegerLoad`, and `lowerReadOnlyTableLoad` across source
home, IR type, bound class/bits, result form, defined/upper-bit contract,
physical writes, exact accepted ordering, EFLAGS effect, diagnostic boundary,
API fit, and future owner.

```text
matrix_sha256=830f65fa6f72fb122b0acf4ecf4ba83a4046d631e37840ebe720433216c0fe1b
rows=28
columns=13
ordinary_accumulator_widths=8/32/64
readonly_accumulator_widths=8/16/32/56/64
readonly_pair_widths=96/128
table_i16_result=scratch32/R8 (non-accumulator)
table_double_result=XMM0 (O3; fenced and untouched)
```

The matrix records two easily blurred negative spaces explicitly: ordinary
i16 passes the top-level width dispatch but has no accepted ordinary source
home, and exact-EI readonly widths outside 8/16/32/56/64/96/128 retain the
legacy width failure. The table-double path remains entirely outside O2.

## Closed dormant actions

The new action-only `.load_address` use form derives compatibility from the
canonical binding plus a closed typed action. No prepared location, register,
spill, stack descriptor, table descriptor, or source identity crosses the
public action execution API.

The action set is split by actual result ownership:

- `load_scalar` covers only genuine EAX/RAX results and requires the existing
  snapshot-free subordinate accumulator session;
- `load_readonly_pair` covers only i96/i128 and uses the existing
  `choosePairScratchForClobber` plus existing clobber/bind authorities;
- `load_stack_i128_alias` creates only the accepted durable stack alias; and
- `load_readonly_table_i16` owns the accepted R8 scratch32 result and opens no
  accumulator session.

Scalar actions own the source-home-dependent ordering. Ordinary loads prepare
the accumulator before pointer/index staging. A spill-backed readonly pointer
stages to RDI first, then the same subordinate accumulator preservation runs,
then the load sequence executes. The action re-derives the canonical prepared
record after preservation, so a dependency that is durably relocated is never
consumed through a stale pre-preservation home.

The pair action introduces no pair allocation or ownership authority. Seal
declares the finite union of physical registers that the existing chooser may
return. Execution stages a spill-backed pointer first and then invokes the
unchanged chooser at the legacy point; an in-pair pointer is relocated to RDI
after the choice exactly as before. Genuine chooser failure remains
`ValueUseLoadPairUnavailable` and creates no mutation outside the outer
rollback owner.

Durable action result identities use the transaction's existing owned-copy
mechanism. Rollback truncates instructions first, removes result bindings,
frees each after-snapshot identity once, and restores labels, counters,
bindings, spills, EFLAGS records, accumulator state, and dependencies.

## Focused proof and dormant guard

Focused tests cover stack i8/i64, stack-array and indexed/addend descriptors,
raw GPR and spilled pointers, readonly direct/spilled scalar loads, the exact
i56 multi-load sequence, pair alias relocation, i96/i128 pair ownership,
stack-i128 aliasing, and register/spill table-i16 loads. The table-double shape
is rejected by the O2 action.

Rollback is forced after pointer staging, after preservation, after the first
partial scalar/pair load, after subordinate result definition/finalization,
and after durable pair/table result binding. Every case restores the full
combined snapshot; a second rollback is rejected, and the testing allocator
reports no leak or double free.

The source guard rejects every load action/use-form occurrence in production
consumers during L-A and rejects the test failure hook outside tests. Thus the
module export is dormant by construction. The frozen O2 bypass inventory is
unchanged:

```text
bypass_inventory_sha256=1cc1fbc62a1478008189b5e33a3ae33ae177a96ebf8d625cec537c6c0754315a
production_before=221
production_after=221
load_action_production_consumers=0
```

## Proposed coherent production ratchet

The audit-derived proposal is tracked in
`inbox103_o2_memory_load_proposed_ratchet.tsv`:

```text
ratchet_sha256=7a742e78a1212eab8be36464882648a6ac687b283b09e31d435674cd08008128
after_ordinary_integer=219
after_readonly_pointer=216
after_table_i16=216
```

Ordinary integer `lowerLoad` removes one `resolveValue` and one
`materializeLocIntoLoc`. Readonly-pointer scalar and pair loads remove one
`resolveValue` and two materializations. The table-i16 semantic migration has
zero honest textual ratchet while O3 remains: `lowerLoad` still needs its
readonly-table dispatch for double, and `lowerReadOnlyTableLoad` retains one
materialization behind the untouched double branch. The future slices must
ratchet by these complete subfamilies, never claim the O3 residual as closed.

## Fresh byte identities

The fresh report used
`tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll`, SHA-256
`7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b`:

```text
full_report=tmp/inbox103_load_actions/full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
```

The accepted-only input remains `tmp/inbox63_accepted_cohort.ll`, SHA-256
`d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4`:

```text
accepted_object=tmp/inbox103_load_actions/accepted_cohort.o
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=tmp/inbox103_load_actions/selection_owner_manifest.tsv
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
```

## Non-Tier-3 validation

```text
focused_transaction_and_guard=1200/1200
full_unit=pass
full_unit_log=tmp/inbox103_load_actions/full_unit.log
full_unit_log_sha256=ad4d8eb7d554f77d2d84fd5e31d2b677fa24cacbdb3a28070403058a761454bb
abi_differential=60/60 cases; 30/30 real functions; result=pass
abi_log=tmp/inbox103_load_actions/abi.log
abi_log_sha256=02728683535a2492018a454306c370a1bcbedf1fc222ffb37787860f19e04ca1
source_guard=current-tree-pass; dormant load consumers=0
tier3=not-run
```

Stop here for INBOX-103 review. Production follows only after acceptance, in
the ordered coherent subfamilies: ordinary integer `lowerLoad`, then readonly
pointer loads, then the admitted table-i16 branch.
