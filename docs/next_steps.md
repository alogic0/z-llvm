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

## Current checkpoint and next work

The [2026-11-02 acceptance](evidence/current_pin_acceptance_20261102.json)
repairs aggregate/optional snapshots, typed addresses and ABI carriers, and
migrates the frozen compiler-core selection to Zig source pin
`1c08b09d1c847f4f02c8216e3b62df323861a437`. The selected 100 functions lower,
emit objects and link in every release mode. Four source-bound functions
execute against independent reference harnesses per mode. Compilation and
linking counts remain separate from executions.

The [membership audit](evidence/real_candidates_release_v3_migration.json)
records 30 retained and 70 replaced prefix entries. Sixty-three former names
have no runtime AIR at this pin. The former COFF size methods now return
`comptime_int`; two Signature methods replace them while the two Requirements
methods remain. Selection uses frozen static facts across all three modes and
never takes lowering outcomes as ranking input.

Zig's unchanged `hello_libc.zig` runs through the local preopt optimizer and
object emitter in all three release modes. Its manifest checks source bytes and
pinned Git contents. Bounded direct C variadic calls admit one fixed pointer
and no unnamed arguments. The pipeline consumes constant string lengths and
removes newly constant safety branches. The program still depends on libLLVM
IR construction, libc, the system linker and CRT.

The ABI differential keeps its ten functions and passes 60 native cases.
The [FMA identity audit](evidence/current_pin_fma_canary_20261102.json) retains
29 exact-result cases and adds 8,192 mandatory comparisons against LLVM's
compilation of the identical frozen IR. Helper and `__multi3` identities stay
fixed. The acceptance evidence records full fresh/cached results separately
from these bounded populations.

Next, repair export publication so the production runner avoids retaining a
second complete `compiler.air` after its verified cache copy is published.
The fresh validation used a hash-checked cleanup wrapper; its disk observations
do not establish the existing footprint forecast. Keep ownership, cache identity
and failure evidence intact, and measure both fresh and cached behavior.

The [space cleanup](evidence/space_cleanup_20261102.json) retired obsolete
selector-v2 failed-run exports and idle compiler caches while preserving the
accepted exports, frozen selector inputs, logs, measurements and source probes.
This reclaims generated state; production export publication still needs the
repair above.

Then increase execution coverage within the fixed 100-row population, starting
with a finite-input function such as `ascii.isAscii`, checking all 256 byte
inputs in each release mode against an independent oracle. Prefer a subsequent
unchanged upstream program with input-dependent branching or memory effects.
Keep unsupported optional ABIs, wider varargs and runtime boundaries explicit.
Use the frozen performance baseline for measured comparisons and the
[validation policy](validation_tiers.md) for matching evidence reuse.

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
