# INBOX-99 — O2-3M-A2 dormant request-failure provenance

Status: delivered for Supervisor/Reviewer review. The stopped M-B production
wiring is not included; M-B remains separately authorized only after M-A2 is
accepted.

## Frozen source and worktree preservation

Implementation started from the Supervisor documentation descendant
`ae955a3a3b9c52e59694595f25b9313e37a05f8f`
(tree `1799c5ab26a24122aaaa76779be713511578f787`), whose production parent is
the accepted M-A commit `a801de63208933da7137e4ff2c6b444eac922a02`
(tree `aaf045695bbed7d9ce563136b0ecaafb4b667067`). No rebase, hard reset, or
branch movement was used.

The stopped M-B work is preserved at
`tmp/inbox98_memcpy_perf/inbox98_mb_hard_stop.patch`, SHA-256
`31f46fb9bd2973c85498078752d6a2c3b60d6ec285aabc04d583a6e127eda38a`.
`git apply --check` succeeds against the clean M-A2 parent. The patch was not
applied in this slice. `stash@{0}` remains `INBOX-93 preserve B2B wiring plus
five diagnosis tests` and was not applied, changed, or dropped.

The only implementation files changed are the dormant value-use transaction,
its unit tests, and the composed-selector source-guard tests. The production
consumer `composed_selector_calls.zig`, the mandatory runner, the frozen
bypass inventory, and the frozen M-B ratchet have no diff. The bypass
inventory remains SHA-256
`3bac06156864f8cc276f816bfa8ceb904f1d0766fa22d13a8cf0af15489f447d`;
the M-B ratchet remains SHA-256
`c90ac9c358ba0f8b02def53ec80268a365120b6220471c65bac2b698536f267e`
and 231 occurrences. There is no production wiring or emission change.

## Narrow diagnostic authority

`ValueUseTransaction` now retains one private optional `RequestHandle`: the
first request to which a failure is attributable. The only public observation
is:

```text
failedRequestIs(handle) bool
```

It exposes no handle accessor, role, index, source identity, location,
binding, retry, or mutation capability. The stored handle begins empty,
remains empty on successful transactions, and is written only when empty.
The record is intentionally not cleared by automatic rollback, allowing the
consumer's caught-error mapper to compare its own locally retained handles.
Authority, index, and generation must all match, so a foreign handle is
always false.

Request provenance is attached at the general request-validation,
destination/mapping, early-plan, fixed materialization, prepared-record,
canonical dependency, post-consumption, action-registration operand, and
closed-action materialization boundaries. Nested action propagation therefore
cannot replace a more precise secondary-operand failure with the owner.
Plan/authority failures remain unattributed: request/mapping capacity,
destination conflicts, copy and semantic-order cycles, lifecycle/phase
errors, EFLAGS rejection, caller-clobber diagnostics, allocation failure, and
the test-only rollback trigger match no request. Provenance is diagnostic
only: no retry, success path, planning decision, or materialization behavior
consults it.

The source guard rejects public provenance accessors beyond the boolean query.
Production query use is dormant today. When M-B is separately authorized, the
guard permits exactly three queries and only inside the brace-bounded
`composed_selector_calls.zig/inlineMemcpyValueUseDiagnostic` mapper; it rejects
another file, another function, a moved success-path query, or a changed
count.

## Focused proofs

The full unit root contains production-shaped coverage proving:

- destination, source, and length unresolved failures independently select
  only their retained request handle and recover the exact
  `composed-block-memcpy-dst|src|len` detail;
- action-registration validation attributes malformed source and length
  operands, while a later failure cannot overwrite the first one;
- a secondary spill operand changed to an invalid XMM home fails during
  materialization, automatically rolls back, retains source provenance, and
  restores the exact binding and instruction stream;
- a secondary source invalidated after preparation/materialization is recorded
  before nested propagation and is not replaced by the destination action;
- copy-cycle, capacity, lifecycle, caller-clobber, EFLAGS, and test-boundary
  failures have no request match;
- foreign handles never match; and
- successful execution and commit keep provenance empty.

The production-shaped negative uses the same three locally retained handles
that M-B will retain and maps an unresolved source to
`composed-block-memcpy-src` solely through `failedRequestIs`; no M-B wiring or
consumer revalidation is present.

## Non-Tier-3 validation

The final full unit and ABI build passed:

```text
full_unit_log=tmp/inbox99_ma2/full_unit.log
full_unit_log_sha256=5bc6ae5aba4027ce54811863d3fa7cfe2348a0747afcc194d36118827dcedd6d
unit=1182/1182
abi_differential=60/60 cases; 30/30 real functions; result=pass
source_guard=current-tree-pass; failure-query production uses=0
```

The fresh report used
`tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll`, SHA-256
`7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b`:

```text
full_report=tmp/inbox99_ma2/full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
```

The accepted-only input is
`tmp/inbox63_accepted_cohort.ll`, SHA-256
`d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4`.
Its projections are exact:

```text
accepted_object=tmp/inbox99_ma2/accepted_cohort.o
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=tmp/inbox99_ma2/selection_owner_manifest.tsv
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
```

No Tier 3 was run. Stop here for M-A2 review; do not resume M-B from this
slice.
