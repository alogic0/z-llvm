# Zig Upstream LLVM Removal Path

This note records the public Zig roadmap direction for reducing and eventually
removing LLVM as a hard dependency. It is source-backed context for this
project's own roadmap; it is not a substitute for local inventories and tests.

This is a strategy note, not an active checklist. Epic completion is tracked in
`docs/README.md`, and active slices should be pulled from the numbered epic
files.

## Sources

- Zig issue #16270: `make the main zig executable no longer depend on LLVM,
  LLD, and Clang libraries`
  <https://github.com/ziglang/zig/issues/16270>
- Zig 2025 devlog: `Self-Hosted x86 Backend is Now Default in Debug Mode`
  <https://ziglang.org/devlog/2025/>
- Andrew Kelley and Loris Cro: `Zig's New Relationship with LLVM`
  <https://kristoff.it/blog/zig-new-relationship-llvm/>

## Upstream Direction

Zig's public direction is not "clone all of LLVM first." The direction is to
make the main `zig` executable stop depending on LLVM, LLD, and Clang libraries,
while keeping optional paths available where they are still useful.

The upstream path can be summarized as:

```text
remove hard libLLVM/libLLD/libClang dependency from the main zig executable
  -> use self-hosted Zig backends for fast/debug-oriented compilation
  -> keep LLVM IR/bitcode handoff possible without linking libLLVM
  -> replace LLD and Clang-adjacent tools separately
  -> improve Zig-owned optimization and codegen quality over time
```

## Main Workstreams

### 1. Remove LLVM Library API Dependence

Zig issue #16270 tracks eliminating direct dependency on LLVM library APIs from
the main executable. One listed direction is direct LLVM bitcode output instead
of using LLVM's IRBuilder API.

Implication for this project:

- Treat LLVM IR/bitcode compatibility as a migration and comparison track.
- Do not require linking LLVM libraries for local optimizer experiments.
- Keep source-level inventories of Zig's current LLVM API use.

### 2. Self-Hosted Native Backends

The 2025 Zig devlog says the self-hosted x86 backend became the default in
Debug mode for x86_64 targets except Windows. The stated motivation is compile
speed and control over code generation.

Implication for this project:

- Do not assume this repo should replace Zig's native backends.
- Use local codegen/MC/object work as a bounded validation and study track.
- Prefer documenting handoff points to Zig-owned backend IRs over growing a
      parallel general backend.

### 3. Incremental Compilation And In-Place Binary Patching

The 2020 Andrew Kelley/Loris Cro article frames LLVM optionality around the
self-hosted compiler, faster debug builds, and incremental compilation with
in-place binary patching. That design requires tight control over frontend,
backend, linker, and debug information.

Implication for this project:

- Keep backend experiments small unless they clarify incremental/backend
      boundaries.
- Do not design local object emission as the main replacement path unless a
      Zig-aligned need is documented.
- Track debug-info and linker implications separately from optimizer work.

### 4. Replace LLD And Clang-Adjacent Dependencies Separately

Issue #16270 lists separate work for LLD removal, `zig ar`, `zig cc`,
`zig c++`, `translate-c`, `@cImport`, import library generation, and Clang
preprocessor replacement.

Implication for this project:

- Keep linker, archive, C frontend, and Clang compatibility out of the core
      optimizer roadmap.
- Inventory them only where they affect the LLVM backend boundary.
- Avoid absorbing LLD/Clang replacement work into this repo's optimizer
      epics.

### 5. Optimization Quality Over Time

Issue #16270 explicitly mentions future Zig-owned optimization passes, but the
current upstream path prioritizes removing hard dependencies and making native
backends useful. LLVM-level release optimization quality is a long-term target,
not a prerequisite for every step.

Implication for this project:

- Implement optimizer behavior only when tied to Zig's real LLVM pipeline.
- Start with semantic correctness and canonicalization:
      verifier, mem2reg, SROA, InstSimplify, InstCombine, SimplifyCFG.
- Add memory, scalar, loop, IPO, vector, sanitizer, and LTO behavior in
      dependency order.
- Compare LLVM-equivalent fixtures against LLVM 22.

## Project Alignment

This repository should help Zig's path by producing:

- authoritative inventories of Zig's LLVM API and pass-pipeline use;
- real Zig-emitted LLVM IR fixtures;
- semantic docs for LLVM-compatible behavior Zig currently emits;
- small optimizer replacements with `opt-22` comparison fixtures;
- conservative gap tables explaining where LLVM does more;
- native-backend handoff notes instead of duplicating Zig backends by
      default.

The aligned local path is:

```text
inventory
  -> Zig-emitted IR corpus
  -> verifier and semantic prerequisites
  -> P0/P1 optimizer slices
  -> native-backend handoff study
  -> bounded codegen/MC validation where useful
  -> optional bitcode/debug/LTO tracks when justified
```

The implementable epic split starts at:

- `../README.md`

## What This Means For Roadmap Priority

- Primary next work: verifier foundation and Zig-emitted IR inventory.
- Optimizer work must come from
      `docs/inventory/zig_llvm_pass_pipeline_inventory.md`.
- Codegen/MC/object work stays paused unless needed for validation.
- Broad backend, linker, debug, sanitizer, vector, and LTO work must have a
      source-backed Zig need before becoming active.
