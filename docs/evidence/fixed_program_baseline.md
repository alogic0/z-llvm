# Fixed-program performance baseline

Protocol v1, frozen 2026-09-26 before measurement. This is the remaining section
5b deliverable of the [architecture plan](../roadmap/architecture_refactor_plan.md).
It measures the current compiler; it is not a before/after speedup claim and
does not change accepted counters.

## Frozen matrix and procedure

The [manifest](../../test/behavioral/performance_manifest.json) freezes source and
driver SHA-256 hashes for five workloads: argument-dependent branches,
initialized loop memory, nested calls, register pressure, and the combined
three-definition/six-composition memset module. The combined module uses the
same exact concatenation as the existing memset canary (family, newline,
compositions starting at its first `define`). No fixture is rewritten to improve
its measured result.

Three routes are measured independently:

- `direct`: prebuilt ReleaseFast z_llvm, original IR, composed selector.
- `release-o3`: the same compiler runs `--passes=release-o3`, then a separate
  process emits the resulting IR with the composed selector.
- `llvm-O3`: clang-22 compiles the original IR with `-O3`,
  `--target=x86_64-unknown-linux-gnu -march=x86-64`.

Local codegen explicitly uses `--target=x86_64-unknown-linux-gnu` and
`--generic-cfg-selector`. Every emitted local definition must appear exactly once
in its owner manifest as `composed_block` or `composed_cfg`. Baseline x86-64 is
used without native CPU tuning; the original memset target attributes remain
intact and hashed. ReleaseFast describes the compiler build and Zig drivers,
not the local optimizer pipeline. The project revision, source tree hashes,
tool paths/binary hashes/versions, CPU model/features, affinity, frequency policy,
kernel, exact command arrays and generated input hashes are recorded per run.

Preflight identified `loops_memory/release-o3` as unsupported: the optimizer
exits 1 with `error: TypeMismatch` before producing IR. Its exact stage and
diagnostic are frozen in the manifest. It has no measured compile-time, runtime
or size result. Other failures, semantic mismatches, missing tools, unexpected
support changes and structural fallback fail the procedure.

The historical runner used Python 3's standard library. Its
[Zig successor](../../tools/fixed_program_baseline.zig) is documented in the
[tooling migration](../validation_tools.md); the measurements below retain their
original timing procedure. The runner performs builds, links, LLVM verification, semantic
comparisons and ownership checks before timing a workload. Scalar semantic
drivers compare all 272 original boundary/LCG results; the memset driver checks
1,442 observations plus both SIGILL bounds traps. Runtime-driver output must
also match LLVM before timing, and every timed execution must reproduce it.

Both semantic and runtime drivers are built with Zig 0.16.0, ReleaseFast,
`-target x86_64-linux-gnu -mcpu=baseline`, with separate object linking and no LTO.
The scalar runtime driver repeats the original 272 inputs 131,072 times
(35,651,584 calls), accumulating and printing the results. The memset driver
uses the original length/fill/offset grid for 4,096 rounds (5,914,624 calls),
checks returned pointers and accumulates live arithmetic and observed bytes.
The full memory oracle and trap subprocesses are outside the runtime metric.
All routes execute the identical driver and input sequence for a workload.

Timing uses monotonic `perf_counter_ns` around fresh subprocesses, with two
warmups and nine measured samples. Work is serial, pinned to one logical CPU;
route order rotates each repetition. OS page caches stay warm, with no forced
flush and no compiler result cache. The local two-step compile result is the
sum of measured optimizer and codegen process durations; both stages are
reported separately. Driver builds, linking, verification, hashing, ownership
inspection and Python bookkeeping are outside compile time. Process creation,
compiler startup and object output are included. Runtime is whole-process driver
wall time including startup, checks, checksum and final output; it is not an
isolated instruction latency. Frequency scaling and other host activity remain
possible sources of noise. Report median, minimum, maximum and median absolute
deviation (MAD), without outlier removal or a statistical significance claim.

Object bytes are exact file lengths. Executable code-section bytes sum ELF64
sections carrying `SHF_EXECINSTR`, cross-checkable in retained `readelf -SW`
output. Symbol tables and undefined references are retained with `readelf -Ws`.
Linked runtime executable sizes are recorded separately and never substituted
for object size. LLVM may call runtime helpers (including memset); their linked
implementation bytes are outside the input object's code-section size.
Object and optimized-IR hashes must remain identical across compile repetitions.

## Reproduction

From the repository root, using an available logical CPU (this host used 2):

```sh
/home/oleg/.zig/0.16.0/files/zig build -Doptimize=ReleaseFast \
  --prefix local-state/validations/fixed-program-baseline-20260926/compiler
python3 tools/fixed_program_baseline.py \
  --compiler local-state/validations/fixed-program-baseline-20260926/compiler/bin/z_llvm \
  --zig /home/oleg/.zig/0.16.0/files/zig --cpu 2 \
  --output local-state/validations/fixed-program-baseline-20260926/run-1
python3 tools/fixed_program_baseline.py \
  --compiler local-state/validations/fixed-program-baseline-20260926/compiler/bin/z_llvm \
  --zig /home/oleg/.zig/0.16.0/files/zig --cpu 2 \
  --output local-state/validations/fixed-program-baseline-20260926/run-2
```

Output directories must be new. Each retains metadata, all command streams,
original/optimized IR, objects, owner manifests, semantic/runtime executables,
raw measured samples and summaries. The second invocation repeats the same
procedure without rebuilding the measured compiler. Absolute tool paths may be
changed for another host; identities and host differences must then be reported.

## Results and validation

Both executions completed on source `fe6f1a0e` (compiler sources unchanged from
`eab54c12`), Zig 0.16.0 and LLVM 22.1.8, on an AMD Ryzen 7 7840HS, Linux x86-64,
logical CPU 2, `amd-pstate-epp` performance governor. The [identities](fixed_program_baseline/identities.json)
record exact source/tool/input hashes, host settings and both commands.
Versioned raw samples and summaries: [run 1](fixed_program_baseline/run-1.json)
and [run 2](fixed_program_baseline/run-2.json). Full streams and artifacts remain
under `local-state/validations/fixed-program-baseline-20260926/`, pinned in the
[retention list](tmp_retention_pins.tsv).

All 15 pairs have explicit outcomes: 14 supported, one optimizer rejection.
Each run checks 7,318 semantic observations and six bounds traps, with each
workload checked before its samples. It collects 126 compile-time and 126
runtime samples (plus warmups). Both runs
agree on source/input/tool identities, supported outcomes, owner manifests,
semantic outputs, object hashes and sizes. Every supported local function has
composed ownership. No metric is fabricated for the rejected pair.

First-run medians follow. Compile total is IR-to-object; optimizer/codegen
columns are stage medians (their sum need not equal the median of paired totals).
For LLVM, the codegen column covers the whole clang `-O3` invocation, including
its optimizer; no separate LLVM stage timing is inferred.
Runtime is per complete fixed driver invocation. All times are milliseconds;
sizes are bytes. Full min/max/MAD for every metric are in the raw reports.

| Workload | Route | Compile total | Optimizer | Codegen | Runtime ± MAD | Object | Code sections |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| arguments_branches | direct | 2.829 | — | 2.829 | 68.110 ± 1.575 | 816 | 116 |
| arguments_branches | release-o3 | 3.608 | 0.901 | 2.685 | 66.209 ± 2.326 | 816 | 116 |
| arguments_branches | llvm-O3 | 23.430 | — | 23.430 | 53.091 ± 1.489 | 616 | 22 |
| loops_memory | direct | 3.049 | — | 3.049 | 263.877 ± 5.107 | 816 | 127 |
| loops_memory | release-o3 | unsupported: TypeMismatch | — | — | — | — | — |
| loops_memory | llvm-O3 | 25.693 | — | 25.693 | 79.522 ± 0.437 | 720 | 124 |
| nested_calls | direct | 2.517 | — | 2.517 | 149.389 ± 0.515 | 920 | 88 |
| nested_calls | release-o3 | 3.248 | 0.826 | 2.297 | 155.327 ± 2.891 | 920 | 88 |
| nested_calls | llvm-O3 | 23.486 | — | 23.486 | 42.262 ± 0.428 | 712 | 59 |
| register_pressure | direct | 2.595 | — | 2.595 | 99.490 ± 1.257 | 896 | 199 |
| register_pressure | release-o3 | 3.309 | 0.894 | 2.448 | 100.381 ± 1.653 | 896 | 199 |
| register_pressure | llvm-O3 | 24.423 | — | 24.423 | 50.153 ± 0.436 | 1040 | 74 |
| memset | direct | 4.762 | — | 4.762 | 75.592 ± 0.388 | 1944 | 787 |
| memset | release-o3 | 5.962 | 1.170 | 4.800 | 75.673 ± 0.313 | 1944 | 787 |
| memset | llvm-O3 | 27.185 | — | 27.185 | 33.059 ± 0.419 | 1832 | 275 |

Second-run compile medians changed by -11.7% to +10.2%; runtime medians
changed by -4.9% to +17.5%. The largest runtime change was direct memset
(75.592 to 88.812 ms) despite an identical object and identical semantic output.
CPU affinity does not remove frequency, scheduling or shared-host noise; these
results establish a reproducible procedure and an observed range, not stable
performance rankings or an optimization improvement. No samples were discarded.

All four supported local optimized objects are byte-identical to their direct
counterparts. The LLVM memset object has an undefined `memset` helper reference;
the local objects do not. Its 275 code-section bytes therefore exclude that
linked helper, while runtime includes it. Process startup overhead and
the small fixed input population also limit generalization to larger programs.

The loop-memory optimizer rejection remains an explicit follow-up diagnostic,
not a completed optimizer capability. Its original fixture and exact error are
retained without modifying the workload to obtain a timing.

Validation: both full matrix executions pass; the ELF section parser agrees
with `readelf -SW` for all 28 supported objects across the runs. Python syntax
and summary-statistic checks pass, as do Zig formatting, documentation/link
validation and `git diff --check`. Checkpoint reuse verifies 1,376 unchanged
files from its 1,377-file source inventory; the sole existing-file difference
is the behavioral README documenting this runner. New measurement files are
validated independently. No compiler, existing driver/fixture, gate/cache
implementation, public compiler CLI, ABI or accepted-status record changed;
the matching correctness checkpoint supplies the existing Tier-3 evidence.

One preliminary attempt was stopped during driver preparation to replace
Python timeout polling with blocking process waits. It produced no accepted
samples; `preflight-interrupted/` retains that bounded diagnostic. Only the two
completed runs above establish this baseline. Section 5b is complete. The
subsequent [checked memcpy slice](composed_memcpy_family.md) records its completed
capability and comparison against this unchanged baseline.
