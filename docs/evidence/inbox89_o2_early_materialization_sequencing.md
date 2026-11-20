# INBOX-89 O2-3B1A3 dormant early-materialization sequencing

Status: implemented and validated; delivered for Supervisor/Reviewer review.
O2-3B1B remains unauthorized and no production consumer is wired.

## Base, preserved B1B work, and boundary

The accepted B1A2 production base is commit `2308bf6d7e89b8d2bd916abd6b8926125fa9eebd`
with tree `a7d47fd383ad9a41e99b49a09c5701f4dad7259f`. The directive arrived at
documentation-only descendant `00c38a64`; the intervening tracked difference
from B1A2 is only `docs/next_steps.md`.

Before modifying the dormant transaction, the uncommitted B1B work was
verified byte-for-byte against its preserved carrier:

```text
patch=tmp/inbox87_resume_perf/inbox87_b1b_hard_stop.patch
patch_sha256=f8fc13e85c53000a1b96ac287c0e1367f8e5d1a3b2a9f3ac42383cf135d537ed
clean_apply_base=2308bf6d7e89b8d2bd916abd6b8926125fa9eebd
git_apply_check=pass (detached clean worktree)
```

The five B1B production/evidence files were then restored. The patch remains
the sole carrier of that work. This slice changes only the dormant
`ValueUseTransaction`, its white-box tests, the exhaustive free-register
query needed by that dormant planner, and this evidence. It does not change a
GEP lowerer, production consumer, bypass inventory, source-guard ratchet,
tool, mandatory runner, or gate.

## Planner-derived sequencing

Seal now retains the complete physical mapping graph after destination
conflict validation and before any selector mutation. The planner derives an
early plan only when all of these hold:

- the destination is an argument GPR declared by the sealed mapping graph;
- the destination is unique, is not itself a mapping source, and is proven
  free by the selector's exhaustive register-availability query;
- one semantic source has one physical mapping (no hidden multi-home or
  parallel-copy scheduling);
- the current source is a supported spill-backed GPR/pointer view; and
- the emitted materialization is rechecked instruction-by-instruction as an
  EFLAGS-preserving copy/reload.

This is deliberately planner-derived. No action flag, function/family
predicate, caller-selected early register, or caller-selected phase exists.
In-register copies keep their prior order; address arithmetic, generated
writes, accumulator destinations, pairs, bounded-descriptor materialization,
and all cycles remain outside the early phase. A genuine cycle still rejects
at seal with `ValueUseCopyCycleRequiresO4`, before mutation.

Prepare emits the selected early reloads first and records a private
transaction-owned prepared home plus the source virtual-register identity.
It then preserves/clobbers the remaining destinations, explicitly excluding
the early homes. Fixed materialization and closed action execution revalidate
the canonical source binding/type/class/dependencies and consume the private
prepared home instead of resolving and rematerializing the original source.
The prepared record also retains the post-preparation canonical source
location, so a later source relocation/rebind still invalidates the lease.

The runtime physical-effect check makes the flags-preserving restriction
fail closed even if an eligible materializer later changes. The one-line
`.stack_f32_pair_ptr` addition to `scratchRegIsProvenFree` is the exhaustive
non-register case required to instantiate that existing authority for the
dormant planner; it creates no capability or emission path.

## Rollback and focused coverage

The existing instruction-level snapshot remains the single outer rollback
authority. It restores instructions, value bindings, spill assignments and
counters, accumulator state, EFLAGS and semantic-record length, labels, and
the address-dependency domain. Rollback additionally invalidates all early
plans/homes before closing the transaction; commit retains their emitted
copies as part of the completed instruction authority.

Focused cases cover:

- the stopped B1B order exactly: reload the spill-backed base into free R8,
  then spill the unrelated live RCX value, then move the offset and append the
  address add;
- exactly one R8 reload, proving the action does not rematerialize the source;
- an occupied/live R8 is not classified free and follows ordinary
  preservation/materialization;
- source/destination aliasing plus two independent safe early reloads;
- the existing same-source multi-destination preservation-once behavior;
- genuine cycle rejection with zero instructions;
- failure after the early copy but before preservation completes, restoring
  exact selector state;
- failure after both early copy and preservation, restoring instructions,
  bindings, spills, counters, EFLAGS/semantic records, and a nonempty
  dependency domain; and
- a live EFLAGS definition surviving all early reload and spill instructions.

The pre-existing B1A2 dynamic bounded-pointer test remains byte-for-byte in
its accepted `mov_rsp_arg64` / adjustment / offset-move / add order; the
planner does not incorrectly advance that flags-writing base materialization.

## Validation

The final source state passed the authorized focused and full validation:

```text
focused_early_sequencing_cases=green
full_unit=1137/1137
full_unit_log=tmp/inbox89_full_unit.log
full_unit_log_sha256=1de0bc649ea3b1dcafb4ffce818d550699afdc727b160337a290fe0ae3ad6d97
abi_differential_from_full_unit=60/60 cases; 30/30 real functions; result=pass
source_guard=current-tree-pass; frozen bypass inventory unchanged
production_consumer_wiring=none (only composed_selector.zig module export)
tier3=not-run
```

The fresh post-final-code cohort log is
`tmp/inbox89_b1a3_full_report.log`, generated from the frozen capture with
SHA-256 `7be46e0b88c96fce0ce527407672843c43d3416ce56257d53a286603bd533e06`:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
```

The report is byte-identical to the accepted baseline. Formatting and
`git diff --check` pass. No Tier 3 was run.

After B1A3 acceptance, B1B must restart from the accepted B1A3 tree using the
preserved patch, recapture the five-run warmed BEFORE performance baseline at
that tree, and retry the complete four-lowerer / 11-occurrence family. The
stopped run's performance evidence remains provisional because this dormant
sequencing amendment changes the compiled binary.
