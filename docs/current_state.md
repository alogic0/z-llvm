# Current state

The accepted record is [accepted_status.json](accepted_status.json). The block
below is generated and checked by `zig build check-docs`; regenerate it with
`zig build check-docs -- --write` after an explicitly accepted evidence update.

<!-- accepted-status:start -->

Accepted revision: `b3be3512a9f4623315bbc3ae657ba620686346c6`; tree: `2b8dea5ff5ccd365ea8e243d65890008177cf032`.

Population: compiler-core candidate prefix (100 rows), selector `real-candidate-selector-v3`.
Modes: ReleaseFast, ReleaseSafe, ReleaseSmall. Source pin: `1c08b09d1c847f4f02c8216e3b62df323861a437`.
Candidate SHA-256: `847e014b2abab0800d0df690ef324dc5fa01299dcf60645b4dc55ca406fe2a31`.

| Metric | Accepted value per mode | Scope |
| --- | ---: | --- |
| Functions lowered | 100 | Compiler-core prefix |
| Objects emitted | 100 | Compiler-core prefix |
| Native links | 100 | Compiler-core prefix |
| Functions executed | 5 | Fixed execution cohort |
| Paired harnesses accepted | 5 | Legacy real_programs_ok cohort metric |
| Local failures | 0 | Compiler-core gate |

Compiler-rt bypass ratchet: 130 (separate 285-function population).

<!-- accepted-status:end -->

The accepted [symbol identity repair](evidence/symbol_identity_acceptance_20261103.json)
at `b3be3512` passes all 17 integration stages on a frozen 2,691-file snapshot.
Shared reference analysis recognizes supported quoted and hexadecimal global
spellings, preserving stores and live definitions that GlobalOpt and GlobalDCE
previously missed. Constant merging uses the same identity; numeric slots remain
distinct from quoted numeric names. All 1,727 units, 13 structural tests and
readiness pass. Five entries pass 240 observations of locally optimized IR
executed by Clang against 80 reused LLVM references. This adds no local
machine-code or whole-program execution credit. The three current AIR exports
are authenticated and reused while execution checks run again. The recorded
minimum is 31.92 GB free, above the 24.36 GB runtime floor; the reported decrease
is 1.71 GB. Opaque coverage, the legacy selection default, all fixed populations
and the bypass ratchet remain unchanged.

The earlier accepted [IR and headroom checkpoint](evidence/ir_headroom_acceptance_20261103.json)
at `abd0bae6` passes both full 17-stage fresh/cached runs. All 1,406 canonical
records match on one unchanged 2,681-file snapshot in the primary checkout.
Numeric local names follow definition order, and printing binds each
`blockaddress` to its function before renumbering. CFG passes preserve functions
whose block addresses escape, while opaque reference coverage stays conservative.
SimplifyCFG generates valid names without collisions; the parser preserves
quoted parameter names with spaces and releases owned values on failed publication.
All 1,718 units, readiness and 13 structural checks pass, including the previously
failing mixed C/Zig native case. Ten regression functions supply 480 observations
of locally optimized IR executed by Clang-22 against 160 reused LLVM references.
Complete optimized panic-module IR and the unchanged repaired Fibonacci IR verify.
These IR checks add no local whole-program execution. Candidate counts, all eleven
native populations and the bypass ratchet remain unchanged. The two failed
attempts, their inputs and frozen snapshots remain retained; full validation uses
the canonical checkout required by the export/execution cohort.

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

The earlier [integer array-stride checkpoint](evidence/array_stride_acceptance_20261103.json)
at `4f69c581`, with correctness repairs `d1fe039a` and `e2fb5841`, passes
all 17 integration stages on a frozen 2,635-file snapshot. Named i64 indexes now
form runtime addresses for bounded literal integer arrays using allocation
strides, including padding and nesting. Live values receive preservation space;
in-place address operands survive scratch writes, and stores consume their value
before staging a spilled destination pointer. Four functions pass 1,536 local
observations against 768 LLVM references across direct/release routes in three
modes. Six negative controls are rejected. All 1,685 units, focused checks and
60 ABI cases pass; prior populations and the bypass ratchet remain fixed.

The earlier [boolean call-return checkpoint](evidence/boolean_call_acceptance_20261103.json)
passes all 17 integration stages on a frozen 2,630-file source snapshot. Exact
i1 direct calls use the existing typed call action, normalize the low bit before
publishing the result, and preserve live values and transaction rollback. Four
native functions pass 1,536 local observations against 768 LLVM references across
direct/release routes in three modes. Three controls reject missing normalization.
All 1,679 unit tests, focused checks and 60 ABI cases pass; compiler-core counts,
previous native populations and the bypass ratchet remain unchanged.

The earlier [global-memory checkpoint](evidence/global_memory_acceptance_20261103.json)
passes a fresh/cached pair of all 17 integration stages, with all 1,403 canonical
records matching on an unchanged 2,624-file snapshot. Symbolic byte addresses,
reachable integer/pointer global storage and ELF data relocations now share the
existing transactional memory consumers. Four address functions pass 192 local
observations against 96 LLVM references; seven copy/store functions pass 240
against 120, through direct/release routes in three modes. All 1,675 unit tests,
focused checks and the 60-case ABI gate pass. Compiler-core counts stay fixed.

The earlier [allocation-padding repair](evidence/allocation_padding_acceptance_20261103.json)
passes all 17 integration subgates. Struct fields now advance by allocation size: the
field after `i24` starts at byte 4 and the field after `x86_fp80` at byte 16. Four
permanent native regressions pass 768 local observations against 384 LLVM references
across direct/release routes in three modes. The 1,662 unit tests and focused
60-case ABI gate pass. Its layout correction remains part of the current compiler.

The [scalar startup checkpoint](evidence/scalar_startup_acceptance_20261103.json)
passes all 17 integration subgates on its frozen source snapshot. Exact named
i64-to-pointer casts preserve every bit and signed i32/i64 nonnegative comparisons
reuse the existing sign-bit authority. Earlier scalar frame stores and their
full-width immediate repair remain accepted. The new standalone native canaries
each pass 1,536 local observations against 768 LLVM references in three modes.

The [current-pin migration](evidence/real_candidates_release_v3_migration.json)
fixes the 100-row selector-v3 population. Its audit retains 30 previous prefix
entries and replaces 70; 63 former names have no runtime AIR at this pin.
Five source-bound functions execute per mode: four constant methods and
`ascii.isAscii`, which checks all 256 byte inputs. These observations do not
turn 100 native links into 100 executions.

AIR publication atomically writes schema-4 metadata and transfers the verified
payload into the cache. The IR/headroom pair authenticates three fresh exports,
then verifies three cache hits while rerunning execution checks. Current exports
use `local-state/caches/ir-headroom-20261103`. The user reduced serial admission
and its runtime reserve by 10 decimal GB: policy schema 3 requires
32,949,672,960 bytes (about 32.95 GB)
at the start and reserves 24,359,738,368 bytes (about 24.36 GB) during execution.
The working budget remains 8 GiB. Nested workers inherit that admission and
continue enforcing the reserve, including stronger caller floors. The accepted
pair reports 7.09 GB fresh and 1.97 GB cached decreases, within the 8 GiB forecast.
Reported minima are 30.85 GB and 33.65 GB; independent two-second samples reach
30.71 GB and 33.65 GB. Both stay above the 24.36 GB reserve. Filesystem activity
outside the runner and non-atomic samples limit these measurements. Raw AIR
needs no manual cleanup wrapper.

Unchanged upstream `hello_libc.zig` and the C fixture execute in all three modes;
the C fixture's six paired cases and 66 call/heap observations remain separate.
The ABI gate passes 60 cases. The frozen FMA canary retains 29 exact-result
checks and 8,192 LLVM-paired observations. In the accepted legacy route, Fibonacci emits `start.main`
through composed selection, then fails to link because 13 required private
symbols are omitted despite having definitions in the captured IR. The unchanged
program retains one LLVM reference execution and zero local executions. Its
isolated arithmetic body passes 31 local/LLVM observations, which does not prove
whole-program execution. LLVM IR construction, the system linker/CRT and libc
remain external dependencies of that route.

The [scalar cleanup](evidence/scalar_startup_cleanup_20261103.json) retains the
13 original source probes, performance baselines and required evidence. The
[audit input migration](evidence/candidate_facts_retention_20261103.json) replaces
historical raw descriptors with 74 MB of exact checked semantic facts, reducing
retained input allocation by 3.85 GB. Audit replay preserves the entire candidate
table and selected mode facts. Current authenticated production AIR remains
pinned. Obsolete generated copies and a source copy exactly present in Git
history are retired without archives. The latest
[generation cleanup](evidence/ir_headroom_cleanup_20261103.json) retires 3.92 GB
of superseded AIR after the complete fresh replacement proof, making room for
the cached run. Both runs now pass; old metadata and hashes remain. The retired
checkout's dependency links are removed while their target repositories remain.
The subsequent [dependency-coverage slice](evidence/dependency_coverage_focused_20261104.json)
at `dad027d9`, including the earlier attribute-group work, is provisional.
Bounded metadata, typed constants and parameter attributes now establish complete
reference coverage while unsupported forms remain conservative. Raw metadata roots
remain live even when constant merging cannot rewrite them. The separate
`85e892f3` repair keeps inferred function attributes before trailing metadata,
fixing invalid LLVM IR. All 1,756 units, 13 structural checks, readiness and
400 LLVM-backed observations of locally optimized IR pass. Fibonacci now selects
34 functions and 16 globals/aliases, matching LLVM after serialization-only SSA
normalization, and still rejects its aggregate alloca with zero local executions.
Cumulative full integration is next, followed by bounded 16-byte and 24-byte
frame storage. Accepted counters remain unchanged; see [next steps](next_steps.md).
