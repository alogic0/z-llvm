# Transform Cost Policy

LLVM references:

```text
llvm-project-22/llvm/include/llvm/Analysis/TargetTransformInfo.h
llvm-project-22/llvm/include/llvm/Analysis/TargetLibraryInfo.h
llvm-project-22/llvm/lib/Transforms/InstCombine/InstCombineCalls.cpp
llvm-project-22/llvm/lib/Transforms/Vectorize/LoopVectorize.cpp
llvm-project-22/llvm/lib/Transforms/Vectorize/SLPVectorizer.cpp
llvm-project-22/llvm/lib/Transforms/Vectorize/VectorCombine.cpp
```

This project separates three legality classes:

| Class | Local status | Examples |
| --- | --- | --- |
| Target-independent | May run when parser/verifier support exists and opt-22 fixtures match. | integer identity folds, DCE of side-effect-free scalar code, scalar CFG cleanup |
| DataLayout-sensitive | May run only when the row's DataLayout facts are parsed and the pass uses the local DataLayout API. | scalar GEP offset reasoning, aggregate size/alignment checks |
| TTI/TLI-sensitive | Must stay placeholder, rejected, or preserve-only until TargetTransformInfo or TargetLibraryInfo equivalents exist. | vectorization profitability, vector-combine, libcall shrink wrapping, div/rem pairing profitability, FP reciprocal/reassociation cost choices |

Current policy:

```text
ReleaseFast and ReleaseSmall accepted corpus pipelines exclude vectorizer passes.
Fixed-vector and lane-operation IR is parser/verifier-only, not optimizer-input.
FP transforms are preserve-only unless they are target-independent and have opt-22 fixture coverage.
AArch64 target records may appear on target-independent scalar fixtures.
The source-backed AArch64 integer row uses only `aarch64-target-independent`.
DataLayout is not a substitute for TargetTransformInfo.
Target feature strings are preserved for future cost modeling but not consumed by transforms.
```

Fixture coverage:

```text
opt-22 equivalent:
  aarch64_instcombine_target_independent
  fp_instcombine_preserve
  fp_dce_dead
  vector_lane_preserve

unit tests:
  accepted Zig corpus pipelines exclude loop-vectorize, slp-vectorizer, and vector-combine
  ReleaseFast and ReleaseSmall accepted pipeline notes document target-cost gaps
  AArch64 accepted pipeline excludes ABI, memory-motion, vector, TTI, and TLI transforms
```
