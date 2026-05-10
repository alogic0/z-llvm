# LTO Pre-Link Surface

LLVM references:

```text
llvm-project-22/llvm/lib/Passes/PassBuilderPipelines.cpp
llvm-project-22/llvm/lib/Transforms/Utils/CanonicalizeAliases.cpp
llvm-project-22/llvm/lib/Transforms/Utils/NameAnonGlobals.cpp
```

Zig's LLVM path uses LLVM's LTO pre-link pipeline for LTO modes. The local
replacement currently models the pre-link pipeline surface without implementing
post-link summary, import/export, WPD, CFI, or bitcode-summary behavior.

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Passes/PassBuilderPipelines.cpp
  llvm-project-22/llvm/lib/Transforms/Utils/CanonicalizeAliases.cpp
  llvm-project-22/llvm/lib/Transforms/Utils/NameAnonGlobals.cpp

LLVM entry points/classes:
  PassBuilder::buildLTOPreLinkDefaultPipeline
  PassBuilder::buildThinLTOPreLinkDefaultPipeline
  CanonicalizeAliasesPass::run
  NameAnonGlobalPass::run

Required analyses:
  Module symbol table.
  Alias and global identity representation.
  LTO mode selection from Zig frontend options.

Required IR invariants:
  Pre-link passes must not assume post-link summary information.
  Alias and anonymous-global transforms require represented aliases/globals.
  Verify remains part of the local LTO pipeline boundary.

Core LLVM algorithm data structures:
  PassBuilder pipeline composition.
  Module global and alias lists.
  Anonymous global naming worklist.

Local target status:
  Placeholder pipeline surface.
```

Implemented subset:

```text
lto-prelink-o3 and lto-prelink-oz local pipelines are explicit.
canonicalize-aliases and name-anon-globals are executable placeholders.
verify and existing scalar/memory/global foundations are present in the local
pre-link pipeline shape.
```

Intentional divergences:

```text
ThinLTO and FullLTO pre-link are documented but not semantically distinct yet.
Zig's current wrapper-level behavior maps nonzero LTO to LLVM pre-link pipeline
construction; the local model keeps O3/Oz pre-link surfaces separate by mode.
No alias canonicalization runs until aliases are represented.
No anonymous global naming runs until anonymous global identity is represented.
No summary index, import/export, post-link inlining, WPD, CFI, or bitcode
summary emission.
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  lto-prelink-o3 and lto-prelink-oz pipeline expansion tests

unit-test only:
  placeholder pass dispatch
```
