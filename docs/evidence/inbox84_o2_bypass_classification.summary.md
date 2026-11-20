# INBOX-84 O2-3A bypass classification and composition contract

Status: corrected O2-3A delivered for Supervisor/Reviewer review. O2-3B0 and
O2-3B1 are recorded sequels, not authorized by this evidence-only follow-up.

## Frozen base and read-only scope

The classification is frozen against accepted O2-2 commit
`a38d9cfa00b25359725f935963ce3c7e00018974`, tree
`b9c3138bfdc14e19f0c9b336e98f01c58d8d0a50`. The workspace authorization
head for the original inventory was the documentation-only descendant
`b9dcbd876e41623700bc532a4fb4ec6e3841065a`. This correction started at the
documentation-only review head `44033050dd49fac93d45a6de87d2ad48042fc8c3`;
`git diff a38d9cfa..44033050 -- src tools build.zig` is empty. Thus the
production code classified here remains exactly the accepted O2-2 production
tree.

The frozen input is
`docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv`, SHA-256
`1590b6d3fe37c79ed04829a74271095ab6524f6c1bdc8aaa83ceb6f174b63e54`.
The classification does not change production code, a source guard, a runner,
or emission.

## Machine-readable accounting

`inbox84_o2_bypass_classification.tsv` has one row for each frozen
file/function/gateway entry. `occurrence_keys` is the exact one-based ordinal
set scoped to that file/function/gateway; every ordinal in a range has the one
category on that row. This retains a stable exact occurrence key without
duplicating identical classification fields 29 times. Re-expanding the ranges
produces all 254 occurrence records.

The TSV exactly joins the O2-0 inventory:

```text
functions=91
gateway_entries=150
occurrences=254
files_with_occurrences=10
zero_unclassified=0
```

| Category | Gateway entries | Occurrences | Disposition |
|---|---:|---:|---|
| 1 ordinary named scalar/pointer/pair use | 14 | 22 | O2-3B+ migration by complete semantic consumer |
| 2 immediate/constant-only path | 0 | 0 | literal-only variants are tracked separately below |
| 3 O1 result/call-result interaction | 47 | 111 | O2-3B+ composition with the accumulator authority |
| 4 FP/XMM/vector/aggregate | 28 | 33 | O3 |
| 5 PHI/cycle/frame/ABI/alias/conditional copy | 30 | 49 | O4/O5 |
| 6 internal state/helper implementation | 31 | 39 | removed only with its classified parent consumer |
| **Total** | **150** | **254** | **zero unclassified** |

The correction delta from the original `26/0/113/31/45/39` occurrence tuple
is `-4/0/-2/+2/+4/0`, producing
`22/0/111/33/49/39`. The exact frozen
`file/function/gateway/occurrence_keys` set is unchanged.

The ownership corrections are:

- `lowerFreeze` (one occurrence) is category 5 / `O4-alias-copy`, an approved
  `alias_only_binding` residual. It resolves a location and creates a durable
  alias through `bindValueLoc`; `ValueUseTransaction` neither returns the
  durable source location nor owns alias creation.
- `lowerSelect` plus `emitScalarSelectValue` (three occurrences) are category
  5 / `O4-conditional-copy`. Distinct true/false sources target the same
  accumulator on mutually exclusive paths. The current seal correctly sees a
  physical destination conflict; same-source multi-destination does not solve
  conditional destination ownership.
- `lowerFpToSignedIntCast` (two occurrences) is category 4 / `O3-FP-XMM`.
  Its source is XMM or `spill_fp`, which the O2 transaction rejects.

Category 6 is deliberately narrow. It means the enclosing helper is not an
independent IR consumer; it does not authorize leaving the bypass behind when
its parent is migrated. Its `disposition` names that parent. Conversely,
PHI/frame/ABI and FP/vector helpers whose architectural ownership is itself
material are classified 5 or 4 rather than hidden as implementation detail.

## Literal-only category-2 residual ledger

The frozen inventory counts textual resolution/materialization gateways. A
literal processed without any gateway therefore is not one of its 254
occurrences. No gateway occurrence is relabeled category 2 merely because the
same polymorphic call site can also receive a literal: its named-source branch
still has to migrate and remains category 1 or 3. The literal branches remain
visible in this residual ledger:

| Owning consumer family | Literal operands | O2-2 transaction status | Required disposition |
|---|---|---|---|
| direct call arguments | typed pointer `.null_value` | supported only with expected pointer type/address space; emits zero with no binding/dependency | migrate through the direct-call outer composition; this is the five-row pointer target form |
| direct call arguments | scalar integer literal | unsupported | retain as explicit category-2 residual until a type-general scalar-immediate request is approved |
| `lowerBinaryImmediateLhs` / `lowerBinaryImmediateRhs` | scalar integer lhs or rhs | unsupported | named complementary operand migrates; literal remains instruction metadata outside the current transaction |
| integer compare forms | scalar integer/null comparison constant | unsupported except typed pointer null | named operands migrate under the compare/O1 composition; scalar literal stays explicit residual |
| select/store/memcpy/GEP operands | scalar literal arm/value/length/index | unsupported | do not silently resolve it or drop it from residual accounting; retain direct literal materialization until an approved extension |
| ctlz/cttz/abs/fshl intrinsic controls | zero-undef, poison-mode, shift amount | validation/control metadata, not a location use | remain validated immediate instruction metadata |
| switch cases and fixed offsets/addends | compile-time case/offset constants | instruction/address metadata, not a location use | remain metadata; named condition/base/index requests still migrate |

The six pointer-call frontier rows are therefore represented honestly: the
one named pointer argument belongs to category 3's direct-call composition;
the five `.null_value` arguments use the already-supported typed-null request.
Scalar immediates remain unsupported and cannot disappear when the bypass TSV
ratchets down.

## Instruction-level composition contract

`inbox84_o2_composition_contracts.tsv` retains all 39 originally audited rows.
There are now 9 category-1 ordinary candidates, 27 category-3 O1-composed
candidates, and three annotated architectural residuals (`lowerFreeze`,
scalar select, and FP-to-signed-int). For every row it records all operands,
the first destructive write, the existing O1 interaction, the single owner of
rollback/commit, `current_api_fit`, and the exact general extension required.

The API-fit audit reports 10 `yes`, 28 `no`, and one `not_applicable` durable
alias residual. `yes` means the current fixed-destination request API can
express the value use; it does not authorize production wiring. `no` names
one or more general architectural gaps. In particular:

- source-location-sensitive consumers such as branch conditions, stores,
  loads, GEP variants, arithmetic, casts, and compares require a
  source-derived prepared view. The view must expose the validated
  post-preparation register/spill/descriptor choice without carrying a stale
  pre-mutation `ValueLoc` or allowing a leaf to resolve again;
- legitimate repeated sources require same-source/type/form requests to
  multiple nonconflicting destinations;
- scalar select requires a separate conditional-destination authority, not
  the repeated-source amendment;
- XMM inputs remain O3; durable alias creation remains O4;
- label-owning families require owned-label rollback before their transaction
  can begin ahead of label allocation.

The binding rule for all later production slices is:

1. the owning instruction begins the single outer authority before its first
   label allocation, preservation spill, clobber, staging move, instruction
   append, result binding, or counter change;
2. it registers every named operand (and typed null request) before sealing;
3. it seals once, then prepares/materializes via handles and composes any
   `AccumulatorDefinitionTransaction` state under the same rollback boundary;
4. it emits the complete instruction, including CFG labels/call alignment and
   normalization where applicable;
5. it commits only after every result definition/binding succeeds.

No `emitValueInto*`, `materialize*`, `resolve*`, call-argument, GEP, or PHI
leaf helper may begin a hidden transaction. A helper receives handles or
prepared views from the instruction owner. Failure in either authority rolls
back both authorities to the one outer snapshot; two independently committed
transactions are forbidden.

## Same source, different destinations

Legitimate instances exist, so the current skeleton restriction is not a
consumer invariant:

- `lowerInlineMemcpy`: `dst == src` still requires both `rdi` and `rsi`;
- direct calls: one named argument may be repeated in distinct ABI slots;
- `lowerFshlI32`, `lowerBinary`, `lowerIcmp`, multiply, division, and overflow
  forms: lhs and rhs may be the same name but require accumulator and scratch
  destinations;
- byte/i32 GEPs: repeated base/index identities can require distinct staging
  registers;
- stores: source aliases may overlap the address source while serving distinct
  roles.

Before the first affected consumer migrates, a separate structural skeleton
amendment must permit the same source/type/form to target multiple
nonconflicting destinations. Exact identical requests may still coalesce;
incompatible type/form requests still reject; physical destination conflicts
and genuine copy cycles still fail at seal. The amendment must be general and
must not contain a consumer, function, or family predicate.

## Mandatory dormant O2-3B0 amendments

The current `ValueUseTransaction.Snapshot` stores `edge_label_count` but does
not snapshot `MachineFunction.owned_labels.items.len`, and rollback neither
frees labels allocated after the snapshot nor truncates the owned-label list.
Resetting only the counter therefore leaves allocated/stale owned names. Any
composition beginning before owned-label allocation is not rollback-safe.

O2-3B0 must remain dormant skeleton work only and complete all three general
amendments before any affected production family is wired:

1. allow the same source/type/form to have multiple nonconflicting
   destinations while preserving exact-request coalescing and rejecting
   incompatible duplicates, destination conflicts, and real cycles;
2. add an approved source-derived prepared-view mechanism that is resolved
   after preparation, has stable transaction-owned lifetime, cannot become a
   pre-mutation `ValueLoc`, and does not permit leaf re-resolution;
3. snapshot `MachineFunction.owned_labels` length and, on rollback, free every
   newly owned label before truncating the list, restoring label counters and
   all other state atomically.

There may be no consumer/function/family predicate and no production wiring in
O2-3B0. It must reproduce the exact baseline report and projections. The label
amendment is mandatory before switch, select, i128-compare, or any other
label-owning family migrates.

## Copy-amplification projection and blocking performance gate

O2-2 measured one `149,761`-byte address-domain snapshot per transaction and
zero per-request domain copies. The static production projection from the
composition table is:

```text
ordinary_category1_outer_transactions=9
o1_composed_outer_transactions=27
annotated_non_O2_composition_rows=3
projected_static_O2_transaction_sites=36
snapshot_bytes_per_transaction=149761
ordinary_projection_bytes=1347849
o1_composed_projection_bytes=4043547
total_projection_bytes=5391396
```

This is static per-one-invocation-of-each-consumer volume, not a runtime cohort
allocation total. O2-3B1 must measure selector wall time and peak memory
against the same source before/after its first production family. A meaningful
regression is a hard stop for a compact snapshot/delta design; it is not
permission for per-request copies or selective consumer predicates.

After O2-3B0 review, O2-3B1 may migrate exactly one API-ready semantic family,
preferably the coherent GEP/address family, and must then stop for performance
and correctness review. Its blocking performance comparison uses at least five
warmed same-input runs before and five after. It compares median selector wall
time and maximum peak RSS. Stop for a compact snapshot/delta design if any of
these is true:

- median selector wall time regresses by more than `max(5%, 100 ms)`;
- maximum peak RSS rises by more than 16 MiB;
- snapshot behavior has nonconstant nesting or takes more than one address
  domain snapshot per instruction authority.

The evidence must record all individual warmed samples, the medians/maxima,
measured dynamic transaction count, and dynamic copy volume
(`transaction_count * 149761` while the full snapshot remains). Later stores,
branch/switch, and memcpy are separate reviewed families and are never
batched. O1-composed families follow only after an ordinary family proves the
composition model and performance envelope.

## Frozen frontier and projection contract

All O2-3 production sub-slices must preserve the exact whole report:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
```

The twelve target diagnostics must remain exactly:

- `compiler_rt.floatuntidf.__floatuntidf`, `floatuntisf.__floatuntisf`, and
  `floatuntihf.__floatuntihf`: `no_emitter/composed-block-icmp-lhs-loc`;
- `compiler_rt.floattidf.__floattidf`, `floattisf.__floattisf`, and
  `floattihf.__floattihf`: `no_emitter/composed-block-icmp-lhs-loc`;
- `compiler_rt.udivmod.__udivmodti4`:
  `no_emitter/composed-block-call-ptr-arg`;
- `compiler_rt.udivmod.__divti3`, `udivmod.__udivti3`,
  `compiler_rt.int.__divmodti4`, `int.__divdi3`, and `int.__divmoddi4`:
  `unsupported_value/composed-block-call-unknown-ptr-arg`.

Any target diagnostic movement during O2-3 is premature. Each production
sub-slice must also prove the 431-row non-target report projection is
byte-identical and the original 285-row object/owner projection remains exact:

```text
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
ledger=167/17/101
```

The bypass ratchet removes exact
`file/function/gateway/occurrence_keys/category` entries only after the owning
semantic consumer is fully migrated. It never claims zero while categories
2, 4, 5, or parent-owned 6 remain. Addition, reclassification, or movement to
an unclassified function/file fails closed. No function-name/family gate is
permitted.

## Validation and stop

This correction is docs/evidence only. No cohort, ABI, canary, Tier-2, or
Tier-3 gate was run because no production or runner file changed. Git path
validation and the machine-accounting checks are recorded in the commit
handoff. Stop here for corrected O2-3A review; O2-3B0 is only recorded and no
production rerouting has begun.
