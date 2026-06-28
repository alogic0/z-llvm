# Working Cycle

This project replaces the LLVM library dependency used by Zig's distribution.
Worker cycles should therefore move x86_64 Zig codegen replacement evidence
forward, not just add local recognizers.

## Cycle Mode

Work in automatic short goal cycles until no clear goals remain or the user
interrupts.

One cycle means:

1.  Choose exactly one concrete goal.
2.  Implement only that goal.
3.  Run focused validation.
4.  Save important logs under `tmp/`.
5.  Update docs, counters, or readiness notes when ownership or evidence
    changes.
6.  Commit the completed goal.
7.  Confirm `git status --short` is clean.
8.  Report the cycle result.
9.  Start the next cycle automatically unless a stop condition applies.

A dirty worktree is allowed while actively implementing a cycle. A dirty
worktree is not allowed when reporting a cycle as complete or starting the next
cycle.

If interrupted mid-cycle, report:

- current goal;
- modified files;
- what remains before commit;
- validation already run or still needed;
- whether the changes are intentional or exploratory.

Do not revert mid-cycle work unless explicitly asked.

## Goal Selection

At the start of every cycle:

1.  Read `docs/next_steps.md`.
2.  Check the latest saved logs under `tmp/`.
3.  Pick the highest-value goal that removes ownership debt toward x86_64 Zig
    codegen replacement.

Prefer goals in this order:

1.  Replace compatibility or temporary static tables with Zig-owned facts or
    provider contracts.
2.  Remove nominal/name-specific admission.
3.  Replace shape recognizers with typed AIR or semantic facts.
4.  Expand object/native-link/executable proof after ownership improves.
5.  Do docs-only cleanup only when it unblocks implementation clarity.

Do not choose docs-only work while clear implementation debt remains.
Do not bundle unrelated goals into one commit.

## Architectural Decisions

Do not stop just because there are two plausible directions.

When an architectural choice appears, choose the option that:

1.  Makes Zig semantic/type facts the source of truth.
2.  Uses function-local inference only as validation or a temporary bridge.
3.  Puts temporary data behind provider/contract abstractions.
4.  Fails closed instead of accepting permissive recognition.
5.  Removes nominal/name-specific admission.
6.  Keeps scope on x86_64 unless the selected goal is explicitly about a
    cross-target boundary.
7.  Minimizes Zig stage4 rebuilds.
8.  Can be validated with focused frontier gates.

Record the decision in `docs/next_steps.md` before or with the implementation.

Stop for architectural review only if the choice would require:

- changing the public hook contract with `../ziglang`;
- broad redesign of the AIR export format;
- abandoning an existing documented milestone;
- accepting behavior that is not fail-closed.

## Current Aggregate Direction

For aggregate layout ownership:

- Zig-owned exported aggregate layout facts are the desired source of truth.
- Function-local inference is validation or a bridge, not the final authority.
- Provider precedence should be explicit:
  `exported_fact > generated_inference > temporary_static_facts > boundary >
  missing`.
- Compatibility fallback entries should remain at zero.
- Packed/unaligned aggregates stay boundary-owned until their layout and ABI
  facts are explicitly supported.

Do not remove temporary static aggregate facts by guessing from names. Remove
them by moving rows to exported facts, generated inference, or proven
function-local evidence.

## Progress Metrics

Each cycle report should include the counters it changed. For aggregate layout
ownership, report:

```text
exported_facts=N
temporary_static_facts=N
generated_inference=N
boundary_provider=N
fallback_entries=N
frontier_source_rows=N
frontier_functions=N
frontier_executable_ok_rows=N
frontier_local_fail=N
boundary_unexpected_accept_rows=N
boundary_wrong_diagnostic_rows=N
```

Measurable forward progress means:

- `temporary_static_facts` goes down;
- `exported_facts` goes up;
- `fallback_entries` stays `0`;
- `frontier_local_fail` stays `0`;
- `boundary_unexpected_accept_rows` stays `0`;
- `boundary_wrong_diagnostic_rows` stays `0`;
- accepted rows use stronger ownership, not broader name matching.

Example cycle result:

```text
Before:
exported_facts=0
temporary_static_facts=45
fallback_entries=0
frontier_local_fail=0

After:
exported_facts=3
temporary_static_facts=42
fallback_entries=0
frontier_local_fail=0
```

That is progress. A cycle that only renames code without improving ownership,
proof, diagnostics, or maintainability is not enough unless it unblocks the
next implementation cycle.

## Validation Policy

Use focused validation by default.

For aggregate layout/provider work, prefer:

```text
zig build test
zig run tools/audit_aggregate_layout_providers.zig > tmp/aggregate_layout_provider_audit.log
zig build distribution-air-release-frontier > tmp/frontier_counter_update.log 2>&1
zig build distribution-air-release-frontier-boundaries \
    > tmp/frontier_boundary_counter_update.log 2>&1
zig run tools/update_doc_counters.zig -- \
    --gate=distribution-air-release-frontier \
    --from-log=tmp/frontier_counter_update.log
zig run tools/update_doc_counters.zig -- \
    --gate=distribution-air-release-frontier-boundaries \
    --from-log=tmp/frontier_boundary_counter_update.log
git diff --check
```

Run `distribution-all` only for a broad milestone confirmation, shared build
orchestration changes, or a documented reason in the active goal.

Do not rebuild `../ziglang` stage4 unless the Zig hook contract or patched Zig
source changed.

## Cycle Report

After each clean commit, report:

```text
commit=<hash>
goal=<one sentence>
architectural_choice=<none or short decision>
validation=<commands/logs>
progress_before=<key counters>
progress_after=<key counters>
remaining_blocker=<one sentence>
next_goal=<one sentence>
git_status=clean
```

Then immediately start the next cycle unless:

- no clear next goal remains;
- a stop-for-architectural-review condition applies;
- validation exposes an unexpected blocker;
- the worktree cannot be made clean;
- the user interrupts.
