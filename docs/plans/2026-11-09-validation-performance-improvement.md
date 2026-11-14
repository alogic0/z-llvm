# Project improvement plan for validation and compiler performance

Date: 2026-11-09
Status: measured delivery implemented and validated; conditional native caching
and scheduling/report-journal changes deferred by the measurements.
Review baseline: `ee1b8317767eb6de5443fd9850f8a0d6098b6aeb`.

Implementation results and remaining limits are recorded in
[validation performance evidence](../evidence/validation_performance.md).
All 17 integration gates and the three-mode fresh/cache comparison pass.
That delivery left accepted counters unchanged. The
[compiler-selection plan](2026-11-08-complete-compiler-selection.md) subsequently
completed, followed by all eight milestones of the
[compiler-object, behavior and self-rebuild plan](2026-11-11-complete-compiler-object-and-self-rebuild.md).
The [final acceptance](../evidence/compiler_behavior_follow_up_acceptance_20261113.json)
records the complete four-mode LLVM/local matrices for both final generations
and a normal-resource self-rebuild at backend source `dbf7ade0`.
The earlier [bounded compiler-throughput slice](../evidence/compiler_throughput.md)
validates faster preservation planning with identical plans and native artifacts.

## Objective and scope

Reduce the time needed to obtain a complete, trustworthy validation result.
Improve compiler selection, harness reuse, compiler throughput and report
handling while preserving independent references, negative controls and
reproducible evidence.

This is a follow-up to the completed
[project improvement plan](../roadmap/project_improvement_plan.md).
[Next steps](../next_steps.md) records the completed baseline and future work.
This performance delivery did not change accepted counters or replace compiler
acceptance. The phase descriptions below retain the original proposal and its
measurement conditions; completed results are linked above.

The proposed order is compiler-selection propagation and bounded profiling,
then harness reuse, followed by remeasurement before artifact caching,
scheduling changes or logging redesign. Apply the existing validation-tier
policy throughout.

## Existing workflow and observations

The reviewed workflow is:

```text
focused tests
  -> compiler builds
  -> native checks, units and readiness
  -> source freeze
  -> integration, census and production replay
  -> evidence verification and retention
```

Batch 06 launches integration, census and production replay concurrently.
The observations below come from retained runs under concurrent load. They
identify expensive work; they are not isolated benchmarks or predicted savings.
Build times also depend on the relevant source version and cache state.

Retained batch-06 evidence is under
`local-state/validations/compiler-selection-completion-20261108/batch-06/`.

| Work | Recorded observation | Evidence within batch 06 |
| --- | --- | --- |
| Debug compiler build | 2.35 seconds | `build-debug-dev-v3.json` |
| ReleaseFast compiler build | 162.13 seconds | `build-fast-dev-v3.json` |
| ReleaseSafe compiler build | 117.11 seconds | `build-safe-dev-v3.json` |
| Census-tool build | 72.33 seconds | `build-census-dev-v3.json` |
| Debug and ReleaseSafe units plus structural checks | 226.41 and 196.53 seconds; 7.05 minutes summed | `units-structural-Debug-dev-v3.json`, `units-structural-ReleaseSafe-dev-v3.json` |
| Readiness | 7.37 minutes; batch 07's corresponding dev-v3 run took 10.49 minutes | `readiness-dev-v3.json`; sibling batch 07 record |
| Full 17-gate integration | 80.82 minutes wall time | `full-cached.log`, final serial summary |
| Integrated-executable gate | 59.54 minutes | `full-cached.log`, slowest-gate summary |
| Native C suite's `z_llvm` calls | 1,176 invocations; 16.92 minutes summed | `full-reports/unchanged-upstream-c--commands.json` |
| Execution-control build/link calls | 96 invocations; 16.23 minutes summed | `full-reports/execution-breadth-controls--commands.json` |
| Repeated direct object/ownership calls | 302 extra calls with identical argument arrays; 3.58 minutes summed | `full-reports/unchanged-upstream-c--commands.json` |
| Whole-compiler production attempt | Backend timed out at the two-hour limit; selection incomplete | `production-compiler.json`, `compiler-production/report.json` |
| Whole-compiler census attempt | Stopped after 132.69 minutes, return code `-15`; incomplete | `census-compiler.json` |
| Native C command history | 2,801 command records | `full-reports/unchanged-upstream-c--commands.json` |

The 3.58-minute repeated-call subtotal is included in the 16.92-minute compiler
subtotal. These savings opportunities must not be added together. The 96
build/link calls comprise 21 reference builds, 21 positive builds and 54 negative
builds; the negative builds account for 9.10 minutes. Linking and independent
reference work remain necessary.

The interrupted whole-input attempts supply diagnostic evidence, not completed
acceptance. Historical attempt timings do not override any later accepted
checkpoint. A faster integration gate alone may leave time to complete acceptance
limited by whole-compiler work.

## Phase 1 Make toolchain selection explicit

The [integrated-executable runner](../../tools/run_distribution_zig_integrated_exe.zig)
resolves `ZLLVM_EXE`, `ZIG_EMITTER` and `ZIG_SOURCE_DIR`, but forwards none of
these selections to its upstream C or `hello_libc` calls. Both the
[C runner](../../tools/validation/upstream_c.zig) and
[real-program runner](../../tools/validation/program.zig) accept `--zllvm`,
`--zig-emitter` and `--zig-source`. Their defaults select `zig-out/bin/z_llvm`,
`../ziglang` and that checkout's `build/stage4/bin/zig`. The outer runner also
installs the default Debug compiler. Consequently, a selected ReleaseFast
compiler or alternate pinned Zig checkout/emitter does not reach these calls.

### Propagation and identity checks

- Forward all three resolved selections to the upstream C and `hello_libc`
  runners. Keep explicit Debug and ReleaseSafe compiler selection usable.
- Audit every nested call against its supported options. The six-program loop
  already forwards all three selections. The
  [input-program runner](../../tools/validation/input_program.zig) accepts only
  `--zllvm` and `--zig-emitter` for tool selection, and already receives both;
  do not add an unsupported `--zig-source` argument there.
- Record resolved compiler/emitter paths and hashes, Zig source path and pin,
  and compiler source/build identity. Keep compiler build mode distinct from the
  ReleaseFast/ReleaseSafe/ReleaseSmall input pipelines under test.
- Check propagation with nondefault paths for each selection independently and
  together. Use a checkout and emitter that satisfy the existing pins; inspect
  child arguments and retained provenance so fallback to defaults is detected.
- Retain rejection of a wrong source pin, modified fixture or incorrect emitter
  identity. Choosing another path must not bypass provenance checks.
- Compare Debug and ReleaseFast using the same source and inputs, preserving
  every object, ownership, observation and negative-control contract. Investigate
  differences and measure this workload before adopting ReleaseFast routinely.

### Retained coverage and build reuse

The following is the proposed coverage contract for the switch. Apply it at the
existing [validation checkpoints](../validation_tiers.md), with valid evidence
reuse; it does not require broad checks after every edit.

| Check | Build mode retained | When required |
| --- | --- | --- |
| `zig build test-unit structural-smoke -Doptimize=Debug` | Debug test executables | Capability and acceptance checkpoints requiring units/structural checks |
| `zig build test-unit structural-smoke -Doptimize=ReleaseSafe` | ReleaseSafe test executables | The same checkpoints; Debug results do not replace this coverage |
| `zig build test-profile-events -Doptimize=MODE` | Debug and ReleaseSafe, separately | When compiler profiling, event output or interrupted-process handling changes |
| `zig build real-program-policy-tests -Doptimize=MODE` | Debug and ReleaseSafe, separately | When validation runners, process ownership/cancellation, provenance, cache or reporting policy changes |
| Complete upstream C/native suite and unchanged `hello_libc` through the affected nested calls | Explicit Debug compiler | Phase-1 baseline/candidate comparison and subsequent acceptance checkpoints affecting these compiler or runner inputs |
| The same complete suites, including every reference and negative control | Explicit ReleaseFast compiler | Phase-1 comparison, then routine expensive integration at the policy's required checkpoints |

`MODE` in the table means one invocation with `Debug` and another with
`ReleaseSafe`. Run the native suites in all three input pipeline modes, retaining
both direct and release routes where defined. Focused development continues to
use affected native populations through
[run_native_canary](../../tools/run_native_canary.zig), such as `large_frame` and
`bounded_storage` for frame work, alongside the change-impact checks. Those
focused runs do not replace complete Debug native coverage.

Retain that full Debug coverage until a later proposal names an exact replacement
set, compares it with the complete baseline and records the accepted coverage
change. Selecting ReleaseFast for the routine expensive run alone does not
authorize reducing the Debug population. Keep readiness and every additional
check required by validation-tier routing. Debug, ReleaseSafe and ReleaseFast
compiler builds remain distinct coverage.

For each compiler build, track the source/dependency hashes, Zig toolchain
identity, target/CPU, optimization mode and effective build options. Rebuild it
when one of those inputs changes, the binary is missing, or its recorded hash
does not match. Build only the modes required by the next validation checkpoint:

- Debug: refresh before affected focused native checks or retained Debug suites.
- ReleaseSafe: refresh before checks that execute a ReleaseSafe compiler; its
  unit and structural test executables must also reflect current dependencies.
- ReleaseFast: refresh before affected integration, profiling or performance
  comparisons. Retain symbols and frame pointers when required for profiling.

Use separate install prefixes and pass the selected executable explicitly so
building one mode cannot overwrite another mode's artifact. Documentation or
unrelated harness edits do not require rebuilding an unchanged compiler. A
changed harness or expected-result contract still invalidates its gate evidence;
compiler reuse and result reuse are separate decisions. Keep the pinned Zig
emitter/source checks even when reusing their artifacts.

Completion requires the requested toolchain identity at every affected consumer,
passing propagation and provenance checks, preserved populations and controls,
the coverage contract above, and measured improvement for this workload. Do not
borrow a speedup ratio from the Fibonacci measurements or remove coverage solely
because it is expensive.

## Phase 2 Profile slow compiler work early

Begin bounded diagnosis alongside the compiler-selection work. Existing
`--profile=PATH` records per-function and phase costs;
`--profile-events=PATH` retains flushed progress through interruption. The
[whole-compiler runner](../../tools/validation/whole_compiler.zig) already supports
both, and the reviewed production attempt enabled events.

Use those records to identify expensive completed functions and the function or
phase active at interruption. Follow [compiler profiling](../compiler_profiling.md)
for hardware sampling with `cycles:u` and `--call-graph fp --user-callchains`.
Add instrumentation only for a specific unanswered attribution question.

Choose a small diagnostic set from the unchanged original inputs, retain its
source identities and exercise known slow functions early. Preserve any module
context needed to reproduce the expensive path. A reduced function case is a
diagnostic and must not replace original-input acceptance.

Record wall time, CPU time, peak RSS, per-phase costs and sample quality. Compare
bounded isolated runs before testing representative concurrent load, so compiler
cost can be distinguished from resource contention. Measure speedups separately
with profiling disabled and the required output/correctness comparisons.

Completion requires measured hotspot attribution and either a validated compiler
improvement or a bounded next investigation. Keep the full census and independent
production replay as separate final evidence. Any proposed consolidation needs
its own equivalence proof, including selected identities, failure tuples and
ownership checks. Increasing a timeout alone is not a performance result.

## Phase 3 Reuse compiled execution harnesses

The [execution-control gate](../../src/distribution_execution_breadth_gate.zig)
builds the linked harness with the positive object and again with deliberately
broken objects. It already supplies shared Zig cache directories. First measure
how much work those repeated commands actually recompile; command counts alone
do not establish the amount of reusable compilation.

Prototype compiling the linked harness once per function and mode, then linking
it separately with each subject object. Reuse requires the same emitter, target,
mode, harness bytes, dependencies and compile flags. Preserve startup, compiler-rt
and native-linker behavior when separating compilation from linking.

Retain the independent reference harness and all positive and negative checks:

- Wrong-symbol controls must still fail at link time for the expected symbol.
- Wrong-result, memory-clobber and high-half-loss controls must still reject
  through the expected explicit oracle result. A crash or timeout is not rejection
  evidence.
- Every required linked executable must still execute and match its observation
  contract in every required mode.

Completion requires unchanged control outcomes and observation counts, plus a
measured reduction in the affected gate. The complete 16.23-minute budget is
not a reclaimable-time estimate.

## Phase 4 Remeasure and reuse identical artifacts within a run

Recalculate duplication after compiler selection and harness reuse. Faster
compilation may make a new cache too costly to justify for the remaining work.

The [native runner](../../tools/validation/native_canaries.zig) repeats some direct
compilations and ownership reports across modes with identical argument arrays.
Those observations identify candidates; matching arguments alone is not a valid
cache key.

Start with reuse inside one frozen validation run. Include the compiler hash,
input content and dependency identities, target, effective arguments, relevant
environment and path context, output kind and expected-result contract. Verify
artifact content before reuse and record the producer identity and each hit.

Generate the object and independent ownership report through their existing
routes before reusing the verified artifacts. Preserve mode-specific optimization,
linking, execution, independent references and CLI/environment equivalence controls.
Report cache hits separately from actual compiler executions.

Completion requires successful forced-fresh/reuse comparisons, invalidation
checks for each relevant input class, corrupt/missing-artifact handling, unchanged
validation outcomes and measurable net benefit. Extend reuse across runs only if
later measurements justify the added lifecycle and retention responsibilities.

## Phase 5 Measure scheduling and report overhead

For scheduling, compare time to complete valid evidence, CPU use, memory pressure
and timeout rates under bounded representative isolated and concurrent runs.
Choose concurrency from those results. Preserve process ownership, cancellation,
source freezing and the current headroom limits. Existing three-mode real-row
concurrency and authenticated AIR-cache reuse remain useful; a separate scheduling
change needs evidence of improvement.

For reporting, measure all three existing update paths:

- The [command runner](../../tools/validation/runner.zig) rewrites accumulated
  `commands.json` after every command, using atomic publication. Its child-command
  timings exclude the subsequent serialization.
- The [checked-run wrapper](../../tools/run_checked.zig) samples telemetry and
  rewrites its growing JSON record approximately every two seconds while the
  child runs, plus initial and final records. The
  [telemetry collector](../../tools/validation/telemetry.zig) launches `df` for
  each sample and, when AIR roots are recorded, scans directories and reads AIR
  file metadata with `statx`.
- The batch-06 retention watcher validates and copies report updates. Measure
  which publications trigger this work and the bytes read and copied.

Rewriting growing command and telemetry arrays creates quadratic serialization
work in record count; the elapsed-time contribution of either is unmeasured.
Measure telemetry collection, serialization/atomic publication, retention copying
and total wrapper CPU/wall time separately over representative record counts and
run durations. Record sample counts, file sizes and bytes written. Distinguish
wrapper elapsed time from child-command timings, and account for overlap with
the running child; their difference alone does not isolate reporting overhead.

Choose a redesign only after those measurements. If material, consider append-only
command and telemetry journals with durable complete records, sequence identifiers,
periodic summaries and atomic final publication. Preserve compatible `commands.json`
and checked-run records for existing consumers during migration. Verify interrupted
writes, truncated tails, cancellation, restart and final-summary equivalence.
Retain headroom observations, AIR identity metadata, child ownership and complete
process outcomes. Direct durable report output should retain lifecycle rules while
reducing dependence on watching temporary directories. Any change to sampling
frequency must preserve the headroom policy's required observations.

Completion requires measured benefit, recoverable partial evidence and identical
final command/result semantics. Avoid a new general artifact framework for a
small serialization improvement.

## Validation and evidence requirements

Apply [validation tiers](../validation_tiers.md) throughout. Reuse a passing gate
only when relevant source state, Zig pin, target, mode, corpus, arguments and
expected-result contract match. Different dev-v1/v2/v3 source states are not
automatically redundant runs.

Use focused checks while developing each change. Gate/cache infrastructure
changes require full distribution and fresh/cache comparison before acceptance.
Compiler changes follow their subsystem routing, including immediate Tier 3
where required for correctness, ABI, frame or other sensitive changes.

For each proposed change, retain:

- Baseline and candidate source/compiler/input identities, actual commands,
  build/cache configuration and scheduling context.
- Repeated timing distributions where practical, plus CPU time and peak RSS;
  do not infer speedups from concurrent diagnostic samples.
- Complete process outcomes, including timeouts and signals, and the existing
  object, ownership, observation and negative-control comparisons.
- A scoped conclusion stating what improved, what coverage was retained or
  deliberately changed, and what remains unproven.

Preserve pinned inputs, original scratch probes, accepted evidence, authenticated
AIR payloads, shared object bundles, independent references and all existing
execution populations. Follow the [retention policy](../retention_headroom_policy.md).
No cleanup or accepted-counter change is part of drafting this plan.

## Delivery checklist

- [x] Adopt a bounded first implementation slice in active direction.
- [x] Establish comparable baselines and record validation-reuse decisions.
- [x] Propagate compiler, emitter and Zig source selections; verify nondefault paths and pin rejection.
- [x] Validate the Debug/ReleaseSafe coverage and rebuild rules before adopting routine ReleaseFast suites.
- [x] Use existing profiles and hardware samples to investigate slow original-input work.
- [x] Prove harness reuse preserves all positive, reference and negative checks.
- [x] Remeasure duplication and implement artifact reuse only if still worthwhile.
- [x] Measure scheduling, command/telemetry publication and retention overhead; implement justified changes.
- [x] Complete the required integration and fresh/cache comparisons for adopted changes.
- [x] Publish measured outcomes and update active documentation after acceptance.

The remaining native duplicate-call budget is 20.09 seconds within the
ReleaseFast compiler subtotal, so no new native result cache is introduced.
Harness reuse and incremental command serialization have measured benefits;
durable integrated output avoids the temporary-report watcher. Existing
concurrency and telemetry sampling remain unchanged. The bounded compiler
investigation identifies allocation-plan scans and dependency validation; no
compiler algorithm change or complete-input acceptance is claimed.
