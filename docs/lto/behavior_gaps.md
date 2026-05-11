# LTO Behavior And Gap Notes

This document records Zig's current LLVM LTO boundary and the local behavior
that remains intentionally deferred.

## Zig Source Anchors

```text
ziglang/src/Compilation/Config.zig:
  lto mode selection and LTORequiresLld policy

ziglang/src/codegen/llvm/bindings.zig:
  TargetMachine.EmitOptions.lto

ziglang/src/codegen/llvm.zig:
  lowers std.zig.LtoMode into TargetMachine emit options
  writes bitcode when LTO output is selected

ziglang/src/zig_llvm.cpp:
  buildO0DefaultPipeline
  buildLTOPreLinkDefaultPipeline
  WriteBitcodeToFile for LTO

ziglang/src/link/Lld.zig:
  COFF / ELF / Wasm LTO linker flags
```

## Current LLVM Shape

Zig's LLVM wrapper chooses between:

```text
debug mode:
  PassBuilder::buildO0DefaultPipeline

non-debug LTO mode:
  PassBuilder::buildLTOPreLinkDefaultPipeline
  emit bitcode for linker LTO handoff

non-debug non-LTO mode:
  PassBuilder::buildPerModuleDefaultPipeline
  then target machine codegen for object/assembly output
```

`ziglang/src/zig_llvm.cpp` currently sets these important tuning options:

```text
LoopUnrolling enabled outside debug
SLPVectorization enabled outside debug
LoopVectorization disabled
LoopInterleaving enabled outside debug
MergeFunctions enabled outside debug
```

## Local Status

```text
lto-prelink-o3 pipeline exists
lto-prelink-oz pipeline exists
canonicalize-aliases placeholder exists
name-anon-globals placeholder exists
global cleanup placeholders exist
bitcode writing is not implemented
ThinLTO and FullLTO are not semantically distinct locally
ThinLTO summary indexes, combined indexes, import/export, WPD, and post-link
pipelines are unsupported
post-link LTO is not represented
Cycle 23 decision: keep bitcode/LTO compatibility deferred and continue
text-IR/native-handoff validation until a source-backed bitcode or LTO handoff
use case activates the track
```

Decision details are recorded in
`docs/bitcode/lto_compatibility_decision.md`.

## Mode-Specific Boundary

| Zig path | LLVM wrapper behavior | Local boundary |
| --- | --- | --- |
| non-LTO `ReleaseFast` / `ReleaseSafe` | `buildPerModuleDefaultPipeline(O3)` then target emission | `release-o3` and accepted corpus aliases; no bitcode handoff. |
| non-LTO `ReleaseSmall` | `buildPerModuleDefaultPipeline(Oz)` then target emission | `release-oz` and accepted corpus alias; no bitcode handoff. |
| `-flto=thin` in non-debug mode | Zig passes `ThinPreLink`, but wrapper builds `buildLTOPreLinkDefaultPipeline` | `lto-prelink-o3` or `lto-prelink-oz`; ThinLTO summary remains deferred. |
| `-flto=full` in non-debug mode | Zig passes `FullPreLink` and wrapper builds `buildLTOPreLinkDefaultPipeline` | Same pre-link aliases as ThinLTO until summary/post-link behavior is represented. |
| explicit bitcode output | LLVM writes bitcode after optimization | No local writer; construct inventory must be complete first. |

The local LTO aliases are therefore optimizer-boundary checks, not bitcode
writer or linker-LTO correctness claims.

## Behavior Gap Table

| LLVM LTO behavior | Why it matters | Local status |
| --- | --- | --- |
| FullLTO pre-link pipeline composition | Determines which module/function passes run before bitcode handoff | Pipeline surface only |
| ThinLTO pre-link pipeline composition | Requires summary-oriented decisions distinct from FullLTO | Missing |
| Bitcode output for LTO | LTO handoff artifact is bitcode, not object code | Missing writer |
| Module summary index | Needed for ThinLTO import/export and WPD | Missing |
| Alias canonicalization | Pre-link canonicalization for module/global identity | Placeholder, aliases missing |
| Anonymous global naming | Deterministic global naming before LTO | Placeholder, anonymous globals missing |
| Linker LTO flags | LLD chooses LTO optimization level and mode | Inventory only |
| Post-link pipeline | Final whole-program optimization decisions | Missing |
| WPD/CFI/import/export | Requires class hierarchy, summaries, and linker participation | Missing |
| Debug metadata during LTO | LTO must preserve or merge debug metadata | Missing metadata semantics |

## Local Test Policy

Local LTO tests should be limited to:

```text
pipeline expansion and placeholder dispatch
pre-link passes that are already meaningful for represented IR
opt-22 comparison only when text IR can model the same pre-link behavior
bitcode round-trip only after the bitcode construct inventory is implemented
```

Do not add post-link or summary tests until bitcode and summary records exist.

## Unsupported Summary Boundary

```text
ThinLTO module summaries are not parsed, printed, generated, or consumed.
FullLTO and ThinLTO share only the local pre-link pipeline descriptor surface.
No local pass may assume cross-module visibility, import/export decisions,
whole-program devirtualization, CFI, or post-link inlining facts.
Any future ThinLTO work must start from a Zig source-backed LTO handoff use
case and an LLVM bitcode/summary verification command.
```

## Activation Criteria

```text
aliases or anonymous globals are represented locally
bitcode writer/parser work is active
a Zig LTO fixture requires a local pre-link behavior
an optimizer pass changes behavior specifically under LTO phase
LLD/linker-facing behavior needs validation for an accepted fixture
```
