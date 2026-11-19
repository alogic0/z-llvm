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
