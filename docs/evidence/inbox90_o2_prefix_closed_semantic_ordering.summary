# INBOX-90 O2-3B1A4 dormant prefix-closed semantic ordering

Status: implemented and validated; delivered for Supervisor/Reviewer review.
O2-3B1B remains unauthorized and no production consumer is wired.

## Base and preserved B1B work

The accepted B1A3 code base is commit
`6e0f3ea0b548d02146915db879e3d2bded7c8070`, tree
`751bec3f886b88bb0ccbcbcb5723bcc3b3852c2a`. The directive arrived at
documentation-only descendant `26801d07`; the intervening tracked changes are
only `docs/next_steps.md` history.

Before modifying the dormant transaction, the reconciled B1B worktree carrier
was verified against a clean detached B1A3 worktree:

```text
patch=tmp/inbox87_second_resume_perf/inbox87_second_resume_hard_stop.patch
patch_sha256=755313923184c649f044a5e18bda0d2d8cda7716367a45a82b400b6171d21d69
clean_apply_base=6e0f3ea0b548d02146915db879e3d2bded7c8070
git_apply_check=pass
```

The five uncommitted B1B files were then restored to the accepted state. The
patch remains the sole carrier of the reconciled B1B production migration.
This slice changes only the dormant `ValueUseTransaction`, its tests, the
value-use source guard, and this evidence. No GEP lowerer, production consumer,
bypass inventory, tool, or mandatory runner changes.

## Prefix-closed semantic-role plan

Seal now builds a separate transaction-private semantic ordering graph and
ordered operand plan in addition to the unchanged physical mapping/copy graph.
For each closed address action the roles are derived internally from the
sealed descriptor:

1. primary/base request;
2. secondary index/offset request, when present; and
3. any future schema operands in descriptor order.

No public role, priority, phase, function predicate, or consumer-selected
ordering input exists. Independent roots use a fixed structural key derived
from their physical destination and stable source identity, never function
name or registration order. Shared action ownership is an ordering
contradiction and fails at seal before destination planning can obscure it
with a physical conflict. The semantic graph is cycle-checked before mutation;
the existing physical copy-cycle authority and its
`ValueUseCopyCycleRequiresO4` boundary remain unchanged.

Each role is classified as already-in-place/no-op, safe-early, or ordinary.
Only the longest no-op/safe-early prefix is retained as an early plan. The
first ordinary role closes the prefix, so an otherwise eligible secondary can
never jump ahead of an ordinary primary. Early copies execute in semantic-role
order. Remaining source views are consumed later by the closed action in that
same base-then-secondary order. The action reuses each planner-owned early home
and does not rematerialize the original source.

Eligibility remains exactly B1A3's narrow, flags-preserving planner policy:
single physical mapping, proven-free non-source destination, and supported
spill-backed GPR/pointer reload. Every emitted early instruction is still
checked through the EFLAGS classification. Genuine copy cycles, allocator
redesign, general parallel-copy scheduling, and producer-selected sequencing
remain out of scope.

Rollback clears the semantic graph, ordered operand plan, early plans/homes,
and restores the existing single instruction-authority snapshot: instructions,
bindings, spills and counters, accumulator state, EFLAGS plus semantic records,
labels, and address dependencies. Commit retains the completed ordered copies.

## Focused coverage

The focused tests cover:

- exact base-then-index reload order for scaled address formation (the
  `__udivei5` hard-stop shape), despite secondary-first registration;
- exact base-then-offset order for byte address formation;
- both operands spill-backed with both destinations proven free;
- reversed physical destinations (`byte: r8/rcx`, `scaled: rcx/r8`) without
  reversing semantic roles;
- primary early followed by secondary ordinary (the retained B1A3 case);
- primary no-op followed by secondary early;
- primary ordinary followed by an otherwise early-eligible secondary, which
  stays ordinary and emits later after the primary;
- source/destination aliasing and multiple independent safe early copies;
- shared secondary ownership rejected before mutation;
- existing physical copy-cycle rejection before mutation; and
- exact rollback after failure following the first ordered early copy and
  after both ordered early copies plus a later preservation failure, including
  live EFLAGS and dependency-domain state.

The source guard rejects a public semantic-role/operand-phase/ordered-operand
surface and caller-visible semantic or ordering priority fields. The existing
no-function/family-predicate and frozen-bypass guards remain green.

## Validation

The final source state passed the authorized validation:

```text
full_unit=1141/1141
full_unit_log=tmp/inbox90_full_unit.log
full_unit_log_sha256=aaac3acdcd3db5d19d202751ae452dc6a49a81ca1bbcb98d7d6c01b0936f382d
source_guard=current-tree-pass; frozen bypass inventory unchanged
production_consumer_wiring=none
tier3=not-run
```

`zig build test` also completed successfully; its existing coupled ABI
differential substep reported 60/60 cases and 30/30 real functions. This was
not a Tier 3 run.

The fresh post-final-code full-cohort diagnostics are retained at
`tmp/inbox90_b1a4_full_report.log`. Capture SHA-256 is
`3575879c50f476c03ae4bfb0e29948d65dc20fce7428aba5dbda5df080d48ca8`;
report SHA-256 is exactly
`49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`:

```text
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
```

The report is byte-identical to baseline. A separate accepted-cohort-only
object check also reproduced
`061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be`.
Formatting and `git diff --check` pass. No Tier 3 was run.

After B1A4 acceptance, the third complete B1B retry must first recapture the
five warmed BEFORE samples at the accepted B1A4 tree, then migrate all four
complete GEP lowerers / exactly 11 bypass occurrences under the previously
pinned correctness, object-identity, and performance rules. If another API or
ordering gap appears, the next escape is to split by complete lowerer families,
never selected rows or branches.
