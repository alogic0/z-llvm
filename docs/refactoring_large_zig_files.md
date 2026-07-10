# Refactoring Large Zig Files

This guide records the repo-local workflow for reducing oversized `.zig` files
without changing behavior. The goal is not a line-count target by itself; the
goal is to make ownership boundaries obvious enough that future codegen,
parser, optimizer, and tool changes can be reviewed and tested locally.

## When To Split

Split a file when one or more of these are true:

- The file owns several phases, such as inspection, planning, lowering,
  emission, and tests.
- A coherent section can be named by responsibility, not by incidental line
  range.
- Callers can keep the same public API through a thin facade.
- The moved code has a focused dependency set.
- Tests can prove the move with `zig build test` or a narrower existing gate.

Do not split only because a generated table, fixture, or row list is large.
Generated files and data-like rows should usually stay where the generator or
consumer expects them unless navigation or ownership is actively painful.

Explicit exclusion: do not refactor
`tools/zigrep_regex/regex/unicode_props_generated.zig` for size. It is a
generated Unicode property table, so ownership belongs to the generator and its
consumer rather than to manual module splitting.

Keep `test/zig/frontier/frontier_sysv_abi.zig` as one source fixture even when
it exceeds the usual size target. The frontier harness compiles it as one
translation unit, its exported cases intentionally share ABI type aliases and
extern declarations, and roadmap evidence refers to it as one corpus. Revisit
this exception only if the frontier harness gains an explicit multi-file
fixture boundary.

## Capability-First Cadence

Large-file refactoring is interlude work while the convergence roadmap has an
active capability chain. Complete and commit a capability slice before taking
a refactor interlude, then apply these limits:

- At most one file split per completed capability slice.
- Split only a file touched by that capability work.
- Do not pause a failing real-row or real-program chain for a repository-wide
  size pass.
- Resume the capability queue immediately after the split is committed green.

The working-cycle goal selector and active worker inbox take precedence over
the size audit. The patterns in this guide still control how an allowed split
is performed.

## Audit Command

Use this command to find the largest Zig files:

```sh
rg --files -g '*.zig' | xargs wc -l | sort -nr | head -n 25
```

Then classify each large file before editing:

- `generated`: generated tables or data; prefer generator fixes over hand
  edits.
- `test-fixture`: broad tests or fixture inventories; split only by test
  ownership.
- `facade-plus-implementation`: good candidate for extraction.
- `mixed-phase`: best candidate; split by phase first.
- `single-algorithm`: consider helper modules only if dependencies are clear.

## Preferred Split Pattern

Use a facade-preserving move:

1.  Identify one coherent responsibility.
2.  Create a sibling module near the current owner.
3.  Move the implementation mechanically.
4.  Export only the types/functions the old file or external callers need.
5.  Leave `pub const` aliases in the old file when callers already depend on
    those names.
6.  Run `zig fmt` on touched Zig files.
7.  Run `zig build test`.
8.  Commit the split separately from behavior changes.

For example, after splitting a selector:

```zig
const planning = @import("generic_cfg/stage2_planning.zig");

pub const StageTwoSummary = planning.StageTwoSummary;
pub const analyzeStageTwoNoSpillEnvelope =
    planning.analyzeStageTwoNoSpillEnvelope;
```

This keeps external imports stable while moving ownership to the new module.

## Good Boundaries

Prefer boundaries that correspond to the program flow:

- `inspection`: cheap preflight diagnostics and unsupported-shape reporting.
- `legacy_lowering`: fixed-template or compatibility dispatch.
- `planning`: liveness, pressure, allocation plans, summaries.
- `types`: shared data types with no behavior-heavy dependencies.
- `helpers`: pure predicates, conversions, and small value utilities.
- `selector` or `lowering`: stateful lowering and machine instruction
  emission.
- `rows`: table-driven rows consumed by one implementation module.
- `tests`: white-box tests may move with private implementation modules when
  they test private methods.

Avoid modules named only by size, such as `part1.zig` or `misc2.zig`.

## Dependency Rules

Keep dependencies pointing inward:

- Facade modules may import implementation modules.
- Implementation modules should import shared types/helpers directly.
- Avoid circular imports by moving shared types before moving behavior.
- If two modules need the same pure helper, move it to a helper module instead
  of duplicating large logic.
- Tiny type predicates can be duplicated only when introducing a shared module
  would create worse coupling.

For Zig module paths, keep new files under the same module root. Do not create
imports that escape the root with paths that build modules cannot see.

## Validation

Minimum validation for a mechanical split:

```sh
zig fmt <touched .zig files>
zig build test
```

Use stronger gates when the split changes a broader surface:

- `zig build structural-smoke` after code-layout or facade boundary changes.
- `zig build handoff` when optimizer-to-codegen handoff behavior might change.
- Relevant distribution gates only when the move touches runtime behavior,
  object emission, ABI lowering, or evidence claims.

Do not use milestone gates such as `distribution-all` as the inner loop for a
mechanical file-size refactor.

## Commit Shape

Keep refactor commits narrow:

- One responsibility per commit.
- No behavior changes mixed with moves.
- No unrelated formatting outside touched files.
- Commit message should name the ownership boundary, for example
  `Split generic CFG stage2 planning`.

If a compile failure appears after the move, fix the import/export issue in the
same commit only when the fix is mechanical. If behavior must change, stop and
make that a separate implementation slice.

## Review Checklist

Before committing, check:

- The old public imports still compile.
- Moved tests still run or equivalent coverage remains.
- New module names describe ownership.
- The old file is simpler, not just shorter.
- The new module does not import the old facade unless that is intentional.
- Generated files and fixtures were not hand-edited.
- `git diff --stat` matches the intended move.

## Current Example

`src/codegen/x86_64/generic_cfg_selector.zig` was reduced by splitting:

- legacy envelope recognition and fixed lowering;
- inspection diagnostics;
- selector shared types;
- stage-two pressure and allocation planning;
- pure composed-selector helpers;
- the composed selector implementation behind a small facade.

That is the preferred style for future large-file reductions: first turn the
oversized file into a stable facade, then continue splitting the implementation
modules only where the next ownership boundary is real.
