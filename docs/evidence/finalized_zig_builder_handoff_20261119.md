# Upstream Zig `cat` through the finalized builder and native ELF linker

Two cold builds of unchanged upstream `test/standalone/simple/cat/main.zig`
produced the same 6,526,422-byte executable. Its SHA-256 is
`2719a3528730fd8e4732c41170de9a98b1ad27bd073766d1e0ac070caead5e12`.
Both passed six byte-for-byte I/O checks, covering empty and binary input,
filenames with spaces, mixed files and stdin, and repeated stdin at EOF.
The source is Git blob `bc894d3881fd59658dc17ca65afc3dd934226560` from
Zig `1c08b09d`. The seed driver used in these runs still links LLVM.
[Original cold build](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/cold-app-05/compile-result.json)
· [Independent build](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-handoff-positive/observations.json)
· [Independent executions](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-handoff-positive/oracle.json)

## What produced the executable

The ordinary driver ran `zig build-exe` in ReleaseFast for baseline
`x86_64-linux-gnu`, with `-fllvm -fno-libllvm -fno-lld` and an explicit
`--zllvm-object-provider`. It serialized the finalized Zig builder, then ran
the local optimizer and local object emitter for both the application and
the compiler runtime. The historical C++ path called libLLVM's bitcode parser
and module printer. The new run observed neither call for the application.
The raw and optimized complete inputs passed an external LLVM 22 verifier.
The link used Zig's native ELF implementation.
[Control on the previous route](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-boundary-stock-03/observed.json)
· [Successful compiler run and corrected path audit](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/cold-app-05-audit/report.json)
· [Independent verifier results](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-handoff-positive/external-verifier.json)

| Artifact | Size | SHA-256 |
| --- | ---: | --- |
| Application object, 1,833 functions | 3,009,064 | `173ba5544050577c0d7faaac50984006decc28cb9f7f8891e6b9b8278b4fc6b2` |
| Actual cold runtime member, 921 functions | 3,061,992 | `253ddd542c35741e37f65593c03d7589288d7d48adb12f3e00ebb30fde86fa3c` |
| Original replay runtime object, 921 functions | 3,061,936 | `b4f14c7a9610148587b9dacb04ddf9d461162bf3f8e054803502cca3e2924a5e` |

The native link named the application object and an archive with SHA-256
`f9610227de4ccd6b5a0f6fecc070f56fb46daa492f149241aeafc3043227314a`.
The native archiver read the runtime object, and the native linker read
the archive and application object. The application's `_start` corresponds
to the ELF entry address `0x1001000`. The executable is static and the
link had no external libc or CRT inputs.
Eight uniquely occurring function bodies from the application object match
bytes in the executable. The archive has one member, whose bytes match the
actual runtime emitter output. An application-only link produced the exact
same executable. Separate native callers therefore establish the runtime
arithmetic coverage. Both full runtime objects matched all 17 LLVM reference
outcomes. Their code, data, thread-local data and relocations are identical.
The independently reduced unsigned-to-double routine matched 4,545 reference
conversions.
[Linked function bodies](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-handoff-positive/linked-code.json)
· [Native archive, link inputs and executable entry](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/runtime-shifts-02-link-02/report.json)
· [Actual archive member](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-numeric-cold/archive.json)
· [Application-only link](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-runtime-contribution/result.json)
· [Runtime section comparison](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/cold-app-05-ir-diff/comparison.json)
· [Cold runtime calls](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-numeric-cold/observed.tsv)
· [Original runtime calls](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-numeric-runtime/observed.tsv)
· [Reference calls](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-numeric-reference/observed.tsv)
· [Conversion regression](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-conversion-fixed/results.json)

## Cache identity and failure handling

With one shared pair of caches, `zig run` built and ran distinct native
and selected-provider executables. An identical warm invocation reused the
selected executable. Replacing the provider's contents at the same path
caused the real target emitter to reject an undefined IR value. Restoring
the bytes reused the original executable. Moving those same provider bytes
to a second path reran the optimizer and emitter and produced the same ELF
under a different cache key. The reviewer identified the actual executable
run for each successful attempt.
[Six cache transitions and object provenance](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-handoff-cache/observations.json)

In cold failure tests the real target optimizer exited zero. The emitter
reported `UnknownValue`, exited 1 and produced no object bytes. Zig exited
1 before the target link. An absent final path stayed absent. A pre-existing
executable kept all 8,119,577 bytes, mode 0775 and its original SHA-256.
The reviewer reran all six I/O cases against the preserved executable.
This corrects an earlier driver revision that truncated the destination.
[Original truncation](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-front-failure/observed.json)
· [Absent destination control](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/runtime-shifts-02-fault-absent/result.json)
· [Existing destination control](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/runtime-shifts-02-fault-existing/result.json)
· [Independent existing-destination observations](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-handoff-fault-existing/observations.json)
· [Six post-failure executions](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-handoff-fault-existing/preserved-oracle.json)

Zig's upstream standard-library test runner also compiled and executed
through this provider. All 75 selected tests passed, including thread join,
detach and thread-local storage. The compile invoked two real optimizer
processes and two real object emitters.
[Native thread test outcomes](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-thread-runtime/result.json)

The reviewed seed driver is `5c6c457c` on Zig patch `a38ad006`. The
ReleaseFast helper is `e1cfa98f` on backend patch `a54687fa` over
`3a9b6d8f`. The initial cold run's outer validation returned 1 after the
program had built and passed its tests. It compared a relative compiler
argument with an absolute observation. Its successor audit resolved the
original paths under their recorded working directory and checked all four
real invocations. Package qualification and two-generation results have
their own evidence requirements.
[Exact driver build patch](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/driver-build-04/driver.patch)
· [Frozen backend patch](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/runtime-shifts-02-source/combined.patch)
· [Corrected path comparisons](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/cold-app-05-audit/operand-paths.json)
· [Dependency removal plan](../plans/2026-11-19-x86_64-releasefast-llvm-dependency-removal.md)

Before publication, the reviewer compared the entire frozen Zig checkout
diff with the build receipt. The earlier handoff cited the development
snapshot `f6779ada`. Between that snapshot and the tested build, the
implementer added rejection of incremental compilation and the new
linker, updated the command-line diagnostic and renamed the staged ELF
output handle. The original build script captured the full patch before
compilation and compared it again after compilation. Its recorded binary
hash matches the executable used for the cold and failure controls.
[Build input identities](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/driver-build-04/inputs.txt)
· [Built driver identity](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/driver-build-04/driver-identity.txt)

## Integration on the frozen backend

All 17 serial distribution gates exited zero. The three fresh AIR exports
covered ReleaseFast, ReleaseSafe and ReleaseSmall. For each of the 237
canary populations the reviewer checked the reference and local counts
against the registry. All three mode rows matched. The integrated
executable checks used helper `e1cfa98f`. The validation checkout
matched full backend patch `a54687fa` before and after the run.
[Terminal validation result](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/runtime-shifts-02-tier3/report.json)
· [Subgate exits and fresh exports](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/runtime-shifts-02-tier3/distribution-all.log)
· [Expected canary populations](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/runtime-shifts-02-tier3/registry-populations.tsv)
· [Native and reference observations](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/runtime-shifts-02-tier3/integrated/unchanged-upstream-c/report.json)
