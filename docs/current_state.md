# Current state

The accepted record is [accepted_status.json](accepted_status.json). The block
below is generated and checked by `zig build check-docs`; regenerate it with
`zig build check-docs -- --write` after an explicitly accepted evidence update.

<!-- accepted-status:start -->

Accepted revision: `3ef5b07c00959b260d6b8ae6a886d9c91f0bfd82`; tree: `c32a050427055a2b67de49fcee657dd33a014716`.

Population: compiler-core candidate prefix (100 rows), selector `real-candidate-selector-v2`.
Modes: ReleaseFast, ReleaseSafe, ReleaseSmall. Source pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`.
Candidate SHA-256: `83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d`.

| Metric | Accepted value per mode | Scope |
| --- | ---: | --- |
| Functions lowered | 100 | Compiler-core prefix |
| Objects emitted | 100 | Compiler-core prefix |
| Native links | 100 | Compiler-core prefix |
| Functions executed | 3 | Fixed execution cohort |
| Paired harnesses accepted | 3 | Legacy real_programs_ok cohort metric |
| Local failures | 0 | Compiler-core gate |

Compiler-rt bypass ratchet: 130 (separate 285-function population).

<!-- accepted-status:end -->

The accepted values above carry forward the declaration in `docs/current_state.md`
at `52e538c5`. The older strict-prefix evidence proves lowering/object/link counts;
it predates the execution cohort. The preserved run manifests contain historical
execution diagnostics. This migration does not claim a new acceptance run or
reinterpret older whole-program counters as cohort counters.

Current development starts at `52e538c5` and includes a four-member execution
cohort. Its expected `4/4` execution counters remain development expectations
until the applicable integration evidence is accepted. The independent behavioral
suite has its own population and does not increase the 100-row compiler-core
counters or the 285-function compiler-rt ABI population.

The [optimizer review repairs](roadmap/optimizer_review_repairs.md), committed as
`629e2ee7`, have newer development validation: 1,439 unit/structural/storage tests,
readiness, and all 17 distribution subgates passed. That run lowered, emitted,
and linked 100 compiler-core functions and executed four cohort members per
release mode. These results have not migrated the accepted record above.
The [architecture map](architecture.md) explains which optimizer and codegen
routes each suite exercises; gate success is not general pass or backend parity.

The artifact authority protocol has been replaced by a small local store. The
fixed worktree inventory, supplemental control repository, historical INBOX
fixtures, and installed-system-binary hashes are retired. Migration and cleanup
are recorded in the [implementation evidence](evidence/project_improvement/implementation.md).

The [correctness checkpoint](roadmap/correctness_checkpoint.md) follows the
latest review at `230a30ef`. Four optimizer repairs and permanent regressions
pass 1,503 unit/structural/storage tests, native LLVM comparisons, readiness and
all 17 integration subgates. The checkpoint before the next memory family is
complete; these development results do not change the accepted record.

The [architecture refactor plan](roadmap/architecture_refactor_plan.md) is complete
for its bounded scope. The [fixed-program baseline](evidence/fixed_program_baseline.md)
records two runs with compile-time, runtime and object/code-section sizes for
14 supported workload/route pairs, plus the explicit loop-memory `release-o3`
optimizer rejection. The subsequent
[checked memcpy family](evidence/composed_memcpy_family.md) supports the retained
`ssp.__memcpy_chk` and `memcpyFast` definitions through shared composed lowering.
Native comparisons, ABI differential checks and all 17 integration subgates pass;
the unchanged performance matrix retains its outcomes and semantic results.
The subsequent [scalar byte-loop slice](evidence/composed_byte_loops.md) closes
retained `ssp.__strncpy_chk` and composes retained `bcmp`/`memcmp`, with a bounded
return-join verification repair. All 17 integration subgates, native and ABI
comparisons pass. The fixed-program matrix retains its supported outcomes,
The subsequent [loop-memory repair slice](evidence/loops_memory_repair.md) repairs
the `release-o3` optimizer `TypeMismatch`, scalarizing single-element aggregates in
SROA, enforcing alloca-type safety in mem2reg, and recording baseline v2 measurements
across all 15 supported pairs. Cyclic byte vectors and broader consumer migrations
remain deferred.
These development results and measurements do not advance accepted counters.

See [next steps](next_steps.md), the [improvement plan](roadmap/project_improvement_plan.md),
and the root [setup instructions](../README.md). Historical milestones remain
under the roadmap and evidence directories; they do not select current work.
