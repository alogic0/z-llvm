# Named Pipelines

LLVM references:

```text
llvm-project-22/llvm/lib/Passes/PassBuilderPipelines.cpp
llvm-project-22/llvm/lib/Passes/PassBuilder.cpp
llvm-project-22/llvm/include/llvm/Passes/PassBuilder.h
```

Upstream entry points to check:

```text
PassBuilder::parsePassPipeline
PassBuilder::buildFunctionSimplificationPipeline
PassBuilder::buildModuleSimplificationPipeline
PassBuilder::buildPerModuleDefaultPipeline
```

LLVM exposes named and textual pass pipelines through `opt -passes=...` and
through optimization-level pipeline builders. This project keeps explicit
comma-separated pass lists, and adds small named aliases for reproducible
development workflows.

Implemented pipelines:

```text
scalar-foundation:
  simplifycfg
  instcombine
  early-cse
  gvn
  dce
  adce

memory-foundation:
  simplifycfg
  sroa
  mem2reg
  dce
```

Usage:

```bash
zig build run -- --passes=scalar-foundation test/opt/inputs/instcombine.ll
zig build run -- --pipeline=memory-foundation test/opt/inputs/mem2reg.ll
```

Implemented subset:

```text
named pipeline aliases expand to existing pass names
explicit comma-separated pass lists still work
pipeline aliases can be mixed with explicit pass names
unit tests check the scalar-foundation pass order
```

Upstream mapping:

```text
This reproduces only the "named pass sequence expands to concrete passes" part of LLVM's pipeline infrastructure.
LLVM's PassBuilder handles optimization levels, analysis managers, extension points, CGSCC/function/module pass nesting, target callbacks, and textual pipeline parsing.
```

Known conservative differences:

```text
no optimization-level builder yet
no nested module/function/loop/CGSCC pass managers
no target-machine pipeline hooks
no extension points
no analysis preservation scheduling
```
