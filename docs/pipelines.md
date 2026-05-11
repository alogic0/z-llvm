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
PassBuilder::buildO0DefaultPipeline
PassBuilder::buildLTOPreLinkDefaultPipeline
```

LLVM exposes named and textual pass pipelines through `opt -passes=...` and
through optimization-level pipeline builders. This project keeps explicit
comma-separated pass lists, and adds small named aliases for reproducible
development workflows.

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Passes/PassBuilderPipelines.cpp
  llvm-project-22/llvm/lib/Passes/PassBuilder.cpp
  llvm-project-22/llvm/include/llvm/Passes/PassBuilder.h

LLVM entry points/classes:
  PassBuilder::buildO0DefaultPipeline
  PassBuilder::buildPerModuleDefaultPipeline
  PassBuilder::buildLTOPreLinkDefaultPipeline
  PassBuilder::parsePassPipeline

Required analyses:
  None for pipeline expansion itself; passes rebuild local analyses.

Required IR invariants:
  Module verification must pass before and after each executed pass.

Core LLVM algorithm data structures:
  Pipeline descriptors
  Named pass registry
  Optimization-level pipeline builders
  Extension-point pass insertion
  Analysis-manager require/invalidate pipeline entries

Local target status:
  LLVM-shaped pipeline subset with per-pass fixture-equivalent status tags

Implemented subset:
  Named pass registry
  Named development pipelines
  Zig mode pipeline descriptors for Debug/O0, Release/O3, Release/Oz, and LTO
  Textual nesting placeholders for module(...), function(...), loop(...), and
  cgscc(...)
  Explicit no-op placeholders for discovered passes whose algorithms are not
  implemented yet

Intentional divergences:
  The local descriptors are dependency-ordered approximations of Zig's LLVM
  modes, not complete textual reproductions of LLVM's printed pipeline.
  Placeholder passes are documented no-ops so the pipeline surface is explicit
  before each algorithm lands.
  Textual nesting placeholders flatten accepted inner passes into the module
  pass manager.
  No real nested module/function/loop/CGSCC pass managers exist yet.

Analysis preservation/invalidation:
  Pipeline expansion preserves no analysis state.
  The pass manager treats every executed pass as invalidating analyses and then
  verifies the module.

Fixture coverage:
  Unit tests check development pipeline expansion.
  Unit tests check Debug/O0 and Release/O3 mode pipeline expansion.
  Unit tests check nested pipeline placeholder flattening and malformed group
  rejection.
  Unit tests check placeholder no-op execution.

opt-22 comparison command:
  opt-22 -passes='default<O3>' -print-pipeline-passes -disable-output /dev/null

Local-only fixture command:
  zig build test
```

Implemented development pipelines:

```text
scalar-foundation:
  simplifycfg
  jump-threading placeholder
  correlated-propagation placeholder
  instcombine
  simplifycfg
  jump-threading placeholder
  correlated-propagation placeholder
  instcombine
  aggressive-instcombine placeholder
  lower-constant-intrinsics placeholder
  early-cse
  gvn
  dce
  adce

memory-foundation:
  simplifycfg
  sroa
  mem2reg
  dce

zig-scalar-foundation:
  simplifycfg
  jump-threading placeholder
  correlated-propagation placeholder
  instcombine
  simplifycfg
  instcombine
  aggressive-instcombine placeholder
  lower-constant-intrinsics placeholder
  early-cse
  gvn
  dce
  adce
```

Implemented Zig mode descriptors:

```text
debug-o0:
  verify
  ee-instrument placeholder
  always-inline placeholder
  alloc-token placeholder
  annotation-remarks placeholder
  verify

release-o3:
  verify
  add-discriminators placeholder
  forceattrs placeholder
  inferattrs placeholder
  sroa
  mem2reg
  simplifycfg
  instcombine
  simplifycfg
  instcombine
  aggressive-instcombine placeholder
  lower-constant-intrinsics placeholder
  early-cse
  gvn
  dse placeholder
  adce
  licm
  globalopt placeholder
  globaldce placeholder
  mergefunc placeholder
  annotation-remarks placeholder
  verify

release-oz:
  size-oriented release descriptor with the same scalar/memory foundation but
  without local LICM until code-size gates exist

lto-prelink-o3 / lto-prelink-oz:
  release descriptors plus canonicalize-aliases and name-anon-globals
  placeholders at the front
```

Usage:

```bash
zig build run -- --passes=scalar-foundation test/opt/inputs/instcombine.ll
zig build run -- --pipeline=memory-foundation test/opt/inputs/mem2reg.ll
zig build run -- --pipeline=release-o3 test/opt/inputs/instcombine.ll
zig build run -- --pipeline=debug-o0 test/opt/inputs/instcombine.ll
zig build run -- --passes='module(verify,function(instcombine,dce))' test/opt/inputs/instcombine.ll
```

Implemented subset:

```text
named pipeline aliases expand to existing pass names
explicit comma-separated pass lists still work
pipeline aliases can be mixed with explicit pass names
unit tests check the scalar-foundation pass order
inventory placeholders are executable documented no-ops
unit tests check debug-o0 and release-o3 expansion
textual nested pipeline placeholders are flattened for now
selected release descriptors repeat simplifycfg and instcombine to model LLVM's
canonicalization shape
```

Upstream mapping:

```text
This reproduces only the "named pass sequence expands to concrete passes" part of LLVM's pipeline infrastructure.
LLVM's PassBuilder handles optimization levels, analysis managers, extension points, CGSCC/function/module pass nesting, target callbacks, and textual pipeline parsing.
```

Known conservative differences:

```text
no real nested module/function/loop/CGSCC pass managers
no target-machine pipeline hooks
no extension points
no analysis preservation scheduling
mode descriptors are not full LLVM pipeline-equivalent yet
```
