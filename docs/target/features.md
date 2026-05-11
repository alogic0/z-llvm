# Target CPU And Feature Attributes

LLVM target features influence TargetTransformInfo, instruction selection,
legalization, vectorization, and codegen. This project currently preserves and
extracts the metadata only; no optimizer transform is allowed to make a
profitability or legality decision from it yet.

## Implemented Surface

```text
"target-cpu"="..."
"target-features"="+feature,-feature,..."
```

`src/target/features.zig` can extract these strings from raw LLVM attribute
text and query whether an exact feature token is present.

## Current Policy

```text
preserve raw attributes in parser/printer
extract target-cpu and target-features for diagnostics and future target-cost work
do not use features in InstCombine, GVN, LICM, vector placeholders, or codegen decisions
keep non-host target facts visible in corpus rows and target docs
```

## Upstream Mapping

LLVM source anchors:

```text
llvm-project-22/llvm/include/llvm/Target/TargetMachine.h
llvm-project-22/llvm/include/llvm/Analysis/TargetTransformInfo.h
llvm-project-22/llvm/lib/Target/X86/X86Subtarget.cpp
```

LLVM builds subtarget feature sets and exposes them through TargetMachine,
Subtarget, and TargetTransformInfo. The local helper is only a parser-facing
metadata extraction layer.

## Known Gaps

```text
no CPU model database
no feature implication graph
no target transform information
no per-function subtarget dispatch
no feature-driven instruction selection or vector legality
```
