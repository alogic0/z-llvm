# Current state

The accepted record is [accepted_status.json](accepted_status.json). The block
below is generated and checked by `zig build check-docs`; regenerate it with
`zig build check-docs -- --write` after an explicitly accepted evidence update.

<!-- accepted-status:start -->

Accepted revision: `d4403016c8da556487d96cdb86223182e169600c`; tree: `0b7f9e73a2412b4d48c6ee7541139aaf618f2d58`.

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

The [allocation-padding repair](evidence/allocation_padding_acceptance_20261103.json)
passes all 17 integration subgates. Struct fields now advance by allocation size: the
field after `i24` starts at byte 4 and the field after `x86_fp80` at byte 16. Four
permanent native regressions pass 768 local observations against 384 LLVM references
across direct/release routes in three modes. The 1,662 unit tests and focused
60-case ABI gate pass. Symbolic global-data helpers are present; their integration
remains a separate work item.

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
payload into the cache. The earlier accepted fresh/cached infrastructure pair
proves ownership transfer and equivalent records; the current scalar-source
checkpoint reuses authenticated exports and reruns executions. It does not claim
a new fresh/cached comparison. Nested workers inherit the original serial
admission and enforce the unchanged reserve and 8 GiB forecast. Raw AIR does not
require a manual cleanup wrapper.

Unchanged upstream `hello_libc.zig` and the C fixture execute in all three modes;
the C fixture's six paired cases and 66 call/heap observations remain separate.
The ABI gate passes 60 cases. The frozen FMA canary retains 29 exact-result
checks and 8,192 LLVM-paired observations. Fibonacci advances through the scalar
operations but remains blocked at a global-copy destination with zero local
executions. LLVM IR construction, the system linker/CRT and libc remain
external dependencies of that route.

The [scalar cleanup](evidence/scalar_startup_cleanup_20261103.json) retains the
13 original source probes, performance baselines and required evidence. The
[audit input migration](evidence/candidate_facts_retention_20261103.json) replaces
historical raw descriptors with 74 MB of exact checked semantic facts, reducing
retained input allocation by 3.85 GB. Audit replay preserves the entire candidate
table and selected mode facts. Current authenticated production AIR remains
pinned. Obsolete generated copies and a source copy exactly present in Git
history are retired without archives. See [next steps](next_steps.md) for
the symbolic global-address/initializer/relocation slice. Historical checkpoints
remain under the roadmap and evidence directories.
