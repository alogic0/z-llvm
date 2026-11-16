# Next steps

The [compiler-object, behavior and self-rebuild plan](plans/2026-11-11-complete-compiler-object-and-self-rebuild.md)
is complete through milestone 8 at backend source `dbf7ade0`. The
[final acceptance](evidence/compiler_behavior_follow_up_acceptance_20261113.json)
records both final compiler generations matching all 2,097 named reference
outcomes in Debug, ReleaseSafe, ReleaseFast and ReleaseSmall through normal LLVM
and local-hook routes. These are 16 complete results and 33,552 exact outcome
comparisons, including reference skips. All 20 delivered local objects pass
independent census, ELF and full ordered-event audits. Normal-resource
self-rebuild passes with fresh backend execution and reuse disabled.

The [cumulative checkpoint](evidence/compiler_behavior_complete_checkpoint_20261113.json)
also closes the original 7,874-definition Debug input and retains complete
8,928-definition compiler, 455-definition runtime and separate 503-definition
Small-runtime objects. Both 225-population native suites, all 17 integration
gates and all 6,724 required faults pass. See [current state](current_state.md)
for the resource settings, unit checks and acceptance limits.

The [throughput follow-up](plans/2026-11-14-compiler-throughput.md) is complete at
`7e7a1063`. It implements
infallible address-owner removal without redundant whole-domain copies. Its
[measurements](evidence/compiler_throughput_20261114.md) reduce median backend
emission for the fixed Debug input from 114.39 to 109.66 seconds (4.1%), with
identical object and owner bytes. Both complete native suites, all 17 integration
gates, all 6,724 required faults and final source verification pass; the
[acceptance record](evidence/compiler_throughput_20261114.json) binds the proof.

The [ReleaseSafe preopt milestone](plans/2026-11-14-release-safe-preopt-behavior.md)
is complete at backend source `ae9d359f`. One unchanged local run matches all
2,097 ordered reference outcomes, with complete 921-definition runtime and
7,716-definition test objects, reconciled inventory and independent audits.
The optimizer failure control stops before emission. All 17 integration gates,
both native preservation proofs, fixed-input qualifications and four-mode
postopt preservation pass. The
[acceptance](evidence/release_safe_preopt_acceptance_20261116.md) records the
source bridge, exact qualified artifact changes and final storage disposition.
Original failed or canceled aggregates remain unchanged; actual completed
subcommand reuse is explicit. LLVM construction, setup and declared providers
remain dependencies.

The current action, authorized by the user on 2026-11-16, is to implement the
[compiler generalization plan](plans/2026-11-16-generalize-compiler-mechanisms.md)
after committing Safe acceptance. Follow its five ordered stages: shared use
queries and atomic rewrite admission; typed constant-table descriptions and a
bounded extension; one structural fixture-handler migration; compact value-use
identities; and selective legalization only if measured benefit justifies it.
The three proposed follow-up abstractions are outside this implementation.
Use separate stage evidence and managed workspaces. The qualified Fast/Debug
Safe binaries remain temporary comparison baselines until their final stage-1
consumer closes; preserve historical model/guard transitions and other holds.

Further work starts from the accepted baseline:

1. Preserve the fixed inputs, generation identities, capture reports and sealed
   evidence. Keep the original five-milestone acceptance and fixed compiler-core
   cohort as separate records.
2. Keep LLVM dependency removal bounded by the ReleaseSafe preopt plan's explicit
   stage captures, independently inventoried inputs, negative control and
   single-mode acceptance. Debug, other release modes, complete compiler preopt
   builds and provider removal remain separate milestones.
3. For further compiler performance work, use the
   [profiling guide](compiler_profiling.md) and
   [validation performance results](evidence/validation_performance.md).
   Measure a specific workload before selecting another optimization or caching
   change, and keep compiler throughput separate from generated-code performance.
   The [architecture](architecture.md) describes the remaining LLVM boundary.

Apply the [validation tiers](validation_tiers.md) to future changes and use the
maintained [Zig validation tools](validation_tools.md), `jqz` and
`zigrep --no-config` for the workflow. No behavior repair or final-generation
matrix remains open in the completed plan.

Every new cycle follows the [development storage contract](development_storage.md):
declare temporary products and retained consumers before execution, use managed
launchers for scripts and tools, and close temporary pipelines with a recorded
storage disposition. The active successor includes this requirement.

## Previous checkpoints

The entries below preserve earlier results and the work proposed at each
checkpoint. Their open-task instructions describe those historical states;
the final acceptance above supersedes them.

Follow-up milestones 6–8 originally required the full pinned upstream Zig
behavior suite with both compiler generations and the reference in all four
modes, audited local postopt objects, repairs for observed failures, and
self-rebuild under normal stack and CPU settings. Successor evidence was
collected separately from the accepted five-milestone baseline below.

The [normal-resource checkpoint](evidence/compiler_behavior_normal_resources_checkpoint_20261112.json)
records a successful unchanged build and self-rebuild at `ba05fef4`, with a
fresh backend execution for generation two. Both newly linked generations are
byte-identical and each matches all 2,097 reference outcomes in all four normal
LLVM modes and passes the nine f80 checks. No CPU or stack override is used.
Both 121-population native suites, all 17 integration gates and all 1,092
required faults pass against the frozen source.

The [scalar-liveness checkpoint](evidence/compiler_behavior_scalar_liveness_checkpoint_20261112.json)
repairs that unsigned multiword remainder error at `9cb21139`. All 17 gates,
both 122-population native suites, strict preservation comparisons, 1,162
required faults and fresh complete original compiler/runtime objects pass.
Both corrected unit builds pass 2,204 tests; the test-only source bridge is
explicit and does not authorize automatic object reuse.

The [eight-family checkpoint](evidence/compiler_behavior_eight_families_checkpoint_20261112.json)
accepts `ca38e3ee`: all 17 gates, both 152-population native suites, strict
preservation and all 2,782 required faults pass. Fresh original compiler and
fixed runtime objects match the preceding checkpoint byte for byte. Debug
behavior selection gains 99 definitions without loss but still rejects 236;
that replay remains failed. The separate Small-runtime input emits all 503
definitions and does not replace the fixed 455-definition corpus.

The [expansion checkpoint](evidence/compiler_behavior_expansion_checkpoint_20261112.json)
validates fifteen further populations at `c1c0ecee`: both 2,271-unit builds,
eight readiness procedures, all 17 gates, both complete 167-population suites
and all 3,592 required faults pass. Strict comparisons preserve all prior
outcomes and owner/optimizer artifacts; individual full-module and execution
proofs review the changed native, compiler and runtime objects. The original
Debug input selects 7,733/7,874, with 141 failures and no complete object.

The [argument checkpoint](evidence/compiler_behavior_arguments_checkpoint_20261112.json)
accepts the six saturation, absolute-value, sign-extension preservation,
vector-input and mixed-stack-call repairs at `c3b77e61`. Both official
2,281-unit builds, all 17 gates, both 173-population native suites and all 3,916
required faults pass. The complete original compiler object is unchanged;
changed runtime conversions have exact encoding and independent LLVM/C proofs.
The original Debug replay gains 34 without loss but retains 107 failures.

The [scalar/vector checkpoint](evidence/compiler_behavior_scalar_vector_checkpoint_20261112.json)
accepts those four repairs at `c3e5547d`. Both official 2,286-unit builds,
eight readiness procedures, all 17 gates, both 177-population suites and all
4,132 faults pass. All 6,332 prior outcomes per build match. The 54 changed
object copies, changed compiler function and runtime helper are fully reviewed.
The original Debug input gains 19 without loss but still rejects 88 definitions.

The six-family FP-input, FP-mask, FP-extrema, integer-product, boolean-call and
bounded-assembly batch is adopted for fresh cumulative validation. Both
2,294-unit builds and all twelve combined native runs pass, with all 324
component faults detected; 37 original selections are gained without loss,
leaving 51 failures. The maintained Zig generator reproduces all 64 files
exactly. Next, freeze and validate the 183-population corpus, including all 4,456
required faults and fresh original objects, then continue closing Debug failures.
Build the final generations and complete both four-mode local-hook
matrices and the normal-resource rebuild after the repairs are accepted.
The existing resource and scalar checkpoints retain their separate scopes.
The entries below retain the preceding checkpoint history.

The [floating PHI checkpoint](evidence/compiler_behavior_progress.md) accepts
`84f1ad7c`: all 17 integration gates, both 116-population native suites and all
822 fault controls pass. The full reference behavior matrix passes; both old
compiler generations expose the repaired exp failure. Fresh compiler rebuilds,
the remaining local-hook behavior boundaries and normal-resource self-rebuild
are still open. Frame-allocation research remains isolated until existing tests
and independent execution proofs pass.

The [vector checkpoint](evidence/compiler_behavior_vector_checkpoint_20261111.json)
accepts `a328d225`: quoted global references, floating vector data and packed x87
lanes. Both 117-population native suites, all 17 integration gates and all 876
fault controls pass, preserving every prior outcome and artifact. The local-hook
Debug suite now reaches variadic parsing. The
[frame checkpoint](evidence/compiler_behavior_frame_checkpoint_20261111.json)
accepts trailing-gap compaction at `46c07b2d`: all 17 gates, both 118-population
native suites, 930 required faults and fresh complete original compiler/runtime
objects pass. The newly built first generation matches the full reference suite
in all four normal LLVM modes and passes f80 layout checks. Normal-resource
self-rebuild still fails in Sema's stack-probing prologue. Close that resource
failure and the remaining full-suite local-hook integer, variadic, atomic,
assembly and ReleaseSmall boundaries before producing and accepting both final
compiler generations.

The active resource repair adopts explicit whole-object lifetime reuse and
removes unused interior spill chunks for immediate cumulative validation. Its
isolated 2,194-unit run and three-mode native regression pass, including branches,
loops and full 8 KiB objects on a 64 KiB worker stack. The previous backend
fails that regression with SIGSEGV. Complete the frozen Tier-3 run and fresh
original compiler/runtime replays, then retry the unchanged normal-resource
build and self-rebuild; the measured 479,000-byte Sema frame alone is no acceptance.

The [compiler object, runtime and self-rebuild plan](plans/2026-11-11-complete-compiler-object-and-self-rebuild.md)
is complete at accepted code `b738377e`, with backend implementation `e398030f`.
Complete census, independent production and balanced event audits establish
local objects for **8,928/8,928 original compiler definitions** and **455/455
original runtime definitions**, preserving prior selections and owners. The
unchanged pinned compiler builds, starts, passes behavior checks and rebuilds
itself through the local postopt hook. Both distinct executables also pass the
f80 layout regression. See the [completion evidence](evidence/compiler_object_self_rebuild.md),
[acceptance record](evidence/compiler_object_self_rebuild_acceptance_20261111.json)
and [runtime contracts](codegen/runtime_completion.md).

Debug/ReleaseSafe each pass 2,182 unit, 63 structural and two profile checks.
Readiness, all seventeen integration gates and both 115-population native suites
pass; all 768 cumulative fault controls are detected. Prior command outcomes,
optimized IR and owner manifests match; every changed object has an individual
review. The fixed prefix/cohort, ratchet 130, accepted-status file and frozen
interfaces remain unchanged.

This closes the original object, link, startup, behavior and self-rebuild stages.
The tested self-build uses CPU 0 and a 1 GiB main stack, with the existing
8 MiB generated-frame and 64 KiB stack-object guards. LLVM optimization and
declared providers remain in use. Further work can reduce the frontend's stack
requirements and extend behavior coverage under the active follow-up. Controlled
performance measurements and further LLVM removal remain later scopes.
Keep the accepted inputs, binaries, captures and sealed evidence as the baseline.

The following checkpoints record the earlier acceptance history.

Batch 08's [SSA/storage slice](evidence/ssa_transport_storage_slice.md) and
selector snapshot-storage changes pass all 17 serial gates, all 79 native
populations with Debug and ReleaseFast compilers, and 2,066 units plus 24
structural/two profile checks in both Debug and ReleaseSafe. Complete original
census and production replays agree on 8,722 selections, adding 58 with no lost
successes or owners. The [acceptance record](evidence/compiler_selection_batch08_acceptance_20261110.json)
retains the complete event audits and source binding. The
[Zig helper migration](evidence/batch08_zig_helpers.md) replaces all seven ad hoc
Python scripts and inline Python workflow. The replay bottleneck is cleared;
capability work has resumed.

Batch 09's shared integer locations preserve the source-width distinction
between split i65–i127 words and aligned whole i128 pairs. Complete original
census and independent production agree on seventeen compiler and eleven runtime
additions with no lost successes or owners. Debug/ReleaseSafe pass 2,076 units,
24 structural and two profile checks each; readiness, all 80 native populations
and all seventeen serial gates pass. Both native build modes preserve the prior
2,945 outcomes and 1,206 compiler artifacts. The
[acceptance record](evidence/integer_physical_abi_acceptance_20261110.json)
binds the 3,173 validated file hashes and both compiler receipts to the committed
tree. The frozen core harness requires the main checkout for its final replay;
the validated source is adopted there. Continue this main plan without waiting
for renewed authorization.

Batch 10's private binary128 carrier preserves raw payloads and uses standard
numerical helpers and all sixteen comparisons. Its complete census and independent
production agree on fifteen compiler and twenty-two runtime additions without
lost successes or owners. Debug/ReleaseSafe each pass 2,086 units, 24 structural
and two profile checks; all nine readiness procedures and seventeen serial gates
pass. Both 81-population native suites preserve every preceding entry, all 2,981
outcomes and 1,221 compiler artifacts per build. The
[acceptance record](evidence/binary128_payloads_acceptance_20261110.json)
binds all 3,186 frozen file hashes and final compiler receipts to the committed
tree. The main plan continues with shared stack-object address materialization;
the fixed prefix/cohort, ratchet and original inputs remain unchanged.

Batch 11's shared owned-object addresses fix pointer-PHI swaps and simultaneous
copy-source preservation. Complete census and independent production agree on
23 compiler additions without lost successes or owners; runtime retains 318.
Debug/ReleaseSafe each pass 2,095 units, 24 structural and two profile checks;
all nine readiness procedures and seventeen serial gates pass. Both complete
82-population native suites preserve the preceding 81 entries and 3,017 command
outcomes. The eighteen intentional object differences in three populations retain
their strict requires-review results and explicit LLVM/native review. All 180
new fault controls are detected. The
[acceptance record](evidence/stack_object_addresses_acceptance_20261110.json)
binds 3,195 source hashes and both final compiler receipts to the code commit.
The final Debug native replay matches all 3,053 same-source outcomes and 1,251
artifacts; its older inspection discrepancy remains explicit. The following
checkpoint resolves the independent frame-address regression and symbolic
integer operand boundaries.

Batch 12's independent object eligibility and symbolic integer operands add
fifteen compiler selections without lost successes or owner changes. Complete
census and independent production agree on 8,792 compiler and 318 runtime
selections; all 4,364,586 compiler events balance. Debug/ReleaseSafe each pass
2,097 units, 24 structural and two profile checks; all nine readiness procedures
and seventeen serial integration gates pass. Both complete 84-population native
suites preserve the preceding 82 entries, 3,053 command outcomes and 1,251
compiler artifacts byte for byte. All 126 new fault controls are detected. The
[acceptance record](evidence/address_value_operands_acceptance_20261110.json)
binds 3,205 source hashes and unchanged executed binaries to the code commit.
Continue through the measured constant-left scalar shifts, scratch-pair shift
and narrow or nullable call-return attributes, then every remaining original
compiler rejection. The all-8,928 plan remains active without renewed approval.

Batch 13's word/pair shifts and narrow or nullable call attributes add fifteen
compiler selections without lost successes or owner changes. Complete census
and independent production agree on 8,807 compiler and 318 runtime selections;
all 4,366,614 compiler events balance. Debug/ReleaseSafe each pass 2,106 units,
25 structural and two profile checks; all nine readiness procedures and
seventeen integration gates pass. Both complete 86-population native suites
retain all prior entries and 3,125 outcomes. Twelve intentional native object
differences and nine core object differences retain strict failures and explicit
reviews. All 162 fault controls are detected. The
[acceptance record](evidence/shift_and_call_operands_acceptance_20261110.json)
binds 3,218 frozen source hashes and unchanged executed binaries to the code
commit. The isolated successor has passing native and unit diagnostics for
full-width integer division, typed i52 truncations and two-word record freezes;
complete unchanged-input proofs must accept its cumulative total. Continue
through every remaining original compiler rejection without renewed approval.

## Completed bounded compiler-throughput delivery

The [allocation-planning throughput slice](evidence/compiler_throughput.md)
replaces repeated interval/site scans with range queries and skips dependency
traversal for empty graphs. On two captured large private plans, median planning
time falls from about 10.98 seconds to 0.45–0.46 seconds with exact plan output.
All 17 integration gates pass. Complete Debug and ReleaseFast native suites
retain all 76 populations and match every baseline command outcome and all
1,161 successful compiler artifacts per build mode. Debug/ReleaseSafe each pass
2,046 units, 24 structural checks and two profiling/interruption checks.

At that earlier checkpoint, bounded sampling identified ordinary interval
lookups and binding scans, and the original function still timed out. That slice
alone accepted no whole-compiler census, object or production replay. The later
batch-08 checkpoint above completes the selection replays.

## Preceding validation performance delivery

The [validation performance plan](plans/2026-11-09-validation-performance-improvement.md)
is implemented with explicit nested toolchain selection, compiler build receipts,
compiled harness reuse and incremental command-report serialization. All 17
integration gates pass, and fresh/cached real-row results match in all three
modes. Complete Debug native coverage and Debug/ReleaseSafe unit, structural,
policy and profiling checks are retained. See the
[measured outcomes](evidence/validation_performance.md) and
[tool usage](validation_tools.md#selecting-and-retaining-validation-compilers).

That delivery is committed at `c19bdc66`. The remaining duplicate native calls
cost 20.09 seconds with ReleaseFast, so a new native result cache is deferred.
Bounded scheduling measurements support keeping existing concurrency. Its
allocation-plan recommendation is completed by the throughput slice above.

## Preceding integer intrinsic slice

The earlier request to finish the integer intrinsic slice and stop was honored
at `f955509f`. The main plan is now resumed as described above.

The [slice evidence](evidence/integer_intrinsic_slice.md) records all 17 serial
gates and 76 native populations passing, with 2,200,836 local observations against
1,100,418 references. The new 43-function population passes with frozen Debug
and ReleaseFast compilers; eight deliberately faulty variants are detected by
both LLVM and local execution. The full source and artifact checks verify.

The preceding accepted [scalable CFG checkpoint](evidence/scalable_cfg_indirect_phi.md)
at `bb74a371` selected **8,664/8,928** compiler definitions and **285/455** runtime
definitions. Its [accepted record](evidence/scalable_cfg_indirect_phi_acceptance_20261109.json)
remains historical evidence. Batch 08 supplies the new whole-input proof above;
the fixed-population `accepted_status.json` remains unchanged.

The preceding frame source at `726a7c55` passed all 17 integration gates and
75 native populations. Its incomplete whole-input attempts were explicitly
superseded. Its frame and spill implementation is included in the current source;
its earlier full execution evidence remains separate from complete-input acceptance.

Resumed work follows measured aggregate PHIs and
freezes, pointer flows, atomic stack views, and wide/FP ABI limits. A complete
unchanged-input census and production replay remain final cumulative acceptance
checks. Selection does not establish complete objects, startup or self-rebuild.

Preserve the 100-row prefix, twelve-function core cohort, ratchet 130, every
execution population, original inputs, prior evidence, authenticated AIR payloads
and thirteen scratch files. Admission remains 20 GB, with an 8 GiB working
allowance and 11.41 GB reserve. Create no archives. See the
[headroom policy](retention_headroom_policy.md#headroom).

For performance diagnosis during this work, follow
[compiler profiling](compiler_profiling.md). Hardware sampling and caller stacks
now work on R780M with user-space events and frame-pointer recording. Run the
preflight before reporting sampling unavailable, and profile the current compiler
when attributing current bottlenecks.

## Preceding checkpoints

The [integer vector graph checkpoint](evidence/integer_vector_graphs.md)
at `d06659d1` selected 8,422 compiler and 285 runtime definitions, with all 17
gates and 69 native populations passing. Its runtime storage, integer memory
and undefined-select recommendations are advanced by the current checkpoint.

The [call values and pointer-promises checkpoint](evidence/call_values_pointer_promises.md)
at `636816de` selected 8,170 compiler and 285 runtime definitions, with all 17
gates and 67 native populations passing. Its vector recommendations are
advanced by the checkpoint above.

The [comparison and pointer-freeze checkpoint](evidence/scalar_comparisons_pointer_freeze.md)
at `9ba5e61c` selected 7,943 compiler and 285 runtime definitions, with all 17
gates and 66 native populations passing. Its private-call and pointer-promise
recommendations are completed by the checkpoint above.

The [narrow-freeze checkpoint](evidence/narrow_freeze.md) at `7080d454`
selected 7,799 compiler and 284 runtime definitions. All 17 gates and 64 native
populations passed. Its pointer-freeze and comparison residuals are advanced
by the accepted checkpoint above.

The [checked-multiply checkpoint](evidence/checked_multiply_operands.md) at
`29e034a7` selected 7,713 compiler and 284 runtime definitions, with 17 gates
and 63 native populations passing. All 59 unsigned multiply operand failures
advanced, adding 56 selections. Its narrow-freeze recommendation is completed
by the current checkpoint above.

The [quoted-symbol checkpoint](evidence/quoted_symbol_addresses.md) at
`a9e9c0f1` selected 7,657 compiler and 284 runtime definitions, with fresh and
cached full runs passing 17 gates and 62 native populations. It closed the
225 quoted-table first failures with 216 additions. Its checked-multiply
recommendation is completed by the current checkpoint above.

The [symbolic integer call-address checkpoint](evidence/symbolic_call_addresses.md)
at `b43dd3dc` selected 7,441 compiler and 284 runtime definitions, with all 17
gates and 61 native populations passing. Its quoted-table recommendation is
completed by the current accepted slice.

The [syscall and comparison checkpoint](evidence/syscall_selection_reduction.md)
at `111f2e0a` selects 7,116 compiler and 284 runtime definitions, with all 17 gates
and 60 native populations passing. It establishes typed syscall facts/tail hints
and full-width transfers for named `samesign ult i64` comparisons. Its symbolic
call-address recommendation is completed by the accepted checkpoint above.

The [global TLS, scalar intrinsic and pressure checkpoint](evidence/global_intrinsics_pressure.md)
at `4b8eac2a` selects 7,040 compiler and 284 runtime definitions, with all 17 gates
and 58 native populations passing. It establishes shared general-dynamic TLS,
scalar bit-intrinsic widths/facts and dynamic allocation/frame admission. Its
syscall and comparison recommendations are implemented by the current frozen
accepted slice above.

The [constant-address, intrinsic-fact and wide ABI checkpoint](evidence/address_intrinsic_wide_abi.md)
at `761ea199` selects 6,752 of 8,928 compiler definitions and 274 of 455 runtime
definitions. All 17 integration gates and 53 native populations pass. Its
global-property, intrinsic and pressure recommendations are implemented by the
accepted `4b8eac2a` checkpoint above.

The [census classification and integer ABI checkpoint](evidence/census_integer_abi.md)
at `baf7a767` selected 4,341 of 8,928 compiler definitions and 274 of 455 runtime
definitions. All 17 integration gates and 50 native populations passed. Its
constant-pointer, advisory-intrinsic and wider-carrier recommendations are now
completed by `761ea199`.

The [compiler parser and runtime cast plan](plans/2026-11-07-compiler-parser-vector-casts.md)
is complete at `57a78095`. All 8,928 compiler definitions and the full unchanged
compiler module parse; all 455 runtime definitions verify. All 17 integration
gates and 47 native populations pass. See the
[evidence](evidence/compiler_parser_vector_casts.md) and
[acceptance record](evidence/compiler_parser_vector_casts_acceptance_20261107.json).

At that checkpoint, the next slice was allocation-related parameter attributes.
Verification first rejected `allocptr` on `free`'s declaration at input line 737421. The
LLVM-valid `local-state/validations/parser-vector-20261107/next-allocptr.ll`
reproducer led to the accepted [allocation/runtime-memory repair](evidence/allocation_runtime_memory.md).
Vector GEP result semantics were a separate gap after their syntax repair.

That earlier runtime census examined all 455 definitions: 265 succeeded and 190 rejected,
with complete diagnostics and capability grouping retained under
`local-state/validations/parser-vector-20261107/`. Its first failure was memset
attributes; `sincos_f32` then rejected ordinary scalar FP pointer loads. Those
repairs were subsequently accepted through shared memory/register contracts.
No complete compiler or runtime object, compiler startup or self-rebuild is
claimed. Preserve the 12-function core cohort, ratchet 130 and all existing
populations. Admission and runtime reserve remain 32.95 GB and 24.36 GB.

The entries below describe preceding checkpoints.

The [whole-compiler diagnostic plan](plans/2026-11-07-whole-compiler-diagnostic.md)
is complete as a diagnostic; compiler emission remains blocked. The pinned
LLVM-enabled ReleaseFast configuration produces 443.6 MB of optimized compiler
IR with 8,928 definition lines. Local parsing stops on a packed aggregate
global. Independent syntax census records 111 packed-global rejections among
36,959 global/alias lines. The executable build separately stops on runtime
verification: vector `fptrunc` in `compiler_rt.sincos.sincos_f32` is rejected
with `InvalidCast`. No compiler object, executable or self-rebuild is accepted.
See the [report](evidence/whole_compiler_diagnostic.md) and
[record](evidence/whole_compiler_diagnostic_20261107.json).

That diagnostic selected shared packed aggregate support, using
`test/whole_compiler/packed_global.ll` and the retained complete compiler IR.
Packed aggregate support, the subsequent parser repair and the runtime vector
cast slice are now complete. The twelve-member cohort and all accepted
populations are preserved. This direction superseded the earlier isolated AIR
error-returning function recommendation.

Raw diagnostics and exact configuration are under
`local-state/validations/whole-compiler-20261107/attempt-4/`. Use the new runner's
`--input-ir` mode for backend replay. Both census tools and focused controls
pass; original probes and compiler/provider hashes verify. Postcheck free space
is 39.64 GB. Admission remains 32,949,672,960 bytes and execution reserve
24,359,738,368 bytes. No archives were created. The older worker-inbox directive
remains historical and superseded.

The entries below describe preceding checkpoints.

The [compiler-core memory and width execution plan](plans/2026-11-07-compiler-core-execution-breadth.md)
is complete at `c08b98d1`. Guarded event resets and packed 64-bit conversions
extend the fixed-prefix cohort from nine to twelve executed functions per mode.
All 45 fresh/cache records match, and all 17 integration gates pass on the
verified frozen source. The 54 fault controls, both input corpora, five fixed
Zig programs and all 45 native populations pass. See the
[acceptance record](evidence/compiler_core_memory_width_acceptance_20261107.json)
and [evidence](evidence/compiler_core_memory_width.md).

The preceding recommendation was callable error-returning compiler-core
execution. `fmt.charToDigit` fails typed AIR lowering on its `error!u8` contract.
Establish Zig-owned payload layout, error-code and calling-convention facts,
then execute the unchanged function on valid and invalid character/base pairs.
It lies outside the 100-row prefix, so declare any additional execution
population separately. Preserve the twelve-member cohort and existing programs.
The retained diagnostic does not prove that payload width is its only gap.

Historical core evidence remains in `local-state/validations/core-execution-20261107/`.
Current core evidence and authenticated AIR use the `quoted-symbols-20261108`
validation and cache roots described above. The superseded AIR payloads are
retired in the [quoted-symbol cleanup](evidence/quoted_symbol_space_cleanup_20261108.json).
At the older core checkpoint, admission was 32,949,672,960 bytes and the execution
reserve was 24,359,738,368 bytes; the current limits are 20,000,000,000 and
11,410,065,408 bytes. That checkpoint's lowest additional disk sample was
40.53 GB and final recorded free space was 41.10 GB. Original probes, prior
evidence and compilers remain; no archives were created. The older worker-inbox
directive is historical and remains superseded.

The entries below describe preceding checkpoints.

The [large-function selection performance plan](plans/2026-11-07-large-function-selection-performance.md)
is complete at `82f485c0`. The shared identifier comparator avoids repeated
parsing while preserving the existing grammar, numeric namespaces and temporary
names. Five alternating Safe comparisons reduce median compiler time from
26.59 to 16.91 seconds for Fibonacci (36.4%) and from 29.13 to 18.68 seconds for
migration (35.9%). Fast/Small migration also improves; the short Fibonacci
measurements remain unresolved. All timed object/owner bytes and all non-timing
profile fields match. See the
[acceptance record](evidence/large_function_selection_performance_acceptance_20261107.json)
and [measurements](evidence/large_function_selection_performance.md).

All 17 gates pass on the verified frozen source. Debug and ReleaseSafe each pass
1,915 unit tests and 30 policy checks; ABI, structural, captured-object, route and
readiness checks pass. Both input corpora, the five fixed Zig programs and all
45 native populations remain green. The 36 core records match prior fresh
execution, retaining 100 lowered/emitted/linked and nine executed per mode.

That performance slice did not expand the cohort. Selection itself remains the
largest Safe profile cost; further performance work should measure inside that phase.
The older cohort-v3 inbox directive remains historical: it predates the accepted
nine-function cohort. Preserve the original probes and create no archives.

The [unchanged Zig input-program plan](plans/2026-11-06-unchanged-zig-input-program.md)
is complete at `9cc31c38`. The pinned language-reference migration tool runs
unchanged with runtime document input, allocation, mutable directives, generated
files and error paths. All 87 input/mode pairs and 603 observation controls pass,
with identical independent ownership replay in Fast, Safe and Small. Three Safe
backend gaps are repaired through shared lowering and executable regressions.
See the [acceptance record](evidence/zig_input_program_acceptance_20261106.json)
and [implementation evidence](evidence/zig_input_program.md).

All 17 integration gates pass. All five existing fixed Zig programs and the C
parser remain green; the parser passes 138 input/mode pairs and 552 observation
controls. Compiler-core counters remain 100 lowered/emitted/linked and nine
executed functions per mode, with all 36 records matching prior fresh execution.
All 45 native populations pass. Original probes and diagnostic worktrees remain.

The [project cleanup](evidence/project_space_cleanup_20261106.json) removes
7.24 GB of allocated data across three audited intervals, including 185.56 MB
of cache regenerated during full validation. This is not a net project-size
change. Current AIR, compiler binaries and prior evidence remain; no archives
were created. That cleanup checkpoint recorded 53.30 GB free; the subsequent
performance acceptance records 51.22 GB free after builds and retained evidence.

The preceding [compiler selection performance plan](plans/2026-11-06-compiler-selection-performance.md)
completed at `fbb249a7`. Profile v2 attributes
time and allocation work to functions and legalizers; nine legalizers defer
candidate copying until the first rewrite. See the
[acceptance record](evidence/selection_performance_acceptance_20261106.json) and
[measurements](evidence/selection_performance.md).

Five alternating comparisons on the retained Safe Fibonacci IR reduce median
ReleaseFast compiler time from 29.78 s to 27.28 s (8.4% less) and median peak RSS
by 60.0%. Logical legalizer allocations fall 70.7%. Every benchmark object and
ownership manifest is byte-identical, with unchanged per-function/per-stage
counters. Profiling overhead is unresolved within sample variation. Twenty-five
parser comparisons per compiler show no regression at 10 ms timing resolution.

Both Fibonacci and the document-input corpus remain useful performance inputs.
Block-sort specializations and the DWARF stack-machine interpreter remain among
the expensive functions after the shared comparison repair. Ownership replay
still duplicates selection work. Ordered scans and original-form retries remain.
Keep extending the common transfer contract when addressing pair/vector PHIs
and spill destinations; those cases and ordinary CLI structural
selection still use their existing paths. Generated-code optimization quality
remains a separate measured milestone.

For large development gates, use a ReleaseFast compiler while retaining Debug
tests. Unchanged programs obtain ownership during object emission; independent
replay remains a permanent route/corpus regression and is available with
`--replay-owners`. Storage thresholds remain 32,949,672,960 bytes before starting
and 24,359,738,368 bytes during execution. No archives were created.

The entries below describe earlier milestones. The requested
[Python-to-Zig tooling migration](evidence/python_tools_migration_20261105.json)
completed at `978ffaf9`. All nine maintained Python modules were replaced using
the pinned `zig-process` and `zig-test-support` sources. All 22 policy/provider tests pass in
Debug and ReleaseSafe, all 17 integration gates pass, and the final log matches
all 1,430 canonical records from the Python-backed accepted run. The separate
fresh/cache replay matches all 24 records across three modes. The frozen
15-pair performance matrix retains its supported outcomes and semantics;
cross-engine timings do not establish a speedup. See the
[tool commands and scope](validation_tools.md).

Obsolete build caches and the verified temporary export cache were removed,
with hashes, metadata and reports retained. No archives were made. The compiler
source and accepted status remained unchanged during that tooling task.
At that tooling checkpoint, unchanged Safe had 46 emission failures; the first was
`debug.writeCurrentStackTrace` / `inline-asm-call`. Fixed acceptance counters
remain 100 lowered/emitted/linked and five executed functions per mode, with
compiler-rt bypass ratchet 130.

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

## Historical checkpoints

The counts and failures below describe earlier checkpoints. Current accepted
capability and the next action are recorded above.

The earlier accepted [integer arithmetic and hash checkpoint](evidence/fibonacci_arithmetic_acceptance_20261105.json)
at `9a8cc1c9` passes all 17 integration stages. Accumulator-address stores,
narrow integer normalization and ABI carriers, constant two-word stores, and
bounded i128 arithmetic preserve values and live operands. Reusing generated
scalar words closes the unchanged `Wyhash.hash` and `Wyhash.init` emission rows.
Immediate arithmetic and shifts now preserve live RCX sources and aliases in
both typed and production dispatch; executable regression and rollback checks
cover the repair. The i16 integration oracle now accounts for truncation before
the reverse shift, with LLVM and local execution agreeing on `0x0234`.
Native fixture accounting and provenance derive from the shared registry.

All 1,862 unit tests, 13 structural checks, 38 captured objects, readiness and
frozen executable canaries pass. The four added native populations check
162,816 local observations against 81,408 LLVM references in all three modes.
All 35 native populations and the unchanged 100-row/five-function cohort pass.
Minimum free space is 35.46 GB, above the unchanged 24.36 GB reserve.
The [focused evidence](evidence/fibonacci_arithmetic_focused_20261105.json)
retains component mutation controls, both earlier integration failures and
their fixes, exact source identities, and the native `Wyhash.init` check.

Unchanged pinned Fibonacci executes all six assertions in Fast and Small with
LLVM-equivalent exit status, stdout and stderr. Safe emits 1,522 of 1,568
functions; 46 failures still prevent whole-program emission and execution.
The first was `debug.writeCurrentStackTrace` / `inline-asm-call`.
The broader i65/i96 work remains an uncommitted diagnostic draft under
`local-state/worktrees/fibonacci-crash-investigation`; it is excluded from this
acceptance. The thirteen original scratch probes remain unchanged; no archives
were made. That slice was stopped at the user's request; subsequent authorization
led to the accepted completion above.

The earlier accepted [atomic, pointer, frame and call checkpoint](evidence/fibonacci_state_acceptance_20261105.json)
at `4242debd` passes all 17 integration stages. Scalar atomics preserve old
values and compare-exchange success flags. Pointer and two-word values retain
symbols and layout, and boolean branches consume the low bit even when upper
bits are dirty. Bounded frame addresses and scaled indexes preserve byte offsets;
CFG scheduling respects definitions. Direct C integer/pointer variadic calls
support up to sixteen arguments through the existing register and stack paths,
and ordinary known function addresses retain module-owned symbol names.
All 1,847 unit tests, 13 structural checks, captured-object smoke, readiness and
frozen executable canaries pass. The four added populations check 153,996 local
observations against 76,998 LLVM references. Each component also rejects its
36 mutation controls. All 31 native populations and the unchanged 100-row/five-function
cohort pass. Minimum free space is 33.03 GB, above the 24.36 GB reserve.
Unchanged pinned Fibonacci executes all six assertions in Fast and Small with
LLVM-equivalent exit status, stdout and stderr. Safe emits 1,478 of 1,568
functions; 90 failures still prevent whole-program execution. The remaining
scalar, memory, vector, CFG and ABI forms, pinned runtime linkage and mandatory
three-mode Fibonacci regression remain open.
The [focused evidence](evidence/fibonacci_state_focused_20261105.json) records
source identity, component checks and the repaired boolean regression. Full-width
accumulator aliases now survive immediate arithmetic and spills; the old poisoned
high-half failure and its regression tests are retained. The separately diagnosed
narrow arithmetic-shift error remains in this checkpoint; its tested prototype
repair awaits the next cumulative full integration. The
thirteen original probes remain unchanged; no archives were made.

The earlier accepted [integer-intrinsic and comparison checkpoint](evidence/fibonacci_intrinsics_acceptance_20261105.json)
at `fb39db75` passes all 17 integration stages. Scalar saturating operations,
narrow extrema and bit reversal preserve significant bits and live operands.
Compare staging now saves overlapping operands: the confirmed `umax33(1, 0)`
wrong-code case returns one. Select condition formation also preserves its arms.
All 1,827 unit tests, 13 structural checks, captured-object smoke and readiness
pass; focused tests pass in all three release modes. The added native population
checks 87,552 local observations against 43,776 LLVM references, and all 36
mutation controls are rejected. All 27 native populations and the unchanged
100-row/five-function cohort pass. Minimum free space is 33.59 GB, above
the 24.36 GB reserve. Unchanged pinned Fibonacci executes all six assertions in
Fast and Small with LLVM-equivalent exit status, stdout and stderr. Safe emits
1,289 of 1,568 functions; 279 failures still prevent whole-program execution.
The disk sampler accepts disappearing linker temporary files only when every
owned root still has a complete count; other sampling errors remain failures.
A fresh export and a cache hit on its exact authenticated bundles check the
same three cohorts.
The [focused evidence](evidence/fibonacci_intrinsics_focused_20261105.json)
records source identity and checks. The thirteen original probes remain
unchanged; no archives were made.

The earlier accepted [word arithmetic and switch checkpoint](evidence/fibonacci_flow_acceptance_20261105.json)
at `be90e939` passes all 17 integration stages. Full-word division, remainder,
checked products, signed checked sums, extrema and byte swaps preserve exact
results and live inputs. Fixed-register arithmetic receives spill capacity
without eagerly relocating all parameters. Private switch chains support wide
conditions and large case lists; the bounded CFG envelope now admits 1,024 blocks.
All 1,822 unit tests, 13 structural checks, captured-object smoke and readiness
pass. Focused word and switch tests pass in all three release modes. The two
added native populations pass 55,680 local observations against 27,840 LLVM
references, with 66 mutation controls. All 26 native populations and the unchanged
100-row/five-function cohort pass. Minimum free space is 33.58 GB, above
the 24.36 GB reserve. The unchanged pinned Fibonacci program still passes all
six assertions in Fast and Small with LLVM-equivalent exit status, stdout and
stderr. Safe emits 1,264 of 1,568 functions; 304 failures still prevent a local
object and whole-program execution. The [focused evidence](evidence/fibonacci_flow_focused_20261105.json)
records the source identity and checks. All thirteen original probes remain
unchanged; no archives were made.

The earlier accepted [checked-integer and address checkpoint](evidence/fibonacci_checked_acceptance_20261105.json)
at `9b6bf0c8` passes all 17 integration stages. Stack addresses can flow through
pointer PHIs, selects, stores, casts and returns. Call preservation saves all
live aliases. Signed and unsigned checked arithmetic covers widths one through
32, and general boolean calls preserve their low ABI bit through pointer,
indirect and stack-argument calls. Zero extension from i32 clears stale upper
accumulator bits. All 1,812 unit tests, 13 structural checks, 13 focused tests per
release mode, captured-object smoke and readiness pass. The two added native
populations pass 49,920 local observations against 24,960 LLVM references,
with 54 mutation controls. All 24 native populations and the 100-row/five-function
cohort pass. Minimum free space is 36.14 GB, above the 24.36 GB reserve.
The unchanged pinned Fibonacci program still passes its six assertions in Fast
and Small with LLVM-equivalent exit status, stdout and stderr. Safe emission
reaches 1,155 of 1,568 functions; 413 failures still prevent a local object and
whole-program execution. The [focused evidence](evidence/fibonacci_checked_focused_20261105.json)
records the two wrong-code repairs and exact source equivalence. All thirteen
original probes remain unchanged; no archives were made.

The earlier accepted [Fibonacci foundation checkpoint](evidence/fibonacci_foundation_acceptance_20261105.json)
at `580a866f` passes all 17 integration stages. Named indirect calls, seven to
sixteen word/pointer arguments, checked word arithmetic and narrow comparisons
use the existing scalar and System V machinery. Bounded storage supports objects
through 64 KiB and total frames through one MiB, with page touches that preserve
incoming arguments. All 1,803 unit tests, 13 structural checks, 22 storage tests
per release mode, captured-object smoke and readiness pass. The four added native
populations pass 38,400 local observations against 19,200 LLVM references;
eighteen protected-stack checks verify page probing. Earlier populations and the
100-row/five-function cohort retain their counts. Minimum free space is
38.80 GB, above the 24.36 GB reserve.
The unchanged pinned upstream Fibonacci program now executes all six assertions
in ReleaseFast and ReleaseSmall, matching LLVM exit status, stdout and stderr.
ReleaseSafe remains incomplete: 1,025 of 1,568 selected functions emit, and 543
fail. Remaining Safe value flow, arithmetic, memory, control flow and the real
compiler runtime link precede three-mode acceptance. The
[focused evidence](evidence/fibonacci_foundation_focused_20261105.json) records
source equivalence, exact validation and remaining boundaries. All thirteen
original probes remain unchanged; no archives were made.

The earlier accepted [scalar startup checkpoint](evidence/scalar_forms_acceptance_20261105.json)
at `d8c135e5` passes all 17 integration stages. Unsigned minimum and signed
less-equal forms reuse scalar compare/select operations. Switch PHI edges retain
original block identities and privately owned machine labels. Bounded stack
memset preserves exact extents and memory boundaries. All 1,788 unit tests,
13 structural checks, 14 focused tests per release mode, captured-object smoke
and readiness pass. Ten native functions pass 3,840 local observations against
1,920 LLVM references; twenty-four mutation controls reject wrong results.
Seventeen earlier native populations and the 100-row/five-function cohort retain
their counts. Minimum free space is 31.29 GB, above the 24.36 GB reserve.
At this source revision, the unchanged canonical Fast capture emits 24 of 34
selected functions and rejects ten, first at `Io.Writer.defaultRebase indirect-call`.
No complete local Fibonacci object or execution is claimed for this checkpoint.
Indirect calls, stack arguments and remaining scalar forms precede execution;
Safe retains its larger separate frontier. The [focused evidence](evidence/scalar_forms_focused_20261105.json)
records the exact validation and unsupported boundaries. All thirteen original
probes remain unchanged; no archives were made.

The earlier accepted [aggregate storage checkpoint](evidence/aggregate_storage_acceptance_20261105.json)
at `fa2371d0` passes all 17 integration stages. Module-owned integer/pointer
layouts up to 256 bytes retain exact padding and alignment. Flat two-word values
support loads, stores, insertion, extraction and ordinary call/return carriers.
Shared frame planning preserves scalar values across stores and argument
permutations, including final-use operands. The 1,783-test unit population,
13 structural checks, 26 focused tests per release mode, captured-object smoke
and readiness pass. Twelve native functions pass 4,608 local observations against
2,304 LLVM references; eighteen mutation controls reject wrong values. Sixteen
earlier native populations and the 100-row/five-function cohort retain their counts.
Minimum free space is 36.84 GB, above the 24.36 GB reserve.
The unchanged canonical Fast capture emits twenty of 34 selected functions and
rejects fourteen, first at `start.expandStackSize composed-block-llvm-intrinsic`.
No complete local Fibonacci object or execution is claimed. Scalar/memory forms,
switch PHI edges, indirect calls and stack arguments remain. Safe retains its
separate larger frontier and real stack-probe runtime requirement. The
[focused evidence](evidence/aggregate_storage_focused_20261105.json) records the
bounded envelopes and validation provenance. All thirteen original probes remain
unchanged; no archives were made.

The earlier accepted [narrow ABI checkpoint](evidence/narrow_abi_acceptance_20261105.json)
at `85f557e9` passes all 17 integration stages. Private register carriers
normalize unannotated integer parameters, returns and ordinary calls at widths
one through sixteen, including direct boolean branches and boolean xor. Ordinary
call preparation now reserves storage for instruction-produced final-use arguments.
All 1,778 units, 13 structural checks, 58 focused tests in each release mode,
captured-object smoke and readiness pass. Thirteen native functions pass 4,992
local observations against 2,496 LLVM references; eighteen mutation controls
reject wrong values. Fifteen earlier populations retain their counts, as do the
100-row/five-function cohort and bypass ratchet. Minimum free space is
39.17 GB, above the 24.36 GB reserve.
The canonical Fast capture emits sixteen of 34 functions and rejects eighteen,
first at `start.expandStackSize composed-block-llvm-intrinsic`. Small has the same
counts. Safe is a separate, larger frontier: conservative selection includes
1,568 functions, of which 206 emit and 1,362 reject. Its LLVM reference also needs
the real `__zig_probe_stack` runtime when linked. No complete local Fibonacci
object or execution is claimed. The [focused evidence](evidence/narrow_abi_focused_20261105.json)
records these mode-specific results and retained scalar limits. All thirteen
original probes remain unchanged; no archives were made.

The earlier accepted [constant remainder checkpoint](evidence/constant_remainder_acceptance_20261104.json)
at `cf1b30cd` passes all 17 integration stages. Unsigned remainder by a
constant power of two now uses the existing AND lowering at 8/16/32/64 bits,
including divisor one and high-bit divisors with signed or unsigned spelling.
The original IR remains unchanged. Existing preservation/home limits remain;
the [focused evidence](evidence/constant_remainder_focused_20261104.json) retains
the frameless loaded-RAX limitation for a 2^32 divisor.
All 1,773 units, 13 structural checks, 32 focused tests in each of ReleaseFast
and ReleaseSafe, captured-object smoke and readiness pass. Eight native functions
pass 3,072 local observations against 1,536 LLVM references, and twelve mutation
controls reject wrong masks or lost live inputs. Fourteen earlier populations,
the fixed 100-row/five-function counts and bypass ratchet remain unchanged.
Minimum reported free space is 41.68 GB, above the 24.36 GB reserve.
Fibonacci still emits ten of 34 selected functions and rejects 24, now first at
`start.expandStackSize composed-block-call-arg-width`. No complete local object
or whole-program execution is claimed. All 13 original probes remain unchanged;
no archives were made.

The earlier accepted [RAX pointer-load checkpoint](evidence/rax_load_acceptance_20261104.json)
at `c6b46f0c` passes all 17 integration stages on a frozen 2,726-file snapshot.
Ordinary integer and pointer loads now stage RAX addresses before preparing the
accumulator result, using the same typed address helper as stores. Physical write
planning and both admission paths agree. Live pointers and scratch values survive;
width/class restrictions, EFLAGS and transaction rollback remain checked.
Seven native functions pass 2,688 local observations against 1,344 LLVM references
across direct/release routes in three modes, including exact-width protected-page
loads, skipped null-slot branches, 56-byte stride loops, helper calls and guards.
Twelve mutation controls reject oversized reads and corrupted live values.
All 1,770 units, 13 structural checks, 17 focused tests each in ReleaseFast and
ReleaseSafe, captured-object smoke and readiness pass. The thirteen earlier
native populations, fixed 100-row/five-function counts, legacy selection and
bypass ratchet stay unchanged. Minimum reported free space is 44.14 GB,
above the 24.36 GB reserve. The retained loop and branch now emit objects.
Fibonacci still emits ten of 34 selected functions; it next rejects unsigned
remainder by 4096 at `start.expandStackSize composed-block-binary-imm-rhs`.
Local whole-program execution remains zero. All 13 original probes remain
unchanged; no archives were made.

The earlier accepted [general array stride checkpoint](evidence/general_stride_acceptance_20261104.json)
at `a81a36fe` passes all 17 integration stages on a frozen 2,720-file snapshot.
Literal integer arrays now use allocation strides from 1 to 255 bytes through
the existing typed address action, including the capture's 56-byte stride.
Stack descriptor and read-only table restrictions remain unchanged. Five native
functions pass 1,920 local observations against 960 LLVM references across
direct/release routes in three modes, checking padding, nesting, negative and
wrapping indexes, helper calls, live values and guarded stores. Twelve mutation
controls reject wrong strides and stores. All 1,766 units, 13 structural checks,
18 focused tests each in ReleaseFast and ReleaseSafe, and readiness pass. The
twelve earlier native populations, fixed 100-row/five-function counts, legacy selection and
bypass ratchet stay unchanged. Minimum reported free space is 45.54 GB,
above the 24.36 GB reserve. Fibonacci still emits ten of 34 selected functions;
its next boundary is an ordinary i32 load through an RAX pointer in
`start.expandStackSize`, reported as `composed-block-load-ptr`. A retained small
loop reproduces it and compiles with Clang; local whole-program execution is
still zero. All 13 original probes remain unchanged; no archives were made.

The earlier accepted [bounded frame checkpoint](evidence/bounded_frame_acceptance_20261104.json)
at `d389d135` passes all 17 integration stages on a frozen 2,714-file snapshot.
Exact integer pairs and padded 16-byte and 24-byte wrappers now reuse existing
frame storage through private codegen views and typed address operations.
Complete layout, alignment and extent checks preserve the source IR and reject
unsupported forms. Four permanent functions pass 768 local observations against
384 LLVM references across direct/release routes in three modes, including mixed
pair/wrapper copies, defined padding, helper calls, live values and guards.
All 1,763 units, 13 structural checks, focused release tests and readiness pass.
The unchanged Fibonacci capture now emits 10 of 34 selected functions and reaches
`start.expandStackSize composed-block-array-gep-stride` for a 56-byte stride;
whole-program execution remains blocked. The 100-row/five-function populations,
eleven earlier native populations, legacy selection and bypass ratchet remain
unchanged. Minimum reported free space is 45.91 GB, above the 24.36 GB reserve.
All 13 original probes remain unchanged; no archives were made.

The earlier accepted [dependency-coverage checkpoint](evidence/dependency_coverage_acceptance_20261104.json)
at `811aa4ba` passes all 17 integration stages on a frozen 2,708-file snapshot.
Bounded attributes, metadata and typed constants now establish complete reference
coverage; unsupported forms remain conservative. Retained raw metadata roots
survive constant merging, and inferred function attributes precede trailing
metadata. All 1,756 units, 13 structural checks and readiness pass. Five optimizer
pipelines add 400 LLVM-backed observations of locally optimized IR. The unchanged
Fibonacci capture selects 34 functions and 16 globals/aliases, matching LLVM after
serialization-only SSA normalization, but still rejects aggregate stack storage.
Three authenticated exports are reused with fresh execution checks. The fixed
100-row/five-function populations, eleven native populations, legacy selection
and bypass ratchet remain unchanged. Minimum reported free space is 47.84 GB,
above the 24.36 GB reserve. All 13 original probes remain; no archives were made.

The earlier accepted [symbol identity checkpoint](evidence/symbol_identity_acceptance_20261103.json)
at `b3be3512` passes all 17 integration stages on a frozen 2,691-file snapshot.
The unchanged 100-row and five-function counts pass in all modes, with three
authenticated export-cache hits and fresh execution checks. Its minimum is
31.92 GB free, above the 24.36 GB reserve. The bounded repair and remaining
reference-analysis work are described below.

The earlier accepted [IR and headroom checkpoint](evidence/ir_headroom_acceptance_20261103.json)
at `abd0bae6` passes both full 17-stage fresh/cached runs. All 1,406 canonical
records match on an unchanged 2,681-file primary-checkout snapshot. The numeric
serialization, blockaddress, quoted-name and allocation-ownership repairs are
accepted with headroom policy schema 3. All candidate, execution and bypass
counts stay fixed; the detailed scope appears below.

The earlier accepted [module dependency checkpoint](evidence/module_selection_acceptance_20261103.json)
at `9c7985e2`, with shared analysis extracted at `68a56ca7`, passes all 17
integration stages on a frozen 2,642-file snapshot. Explicit
`--codegen-reachable` selection follows parsed function, global and alias references;
private helpers keep local ELF bindings and selected alias chains resolve in any
definition order. Opaque references conservatively retain all definitions.
Seven functions pass 330 local observations against 165 LLVM references across
direct/release routes in three modes. Thirty rejection controls and three
CLI/environment equivalence checks pass, along with all 1,689 unit tests, focused
checks and 60 ABI cases. Earlier populations and the bypass ratchet stay fixed.
Legacy selection remains the default. Unchanged Fibonacci now rejects during
code generation at `start.expandStackSize unsupported_type:alloca` in the explicit
mode; it still has zero local executions.

The earlier accepted [integer array-stride checkpoint](evidence/array_stride_acceptance_20261103.json)
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
reserve. The accepted headroom policy schema 2 used a fixed
32 GiB reserve plus the unchanged 8 GiB working budget: 40 GiB (about 42.95 GB)
free at admission. Runtime reserve checks and stronger caller floors remain.
That pair reports 5.86 GB fresh and 2.16 GB cached decreases; reported minima
are 44.09 GB and 43.31 GB, above the 34.36 GB reserve. The 51 runner/policy and
41 comparison tests pass. These filesystem observations do not establish a speedup.
The user subsequently lowered both admission and reserve by 10 decimal GB.
At that checkpoint, policy schema 3 required 32.95 GB at admission and a 24.36 GB
runtime reserve, with the same 8 GiB working budget. Its accepted fresh/cached
pair reports 7.09 GB and 1.97 GB decreases. Independent sampled minima are
30.71 GB and 33.65 GB, above the reduced reserve; all 1,406 canonical records match.
The [generation cleanup](evidence/global_memory_cleanup_20261103.json) retires
3.92 GB of superseded AIR after both full runs and replacement hash verification.
That checkpoint used `global-memory-headroom-20261103`. The later
[IR generation cleanup](evidence/ir_headroom_cleanup_20261103.json) retires those
payloads after the complete fresh replacement proof and before cached validation
to meet its admission threshold. Both replacement runs pass. That checkpoint's
exports and paired work selection used `ir-headroom-20261103`; the later
execution-breadth checkpoint supersedes them. The [project cleanup](evidence/project_space_cleanup_20261106.json)
retires the old payloads while retaining their metadata, hashes, proofs and
source probes, with no archives.

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

The [numeric SSA serialization repair](evidence/numeric_ssa_focused_20261103.json)
now has a [focused integration follow-up](evidence/ir_blockaddress_focused_20261103.json).
The first full run failed after six stages on a retained jump-table initializer;
its sampled minimum stayed above the reduced reserve. Printing now binds each
`blockaddress` to its function before renumbering. CFG passes preserve functions
whose block addresses escape, while opaque reference coverage stays conservative.
SimplifyCFG generates valid names without collisions, and the parser preserves
quoted parameter names with spaces. The earlier allocation-ownership fixes remain.
All 1,718 units, readiness and 13 structural checks pass, including the previously
failing mixed C/Zig native case. Ten regression functions supply 480 observations
of locally optimized IR executed by Clang-22 against 160 reused LLVM references.
Complete optimized panic-module IR and the unchanged repaired Fibonacci IR verify.
These IR checks add no local whole-program execution. The accepted fresh/cached
pair passes all 17 stages with matching canonical records and an unchanged source
snapshot. The isolated retry had passed nine stages before exposing the export
worker's fixed checkout path; the accepted pair ran from the primary checkout
after merging the focused commits. Failed logs and frozen snapshots remain.
The follow-up fixes have separate printing, parser and optimizer source commits;
the fixed candidate and execution cohorts remain unchanged.

The accepted [symbol identity prerequisite](evidence/symbol_identity_acceptance_20261103.json)
at `b3be3512` passes 1,727 units, 13 structural tests, readiness and full
integration. It fixes GlobalOpt ignoring escaped stores and GlobalDCE deleting
differently spelled live globals; constant merging uses the same identity. Five entries pass
240 observations of locally optimized IR via Clang against 80 reused references.
The local verifier still rejects differently spelled direct callees, alias
targets and global-initializer targets; graph-only tests do not establish their
CLI admission. Unsupported symbol spellings and opaque regions stay conservative.
The frozen cached run passes all 17 stages; its exact command and reuse rationale
are recorded in the evidence. Only the idle project build cache was retired for
admission, preserving sources, current exports and all 13 original probes.
No shared caches were deleted, and no archives were created.

The earlier [attribute-group slice](evidence/reference_attributes_focused_20261103.json)
at `fa85a805` recognizes bounded enum, alignment, memory-effect and string
attributes through one module context. Missing/duplicate groups and unfamiliar
strings such as `probe-stack` remain conservative. It passes 1,739 units,
13 structural tests, 19 focused tests in each of ReleaseFast and ReleaseSafe,
readiness and 400 observations of optimized IR executed by Clang against
80 reused LLVM references. The subsequent checkpoint accepts the family.

The [dependency-coverage checkpoint](evidence/dependency_coverage_acceptance_20261104.json)
accepts `dad027d9`, the attribute-ordering repair `85e892f3` and the corrected
negative fixture `811aa4ba`. The first full attempt was stopped after a narrow
check confirmed that its opaque-coverage control used now-supported metadata.
The control now uses unknown named metadata. All 330 local module observations,
30 rejection controls and three environment checks pass, and the frozen retry
passes all 17 stages. The original and retry logs remain retained.

The dependency checkpoint established complete coverage for the unchanged
Fibonacci input: 34 functions and 15 globals plus one alias. Its selected names
match LLVM GlobalDCE after serialization-only numeric SSA normalization. At that
checkpoint, nine functions emitted and 25 rejected, first at aggregate allocation.

The [bounded frame checkpoint](evidence/bounded_frame_acceptance_20261104.json)
accepted exact 16-byte integer pairs and the capture's padded 16-byte and
24-byte wrappers. The existing allocator and typed address authority own storage
and access; private views preserve source records and borrowed call arguments.
Mixed pair/wrapper copies retain their proven literal length through both views.
All-mode native proof and all 17 integration stages passed. At that checkpoint,
Fibonacci emitted ten functions and rejected 24, first at the 56-byte array stride
in `start.expandStackSize`; local whole-program execution remained zero.

The [general array stride checkpoint](evidence/general_stride_acceptance_20261104.json)
accepted bounded allocation strides from 1 to 255 bytes, including `[56 x i8]`,
with all-mode native proof and all 17 integration stages. At that checkpoint, the
unchanged capture emitted ten functions and rejected 24; its first boundary moved to
`start.expandStackSize composed-block-load-ptr`. Read-only debugger inspection
identifies a 64-bit pointer in RAX rejected during transaction seal for an i32
load. The [focused evidence](evidence/general_stride_focused_20261104.json) retains
a small loop reproducer and its successful Clang compile. This is a codegen
boundary, with zero local whole-program executions.

The [RAX pointer-load checkpoint](evidence/rax_load_acceptance_20261104.json)
accepts that ordinary-load address through shared RAX-to-RCX staging and
accumulator ownership. Both retained load reproducers now emit objects, and
all-mode native checks and all 17 integration stages pass. The unchanged capture
still emits ten functions and rejects 24; it now reaches `urem i64` by 4096,
reported as `start.expandStackSize composed-block-binary-imm-rhs`.
The [focused evidence](evidence/rax_load_focused_20261104.json) retains a small
control-flow reproducer with that exact rejection and a successful Clang compile.

The [constant remainder checkpoint](evidence/constant_remainder_acceptance_20261104.json)
accepts that bounded unsigned operation. The unchanged capture now reaches
`composed-block-call-arg-width`; all 24 function failures remain tracked.

The user's latest instruction is to finish the current slice and stop. The
arithmetic/hash slice is finished and recorded above; no further slice is active.
The earlier authorization to continue automatically is superseded. The remaining
plan below is retained for a future user request:

1. Narrow call arguments/returns, boolean parameter handling and the main
   function's call-preservation frame are accepted at the checkpoint above.
2. Bounded stack structures and flat two-word aggregate loads,
   insertion/extraction and call/return values are accepted above. Larger or
   unsupported layouts remain explicit boundaries.
3. Unsigned minimum, signed less-equal, switch PHI edges and bounded stack
   memset are accepted above. Resolve any remaining scalar forms as they emerge
   in the call and Safe paths.
4. Named indirect calls, bounded stack arguments and their result handling are
   accepted above. Fast and Small execute the complete unchanged program.
5. Resolve the remaining Safe scalar, memory, atomic and control-flow forms,
   link the real pinned compiler runtime and execute the unchanged Safe program.
6. Retain matching LLVM exit status/stdout/stderr in all three release modes and
   add a permanent mandatory regression before full integration acceptance.

Rerun the whole captured failure report after each implementation change;
newly exposed failures update the work order. Completion requires all six original
assertions to pass with matching exit status/stdout/stderr through the local
backend. Use the validation tiers for provisional commits and family acceptance.
Keep fixed populations, default legacy selection, the bypass ratchet and agreed
disk limits unchanged. Preserve the original scratch probes and create no archives.

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
