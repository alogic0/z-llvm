# Shared validation library adoption, 2026-11-05

Implemented and validated on x86-64 Linux with Zig 0.17.0.

| Provider | Version | Committed revision |
| --- | --- | --- |
| zig-process | 0.6.1 | `e9fcfccecc84f44a362b12de1bee78258b1e811f` |
| zig-test-support | 0.2.0 | `f0f54d4e8cb649af7673ca498f259b6b2f9aa25e` |

Each provider has its implementation plan and results under `docs/plans`.
The copied source files are verbatim and checked by
`tools/vendor/process.SHA256SUMS` and `tools/vendor/test_support.SHA256SUMS`.
The support provider now vendors process source with a commit and digest ledger;
its former dependency archive was removed. No archives were created.

## Changes

Linux child observation, launch acknowledgement and stop grace use bounded ppoll
readiness waits. Exit wakes immediately; intervals of at most 10 ms retain token
and std.Io cancellation checks under the original deadline. Process ownership,
group signaling and exact-child reaping remain with the process provider.

The support provider adds atomic file/JSON publication, append-safe owned logs,
file-backed command reports, streaming SHA-256, permissive string extraction,
sorted-key serialization and structural JSON equality. Atomic writes promise
visibility, not power-loss durability; cleanup on failure is uncancelable and
best effort. Existing nonempty-string entry points retain their behavior.

z_llvm delegates these mechanisms to the providers. Its benchmark's indefinite
pidfd wait is removed; launch and execution share the configured timeout. Exit
codes, log paths and primary/cleanup diagnostics remain consumer policy. Typed
JSON equality distinguishes number tags without floating-point coercion.
Measurements now identify `zig-process-0.6.1-readiness-v2`, because launch waiting
and timeout handling changed. No cross-engine speedup is claimed.

The new report uses u64 elapsed nanoseconds. An independent minimal reproducer
confirmed an installed Zig 0.17.0 Threaded Future allocation/alignment problem
with an i128-containing result. The delivered report passes asynchronous await
and cancellation tests; the installed toolchain was not modified.

## Validation

| Check | Result |
| --- | --- |
| zig-process `test check`, Debug and ReleaseSafe | 31/31 cases in each profile; final Debug reused four already-passing capture-failure cases |
| zig-test-support `test example`, Debug and ReleaseSafe | 25/25 tests and extended example in each profile |
| Isolated support package from copied source, private cache | Passed in Debug and ReleaseSafe; temporary copies/cache removed |
| Consumer `verify-validation-sources real-program-policy-tests` | 23/23 tests in Debug and ReleaseSafe |
| Frozen candidate replay | 21,117 rows, 100 selected; TSV and complete audit byte-identical to the preceding accepted replay |
| Standalone unchanged `hello_libc` program | Three reference executions, three local executions, three matching modes; passed |
| Formatting, source digests and diff whitespace | Passed |

The consumer suite includes an explicit-output measurement timeout regression.
An existing descendant test initially assumed terminal state immediately after
SIGKILL. It now observes exit/zombie state under a two-second deadline, matching
the provider's contract: the leader is joined, while grandchildren receive the
group signal and are reaped by their own parent. A surviving descendant fails.

Raw logs, command records, candidate outputs and the program report are retained
under `local-state/validations/shared-libs-20261105/`. The program report includes
the provider revisions and verified tool-source hashes. Runs preceded the consumer
commit; their recorded source hashes describe the validated implementation.

| Artifact under that directory | SHA-256 |
| --- | --- |
| `policy-debug.log` | `b56ba7ad8b2bfb059a5ff3afa4a4a427766220b66efaa85cd9ffd5c4696306f0` |
| `policy-safe.log` | `193d3757552f589719ef0afbe56a49ee1dd34cda44448d15e90a0ef3fe06ad12` |
| `candidates.tsv` | `847e014b2abab0800d0df690ef324dc5fa01299dcf60645b4dc55ca406fe2a31` |
| `candidates.audit.json` | `ae13c654360362f4574b16519ba81857721b79f4c394935c9ba545d126e7ddf0` |
| `hello/report.json` | `19fa8bfd8b5dd1ebb0c06430e4a5bf93345bb2aca214621c3d0efc2a198b53e0` |
| `hello.log` | `12262d91cbc41000373ae5acaed66a5a7442f3e111baa0598670b0f704264166` |

Compiler sources, build configuration, Fibonacci acceptance and disk reserves are
unchanged. The compiler binary remains
`1aefcf52084a5ac2f2c65f8790bd221264fbb30c431684c3d628f9fc26e8a1e4`.
The long 17-gate compiler qualification and frozen performance matrix were not
rerun for this helper adoption. The existing untracked scratch probes are retained.
