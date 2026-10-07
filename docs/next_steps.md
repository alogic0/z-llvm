# Active direction

The [architecture refactor plan](roadmap/architecture_refactor_plan.md) is
complete for its bounded scope: four refactors, the memset shared-lowering
capability, the correctness checkpoint and the
[fixed-program performance baseline](evidence/fixed_program_baseline.md).
The baseline records two runs of five workloads across three explicit routes,
with semantic checks and all three metrics for 14 supported pairs. The loop-memory
`release-o3` pair rejects with `TypeMismatch`; that optimizer limitation is
recorded separately and does not acquire invented performance results.

The [checked memcpy family](evidence/composed_memcpy_family.md) is now complete
for the retained `ssp.__memcpy_chk` and `memcpyFast` definitions. Shared composed
lowering, native comparisons, the ABI differential gate and all 17 integration
subgates pass. The frozen performance matrix retains its supported outcomes and
semantic results; two local memset code sections grow by 11 bytes for the
byte-GEP preservation repair. Timing differences do not establish a speedup.

The subsequent [scalar byte-loop slice](evidence/composed_byte_loops.md) closes
the retained `ssp.__strncpy_chk` definition and moves retained `bcmp`/`memcmp`
to composed lowering. A bounded shared-return proof fixes their verifier
rejection. Native comparisons, protected-page checks, ABI checks and all 17
integration subgates pass. The frozen performance matrix retains all outcomes,
semantic results and object hashes from the memcpy checkpoint.

The [loop-memory repair slice](evidence/loops_memory_repair.md) repairs the
frozen `loops_memory/release-o3` optimizer `TypeMismatch`. SROA scalarizes single-element
aggregates with direct field loads/stores, and `mem2reg` enforces alloca-type
safety. Focused regressions and the behavioral differential suite pass. Semantic
and runtime driver outputs match Clang-22 -O3 byte-for-byte across all 272
observations. The matrix is versioned to `fixed-architecture-programs-v2` with all
15 pairs supported, and repeated measurements are recorded while preserving the
original frozen manifest and baseline evidence.

The [cyclic byte-vector transfer slice](evidence/cyclic_byte_transfers.md) admits
cyclic `<16 x i8>` vector loads and stores in composed x86-64 loops with a verified
loop-carried XMM ownership proof. Invariants enforce block-local vector life cycle,
sequential single-register ownership, absence of loop-carried XMM phi values, and
no external vector escapes. Machine structure, assembly (`movups`), and bit-exact
runtime execution pass across 0, 32, and 64 byte inputs.

## Next: real-rows Zig 0.17.0 migration and deferred capabilities

The compiler-core real-rows denominator migration to tracked Zig 0.17.0 remains
the active integration frontier (closing the remaining 67 unsupported opcodes and
rebuilding the mode-stable denominator). Further string families, broader pass
migrations, opaque parsing and integer families remain deferred until a concrete
consumer or reproduced correctness issue justifies them.

Use the frozen baseline for future measured comparisons; it establishes neither
a speedup nor general optimizer/backend parity. Reuse matching correctness
evidence under [validation tiers](validation_tiers.md) and select new checks from
the actual implementation changes.

## Completed prerequisites and operating rules

The [project improvement plan](roadmap/project_improvement_plan.md) completed its
six phases, including storage replacement/cleanup, exact summary validation,
compiler selection, behavioral coverage and current documentation. Its
[implementation evidence](evidence/project_improvement/implementation.md) includes
the passing fresh/cached 17-subgate pair and matching canonical records.
Those phases are not reopened by the completed architecture baseline.

The [memset family](evidence/composed_memset_family.md),
[integer/allocation repairs](roadmap/optimizer_boundary_repairs.md), and
[correctness checkpoint](roadmap/correctness_checkpoint.md) are complete.
The checkpoint was committed as `eab54c12`: 1,503 unit/structural/storage tests,
focused ReleaseFast tests, native LLVM comparisons, readiness and all 17
integration subgates passed against an unchanged source snapshot. It does not
establish program performance or claim a full ReleaseFast unit-suite pass.

Use Zig 0.17.0, retain the patched emitter and unique source work, and follow the
[current keep-list](evidence/tmp_retention_pins.tsv). Historical worktree and
artifact-authority requirements retired by the improvement plan remain retired.
Every new cache or failure capture needs a current consumer or bounded diagnostic
reason. The [architecture map](architecture.md) describes implemented routes.
Keep [accepted counters](accepted_status.json) unchanged until an explicit,
evidence-backed migration; passing tests or collecting timings never advances
them automatically.
