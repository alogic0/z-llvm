# Optimizer boundary repairs

Baseline: `465f3bbc`, 2026-09-26. The user requested fixes for the three
reproduced review bugs and the contradictory improvement-plan status.
Accepted counters and compiler capability claims do not change.

## Implementation

- Signed min/max uses shared width-aware comparisons, preserving the chosen
  operand's bit pattern. Unsigned folding uses the same normalization and
  retains full-width results through a bit cast rather than a signed numeric cast.
- Explicit alloca element counts are typed operands. Parsing, printing, operand
  traversal, verification, replacement walks, and loop dependency checks include
  them. DCE and InstCombine can retain live count producers and still remove
  unrelated dead instructions. Single-object promotion and local frame lowering
  reject non-singleton counts; this does not add dynamic local stack codegen.
- The improvement plan's header and progress table now agree with its completed
  memset-family section. Documentation validation includes the current architecture,
  refactor plan, this repair record, and the memset evidence page.

Upstream mappings: `llvm/lib/Analysis/InstructionSimplify.cpp` and
`llvm/lib/IR/ConstantFold.cpp` for integer intrinsic/constant semantics;
`llvm/include/llvm/IR/Instructions.h` (`AllocaInst` array-size operand),
`llvm/lib/AsmParser/LLParser.cpp`, and `llvm/lib/IR/Verifier.cpp` for allocation
operands; `llvm/lib/Transforms/Scalar/DCE.cpp` for use-based deletion.
The independent execution and verification oracle is LLVM 22.

## Validation preflight

Compiler: Zig 0.16.0. Evidence root:
`local-state/validations/optimizer-boundaries-20260926/`.

New focused tests reproduced signed min/max's wrong result and the missing live
allocation size before the fixes. The review's retained i127 probe reproduced
an integer-overflow abort in `unsignedInt`. Native regressions add seven functions
and 134 observations per pipeline, checked against both explicit expectations and
an LLVM-compiled original. Transformed IR is verified and compiled at `-O0`.

These are confirmed wrong-code and verifier/IR repairs, requiring Tier 3 under
[validation tiers](../validation_tiers.md). Previous integration logs cannot
validate the changed source and regression inputs. Reuse only the unchanged
emitter's immutable export cache; all validation runs again.

```sh
/home/oleg/.zig/0.16.0/files/zig build distribution-all -- --serial \
  --serial-root=local-state/validations/optimizer-boundaries-20260926/full \
  --real-rows-validation-root=local-state/validations/optimizer-boundaries-20260926/project-improvement \
  --real-rows-cache-root=local-state/caches/project-improvement \
  --zig-emitter=/home/oleg/prog/ziglang/build/stage4/bin/zig
```

Completed focused validation: 1,479 unit tests, eight structural tests, and nine
storage tests passed (`unit-final.log`). All nine new boundary tests pass in
Debug and ReleaseFast; the filtered ReleaseFast invocation reports 18 tests
including imported test roots (`releasefast-final.log`). The native optimizer
runner passes every fixture and pipeline (`native-final.log`), including the
seven added functions with 134 observations in each of two pipelines. Current
documentation links and both accepted-status blocks pass validation.

Readiness passed (`readiness-final.log`): optimizer fixtures, native regressions,
ABI comparisons, parser corpus, handoff checks, generated scalar tests, and all
24 behavioral program/mode pairs with 6,528 observations. LLVM tools report
22.1.8; the emitter source remains `bdee02bc0c7f227c0f11bc9a449df673fe803540`.

Full integration passed (`distribution-all.log`, exit 0): all 17 subgates
completed with `local_fail=0` in 2,362,835 ms wall time (39m 23s). All three
export-cache identities were verified hits. Each release mode lowered, emitted,
and linked 100 compiler-core rows and passed four execution-cohort probes.
The integrated executable gate also passed all 6,528 behavioral observations
and all 8,652 memset observations with 12 checked traps. Release-object inspection,
native links/probes, and boundary checks passed. The release bundle identity is
`a5dcce564ade761f3cf47c9767f69615cdadbe0d6c2cc88419efaaf52e9518fa`.

`source-before-tier3.sha256` and `source-verification.txt` establish that all
1,374 compiler, tool, test, and build files were unchanged across the final run.
The external emitter checkout was clean before and after validation. The
original review inputs and failing outputs are retained in `review-baseline/`.
Earlier readiness and intermediate test logs remain development diagnostics;
the final logs and source snapshot establish repair acceptance. Accepted-status
counters are unchanged, and dynamic/multi-element local stack codegen remains
an explicit unsupported boundary.
