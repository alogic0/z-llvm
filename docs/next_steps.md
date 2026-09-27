# Active direction

The [architecture refactor plan](roadmap/architecture_refactor_plan.md) is
partially complete: its four bounded refactors, the memset shared-lowering
capability, and the subsequent correctness checkpoint are done. The remaining
required deliverable is section 5's fixed-program performance baseline.
The plan's current completion table separates that work from deferred migrations
and historical validation records.

## Next: establish the fixed-program baseline

Freeze a small set of existing behavioral/memset workloads and document the
measurement protocol before collecting results. Measure compile time, native
runtime and object/code-section size for explicit direct-local, local
`release-o3`-plus-codegen and independent LLVM routes. Pin compiler/source/input
identities, target, modes, cache conditions, warmups and repetitions. Check
semantic agreement and composed ownership for supported local routes, and record
unsupported pairs explicitly. The [plan's baseline exit criteria](roadmap/architecture_refactor_plan.md#remaining-deliverable-fixed-program-performance-baseline)
define the completion evidence.

Full-gate timings and the historical calls-performance population do not satisfy
this program baseline. Reuse matching correctness evidence under
[validation tiers](validation_tiers.md); select new checks from the actual
implementation changes. Do not rerun full integration for this documentation
reconciliation.

## After the baseline

Record the baseline and close the remaining architecture-plan deliverable, then
reproduce the next bounded memory family from the retained compiler-rt report,
starting with `ssp.__memcpy_chk`. Identify its typed-call and intrinsic blockers
before selecting an implementation slice. `ssp.__strncpy_chk` remains outside
the memset slice and reports a load-width blocker. Broader pass migrations,
opaque parsing and integer families remain deferred until a concrete consumer
or reproduced correctness issue justifies them.

## Completed prerequisites and operating rules

The [project improvement plan](roadmap/project_improvement_plan.md) completed its
six phases, including storage replacement/cleanup, exact summary validation,
compiler selection, behavioral coverage and current documentation. Its
[implementation evidence](evidence/project_improvement/implementation.md) includes
the passing fresh/cached 17-subgate pair and matching canonical records.
Those phases are not reopened by the remaining architecture baseline.

The [memset family](evidence/composed_memset_family.md),
[integer/allocation repairs](roadmap/optimizer_boundary_repairs.md), and
[correctness checkpoint](roadmap/correctness_checkpoint.md) are complete.
The checkpoint was committed as `eab54c12`: 1,503 unit/structural/storage tests,
focused ReleaseFast tests, native LLVM comparisons, readiness and all 17
integration subgates passed against an unchanged source snapshot. It does not
establish program performance or claim a full ReleaseFast unit-suite pass.

Use Zig 0.16.0, retain the patched emitter and unique source work, and follow the
[current keep-list](evidence/tmp_retention_pins.tsv). Historical worktree and
artifact-authority requirements retired by the improvement plan remain retired.
Every new cache or failure capture needs a current consumer or bounded diagnostic
reason. The [architecture map](architecture.md) describes implemented routes.
Keep [accepted counters](accepted_status.json) unchanged until an explicit,
evidence-backed migration; passing tests or collecting timings never advances
them automatically.
