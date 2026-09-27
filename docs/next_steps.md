# Active direction

The [current architecture](architecture.md) describes implemented routes and
ownership. The [architecture refactor plan](roadmap/architecture_refactor_plan.md)
records the completed operand traversal, ownership, integer-semantics, and
module-reference slices, including GlobalOpt, GlobalDCE, and ADCE migrations.
The ADCE dependency and verifier allocation-cleanup follow-ups are repaired.
The first shared-lowering slice implements the bounded memset family; see
[its validation evidence](evidence/composed_memset_family.md). Accepted counters
remain unchanged.

The user's 2026-09-10 instruction authorizes implementation of the entire
[project improvement plan](roadmap/project_improvement_plan.md), in its stated
priority order. It supersedes the former three-file housekeeping stop,
43-worktree protection, and further artifact-authority decomposition directives.

Finish and validate the store replacement and cleanup, exact summary parser,
compiler selection, behavioral coverage, and current documentation. Track exact
commands, source/input identities, and remaining limitations in the
[implementation evidence](evidence/project_improvement/implementation.md).

Use [validation tiers](validation_tiers.md) to select checks. Keep the accepted
record in [accepted_status.json](accepted_status.json) separate from development
expectations and newly collected evidence. A source change or passing focused
test never advances accepted counters automatically.

Project implementation and new tools use Zig 0.16.0. Keep unique source work and
the patched emitter. The [current keep-list](evidence/tmp_retention_pins.tsv)
replaces historical retention pins. Every new cache or failure capture needs a
current consumer or a bounded diagnostic reason.

The cache retry fix is validated: full fresh and cached Tier-3 runs each passed
17/17 subgates, and their 1,315 canonical records match. Completed logs, focused
regressions and per-subgate timings are in the implementation evidence. The
external checkout was clean for those acceptance runs.

Current checkpoint: shared pointer returns, `i8 zeroext` entry parameters, and
nonvolatile `llvm.memset.p0.i64` emit the three retained functions `__memset`,
`memset`, and `ssp.__memset_chk` through composed lowering. Native differential
checks pass in both direct and release-o3 routes and all three harness modes.
Full integration passes all 17 subgates, closing the Phase-5 named-family item.

The project-review repairs are complete: signed min/max and unsigned folds use
width-aware semantics, and explicit alloca sizes are typed operands preserved
by optimizer use/replacement walks. All 1,496 unit/structural/storage tests,
focused ReleaseFast checks, native comparisons, readiness, and all 17 integration
subgates passed; see [the repair record](roadmap/optimizer_boundary_repairs.md).
Dynamic local stack codegen remains unsupported. Accepted counters are unchanged.

The [correctness checkpoint](roadmap/correctness_checkpoint.md) now passes before
the next memory family: all four review repairs, seven permanent unit regressions,
11 native regression functions, readiness and all 17 integration subgates are
validated against an unchanged source snapshot. Accepted counters remain fixed.

Next: reproduce the next bounded memory family from the same report,
starting with `ssp.__memcpy_chk`. Identify its typed-call and intrinsic blockers
before choosing the implementation scope. `ssp.__strncpy_chk` remains outside
the memset slice and now reports a load-width blocker. Keep accepted counters
unchanged until an explicit evidence-backed migration is recorded.
