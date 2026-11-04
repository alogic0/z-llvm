# Current state

The accepted record is [accepted_status.json](accepted_status.json). The block
below is generated and checked by `zig build check-docs`; regenerate it with
`zig build check-docs -- --write` after an explicitly accepted evidence update.

<!-- accepted-status:start -->

Accepted revision: `9c7985e27078d18e4958eb63fb0c0011881c3cda`; tree: `0bbde5100847ce57f27eae68db8797afa91a83aa`.

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
These IR checks add no local whole-program execution. Full fresh/cache integration
remains pending, so the accepted checkpoint above stays unchanged. The isolated
retry passed nine stages, then exposed the export worker's fixed checkout path.
The fresh/cache pair now runs from the primary checkout after merging the focused
commits; the failed logs and both frozen snapshots remain retained.

The accepted [module dependency checkpoint](evidence/module_selection_acceptance_20261103.json)
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
payload into the cache. The global-memory pair authenticates three exports; the
boolean and array-stride checkpoints reuse them and rerun execution checks on
cache hits. The user has reduced serial admission and its runtime reserve by
10 decimal GB: policy schema 3 requires 32,949,672,960 bytes (about 32.95 GB)
at the start and reserves 24,359,738,368 bytes (about 24.36 GB) during execution.
The working budget remains 8 GiB. Nested workers inherit that admission and
continue enforcing the reserve, including stronger caller floors. Full fresh/cache
validation of the revised limits is pending. The earlier accepted pair reported
5.86 GB and 2.16 GB decreases under policy schema 2. Raw AIR needs no manual
cleanup wrapper.

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
[generation cleanup](evidence/global_memory_cleanup_20261103.json) retires 3.92 GB
of superseded AIR after verifying the accepted replacement and all payload hashes;
metadata and historical proofs remain. See [next steps](next_steps.md) for
numeric SSA serialization and dependency-reference coverage. Historical checkpoints
remain under the roadmap and evidence directories.
