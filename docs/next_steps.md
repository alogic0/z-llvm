# Active direction

The [current architecture](architecture.md) describes implemented routes and
ownership. The [architecture refactor plan](roadmap/architecture_refactor_plan.md)
proposes bounded shared-IR and lowering work; only its documentation correction
is completed. Its implementation steps do not supersede the named capability
objective below or advance accepted counters.

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
external checkout is clean; no validation run remains active.

Next: close one named recurring real-function failure family through shared
lowering. The retained discovery report identifies four pointer-return failures
(`__memset`, `memset`, `ssp.__memset_chk`, `ssp.__strncpy_chk`) as a candidate;
these also require composed memory intrinsic support. Select the bounded family,
reproduce its failures, and add executable and nearby rejection cases before
claiming closure. The passing standalone behavioral suite does not fulfill this
remaining Phase-5 requirement. Keep accepted counters unchanged until an explicit
evidence-backed migration is recorded.
