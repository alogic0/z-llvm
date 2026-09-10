# Active direction

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

The external checkout prerequisite is resolved. Remaining completion work:
finish the running fresh validation, complete its cached Tier-3 comparison, and close one
named recurring real-function family through shared lowering. The standalone
behavioral suite passes, but does not fulfill that last real-family requirement.
The recorded failed integration attempt is not acceptance evidence.
