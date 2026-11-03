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

The accepted [integer array-stride checkpoint](evidence/array_stride_acceptance_20261103.json)
at `4f69c581`, with correctness repairs `d1fe039a` and `e2fb5841`, passes
all 17 integration stages on a frozen 2,635-file snapshot. Named i64 indexes now
form runtime addresses for bounded literal integer arrays using allocation
strides, including padding and nesting. Live values receive preservation space;
in-place address operands survive scratch writes, and stores consume their value
before staging a spilled destination pointer. Four functions pass 1,536 local
observations against 768 LLVM references across direct/release routes in three
modes. Six negative controls are rejected. All 1,685 units, focused checks and
60 ABI cases pass; prior populations and the bypass ratchet remain fixed.

The earlier accepted [boolean call-return checkpoint](evidence/boolean_call_acceptance_20261103.json)
at `43fa83d2` passes all 17 integration stages on a frozen 2,630-file snapshot.
Exact i1 direct-call returns now use the typed call action and normalize the low
bit before publication. Four native functions pass 1,536 local observations
against 768 LLVM references through direct/release routes in three modes; three
controls reject missing normalization. All 1,679 unit tests, focused checks and
60 ABI cases pass. The unchanged 100-row selection, five-function execution
cohort, earlier native populations and bypass ratchet remain fixed.

The earlier accepted [global-memory checkpoint](evidence/global_memory_acceptance_20261103.json)
at `db272521`, with disk policy commit `61dfbb3b`, passes both full 17-stage
fresh/cached runs. All 1,403 canonical records match on an unchanged 2,624-file
snapshot. Four global-address functions pass 192 local observations against 96
LLVM references; seven copy/store functions pass 240 against 120 through
direct/release routes in three modes. The 1,675 unit tests, focused checks and
60-case ABI gate pass. Candidate, execution and bypass counts stay fixed.

Symbolic byte addresses now reach bounded ordinary native integer/pointer global
objects, including named unpacked structs, arrays, explicit alignment, local
symbols and pointer fixups in `.rela.data`. Private legalization feeds the existing
transactional memcpy/store consumers. Constant copy lengths, dying ABI operands
and narrow RAX-address stores have permanent native and rollback coverage. TLS,
weak linkage, custom sections, nondefault address spaces, floating/vector
initializers and zero-sized global placement retain explicit boundaries.

The earlier accepted [allocation-padding repair](evidence/allocation_padding_acceptance_20261103.json)
at `d4403016` fixes a native mismatch with LLVM: `{ i24, i8 }` previously
placed the second field at byte 3 instead of 4. Nested structs/arrays and 80-bit
floating allocation padding are covered by a permanent all-mode canary. The
1,662 units, focused ABI/native checks and all 17 integration gates pass on a
verified 2,615-file source snapshot. Candidate, execution and bypass counts stay fixed.

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
identities replay unchanged; 15 offline policy tests pass. That migration left
the production AIR and compiler checkpoint unchanged. No archives are created.
Follow the [current keep-list](evidence/tmp_retention_pins.tsv).

The earlier [disk calibration](evidence/headroom_calibration_20261102.json) is accepted:
an 8 GiB forecast covers the sampled 6.10 GB fresh and 1.60 GB cached decreases.
The original serial admission is inherited by nested row workers, whose reserve
stays enforced and whose transient minimum enters the serial report. Allocated
disk telemetry covers all seven owned roots, including retained exports. The
earlier 49 runner/policy and 39 comparison tests passed. Filesystem noise and sampled,
non-atomic observations remain measurement limits.
The allocation-padding cached run reported a 3.37 GB decrease under the previous
reserve. At the user's direction, headroom policy schema 2 now uses a fixed
32 GiB reserve plus the unchanged 8 GiB working budget: 40 GiB (about 42.95 GB)
free at admission. Runtime reserve checks and stronger caller floors remain.
The new pair reports 5.86 GB fresh and 2.16 GB cached decreases; reported minima
are 44.09 GB and 43.31 GB, above the 34.36 GB reserve. The 51 runner/policy and
41 comparison tests pass. These filesystem observations do not establish a speedup.
The [generation cleanup](evidence/global_memory_cleanup_20261103.json) retires
3.92 GB of superseded AIR after both full runs and replacement hash verification.
Current exports and their paired work selection now use
`global-memory-headroom-20261103`; historical metadata, proofs and source probes
remain, with no archives.

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

The [module dependency selection implementation](evidence/module_selection_focused_20261103.json)
at `9c7985e2` now has focused proof. It reuses the shared GlobalDCE dependency
analysis, follows parsed calls/global references/aliases, and resolves selected
alias chains while preserving local bindings and visibility. The explicit mode
passes 330 local/165 LLVM observations, 30 rejection controls, three matching
CLI/environment checks, all 1,689 units and the focused gates. Legacy selection
remains the default; opaque live references retain all definitions.

Next, complete the full cached 17-stage run before accepting this checkpoint.
Owned idle-cache cleanup removed 1.39 GB of allocation, leaving 41.71 GB at that
measurement, below the fixed 42.95 GB admission requirement. The shared Zig cache
is outside this cleanup scope and had active consumers during the read-only audit.
Current AIR, accepted evidence, performance baselines and 13 source probes remain;
no archives are created.

The unchanged Fibonacci retry now reports its codegen boundary instead of omitting
private helpers and reaching a link failure: `start.expandStackSize` rejects an
aggregate alloca. Coverage is conservative: 35 functions are selected, ten emit
and 25 reject; no object is published and there are zero local executions.
Its first stack types are the 16-byte `{ i64, i64 }` rlimit and a 24-byte padded
result wrapper. A 56-byte array stride and narrower call ABI forms are visible
later in the same function. Narrow opaque reference coverage before adopting
this selection by default, then extend bounded aggregate frame storage through
the existing private legalization and typed address authorities. These are planned
boundaries, not accepted capabilities. Keep the fixed compiler-core population
and bypass ratchet unchanged without a separate migration.

Keep broader optional ABIs and
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
