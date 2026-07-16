# INBOX-97 — O2-3M-A dormant inline-memcpy action set

Status: delivered for Supervisor/Reviewer review. M-B production wiring is not
included.

## Frozen source and scope

The accepted B3C production parent is
`4aa17f9b8e45d1931c00151c3a1ed9f836bb402f` (tree
`deaafc13d33c7b760d1734b8ccdbd2601d6a6bec`). Work began at the existing
documentation-only descendant `1da673f628b74f3f64aff126d97e10d8b6008b27`
(tree `b802d43db876dc09aaf535d1a1c51f0f9bfc2fc7`); its only production-parent
diff was `docs/next_steps.md`. No branch movement, rebase, or destructive
worktree operation was used. `stash@{0}` remains
`INBOX-93 preserve B2B wiring plus five diagnosis tests` and was not applied,
modified, or dropped.

The only source changes in M-A are:

```text
src/codegen/x86_64/generic_cfg/composed_selector_value_use_transaction.zig
src/codegen/x86_64/generic_cfg/composed_selector_value_use_transaction_tests.zig
src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig
```

`composed_selector_calls.zig`, the mandatory runner, and the frozen bypass
inventory have no diff. `lowerInlineMemcpy` still contains all three accepted
`emitValueIntoScratch` calls; M-A changes no production consumer or emission.

## Complete dimensional matrix

The pre-wiring matrix is
`docs/evidence/inbox97_o2_memcpy_api_fit_audit.tsv`, SHA-256
`07c6dc463f43e59ec479bb6e3dc1a6d657aa3f0ac614d79b3d3d1ba8a1bcb798`.
It freezes:

- result, direct/indirect form, calling convention, return metadata, tail kind,
  return/arity/signature, volatility, and operand-type diagnostics, all of
  which remain pre-transaction dispatch responsibilities;
- the accepted ignored `callee_function_ty`, call-attribute, and argument-
  attribute text, including the real `nonnull`, `align`, `noalias`,
  `readonly`/`writeonly`, `captures`, and `immarg` forms;
- named, immediate, null, and other value forms for both pointers and the i64
  length;
- canonical class/defined-bit metadata and every legacy register,
  accumulator, spill, pair-low-limb, stack/address/table, FP, vector, and
  aggregate home; and
- distinct operands, the same named pointer requested for both RDI and RSI,
  caller-clobber aliases, and a genuine RDI/RSI/RDX copy cycle.

Only the legacy named homes are admitted: scalar 64-bit registers, RAX,
spill64, and the low limb of an existing register pair with at least 64
defined bits. Immediate and typed-null operands remain rejected for this
consumer even though typed null exists elsewhere in the general transaction.
Stack/table/XMM/pair-spill/aggregate forms remain outside the action.

## Closed dormant action

`PreparedAction.inline_memcpy` is owned by the destination-pointer request and
contains only opaque handles for the already-registered source pointer and
i64 length. The action adds no callee, result, memmove, stack-argument, or
general-call capability. Its action-specific request forms prevent generic
pointer materialization from widening the legacy memcpy boundary.

Seal constructs the complete physical graph before mutation:

```text
destination -> RDI
source      -> RSI
length      -> RDX
```

The existing same-source/multiple-nonconflicting-destination rule accepts a
single named pointer used as both destination and source. A genuine physical
cycle still returns `ValueUseCopyCycleRequiresO4` before mutation. The sealed
semantic-role plan is primary destination, secondary source, tertiary length;
no caller field or registration order controls it. Memcpy forms are not early
materialization candidates, so the action retains the exact call order.

Execution first validates the final `.clobber` against a copied EFLAGS state,
before mutation. It then calls the existing
`spillLiveCallerClobbersForCall` exactly once. That routine remains the sole
preservation authority; the action adds no spill or scratch algorithm. Its
original diagnostic is retained through `ValueUseActionDiagnostic` and the
transaction-owned diagnostic channel.

After preservation, transaction-owned prepared records are re-derived from
canonical bindings. This covers the accepted case where preservation moves an
at-current accumulator operand to its spill home without granting artificial
post-call liveness. Stable vreg identity and the normal strict post-action
re-derivation continue to reject an action rebind.

The action then emits exactly RDI, RSI, RDX staging and finally calls the sole
EFLAGS append authority with
`memcpy_rdi_rsi_rdx_rax/.clobber`. It creates no result binding. The existing
snapshot owns all instructions, bindings, spills/counters, accumulator state,
EFLAGS and semantic records, labels, PHI state, and address dependencies. The
address domain remains one snapshot per authority and zero copies per request.

The source guard rejects `.memcpy_pointer`, `.memcpy_length`,
`.inline_memcpy`, and the white-box failure control from every production
consumer file. It therefore proves the action remains dormant in M-A.

## Focused coverage

The full unit root includes focused cases proving:

- exact caller preservation followed by RDI -> RSI -> RDX staging and one
  committed call-clobber semantic record;
- the same named pointer in RDI and RSI plus an audited register-pair low-limb
  view;
- immediate/null, insufficient-width, unsupported-home, and genuine-copy-
  cycle rejection before mutation;
- exact rollback after authoritative preservation, after RDI, after RSI,
  after RDX, and after the call append, including instructions, bindings,
  spill maps/counters, dependency metadata, EFLAGS, and semantic records;
- original caller-preservation diagnostic retention; and
- a live EFLAGS definition rejecting before preservation or argument staging.

Every rollback boundary uses `std.testing.allocator`; the complete run is
leak- and double-free-clean. The failure control is compile-time test-only and
the production source guard rejects any consumer reference to it.

## Frozen M-B ratchet

`docs/evidence/inbox97_o2_memcpy_mb_ratchet.tsv`, SHA-256
`c90ac9c358ba0f8b02def53ec80268a365120b6220471c65bac2b698536f267e`,
freezes exactly the three `lowerInlineMemcpy/emitValueIntoScratch`
occurrences: destination, source, and length. The expected separately reviewed
M-B movement is 231 -> 228. M-A remains 231; the frozen inbox81 inventory is
unchanged at SHA-256
`3bac06156864f8cc276f816bfa8ceb904f1d0766fa22d13a8cf0af15489f447d`.

## Non-Tier-3 validation

The final full unit build passed 1177/1177, including the mandatory ABI
differential at 60/60 cases and 30/30 real functions:

```text
full_unit_log=tmp/inbox97_ma/full_unit.log
full_unit_log_sha256=ce4ce41a58721aad9ae3d37f354cb959a915ffed2a6d3d1cfa4fd6ba718f5b69
abi_differential=60/60 cases; 30/30 real functions; result=pass
source_guard=current-tree-pass; production memcpy action wiring=none
```

The directly invoked procedural canaries remain green:

```text
focused_codegen_canaries=2/2; execution_cases=35; local_fail=0
focused_canaries_log=tmp/inbox97_ma/focused_canaries_final.log
focused_canaries_log_sha256=7671352de65ca9f993fcd8be0e0038bbded33f2fb36be581ffcaa6fb9f15c133
```

The fresh post-final-code report used frozen input
`tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll`, SHA-256
`7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b`:

```text
full_report=tmp/inbox97_ma/full_report_final.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
```

The accepted-only projection is exact:

```text
accepted_object=tmp/inbox97_ma/accepted_cohort_final.o
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=tmp/inbox97_ma/selection_owner_manifest_final.tsv
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
```

The exact whole-report hash proves no target or collateral row moved. No
integrated runner, strengthened Tier 2, or Tier 3 run was needed for this
dormant action-only slice; Tier 3 was not run.

Stop here for M-A review. M-B production wiring is not authorized by INBOX-97.
