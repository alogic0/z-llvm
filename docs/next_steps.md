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

The [scalar startup acceptance](evidence/scalar_startup_acceptance_20261103.json)
at `1f92385e` completes exact named i64-to-pointer conversion and signed i32/i64
nonnegative comparisons through the existing value-use authorities. The preceding
[frame-store checkpoint](evidence/scalar_frame_acceptance_20261103.json) remains
accepted. A serial distribution run passes all 17 subgates against a frozen
2,589-file source snapshot. Three authenticated AIR exports are reused; execution
checks run again. The source pin remains
`1c08b09d1c847f4f02c8216e3b62df323861a437`.

The compiler-core selection remains the same 100-row selector-v3 prefix. Every
row lowers, emits an object and links in each release mode; five source-bound
functions execute per mode. The four constant methods remain in the cohort.
`ascii.isAscii` adds all 256 byte inputs per mode, compared with an independent
high-bit oracle and exact ordered output: 768 paired observations. Six native
constant-result negative controls reject. These input observations do not turn
100 links into 100 executions.

Production AIR publication writes schema-4 metadata atomically and transfers
ownership of the verified payload. Same-filesystem publication renames the
original file; cross-filesystem publication removes raw only after commit.
Readers support schemas 3 and 4, including the parent's cache-pin verifier.
The earlier fresh/cache proof identifies the same inode as raw and cached in all
three modes, with one complete payload per mode and no manual cleanup wrapper.
Rollback, legacy migration, reuse and actual cross-filesystem tests pass.

The unchanged upstream `hello_libc.zig` still executes in all three release
modes. Zig's unchanged [C compiler fixture](evidence/upstream_c_program_20261102.json)
adds an input-dependent branch, heap stores/loads and stdio. Its two argument
paths pass against LLVM in each local release pipeline: six paired case
executions. A separate native canary adds 48 integer-varargs and 18 heap-call
observations, checking AL, pointer identities, argument permutations, live
values and integer boundaries. C assertions stay enabled and C sanitizers are
disabled; these mode labels do not establish Zig safety behavior. Pinned
Zig/Clang IR construction, libc, the system linker and CRT remain dependencies.

The ABI cohort retains ten functions and passes 60 cases plus its negative
controls. The frozen FMA canary still passes its 29 exact-result cases and
8,192 LLVM-paired observations with unchanged identities. The scalar checkpoint
checks passed 1,649 compiler unit tests, 11 structural tests and seven Python
policy tests. Standalone, compiler-core and compiler-rt populations remain
separate; the compiler-rt bypass ratchet remains 130.

The [current cleanup](evidence/scalar_startup_cleanup_20261103.json) retires idle
owned caches, superseded non-performance executables and resolved exploratory
hello captures. A redundant 2,465-file source copy exactly matches Git commit
`56e66794` and is removed with its reconstruction proof retained. The preceding
[frame-store cleanup](evidence/scalar_frame_cleanup_20261103.json) preserves all
228 paths and hashes of deduplicated immutable evidence. Current exports, frozen
inputs, performance baselines and 13 original source probes remain. The subsequent
[audit input migration](evidence/candidate_facts_retention_20261103.json) retains
74 MB of verified semantic facts and retires the old raw descriptors, reducing
input allocation by 3.85 GB. All 21,117 rows, selected mode facts and rejection
identities replay unchanged; 15 offline policy tests pass. Current production
AIR and the compiler checkpoint remain unchanged. No archives are created.
Follow the [current keep-list](evidence/tmp_retention_pins.tsv).

The earlier [disk calibration](evidence/headroom_calibration_20261102.json) is accepted:
an 8 GiB forecast covers the sampled 6.10 GB fresh and 1.60 GB cached decreases.
The original serial admission is inherited by nested row workers, whose reserve
stays enforced and whose transient minimum enters the serial report. Allocated
disk telemetry covers all seven owned roots, including retained exports. The
49 runner/policy and 39 comparison tests pass. Filesystem noise and sampled,
non-atomic observations remain measurement limits.
The current cached run reports a 2.32 GB decrease with the same reserve and
forecast; AIR publication and runner infrastructure are unchanged.

The [bounded memory slice](evidence/startup_word_pair_memory_20261102.json)
reuses existing 128-bit frame storage for an exact 16-byte pointer/length object
and transparent wrappers. Constructor stores, field extraction and bounded memcpy
pass 384 local observations through direct/release routes in three modes, against
192 LLVM-reference observations reused across routes. This does not establish
general aggregate memory or ABI support.

Runtime pointer values from registers, spills and returned RAX now store through
the existing authority into typed 64-bit frame slots, with 768 local observations
against 384 references. Scalar frame stores, eight full-width constants through
frame and ordinary-pointer destinations, and literal null add 486 local
observations against 243 references. References are reused across direct/release
routes in all three modes. The C fixture's six paired cases/66 call observations,
the existing word-pair canary and accepted compiler counters stay separate.

The new cast and comparison canaries each contribute 1,536 local observations
against 768 LLVM references across direct/release routes in three modes, with
references reused across routes. They check full-width bit preservation, signed
extrema, live values, spills, returned values and output guards. Other cast widths,
immediate sources, cast flags, pointer targets and unproved compare forms retain
explicit boundaries; frozen residual fingerprints and the bypass ratchet stay
unchanged.

Next, extend symbolic global-address memory support. Unchanged
`test/cases/recursive_fibonacci.zig` passes the new scalar operations and stops
in `start.main` at `unsupported_value:composed-block-memcpy-dst`, on a 16-byte
copy to `getelementptr i8, ptr @Io.Threaded.global_single_threaded_instance, 888`.
Its reference executes once and local execution remains zero. Establish address
formation, actual global initializer bytes/layout and relocations together;
accepting an address without emitting its defined storage is insufficient.
Prove stack/global and global/global copies against LLVM, including guarded
2-, 12-, 16- and 80-byte lengths, live values and rejection boundaries, then retry
the unchanged program. Keep TLS and nondefault address spaces explicit. Further
startup boundaries may follow. Keep broader optional ABIs and
floating/indirect/aggregate/stack varargs as explicit boundaries. Use the frozen
performance baseline for measured comparisons and the
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
