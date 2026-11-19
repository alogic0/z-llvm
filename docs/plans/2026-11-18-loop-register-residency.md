# Measure the cost of spilling the x86_64 loop state

Oleg authorized the implementer and primary reviewer to run this milestone
on November 18. Start from production compiler source `56eb24a6`. On the
original loop, its Fast executable took 212.59 ms. The function carries
the accumulator, index and limit through a 280-byte frame. One trip reads
the stack five times and writes it twice. LLVM Oz keeps those values in
registers and rotates the loop. LLVM O3 also unrolls it. Measure the
contribution of register residency on the existing loop shape.
[Previous measurements](../evidence/x86_loop_edges_20261118.md)

## Matched experiment

1. Reproduce the production Fast and Small loop objects and the static
   executables with the frozen external driver. Check their bytes against
   the previous run. Build a diagnostic version of the same function that
   keeps the three hot values in caller-saved registers. Preserve the
   System V ABI, frame reservation, arithmetic, header comparison, exit
   branch and unconditional backedge. Keep unrolling off. Inspect both
   linked functions. Record function and header addresses, branch offsets,
   padding, stack traffic and any changed entry or exit work. The implementer
   sends the proposed layout to the reviewer before timing.
2. Run the original 272 inputs and their 35,651,584-call driver. Repeat at
   fixed trip counts of 0, 1, 8, 15, 64 and 256, with a common call count
   across the six fixtures and identical driver bytes across arms within
   each fixture. Verify exact return values, wrapping arithmetic, aggregate
   digests, exit status and stderr against an independent model. Include a
   deliberately wrong result to demonstrate that the oracle detects it.
   Keep calls external and observable. [Original driver](../../test/behavioral/performance_scalar.zig)
3. Use the existing pinned CPU and balanced timing protocol in Fast and
   Small, with two warmups and twelve measured pairs. Keep the original
   LLVM comparisons as context. Record raw visits, executable hashes,
   run order, median paired savings, MAD and range. Report nanoseconds per
   call at each trip count. The zero-trip difference measures changes to
   entry, the loop test and exit together. Use the change in savings over
   longer trip intervals to estimate the cost saved per iteration.
   Check agreement across both modes and visit orders. If a layout change
   or dispersion obscures the decision, isolate it with the smallest
   matched control. [Measurement protocol](2026-11-17-generated-program-performance.md)

**Layout review.** The reviewer verified all 680 compiler source inputs
against `56eb24a6`. The fresh compiler reproduced the accepted object with
111 bytes of loop code and the 237,480-byte original-driver executable. The matched
version changes 28 bytes in nine instructions. The timed executable has
identical bytes outside the function. Its frame, all instruction start
addresses, comparison, three jumps and return are preserved. EDI carries
the accumulator, R10D the index and ESI the limit. Register copies and LEAs
replace all seven hot stack accesses. The independent model reproduced the
original four route outputs and counts 1,999 iterations per 272 mixed calls.
See `prepare/images.tsv`, `prepare/layout.tsv` and `review-oracle/model.json`.

**First timing decision.** The register version saved a paired median
12.39 ms in Fast and 16.32 ms in Small on the original mix. It also won at
15 trips. On the same fixed-trip executable it lost 325 ms and 314 ms at
64 trips, then 2,288 ms and 2,217 ms at 256. All twelve 256-trip pairs
favored the production code in each mode. The reviewer recalculated these
results from all 392 visits. Two seven-byte LEAs carry the accumulator
through consecutive loop iterations in the register version.

The reviewer assigned a four-way control on the original mix and fixed
0, 15, 64 and 256 trips. Compare the production code, the first register
version, and two register versions with short copies at those sites. One
uses a base-only LEA, the other a MOV. Each short copy is followed by
the same five-byte NOP. These two versions have the same instruction
addresses and count. Time all four in balanced blocks. Compare production
directly with MOV, short LEA with MOV, and the original long LEA with
short LEA plus padding. Keep both image pipelines through independent native,
linked-byte and timing review in `review-copy-control/`. The fixed driver
and mixed driver have different trip histories and loop-header positions
within a 64-byte line. Each comparison uses equal positions within its own
driver. See `sample/report.json` and the `control-*` stages in the batch.

**Prototype decision.** In 560 fresh visits, the short MOV version beat
production in every mixed-input pair. The median paired savings were
24.69 ms in Fast (MAD 1.55) and 21.76 ms in Small (MAD 2.44), about
12% and 10% on this host. The zero-trip differences were within dispersion.
At 64 trips the savings were 284 ms and 272 ms. At 256 trips they grew to
1,157 ms and 1,120 ms. Over that interval the additional saving per
iteration was 0.122 ns in Fast and 0.125 ns in Small.

Short LEA and MOV differed in four bytes across the two accumulator-copy
sites. Their median difference was smaller than the measured dispersion on
every fixture. Replacing the long LEAs with short LEAs plus padding removed
the long-trip regression. The reviewer assigned a bounded production
compiler prototype on `56eb24a6`. A single reusable opportunity to keep a
value in a register is enough to test. Check the emitted loop through the
normal compiler entry points, adjacent ineligible shapes and all five
frozen workloads. The implementer reports the candidate separately from
the experimental assembly. See `control-sample/report.json`.

## Decision and follow-through

The implementer reports results to the primary reviewer
(`01a1ed95-6d13-7532-803a-576eed555ef8`). The reviewer checks the
source, actual linked code, independent oracles and raw paired measurements,
then dispatches the applicable follow-up to the same implementer
(`01a1edc3-c301-7260-9e47-cd7cdbfef4b3`).

- If the original mix improves repeatably and savings increase with trip
  count, prototype one bounded compiler change for the demonstrated cause.
  Use normal local release emission, define which IR and control-flow
  shapes qualify, and exercise nearby exclusions including a live value or
  alternate predecessor. Compare the actual compiler with `56eb24a6` on
  the original loop and the five frozen workloads. Recheck correctness,
  code size and Fast/Small runtime. Use the change-impact tier for the
  code touched. The reviewer decides whether to land the prototype.
- If residency accounts for little on the original mix, profile the pinned
  `jsmn jsondump` program on comparable local and LLVM builds. Reuse the
  existing 46-case oracle. Select a sufficiently long valid input, check
  exact output once for each image and keep I/O conditions equal in the
  measured runs. Report where time is spent in application and library
  code, and identify a source-level hypothesis supported by the profile.
  [Program and oracle](../../test/real_programs/jsmn_jsondump.json)

Record the measured decision, follow-up outcome, source identities and
review here and in the published results. A diagnostic assembly result
quantifies the opportunity. A production speed claim uses the compiler
that emitted the measured program. [Validation tiers](../validation_tiers.md)

## Evidence and storage

Use `local-state/validations/loop-register-residency-20261118/batch-01/`.
Before producing data, declare each run and its consumers in `retention.md`.
Build the compiler, drivers, matched objects and executables in managed
pipelines. Keep the compiler through code inspection and any qualified
compiler comparison, and the executables through native checks, timing and
independent review. Reviewer fixtures and negative controls use their own
managed stages. If the profiling branch runs, keep raw profiles in managed
scratch through extraction and review. Keep compact identities, commands,
source differences, disassembly, semantic outputs, raw timings, profile
summaries and decisions in evidence. The historical inputs and manifests
retain their existing owners. Run stages through `tools/run-validation`,
release each pipeline after its last consumer, and collect at each completed
boundary. Record the final cleanup receipt, other owners and any continuing
exception. [Development storage contract](../development_storage.md)
