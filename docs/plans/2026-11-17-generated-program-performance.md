# Generated-program performance against LLVM

The independent reviewer accepted M1 at `a27b8e86` and authorized M2 for
x86_64-linux-gnu. The implementation owner measures the unchanged compiler
core `c32ba3cf`. The reviewer owns the decision to open M3.
[Milestone decisions](2026-11-17-preopt-qualification-performance-self-rebuild.md)

## Frozen population and comparisons

Use all five members of `test/behavioral/performance_manifest.json` at SHA-256
`f0137fba1d79f2c6ac276e0c32d9ad933f43b8d72bc67cc815a86148de76329a`.
Check its ten individual source/driver hashes. The original IR is identical for
all four routes. For memset, append the definitions from the second module to
the first, as in the fixed-program baseline. Retain the resulting input hash.

| Workload | Behavior observed | Calls per timed process |
| --- | --- | ---: |
| arguments_branches | Signed division, shift, branch and merge | 35,651,584 |
| loops_memory | Bounded loop carrying a value through a stack slot | 35,651,584 |
| nested_calls | Three functions with repeated internal calls | 35,651,584 |
| register_pressure | Twelve overlapping integer values and an XOR reduction | 35,651,584 |
| memset | Three runtime functions and six compositions, including checked fills and pointer returns | 5,914,624 |

For each scalar input an independent arithmetic model specifies the 272 signed
outputs and the repeated-call digest. The memset semantic driver checks all
buffer bytes, return pointers and live values across 1,442 observations. Its
two bounds failures must terminate with SIGILL. Freeze both stdout hashes per
workload from the earlier LLVM rows in
`docs/evidence/composed_byte_loops_performance.json` (file SHA-256
`a419b629c6c75935c9eefacd3e5650d7fbc494fb86f32f7ebae2e1c7475166db`).
Every normal process must exit zero with empty stderr and expected stdout,
including every warmup and timed sample. Preserve actual failures and partial
results. A failed correctness check prevents a completed comparison.

| Route | Optimization and object generation |
| --- | --- |
| local-fast | `--passes=zig-release-fast-accepted`, then local x86_64 object emission |
| llvm-O3 | LLVM 22 clang `-O3` on the original IR |
| local-small | `--passes=zig-release-small-accepted`, then local x86_64 object emission |
| llvm-Oz | LLVM 22 clang `-Oz` on the original IR |

The local emitter uses `--emit=obj --generic-cfg-selector --codegen-reachable
--report-all-codegen-failures --target=x86_64-unknown-linux-gnu` and a selection
owner report. Admit each actual input at its file length plus one. Bind each
optimizer output to the emitter's input by hash. LLVM verifies IR outside the
timing interval. Clang receives `-x ir --target=x86_64-unknown-linux-gnu
-march=x86-64 -mtune=generic -fno-pic -fno-pie -fno-lto -g0`. Both comparisons
use baseline x86_64, static linking, a stripped executable and disabled LTO.
Compile each distinct Zig semantic/runtime driver to a separate common object
once with the pinned SDK in ReleaseFast. Link those exact bytes to every route
with the same SDK/linker options and input order. Record all argv, outcomes,
hashes, providers and executable ELF headers.

## Sampling and interpretation

Run native executables serially on logical CPU 2. Record CPU model, affinity,
SMT sibling, frequency policy and host load. Preserve normal boost and OS page
cache. Perform two warmup blocks followed by twelve measured blocks. Rotate
the starting workload each block. With routes numbered in table order, cycle
the four balanced orders 0132, 1203, 2310 and 3021 for each workload. Each
route occupies every within-workload position three times in the measured set.
Route timing covers process launch, the common driver, generated code and reap
on a monotonic clock. Compilation, linking, ELF inspection, verification and
output hashing occur outside timing. Run without profiling or tracing.

Record all 40 warmups and 240 measured durations, the scheduled order and
per-process outcome. Report median, MAD, min/max and paired local/LLVM ratios
by workload and mode. Retain outliers. Report exact object and timed executable
file sizes, allocated executable sections, named text/rodata/data and NOBITS
bytes. Retain section listings and object disassembly for interpretation.
Rank follow-up proposals from observed gaps with a specific implementation and
re-measurement boundary. Fast and Small share passes in this compiler.
Claims apply to this fixed input set, linked drivers and host conditions.

## Admission, validation and storage

Evidence root: `local-state/validations/generated-program-performance-20261117/batch-01`.
The owner writes `retention.md` here and in every checked stage before launching
it. Freeze this protocol, actual compiler build receipt, complete SDK/library
and provider identities, source/driver/oracle membership and measurement
procedure before comparing outputs, sizes or samples.

| Stage | Owned temporary products and consumers | Release condition |
| --- | --- | --- |
| Build and admission | Private SDK caches and managed ReleaseFast backend pipeline. Admission authenticates core, backend, SDK and providers. | Release backend after its final object or cumulative-gate consumer. |
| Measurement tool | The instrument pipeline builds and hashes the native runner, exercises the scalar oracle and balanced order in Debug and ReleaseFast, and supplies the same binary to admission, preparation and timing. | Release after sampling and executable identity verification. |
| Program preparation | Common driver objects, verified IR, program objects and linked binaries under a retained checked workspace. | Release after correctness, all samples, ELF inspection and report validation. |
| Sampling and analysis | Native measurement tool and private caches. | Collect after checked success. Preserve commands, stdout/stderr, samples, identities, disassembly and size reports. |
| Cumulative preservation | Reuse a prior check only on complete relevant identity. A different backend requires a fresh serial distribution gate using the selected executable, pinned emitter and managed output roots. | Close stage and any owned default install after its last consumer. Preserve the serial summary and individual gate receipts. |
| Final verification | Check the matrix, original inputs, oracles, identities, nine current manifests, 17 independent holds and owned workspace inventory. | Release final consumers, collect immediately and record actual receipts. |

The launcher and collector retain their independently owned bootstrap caches.
Ordinary binaries and caches acquire no new pins. Preserve failed receipts and
diagnose their scratch before ordinary release. Retry busy collection at the
next idle boundary. The result commit freezes M2 for independent source/log
review. Substantial optimizer changes require a separately reviewed slice.

The native entry point is `tools/measure_preopt_programs.zig`. Its `oracles`
command checks the model against the frozen LLVM outputs. Under a managed
pipeline, `prepare --compiler EXE --zig SDK` builds all four common driver
objects and the twenty pairs of semantic and timed executables. A separate
managed `sample --prepared REPORT` reads that preparation report and verifies
the linked images before and after the complete schedule. The admission receipt
binds the implementation binary used by all three commands.
