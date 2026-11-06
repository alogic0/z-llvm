# Input-driven execution and compiler phase measurements

Status: in progress. Builds on the accepted
[execution-breadth checkpoint](../evidence/execution_breadth.md).

## Intended result

Compile one unchanged upstream program once per release mode, then execute a
frozen input corpus covering empty, valid, malformed, nested and growth-heavy
inputs. Record independent expected observations as well as LLVM comparisons.
Measure compiler work by phase, and obtain selection ownership from the same
selection run that emits the object. Keep independent ownership replay as a
regression check.

The first program is the upstream `jsmn` JSON-dump example and parser, pinned to
an audited revision with unchanged source bytes and license. Its stdin handling,
heap growth, mutable token/parser state, recursion and error paths provide a
different workload from the existing constant-input Zig examples. This is C
frontend coverage through the three local release pipelines; it does not claim
new Zig frontend coverage or C sanitizer support.

## Implementation order

1. Add opt-in structured phase measurements for input, parsing, verification,
   optimization, reachability, mandatory normalization, optional legalization,
   selection, object writing and ownership writing. Use exclusive nested timers
   and explicit per-compilation state. Count legalizer attempts, rewrites,
   original-form retries, selected functions and emitted spill instructions.
   Reports must not alter object bytes or ordinary stdout.
2. Write ownership alongside successful object emission without selecting again
   or reordering object functions. Retain the existing standalone manifest route.
   Compare both manifests and object bytes in permanent route tests; update the
   unchanged-program runner to consume the sidecar and keep replay opt-in.
3. Consolidate optional legalization into an explicit bounded driver while
   preserving mandatory normalization, original-form retry semantics, rollback
   and generated switch labels. Test rewrite progress and exhaustion. Preserve
   shared parallel-transfer transactions; change pair/vector/spill paths only
   when a reproduced failure requires extending their contract.
4. Vendor the small unchanged upstream program with revision/hash/license
   provenance. Add file-backed stdin to the existing process runner and a
   permanent corpus gate. Compile once per mode and record each input, expected
   exit/stdout/stderr and actual observations. Include negative oracle controls.
   Repair demonstrated compiler failures through shared lowering authorities.
5. Run the complete compiler and integration checks, including the existing
   Fibonacci and execution populations. Record phase profiles on the retained
   Safe Fibonacci IR and the new program. Keep compiler throughput distinct from
   generated-code performance. Promote evidence only after checks pass.

## Acceptance and storage

Require Debug and ReleaseSafe unit tests, policy and structural checks, ABI and
compilation-route checks, readiness, and all integration gates. The new corpus
must pass in Fast, Safe and Small with authenticated source, inputs, tools and
compiler identities. Verify profiled/unprofiled object equality and sidecar/replay
ownership equality. Timing samples are diagnostic measurements, not speedup
claims. Existing accepted counters retain their population definitions.

Retain prior evidence, the original thirteen scratch probes and diagnostic
worktrees. Create no archives. Keep the 32,949,672,960-byte start threshold and
24,359,738,368-byte execution reserve; remove only reproducible task-owned build
products if needed after retaining reports and provenance.
