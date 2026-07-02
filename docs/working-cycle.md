# Working Cycle

This project replaces the LLVM library dependency used by Zig's distribution.
The active milestone validates x86_64 first, but implementation must keep target
ownership explicit so later targets are not blocked by hidden x86_64 shortcuts.
Worker cycles should therefore move x86_64 Zig codegen replacement evidence
forward while preserving target boundaries.

## Cycle Mode

Work in automatic short goal cycles until no clear goals remain or the user
interrupts.

One cycle means:

1.  Choose the next goal through the Goal Selection rules below (driven by
    `docs/roadmap/convergence_progress.md`).
2.  Implement only that checklist item.
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

The strategy reference is
`docs/roadmap/end_to_end_convergence_plan.md`; the live tracker is
`docs/roadmap/convergence_progress.md`.

At the start of every cycle:

1.  Read `docs/roadmap/convergence_progress.md`.
2.  Read `docs/next_steps.md` for active blocker notes.
3.  Check the latest tracked evidence summaries under `docs/evidence/` (and
    saved logs under `tmp/` for the current cycle only).
4.  Pick the cycle goal in this priority order:
    1.  the first failing `distribution-real-rows` entry, when that gate
        exists;
    2.  the first failing real-program milestone gate
        (`distribution-zig-integrated-exe`), when it exists;
    3.  the first unchecked item in
        `docs/roadmap/convergence_progress.md`, top to bottom.

When the selected goal directs family work, use
`docs/roadmap/x86_64_compiler_core_family_checklist.md` as the tactic list
for that goal — the family checklist no longer drives goal selection on its
own. Stay on the selected goal until one of these happens:

- the goal is complete;
- the goal needs an architectural-review stop;
- validation exposes an unexpected blocker.

When a goal is completed, check it off in
`docs/roadmap/convergence_progress.md` (and, for family items, in the family
checklist) in the same commit as the implementation and evidence update.
When ratchet counters move, update the Ratchet State table in
`docs/roadmap/convergence_progress.md` in the same commit; never lower a
counter without a ratchet-migration note in the cited evidence summary.

Prefer goals in this order:

1.  The first failing real row or real-program gate, then the first
    unchecked convergence-progress item.
2.  Replace compatibility or temporary static tables with Zig-owned facts or
    provider contracts.
3.  Remove nominal/name-specific admission.
4.  Replace shape recognizers with typed AIR or semantic facts.
5.  Expand object/native-link/executable proof after ownership improves.
6.  Do docs-only cleanup only when it unblocks implementation clarity.

Do not choose docs-only work while clear implementation debt remains.
Do not bundle unrelated goals into one commit.

## Reference Policy

This file controls worker goal selection and cycle mechanics. For detailed
technical policy, use [development_cycle.md](development_cycle.md),
especially:

- evidence freshness;
- validation scope;
- compiler/stage4 selection;
- linker ownership;
- upstream LLVM mapping;
- replacement matrix rules.

If the two documents conflict, follow this file for active worker goal
selection and cycle mechanics, and `development_cycle.md` for technical
policy.

## Initial Target Policy

The active replacement milestone is x86_64. Validate and claim progress only
for x86_64 unless the selected goal is explicitly about a cross-target
boundary.

This does not mean hardcode x86_64 behavior in generic code. Target-specific
logic must stay visible behind target, ABI, object, or provider boundaries.
Acceptable locations and names include:

- `src/codegen/x86_64/`;
- x86_64 SysV ABI planners and classifiers;
- x86_64 DataLayout helpers;
- x86_64 object, relocation, and native-link handoff paths;
- provider kinds or diagnostics that explicitly say x86_64.

Generic modules may call target-specific helpers, but they must not silently
encode x86_64-only rules as if they were target-independent.

For non-x86_64 targets:

- do not implement them in this milestone;
- keep them as explicit future or boundary rows;
- fail closed when a generic path cannot prove the target;
- document target assumptions in `docs/next_steps.md` or readiness docs.

A change is acceptable if it advances x86_64 while keeping target ownership
visible. A change is not acceptable if it makes x86_64 behavior look generic
when it is not.

## Architectural Decisions

Do not stop just because there are two plausible directions.

When an architectural choice appears, choose the option that:

1.  Makes Zig semantic/type facts the source of truth.
2.  Uses function-local inference only as validation or a temporary bridge.
3.  Puts temporary data behind provider/contract abstractions.
4.  Fails closed instead of accepting permissive recognition.
5.  Removes nominal/name-specific admission.
6.  Keeps validation and claims scoped to x86_64 unless the selected goal is
    explicitly about a cross-target boundary.
7.  Keeps target-specific behavior behind explicit target/ABI/provider modules.
8.  Minimizes Zig stage4 rebuilds.
9.  Can be validated with focused frontier gates.

Record the decision in `docs/next_steps.md` before or with the implementation
only when the decision blocks, changes active family, or needs review. Routine
narrow hook-contract facts should be recorded in the family checklist and commit
message instead.

### Narrow Hook-Contract Exception

The worker may continue without stopping when all of these are true:

- the active checklist item requires one missing typed-v2 fact;
- the change is a narrow additive or versioned export in `../ziglang`;
- the change does not redesign the AIR export format;
- the change does not remove or weaken existing facts;
- the change does not introduce source-name, case-id, or AIR-text recovery;
- unsupported variants remain fail-closed;
- the z_llvm consumer and source-backed proof are implemented in the same
  cycle.

This exception exists so compiler-core family items can make normal progress
when Zig has the semantic data but the current typed-v2 export omitted one
operand, type, block, or control-flow fact.

Stop for architectural review only if the choice would require:

- broad, ambiguous, or cross-family hook-contract changes in `../ziglang`;
- changing existing hook fact semantics instead of adding a narrow versioned
  fact;
- broad redesign of the AIR export format;
- abandoning an existing documented milestone;
- making an x86_64-only rule appear target-independent;
- accepting behavior that is not fail-closed.

## Current Aggregate Direction

For aggregate layout ownership:

- Zig-owned exported aggregate layout facts are the desired source of truth.
- Function-local inference is validation or a bridge, not the final authority.
- Any x86_64 ABI interpretation of those facts must stay in x86_64 ABI
  planning code, not in the generic fact contract.
- Provider precedence should be explicit:
  `zig_emitted_exported_fact > sidecar_exported_fact >
  temporary_static_facts > boundary > missing`.
- The patched Zig hook now emits a narrow
  `zllvm-aggregate-layout-facts-v1` descriptor section for supported aggregate
  semantic layouts; checked-in sidecars remain a temporary compatibility
  provider until all accepted rows are proven from Zig-emitted facts.
- Compatibility fallback table plumbing should remain removed.
- Generated inference is currently not an active aggregate layout provider; use
  function-local inference only as validation/bridging evidence, not as a
  nominal lookup source.
- Packed/unaligned aggregates stay boundary-owned until their layout and ABI
  facts are explicitly supported.

Do not remove temporary static aggregate facts by guessing from names. Remove
them by moving rows to exported facts or proven function-local evidence.

## Progress Metrics

Each cycle report should include the checklist item it completed and the
counters it changed. For compiler-core family work, report:

```text
family=<name from x86_64_compiler_core_family_checklist.md>
item=<completed checklist item>
checklist_before=<unchecked or partial>
checklist_after=<checked>
inventory_bucket_before=N or not refreshed
inventory_bucket_after=N or not refreshed
frontier_source_rows=N
frontier_functions=N
frontier_executable_ok_rows=N
frontier_local_fail=N
boundary_unexpected_accept_rows=N
boundary_wrong_diagnostic_rows=N
```

For aggregate layout ownership, also report:

```text
exported_facts=N
temporary_static_facts=N
generated_inference_examples=N
boundary_provider=N
fallback_table=removed
frontier_source_rows=N
frontier_functions=N
frontier_executable_ok_rows=N
frontier_local_fail=N
boundary_unexpected_accept_rows=N
boundary_wrong_diagnostic_rows=N
```

Measurable forward progress means:

- one checklist item in the active family is checked off with implementation
  evidence;
- the targeted inventory bucket goes down, or unsupported forms are explicitly
  reclassified as fail-closed boundaries;
- compatibility emitters, static facts, sidecars, name matching, or selected
  case handling go down;
- x86_64-specific assumptions remain in explicit x86_64/ABI/provider code;
- `frontier_local_fail` stays `0`;
- `boundary_unexpected_accept_rows` stays `0`;
- `boundary_wrong_diagnostic_rows` stays `0`;
- accepted rows use stronger ownership, not broader name matching.

For non-family work, report replacement-matrix movement instead:
mode/target/stage/status before and after, fallback rows removed, boundary rows
clarified, and focused gate health. Non-family work should be rare while the
compiler-core family checklist has actionable unchecked items.

Example cycle result:

```text
Before:
family=error-union try/wrap/unwrap
item=Lower try with payload continuation
checklist_before=unchecked
inventory_bucket_before=237172
frontier_local_fail=0

After:
family=error-union try/wrap/unwrap
item=Lower try with payload continuation
checklist_after=checked
inventory_bucket_after=lower or pending refresh
frontier_local_fail=0
```

That is progress. A cycle that only renames code without improving ownership,
proof, diagnostics, or maintainability is not enough unless it unblocks the
next implementation cycle.

## Documentation Update Policy

Normal implementation cycles should update as few docs as possible.

For a completed checklist item, update only:

1.  `docs/roadmap/x86_64_compiler_core_family_checklist.md`;
2.  generated counter sections via `tools/update_doc_counters.zig`, only when
    counters changed.

Do not update `docs/next_steps.md` unless:

- the active family is blocked;
- the next item needs a hook-contract or architectural decision;
- the worker changes active family;
- the worker stops with a blocker.

Do not update readiness, matrix, frontier, inventory, or build-step docs unless:

- a whole family is completed;
- a replacement claim changes;
- a boundary policy changes;
- a build step or command changes;
- a milestone gate is promoted.

The checklist is the per-cycle progress ledger. Other docs are milestone or
reference documents, not routine cycle logs.

## Validation Policy

Use focused validation by default.

### Minimum Measuring Rules

Do not measure the same state repeatedly. A cycle should run the smallest proof
that can validate the completed checklist item.

Use this order:

1.  Read existing logs first. If a fresh log already proves the unchanged
    counter or inventory state, cite it instead of rerunning the same gate.
2.  Run the narrowest focused row, case, or family gate that exercises the
    touched code.
3.  Run `zig build test` for shared parser/model/lowering/backend changes.
4.  Run full frontier or boundary gates only when accepted rows, boundary rows,
    diagnostics, or documented counters changed.
5.  Run inventory only when choosing a new family, completing a family, or
    proving that a targeted inventory bucket dropped or was reclassified.
6.  Run `distribution-all` only for milestone confirmation, shared build
    orchestration changes, or an explicitly documented reason.

For a normal implementation cycle that does not change documented counters, the
minimum validation is:

```text
zig build test
focused row/case/family gate > tmp/<family>_<item>_<gate>.log 2>&1
git diff --check
```

Use stable, descriptive `tmp/` log names. Do not create new counter logs just
to preserve identical numbers.

### Counter And Inventory Refreshes

Run `tools/update_doc_counters.zig` only when the relevant counter actually
changed or when closing a family/milestone. Do not run counter updaters as a
routine proof of a small local edit.

Run `distribution-air-release-frontier` only when:

- a source-backed accepted frontier row was added or removed;
- `source_rows`, `discovered_functions`, `object_emitted_functions`, or
  executable counts changed;
- a family completion claim depends on the full frontier staying green.

Run `distribution-air-release-frontier-boundaries` only when:

- a boundary row was added or removed;
- fail-closed diagnostics changed;
- a completed item claims unsupported subforms remain correctly rejected.

For aggregate layout/provider work, run
`tools/audit_aggregate_layout_providers.zig` only when provider precedence,
exported facts, sidecars, temporary facts, or boundary providers changed.

For compiler-core inventory refreshes, prefer per-mode runs such as
`zig build distribution-zig-air-inventory --
--slice=compiler-core-module --mode=ReleaseFast`. The all-mode
compiler-core-module refresh is milestone-cost evidence, not a default worker
cycle gate.

Do not rebuild `../ziglang` stage4 unless the Zig hook contract or patched Zig
source changed.

## Cycle Report

After each clean commit, report:

```text
commit=<hash>
family=<active family milestone>
item=<completed checklist item>
goal=<one sentence summary>
architectural_choice=<none or short decision>
validation=<commands/logs>
progress_before=<key counters>
progress_after=<key counters>
target_scope=<x86_64 only, or named cross-target boundary>
remaining_blocker=<one sentence>
next_family=<same family or new family>
next_item=<next unchecked checklist item>
git_status=clean
```

Then immediately start the next cycle unless:

- no clear next goal remains;
- a stop-for-architectural-review condition applies;
- validation exposes an unexpected blocker;
- the worktree cannot be made clean;
- the user interrupts.
