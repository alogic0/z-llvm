# Validation performance implementation

Date: 2026-11-09. Implements the measured delivery in the
[validation performance plan](../plans/2026-11-09-validation-performance-improvement.md).
The [machine-readable record](validation_performance_20261109.json) binds the
commands, source snapshots, compiler receipts and retained evidence.

## Changes

Explicit `ZLLVM_EXE`, `ZIG_EMITTER` and `ZIG_SOURCE_DIR` selections now reach
`hello_libc`, the C/native suite and the other supported nested consumers.
The input-program runner receives only its supported compiler/emitter options.
Imported behavioral, memset, memcpy and byte-loop canaries also use the selected
compiler. Explicit selection skips nested installation of the default compiler.
Reports retain selected and resolved paths, executable hashes, the Zig pin and
the actual compiler build identity. Program validation now checks the audited
emitter hash in addition to its version and source revision.

`tools/build_validation_compiler.zig` builds one requested mode in a separate
prefix using Zig's dependency cache. Its receipt records source/dependency and
Zig library hashes, target, CPU, effective options and the produced binary.
It preserves the original producer receipt after an unchanged cached build and
repairs missing or corrupt installed binaries. Arbitrary caller-supplied
compilers remain explicitly unrecorded when no receipt exists. Build receipts
describe artifacts; they do not authorize reuse of validation results.

The execution-control gate compiles its linked harness once per function and
input mode, then relinks it separately with every subject object. Executable-mode
assembly retains `std.start`; assembly and linking use the same pinned emitter,
target, mode and native linker, with compiler-rt and without LTO. Source/object
hashes and the emitter/library identity are checked. The independent reference
still compiles separately. Wrong-symbol rejection requires a completed undefined
symbol failure naming the expected function. Semantic controls require completed
exit 1 with `OracleMismatch`. `--fresh-harness` retains the previous compilation
route, and `--mode` supports bounded comparisons; the default still runs all modes.

Command reports serialize each immutable command once and atomically publish the
same complete `commands.json` after every command. Successful, failed, timed-out
and launch-failed records match the previous JSON bytes. There is no new journal
or change to process ownership and cancellation. An optional
`ZLLVM_INTEGRATED_OUTPUT_ROOT` creates an exclusive durable directory, preserving
partial evidence on failure and avoiding a temporary-directory retention watcher.
The ordinary temporary-output lifecycle remains available.

## Measurements and preserved outcomes

Raw evidence is retained under
`local-state/validations/validation-performance-20261109/` (`E` below).
Native and complete harness comparisons use one full run per route. Publication
and scheduling probes use three repetitions. These are scoped measurements;
historical concurrent batch-06 timings are not a comparable end-to-end baseline.

| Workload | Baseline | Candidate | Evidence / scope |
| --- | --- | --- | --- |
| Complete C/native suite | Debug 1,051.97 s | ReleaseFast 179.12 s | `c-debug.time`, `c-fast.time`; all three input pipelines |
| Compiler calls within that suite | 950.21 s summed | 80.09 s summed | Included in the suite budget, not additive savings |
| 2,801 growing command publications | Median 24.706 s | Median 1.218 s | `publication-comparison.json`; three replays, exact final bytes |
| Linked harness rebuild | Approximately 11.5 s | Object relink 0.05–0.06 s | `harness-assembly-prototype/`; compilation 11.52 s plus assembly 0.51 s once |
| ReleaseFast seven-function control gate | 353.26 s | 169.13 s | `harness-fresh-reuse-comparison.json`; 7,596 observations and 18 controls |
| Three large-CFG compilations | Sequential median 6.006 s | Concurrent median 2.132 s | `scheduling-summary.json`; three alternating rounds, exact objects |

The Debug native suite used 980.74 s user / 59.95 s system CPU, with maximum
RSS 520,832 KiB; ReleaseFast used 130.11 / 36.40 s, with maximum RSS 527,396 KiB.
Both retain **76 populations**, **2,200,836 local observations** and
**1,100,418 references**, plus the C fixture's paired executions and call/heap
checks. Their 2,837 command outcomes match after normalizing selected paths.
All 237 optimized IR and 459 ownership outputs are byte-identical. Of 465
successful object outputs, 456 match exactly. Nine reviewed objects differ only
in unused upper halves of i32 all-ones materializations in RSI: the variadic
fixture consumes `int32_t`, and the atomic fixture consumes 32-bit operands.
Disassembly, object metadata and targeted byte comparisons exclude other changes;
all independent observations and guards match. Full Debug coverage is retained.

The final integrated native run matches the ReleaseFast baseline's outcomes,
counts and all 1,161 successful compiler artifacts byte-for-byte. The complete
harness population passes **21 function/mode pairs**, **22,788 observations** and
**54 negative controls**, using 21 harness compilations and 21 assemblies.
Fresh and reused ReleaseFast harness routes have identical subject objects,
observations and control counts. No artifact is reused across functions, modes
or validation runs.

The remaining **315 identical-argument compiler calls cost 20.09 s**, included
in the 80.09 s ReleaseFast compiler subtotal. A native result cache is deferred:
that remaining budget does not justify new identity, invalidation and retention
machinery. Every direct object, independent ownership route, mode-specific
optimizer, reference, link, execution and CLI/environment equivalence check still
runs. No cross-run result cache is introduced.

## Reporting and scheduling decisions

The publication replays write 2,844,179,099 logical bytes each, ending at
2,033,667 bytes. Incremental serialization removes repeated encoding; complete
atomic publications still write a growing file. Final JSON is byte-identical to
the retained 2,801-command history. Existing atomic-write and interruption policy
is retained, including complete process outcomes.

Telemetry collection averages 1.73 ms without AIR metadata and 1.99 ms with it
in separate 100-sample probes. Three replays of 2,396 growing samples, representing
the retained 80-minute run, have median serialization 32.19 s and publication
1.48 s, writing 4,204,094,678 logical bytes each and ending at 3,506,573 bytes.
The retention probe handled 2,788 moved-to publications and a nine-file final
scan, copying 3,903,396,293 logical bytes. Its watcher consumed 100.62 s wall,
77.65 s user and 22.77 s system CPU; the concurrent instrumented producer took
100.34 s wall, 88.26 s user and 11.23 s system CPU. One replacement/copy race was
recovered by the final scan; the final nine copies match. Overlap and probe
instrumentation prevent treating these figures as isolated end-to-end savings.

Durable output removes the need for that watcher on selected runs. Telemetry
sampling remains every two seconds with headroom and AIR identity fields; its
small measured budget does not justify a journal or sampling redesign here.

The bounded scheduling probe runs three identical large-CFG object compilations
sequentially and concurrently over three alternating rounds. All 18 objects
match the already executed native baseline, with no timeouts. Maximum individual
child RSS is approximately 496 MiB in both routes; memory-pressure snapshots and
CPU measurements are retained. This supports retaining the existing three-mode
concurrency for the bounded workload. It does not establish safe concurrency for
whole-compiler attempts or predict long AIR export latency. No scheduler change
is adopted.

## Bounded compiler investigation

LLVM extraction retains an original compiler function,
`codegen.loongarch.Assemble.parseInstruction`, from the unchanged 443,624,107-byte
compiler IR. The 9,955,953-byte diagnostic has 20,976 blocks and 133,719
instructions and independently verifies with LLVM. A 90-second interrupted run
records wall 90.26 s, user 78.36 s, system 11.87 s and peak RSS 3,211,756 KiB.
The original input, extraction and compiler hashes, invocation, events and
`perf.data` are retained.

`cycles:u` sampling at 199 Hz with frame-pointer user callchains records 17,917
samples, zero reported losses and 1.05% unknown leaf samples, with decoded caller
stacks. Allocation planning accounts for 35.71% of self samples; boundary
liveness is 9.85%, dependency queries 8.37% and dependency validation 6.50%.
All 486 retained event records have complete sequential identifiers. The last
event is an original-form selection retry at 27.293 s; selection remains active
at interruption. There is no completed profile or verified object.

The bounded next investigation is to count allocation-plan interval/site scans
and repeated dependency validation while preserving frame and ownership guards.
No compiler backend algorithm changes, larger timeout, complete census or
production replay are credited by this diagnostic.

## Validation and evidence reuse

Debug and ReleaseSafe each retain 2,043 compiler unit tests and 24 structural
checks. Final policy tests pass 36 per mode and profiling/interruption tests pass
two per mode. The tests cover independent selections and paths with spaces,
receipt/binary replacement, library content and membership changes, corrupt or
missing harness objects and byte-identical command publication. Real path probes
cover independent compiler, emitter and source selection and their combination.
Eight provenance controls reject wrong pins, wrong versions, same-version wrong
emitter hashes and modified upstream fixtures. Compiler repair probes preserve
size/mtime while corrupting content and exercise missing binaries. Durable-output
controls retain failed runs and reject existing roots.

The only modified `src` file is the execution-control gate, which is not a
compiler dependency. Rebuilding into separate final prefixes produces identical
Debug and ReleaseFast compiler hashes. Units, structural checks and complete
Debug native execution are reused only for their unchanged compiler inputs.
The changed validation procedures receive fresh policy, full distribution and
fresh/cache coverage under the gate/cache infrastructure row of
[validation tiers](../validation_tiers.md).

The corrected fresh serial distribution run passes **all 17 gates** in
2,964.68 s (49.41 minutes). The required-hit replay passes all three modes;
the unchanged comparator matches all **45 canonical real-row records** after
extracting the three complete raw row blocks from the full log. The complete
frozen source snapshot verifies after these runs. The integrated suite uses
explicit ReleaseFast compiler and nondefault pinned emitter/source selections.
The real-row CLI keeps its existing canonical-emitter-path requirement.

The first integration attempt passed nine gates before rejecting an emitter
alias at that existing path guard; it exported no AIR. It is retained separately.
An initial harness-object prototype did not persist the executable root object;
the successful executable-assembly route and its controls supersede it. Failed
prototype and retention-copy diagnostics remain labelled in the evidence root.

The fresh full run ends with 59,200,307,200 free bytes, above the unchanged
11,410,065,408-byte reserve; admission remains 20,000,000,000 bytes. Original
inputs, prior accepted evidence, authenticated AIR generations, shared object
bundles and thirteen scratch probes are preserved. No archive or cleanup is
part of this delivery. The complete compiler-selection goal remains paused;
accepted **8,664/8,928** compiler and **285/455** runtime counts are unchanged.
