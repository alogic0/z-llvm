# Vector IR And Target Cost Epic

Status: future epic.

Goal: add the IR and analysis surfaces required before vectorization passes can
move beyond placeholders.

## Required First Slices

- Add vector types and verifier rules.
- Add vector constants, vector `select`, and lane-aware scalar operations.
- Add target legality queries for supported targets.
- Add TargetTransformInfo-style cost modeling.
- Add opt-22 fixtures for vector IR round-tripping before enabling
  `loop-vectorize`, `slp-vectorizer`, or `vector-combine`.

## Upstream Mapping

```text
llvm-project-22/llvm/lib/Transforms/Vectorize/LoopVectorize.cpp
llvm-project-22/llvm/lib/Transforms/Vectorize/SLPVectorizer.cpp
llvm-project-22/llvm/lib/Transforms/Vectorize/VectorCombine.cpp
llvm-project-22/llvm/include/llvm/Analysis/TargetTransformInfo.h
```
