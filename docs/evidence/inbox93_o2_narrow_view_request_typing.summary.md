# INBOX-93 dormant narrow-view request typing

Status: dormant amendment implemented and validated. Store production wiring is
not present in this commit; B2B retry and performance-baseline recapture remain
separately reviewed work.

## Base and scope

The amendment is based on evidence commit `24e11e51`, whose source parent is
the accepted B2A commit `714af637`, tree
`02d8e695d57984731a6c36ccd8100757e1fbd1cc`. Commit 1 froze the 34-cell
store/GEP compatibility cross-product and found only homogeneous low-bit
integer views of wider scalar bindings.

This commit changes only the dormant `ValueUseTransaction` compatibility
validator, its white-box tests, and this evidence. It does not change
`composed_selector_memory.zig`, any store consumer, GEP consumer wiring, the
source-guard inventory, tools, mandatory runners, or gate contracts.

The five diagnosis scenarios preserved in
`INBOX-93 preserve B2B wiring plus five diagnosis tests` were folded into the
dormant transaction suite. The original store wiring remains carried solely by
the verified patch:

```text
tmp/inbox92_store_perf/inbox92_store_wiring_hard_stop.patch
sha256=6be43a125f2ab937365a02d54158b3c6a99181dc35892209c446d6140f26727b
```

## Compatibility relation

Every named request now validates the canonical binding, semantic request, and
current home together. Exact class matches retain the prior path. A class
mismatch is compatible only when all conditions hold:

```text
request form = gpr32
request type = integer width 1...32
request class = gpr32
binding class = gpr64
binding defined bits >= semantic integer width
current home = arg64 | scratch64 | rax | spill64
```

The semantic request remains authoritative. Materialization continues through
`materializeScalar32`, producing the existing low-register operation:
`mov_arg_eax`, the EAX alias no-op, or `reload_rsp_eax`. The relation does not
mutate or rebind the source, rewrite its vreg class/bits, create a dependency,
or claim sign/zero extension beyond selecting the low semantic bits.

The same validator is used again after preparation and for prepared-record
re-derivation. A relocation to an unsupported home therefore fails closed; no
pre-mutation location is carried across preparation.

Pointer, stack descriptor, FP/XMM, vector, aggregate, pair, reverse-width,
insufficient-defined-width, non-integer, and durable-result action mismatches
remain rejected. No caller override, consumer predicate, function predicate,
new request field, or generalized class relaxation was added.

## Focused coverage

The suite covers the audited positive homes:

- wide-class `arg64` materialized with `mov_arg_eax`;
- wide-class accumulator `rax` consumed through its `eax` alias without a
  move;
- wide-class `.spill64` materialized with `reload_rsp_eax`;
- the exact `%236` at-current case with its original `gpr64/64` binding and
  slots 380/486/450, asserting:

```text
reload_rsp_eax slot380
reload_arg64_rsp rcx slot486
reload_arg64_rsp r8 slot450
add_r8_rcx
store_eax_stack_rcx4_disp32 0x1b94
```

- an exact-class `gpr32/.spill64` control through registration, seal,
  preparation, and materialization;
- a wide spill value live after the store, reloaded exactly once with its
  binding retained; and
- failure after preparation restoring instructions, bindings, address
  dependencies, and EFLAGS exactly.

Focused negatives cover insufficient binding width, non-integer request,
unsupported low32 home, pointer/class mismatch, the unchanged request type
contract, and an attempted durable address-result action. Existing XMM,
aggregate, pair, reverse-width, phase, cycle, GEP, and rollback negatives remain
green in the full root.

## Non-Tier-3 validation

The final dormant source state passed:

```text
full_unit=1155/1155
full_unit_summary_log=tmp/inbox93_b2a2/full_unit_summary.log
full_unit_summary_sha256=88b9f0543090b0f935a5073797f09accc0cd7d58b5c6629eb71221adcaaefde7
abi_differential_from_full_unit=60/60 cases; 30/30 real functions; result=pass
focused_codegen_canaries=2/2; execution_cases=35; local_fail=0
focused_canaries_log=tmp/inbox93_b2a2/focused_canaries.log
focused_canaries_sha256=7671352de65ca9f993fcd8be0e0038bbded33f2fb36be581ffcaa6fb9f15c133
source_guard=current-tree-pass; frozen bypass inventory unchanged
tier3=not-run
```

The fresh direct report log is
`tmp/inbox93_b2a2/full_report_direct.log`:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
```

The accepted 285-row GEP/object/owner projection is exact:

```text
accepted_object=tmp/inbox93_b2a2/accepted_cohort.o
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=tmp/inbox93_b2a2/selection_owner_manifest.tsv
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
composed_block=40
composed_cfg=127
legacy_envelope=17
structural_fallback=101
ledger=167/17/101
```

No Tier 3 was run. After acceptance, the next slice must recapture the
authoritative five-run performance baseline at this amendment tree before the
complete ten-occurrence B2B store retry.
