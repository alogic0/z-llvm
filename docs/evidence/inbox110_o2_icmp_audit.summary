# INBOX-110 — O2-3I-0 ICMP branch and use-site audit

Status: PASS; evidence-only audit ready for Supervisor/Reviewer review.

Date: 2026-07-16

## Frozen source and method

```text
accepted_code_commit=ec3cfbea
accepted_code_tree=48befd4ad46e18692026b2f3637fc3ec5d369a36
supervisor_docs_head_at_audit=65702257
supervisor_docs_tree_at_audit=eb9c0b4cdac465663e8c834994872656d18c2620
icmp_source=src/codegen/x86_64/generic_cfg/composed_selector_icmp.zig
icmp_source_sha256=8d96a4c345f47ebf3393cf04a02df7f80d048f3d06287448c04bf247472cff4c
accepted_cohort=tmp/inbox63_accepted_cohort.ll
accepted_cohort_sha256=d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4
zig_version=0.16.0
production_or_test_files_changed=0
```

The matrix
[`inbox110_o2_icmp_audit.tsv`](inbox110_o2_icmp_audit.tsv) follows the
source-order decision tree in `lowerIcmp` and
`lowerExactEiNarrowIcmp`. It records every accepted leaf and every rejecting
tail, including type, RHS-form, and final form rejection. The `I12` and `I27`
source branches are split by width because their i32 and i64 paths have
different staging authorities and therefore belong to different future
subgroups.

Accepted-cohort correlation used the accepted-only IR and the frozen owner
manifest, retained only scalar/pointer ICMP instructions in rows owned by
`composed_block` or `composed_cfg`, and applied the source-order predicates.
The two accepted vector ICMP instructions are intentionally excluded: the
dispatcher routes `.vector` operands to `selector_vector.lowerIcmp`, not this
file. The result reconciles to:

```text
scalar_pointer_icmp_instructions=1062
accepted_cohort_rows_with_scalar_pointer_icmp=130
matrix_accepted_instruction_sum=1062
unclassified_scalar_pointer_icmp_instructions=0
accepted_branch_count=35
rejecting_or_zero-hit_branch_count=3
```

Each accepted matrix branch records the instruction count, unique cohort-row
count, and an exact row-set SHA-256. The set input is the semicolon-joined,
bytewise-sorted exact function identities followed by one newline. This is an
exact, reproducible row identity rather than a representative sample. The
combined classified-hit projection is:

```text
projection_columns=branch, instruction_count, function_count, forms, accepted_rows
projection_sha256=937d2849e4d2b0216964adcda7179adf645e7fd5149f6bd7f854cb338a8fb056
```

The four narrow exact-EI accepted hits are
`compiler_rt.floateihf.__floateihf`,
`compiler_rt.floateisf.__floateisf`,
`compiler_rt.floatuneidf.__floatuneidf`, and
`compiler_rt.floatuneihf.__floatuneihf`. Their source/AIR identity is
distinguished by the existing exact-EI family predicate (floating result,
readonly pointer plus i64 operands, and the exact five-way i16 switch). The
audit does not propose a new function-name or family predicate.

## Home/class notation and accumulator policy

The matrix uses these source-home sets, derived from the called production
helpers:

- `H32`: EAX/RAX, arg32/scratch32, arg64/scratch64, spill64, or the low limb
  of arg128/scratch128. The canonical binding may therefore be GPR32, GPR64,
  or the existing read-only pair class when the helper admits the low limb.
- `H64`: RAX, arg64/scratch64, spill64, or the low limb of
  arg128/scratch128, with a GPR64 or existing pair binding.
- `P64`: the pointer-semantic subset of `H64`; pointer type/class validation
  remains authoritative.

`emitValueIntoScratch` stages a nonresident source only after clobbering the
requested RCX/R8 destination. A source already in that destination is a
no-op. `emitValueIntoEax`/`emitValueIntoRax` similarly reuse the accumulator
when already resident. The first-destructive-write column is therefore the
first branch-specific write after the outer transaction's existing
live-accumulator preservation loop; it explicitly notes no-op cases and
preservation that can precede staging.

The four policy classes requested by the Reviewer are used literally:

- `scratch-staged`: fixed RCX/R8 materialization before compare;
- `current-home test`: no fixed staging except the accepted spill-to-RCX
  reload;
- `reuse_source`: source is staged/reused in EAX and the compare/setcc
  overwrites the same accumulator; and
- `transformed-in-place`: the accumulator or pair-derived temporary is
  transformed to the final boolean.

Every setcc result becomes a `.zeroExtending(1)` EAX definition. The sign
extraction leaves (`slt i128/i64/i32, 0`) instead use the final SHR result
directly and have no EFLAGS consumer. No ICMP leaf allocates or owns a label.
This corrects the old generic composition note: `lowerIcmp` is a scalar
result producer, not a switch compare-chain or CFG-label action. Owned-label
machinery is not part of the ICMP action design unless a later, separately
reviewed source change introduces a real label-owning path.

## EFLAGS and diagnostic/provenance contract

Compare/test instructions are emitted through the O1 EFLAGS authority as
`.definition`; setcc is `.use`. Masks, sign-normalization shifts, XOR/OR
combination, and terminal sign shifts are `.write`, except the intentional
AND-as-definition sign-bit tests whose flags feed `sete`. The result is
defined and the accumulator transaction commits only after the consumer or
terminal transform.

The future composed authority must preserve the matrix's precedence:
form/immediate validation that currently precedes staging remains first;
named LHS failure precedes named RHS failure; preparation/EFLAGS failures
remain authority-level. Named operands can use retained request handles with
`failedRequestIs`. Immediate, form, chooser, preservation, and global
authority failures have no unique request provenance and must not be
attributed to one.

No leaf exposes a prepared location. The current-home leaf is the one
source-derived action candidate; its future action must classify and consume
the canonical current home internally rather than returning a location to
the consumer.

## Pair audit and O2 target fence

There are two different accepted i128 result paths:

1. `eq i128 lhs, minInt(i128)` calls `resolvePairValue`, chooses the existing
   nonoverlapping pair, and calls `materializePairValue`. Current materialized
   sources are arg128/scratch128, stack128_value, and spill128. The chooser
   and pair ownership remain exactly as accepted.
2. `slt i128 lhs, 0` calls `emitPairHighLaneIntoRax`, which reads the existing
   high limb from arg128/scratch128, stack128_value, or spill128 and shifts
   it in place. That helper call was not one of the frozen textual gateways,
   so its semantic migration has textual ratchet delta zero.

Future pair actions may wrap these helpers. They may not add pair allocation,
pair result ownership, preservation redesign, or cycle resolution.

The six O2 targets are not accepted pair leaves. They reach the generic
`eq integer, zero` current-home branch with LHS `.spill128`, which that branch
rejects. The fresh report proves every row remains at the exact required
frontier:

```text
compiler_rt.floatuntidf.__floatuntidf  no_emitter/composed-block-icmp-lhs-loc
compiler_rt.floatuntisf.__floatuntisf  no_emitter/composed-block-icmp-lhs-loc
compiler_rt.floatuntihf.__floatuntihf  no_emitter/composed-block-icmp-lhs-loc
compiler_rt.floattidf.__floattidf      no_emitter/composed-block-icmp-lhs-loc
compiler_rt.floattisf.__floattisf      no_emitter/composed-block-icmp-lhs-loc
compiler_rt.floattihf.__floattihf      no_emitter/composed-block-icmp-lhs-loc
```

Admitting `.spill128` to that current-home request is explicitly O2-6. It is
not part of any O2-3 ICMP subgroup.

## Honest future slicing and ratchet arithmetic

The frozen bypass inventory contains exactly 44 ICMP occurrences:

```text
lowerExactEiNarrowIcmp emitValueIntoEax=1
lowerIcmp emitValueIntoEax=10
lowerIcmp emitValueIntoRax=1
lowerIcmp emitValueIntoScratch=29
lowerIcmp materializePairValue=1
lowerIcmp resolvePairValue=1
lowerIcmp resolveValue=1
total=44
current_global_ratchet=216
```

Minimum reviewed migration order and arithmetic:

| Future subgroup | Frozen occurrences | Global ratchet if complete |
| --- | ---: | ---: |
| fixed-scratch scalar/pointer comparisons | 29 scratch gateways | `216 -> 187` |
| accumulator-resident/current-home + exact-EI/in-place forms | 1 exact-EI EAX + 10 lowerIcmp EAX + 1 RAX + 1 resolveValue = 13 | `187 -> 174` |
| i128 pair-source forms, last | 1 resolvePairValue + 1 materializePairValue = 2 | `174 -> 172` |

This is textual bypass arithmetic, not a claim that the pair subgroup contains
only two semantic operations. `emitPairHighLaneIntoRax` remains part of the
complete i128 semantic consumer but contributes zero to the frozen count.
Each future production slice must freeze its exact occurrence list again
before wiring; no subgroup may absorb a rejected tail, a vector path, or a
target `.spill128` row.

## Fresh identity proof

The final docs-only tree was checked with fresh outputs:

```text
fresh_report=tmp/inbox110_icmp_audit/fresh_full_report.log
fresh_report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type

accepted_object=tmp/inbox110_icmp_audit/accepted.o
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=tmp/inbox110_icmp_audit/owner_manifest.tsv
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
target_rows_advanced=0
textual_bypass_ratchet=216 (unchanged)
tier3=not-run
```

Only these evidence files changed. No source, test, tool, guard, or mandatory
runner file changed. `stash@{0}` remains untouched. INBOX-110 stops here for
review before any dormant ICMP action is designed.
