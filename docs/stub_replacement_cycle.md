# Stub Replacement Cycle

Use this cycle when implementing
[`roadmap/llvm_shaped_stub_replacement_plan.md`](roadmap/llvm_shaped_stub_replacement_plan.md).
It is based on [`development_cycle.md`](development_cycle.md), but it is
stricter: the goal is to replace placeholders and local-conservative stubs with
LLVM-shaped implementations one planned slice at a time until the replacement
plan is finished.

## Scope

The active source of planned work is:

```text
docs/roadmap/llvm_shaped_stub_replacement_plan.md
```

Work through that file in order:

```text
Slice 1 -> Slice 2 -> ... -> Slice 32
```

Do not skip a slice unless the slice is blocked by missing IR surface that must
be implemented first. If that happens, add the smallest prerequisite sub-slice
to `docs/next_steps.md`, document why it blocks the planned slice, implement
and commit the prerequisite, then return to the blocked slice.

## Cycle Shape

Each slice follows this sequence:

```text
select -> map upstream -> reduce scope -> implement -> compare -> document -> review -> commit -> mark progress
```

Commit/validation continuation policy:

```text
For each slice: update docs/next_steps.md, map upstream LLVM first, implement
the LLVM-shaped behavior, add opt-22 fixtures, run focused comparison and
readiness checks, commit that slice, then immediately continue with the next
unchecked slice. Do not stop between successful slices.
```

## 1. Select The Next Slice

- Read `docs/roadmap/llvm_shaped_stub_replacement_plan.md`.
- Pick the first unchecked slice.
- Copy only that slice into `docs/next_steps.md` as the active checklist.
- Include this header in `docs/next_steps.md`:

```text
Source roadmap: docs/roadmap/llvm_shaped_stub_replacement_plan.md
Active slice: Slice N: <name>
Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior
```

- If the slice is too large for one commit, split it into ordered
      sub-slices under the same active slice. Each sub-slice must still replace
      real behavior, not just add a placeholder.

## 2. Map Upstream LLVM First

Before editing local implementation code, identify the LLVM reference points:

- LLVM source files.
- LLVM pass, class, or helper entry points.
- Core data structures used by LLVM.
- Preconditions LLVM expects before applying the transform.
- How LLVM updates CFG, PHIs, analyses, metadata, or debug info.
- Which behavior is inside this local slice and which behavior remains out
      of scope.

Use the local LLVM checkout at:

```text
../llvm-project-22
```

Prefer exact source references such as:

```text
llvm/lib/Transforms/Scalar/JumpThreading.cpp:<function>
llvm/lib/Analysis/MemorySSA.cpp:<class or method>
```

If the upstream mapping is incomplete, do not implement yet. First narrow the
slice until the mapping is clear.

## 3. Define Accepted Local IR Preconditions

Each slice must state the local IR surface it supports:

- Supported instruction forms.
- Supported terminators and CFG shapes.
- Supported metadata and attribute behavior.
- Supported memory, alias, or DataLayout assumptions.
- Unsupported forms and their diagnostics or preservation behavior.

This section prevents vague "conservative" fixes. A rejected case is acceptable
only when it is outside the selected LLVM-shaped surface and is documented.

## 4. Implement LLVM-Shaped Behavior

Implementation rules:

- Replace the placeholder or conservative path for the selected surface.
- Preserve the LLVM algorithm shape for that surface.
- Reuse or extend existing local analyses instead of bypassing them.
- Update CFG, PHIs, uses, debug records, metadata, and analysis state in
      the same category of places LLVM updates them.
- Keep the diff bounded to the selected slice.

Do not land behavior whose only purpose is to avoid a failing fixture. If the
LLVM algorithm needs infrastructure that does not exist, split out that
infrastructure as the current sub-slice.

## 5. Add Fixtures And Comparison

Each implementation sub-slice needs proof:

- Add one positive fixture that LLVM transforms or preserves in the same
      way.
- Add at least one negative fixture for the boundary if the slice rejects
      unsupported IR.
- Compare with `opt-22` when LLVM accepts the input.
- Mark fixture classification honestly:

```text
opt-equivalent
fixture-equivalent
LLVM-shaped subset
local-conservative
parse-preserve-only
```

`local-conservative` is allowed only for explicit out-of-scope boundaries. It
does not count as replacing the planned stub unless the selected slice's
positive behavior is also implemented.

## 6. Update Documentation

Update the relevant docs before marking the slice complete:

- `docs/passes/<pass>.md` for pass behavior.
- `docs/analysis/<analysis>.md` for analysis behavior.
- `docs/ir_*.md` for new accepted IR syntax or verifier rules.
- `docs/analysis/algorithm_parity_audit.md` if a pass status changes.
- `docs/roadmap/llvm_shaped_stub_replacement_plan.md` to mark the slice
      complete only after tests pass.
- `docs/next_steps.md` to record the active slice completion.

Every updated behavior doc must include:

```text
LLVM source files
LLVM classes/functions used as reference entry points
reproduced behavior
known missing behavior
fixtures or opt commands used for comparison
```

## 7. Run Validation

Use focused validation first:

```bash
zig build
zig build compare-opt -- <fixture-name>
```

Then run the broader gate appropriate for the touched area. For pass-manager,
pipeline, parser, verifier, or shared analysis changes, prefer:

```bash
zig build readiness
```

For Zig-emitted corpus changes, follow the compiler policy in
[`environment.md`](environment.md) and [`development_cycle.md`](development_cycle.md):

- use `zig` on `PATH` for building and testing `z_llvm`;
- use `../ziglang/build/stage4/bin/zig` for authoritative Zig-emitted LLVM IR
  fixtures;
- record Zig version, optimize mode, target triple, command, and emitted IR
  path in the manifest.

## 8. Review Before Commit

Use the review loop from
[`three_agent_bug_discovery_fix_review_scheme.md`](three_agent_bug_discovery_fix_review_scheme.md)
when the slice changes optimizer legality, CFG rewriting, MemorySSA, aliasing,
debug salvage, or backend handoff behavior.

The review must check:

- The fix follows the mapped LLVM entry points.
- The local IR preconditions are explicit.
- Positive and negative fixtures cover the intended surface.
- Docs do not overclaim full LLVM parity.
- No placeholder is marked complete without implemented behavior.

Commit only after positive review for slices that use the review loop.

## 9. Commit Policy

Commit every completed slice or sub-slice separately. Follow
[`commit_policy.md`](commit_policy.md):

- Stage all files for that completed slice.
- Create a temporary commit-message file.
- Include a header and list of changes.
- Use `git commit -F path_to_temp_file`.
- In commit messages and comments, never write full local paths; use paths
      relative to `prog`.

Do not combine unrelated planned slices in one commit.

## 10. Mark Progress And Continue

After a successful commit:

- Mark the slice or sub-slice complete in `docs/next_steps.md`.
- Mark the same slice complete in
      `docs/roadmap/llvm_shaped_stub_replacement_plan.md`.
- If the slice was split, keep the parent slice unchecked until all
      sub-slices are complete.
- Pull the next unchecked slice into `docs/next_steps.md`.
- Repeat the cycle until every slice in
      `docs/roadmap/llvm_shaped_stub_replacement_plan.md` is complete.

## Stop Conditions

Stop only when one of these is true:

- All slices in `docs/roadmap/llvm_shaped_stub_replacement_plan.md` are
      complete and committed.
- The next slice requires missing IR syntax, verifier support, or analysis
      infrastructure. In that case, create and commit the prerequisite slice,
      then resume.
- Upstream LLVM behavior cannot be mapped locally. In that case, document
      the exact missing mapping and do not mark the planned slice complete.

## First Or Resumed Cycle

When starting this workflow for the first time, pull the first unchecked slice
from `docs/roadmap/llvm_shaped_stub_replacement_plan.md`. At the moment that is:

```text
Slice 1: always-inline for direct internal calls
```

When resuming after an interruption:

- If `docs/next_steps.md` already has an active stub-replacement slice, continue
  that slice until it is implemented, reviewed, committed, and marked complete.
- If `docs/next_steps.md` has no active stub-replacement slice, open
  `docs/roadmap/llvm_shaped_stub_replacement_plan.md` and pull the first
  unchecked slice.
- If a slice is partially implemented but not committed, inspect `git status`
  and the relevant docs before changing direction. Continue that partial slice
  unless the changes are clearly unrelated.
- If the last slice was committed but not marked complete, mark it complete in
  `docs/roadmap/llvm_shaped_stub_replacement_plan.md` only after confirming the
  commit contains implementation, fixtures, docs, and validation notes.
- Do not start a later slice while an earlier unchecked slice is still active
  or partially implemented.

## First Slice Bootstrap

Use Slice 1 to validate the workflow itself. While implementing it, verify
that:

- `docs/next_steps.md` contains only the active slice.
- Upstream LLVM mapping is concrete before code changes.
- Fixtures prove both positive behavior and unsupported boundaries.
- Review happens before commit when the slice touches optimizer legality, CFG
  rewriting, MemorySSA, aliasing, debug salvage, or backend handoff behavior.
- The roadmap checkbox is updated only after the commit passes validation.

After Slice 1, do not treat later slices differently. Resume from the first
unchecked roadmap item.
