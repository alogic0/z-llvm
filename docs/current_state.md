# Current state

The accepted record is [accepted_status.json](accepted_status.json). The block
below is generated and checked by `zig build check-docs`; regenerate it with
`zig build check-docs -- --write` after an explicitly accepted evidence update.

<!-- accepted-status:start -->

Accepted revision: `db272521bfcd49fae366985fa47a0ff5ef58dc27`; tree: `2de39921e5dbef2335a7687b01edffd3b73f4d8c`.

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

The accepted [global-memory checkpoint](evidence/global_memory_acceptance_20261103.json)
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
payload into the cache. The current pair authenticates three new exports and
reruns execution checks on cache hits. At the user's direction, serial admission
now uses a fixed 32 GiB reserve plus the existing 8 GiB working budget: 40 GiB
(about 42.95 GB) free at the start. Nested workers inherit that admission and
continue enforcing the reserve. Reported fresh/cached free-space decreases are
5.86 GB and 2.16 GB, within the forecast. Raw AIR needs no manual cleanup wrapper.

Unchanged upstream `hello_libc.zig` and the C fixture execute in all three modes;
the C fixture's six paired cases and 66 call/heap observations remain separate.
The ABI gate passes 60 cases. The frozen FMA canary retains 29 exact-result
checks and 8,192 LLVM-paired observations. Fibonacci selection advances through
the scalar and global-memory operations but stops at a `fastcc i1` call-return
width with zero local executions. LLVM IR construction, the system linker/CRT and libc remain
external dependencies of that route.

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
the exact boolean call-return slice. Historical checkpoints
remain under the roadmap and evidence directories.
