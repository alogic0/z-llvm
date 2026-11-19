# Loop promotion and bounded memset on x86_64

The starting point is the accepted M3 commit `156346e3`. The implementer
(`01a1edc3-c301-7260-9e47-cd7cdbfef4b3`) owns the builds, changes,
measurements and handoffs. The primary reviewer
(`01a1ed95-6d13-7532-803a-576eed555ef8`) owns the independent review and
the decision on each candidate. The user authorized this plan on 2026-11-18.

## Review decisions

**Loop timing, 2026-11-18.** Both IR forms used the same fresh M3 compiler
(`6a4dcb44`) and common drivers. Primary review checked the schedule, image
identities, stdout and stderr of all 112 visits and recalculated the paired
medians from the original observations. Promotion was slower in all twelve
pairs in each mode, by 40.99 ms in Fast (MAD 2.47 ms) and 40.09 ms in
Small (MAD 3.15 ms). The original and promoted forms matched on all 272
scalar outputs. Promotion removed the IR slot and cut object text from
127 to 125 bytes, but added stack transfers for the accumulator on the
backedge. The reviewer declined a release-pipeline promotion and assigned
the bounded fill experiment. See `loop-original/`, `loop-sroa/` and
`loop-sample/report.json` under the batch root below.

**Bounded fill candidate, 2026-11-18.** The reviewer verified the frozen
eight-file patch `46a70903`, the identities of the measured images and
all 560 scheduled visits across five workloads. On the original fill
driver, the paired median saving was 21.37 ms in Fast and 21.63 ms in
Small. The other four workloads had identical baseline and candidate
objects and executables. Fill kernel text grew from 843 to 1,130 bytes
and the stripped executable grew by 288 bytes in both modes.

The per-length runs showed gains even on long fills taking the byte loop.
At the reviewer's request the implementer kept the candidate layout fixed
and diverted just the seven eligible paths to the fallback. Fourteen bytes
differed in each whole executable. The genuine candidate saved 3.86 ms in
Fast and 3.93 ms in Small against this control, winning all twelve pairs
in both modes. The control takes one extra branch on eligible lengths.
This qualifies the performance tradeoff on the measured host and driver.
The reviewer verified the guard results, assembled bytes at all fourteen
mode/site combinations, 1,176 length-diagnostic visits and the 112
fixed-layout visits. The core Tier 2 checks passed.
See `fill-sample/`, `fill-lengths/lengths/`, `fill-controls-02/` and
`layout-control/` under the batch root below.

**Final review, 2026-11-18.** The reviewer accepted the implementation at
`5d6b921e` and the [published evidence](../evidence/loop_and_bounded_memset_20261118.md)
at `d9b9281b`. The committed diff reproduces the frozen patch, and all 679
source hashes match. The seven integrated executables passed. Across Fast,
Safe and Small the reviewer checked the original 2,133 executable outputs
and 1,422 selection-owner manifests against all 237 registered populations.
All 36 temporary roots were released and collected. Eleven receipts account
for 5,131,485,184 reclaimed bytes. The final idle sweep found zero eligible
roots. Both assignments are closed. The loop backedge copies are recorded as
a possible future optimization.

## Loop backedge and compare follow-ups

On 2026-11-18 the user assigned both changes below to the same implementer
and primary reviewer. Start from `478a57cc`, whose production compiler source
is `5d6b921e`. Each candidate has its own diff, disassembly, timing
comparison and review decision. Continue to the comparison change after the
backedge decision. Use the accepted backedge change as the second baseline
if it lands. [Measurements that prompted the work](../evidence/loop_and_bounded_memset_20261118.md#loop-promotion)

1. **Forward the next loop value to its PHI slot.** On the original
   `loops_memory` backedge, EAX holds the next index. The emitter stores it to
   a temporary, reloads it and stores it in the header's PHI slot. On an
   unconditional edge, try storing the register directly in the final slot
   when the incoming value's uses, other live values and parallel PHI copies
   allow it. Check zero, one and many trips, wrapping arithmetic, a live
   neighbor, and a swap between two PHIs that would expose a clobbered
   source. Inspect the emitted object on both the original IR and the
   scalar-promoted IR. For each IR form compare current and patched backends
   with the same driver in ReleaseFast and ReleaseSmall. Base adoption on a
   repeatable gain on the original production loop. Report the effect on
   the promoted loop separately.
2. **Branch on the integer comparison's flags.** For an eligible single-use
   scalar `icmp` feeding `condbr`, use the comparison flags directly. Start
   with the existing loop predicate. Prove the flags survive to the jump
   and that the normal selector preserves any other use of the Boolean.
   Check both branch outcomes, swapped operands or predicates admitted by
   the change, intervening flag writers, additional uses, and successor PHIs.
   Inspect the actual branch in the emitted object. Measure the incremental
   effect on the original loop and other affected workloads against this
   candidate's own baseline in both release modes.

Use the existing five-workload driver and balanced measurement protocol
below. Record correct native outputs, paired medians and dispersion, and
changes in kernel and stripped executable sizes. Investigate repeatable
regressions before promotion. The implementer sends each frozen candidate
and evidence to the reviewer, addresses findings, and reports final results.
The reviewer verifies the source, native controls, emitted instructions,
raw measurements and applicable selector gates. Focused selector changes
use Tier 2. Route any change to shared allocation or frame layout under the
[validation tiers](../validation_tiers.md). A negative performance result
closes an experiment with its candidate and evidence identified.

The evidence root for these two assignments is
`local-state/validations/x86-loop-edges-20261118/batch-01/`. Before producing
data, record each stage in its `retention.md`. Build baseline and candidate
compilers and shared driver objects in managed pipelines. Keep compiler
products through emission and applicable qualification, and the linked
programs through native controls, inspection and paired timing. Use separate
checked stages for focused tests and qualification. Maintain frozen patch
and input identities, commands, native outcomes, disassembly, raw samples,
size comparisons, review decisions and release receipts. The historical
loop IR and oracles retain their existing ownership. Record any further
exception with its path, consumer and end condition. Release each pipeline
after its last consumer, collect at stage boundaries, and record the final
receipt and remaining owners. [Development storage contract](../development_storage.md)

## 1. Measure what loop promotion buys on M3

The M2 loop took 230 ms locally and 80 ms with LLVM O3. An older local
pipeline already removed the stack slot and ran 33–41 ms slower than direct
emission across two runs. Several passes ran together. The first assignment
isolates the existing scalar replacement pass (SROA), which can promote
this exact one-element array. [M2 measurements](../evidence/generated_program_performance_20261117.md)
· [Earlier loop results](../evidence/loops_memory_repair.md)
· [Existing SROA test](../../src/tests/codegen_x86_64_opt_and_normalization.zig)

- Produce the original and SROA-only forms of `loops_memory` from the
  frozen input. Bind the IR and attributes, then feed each through the same
  freshly built M3 x86_64 emitter and link the same driver. Inspect the
  loop body and backedge in each disassembly. Identify accumulator and
  induction-value loads, stores and edge copies separately.
- Check the 272 scalar observations and timed digest, including zero and
  one trip, multiple trips, wrapping values and both live backedge values.
  Compare elapsed time under the protocol below. Send both forms, commands,
  outcomes, disassembly and the resulting recommendation to the reviewer.
- If promotion cuts hot stack traffic and gives a repeatable gain, qualify
  the smallest change that uses the existing promotion for a nonescaping
  single-element slot with plain, full-width, offset-zero accesses. Exercise
  escapes, aliases, volatile/atomic accesses and mismatched widths as exclusions.
  Account for ReleaseSafe sharing the release pass list.
- If the promoted form still spills, test one identifiable redundant transfer
  on fixed IR if the evidence supports it. Measure any single-use
  compare-to-branch change independently, with flag liveness and extra-use
  controls. Proceed to the fill experiment if the loop gain is within run
  dispersion, regresses Small materially or needs broader allocator work.

## 2. Test the bounded fill when the loop result calls for it

On baseline x86_64, try two unaligned eight-byte stores for an ordinary
nonvolatile dynamic fill of 8 through 16 bytes, using the repeated low byte
at `dst` and `dst + len - 8`. Both stores must fit inside the requested
range. Preserve the original return pointer, live registers, zero-length
behavior and the checked wrappers' trap before any store.

Use a length sweep including 0, 7, 8, 9, 15, 16 and 17, unaligned destinations,
guard bytes, high fill bits, and the existing 1,442 observations and both
checked trap cases. Measure the added branch cost on fallback lengths.
Only lengths 15 and 16 hit the new path in the frozen timed driver. Judge
the result on the original whole-family run in Fast and Small. Record a
negative result if the trial loses. [Timed driver](../../test/behavioral/performance_memset.zig)

## Measurement and review

Use the [frozen M2 protocol](2026-11-17-generated-program-performance.md).
Compare baseline and candidate in balanced, interleaved order on the same
CPU, with two warmups and twelve measured blocks, identical inputs,
attributes, target, driver and static stripped link. Record host conditions.
Keep the local Fast/LLVM O3 and Small/LLVM Oz references. Report paired
whole-process differences in ms, dispersion and ratios, and code, read-only
data and file sizes. Collect diagnostic measurements outside timed runs.
Before promoting a compiler change, check all five frozen workloads for
regressions and run its applicable [validation tier](../validation_tiers.md).

The implementer reports each decision point and frozen candidate, with its
commit or patch identity, original failures, evidence paths and storage
disposition. The reviewer checks the source, raw samples, oracles and code
generated through the production path, returns findings directly, and records
the decision here or in linked evidence after re-review. An isolated IR
experiment informs the choice of implementation. A production speedup claim
requires the measured production candidate.

## Evidence and storage

Evidence root: `local-state/validations/loop-and-bounded-memset-20261118/batch-01/`.
Use a distinct checked run per stage and attempt. Before producing data,
the implementer writes the batch and run `retention.md` with actual paths,
producers, consumers, exceptions and release conditions. Run maintained
tools through `tools/run-validation` and scripts through its `--command`
mode. [Development storage contract](../development_storage.md)

| Producer | Temporary products and consumers | Release condition |
| --- | --- | --- |
| Compiler and harness builds | Baseline/candidate compilers, driver objects, runner and private caches for emission, qualification and sampling | Release after the last named consumer |
| IR preparation and linking | Comparable objects and executables for correctness, disassembly and timing | Release after the final inspection and sample |
| Focused checks and qualification | Test binaries, caches and scratch for the affected validation tier | Collect after the checked result or documented failure disposition |

Maintain commands, source and binary identities, relevant IR and disassembly,
raw samples, semantic outputs, analysis and receipts. Keep ordinary products
in managed workspaces. Any additional replay dependency needs an exact path,
consumer and release condition in the run note. Collect at each completed
stage, immediately after releases and again at the next idle boundary if
deferred. The final handoff identifies remaining roots and owners and
preserves existing accepted artifacts and independent holds.
