# Zig-Aligned LLVM Removal Plan

Goal: make this project useful to Zig's real LLVM removal path. The project
should not try to rewrite all of LLVM in isolation. It should identify the exact
LLVM behavior Zig still relies on, reproduce the smallest correct subsets in
Zig, and produce fixtures, docs, and implementation slices that can guide or
eventually feed Zig's self-hosted compiler work.

## Direction

Zig's practical LLVM-removal path is:

```text
make LLVM optional in the main zig executable
  -> use Zig native backends where they are good enough
  -> keep LLVM IR/bitcode handoff available as an optional compatibility path
  -> replace LLD/Clang-adjacent pieces separately
  -> improve Zig-owned optimization and backend quality over time
```

This project's aligned role is:

```text
inventory Zig's real LLVM dependency
  -> preserve LLVM-compatible semantic understanding where Zig currently emits it
  -> reproduce required optimizer behavior slice by slice
  -> produce small verified fixtures from Zig-emitted IR
  -> learn from Zig native backends for final code generation
  -> avoid building unrelated LLVM subsystems before Zig needs them
```

## Non-Goals

- [ ] Do not attempt a full pass-for-pass LLVM clone before proving Zig needs
      each pass.
- [ ] Do not prioritize a general native backend over Zig's existing native
      backend work.
- [ ] Do not implement broad MC/object/debug/LTO systems before optimizer and
      IR semantics prove they are needed.
- [ ] Do not treat LLVM textual IR compatibility as the final architecture; use
      it as a comparison and migration tool.
- [ ] Do not add optimizer passes unless they are tied to Zig's actual LLVM
      pipeline inventory or a Zig-emitted fixture.

## Phase 1: Authoritative Zig LLVM Dependency Inventory

Goal: keep a living map of the LLVM surface Zig actually depends on.

- [ ] Keep `docs/inventory/zig_llvm_api_inventory.md` current.
- [ ] Keep `docs/inventory/zig_llvm_pass_pipeline_inventory.md` current.
- [ ] Add an inventory of Zig-emitted LLVM IR constructs from real small Zig
      programs.
- [ ] Classify each dependency as:
      IR semantics, optimizer, target/data-layout, backend/codegen, MC/object,
      linker/archive, debug info, sanitizer/coverage, LTO, Clang/C frontend.
- [ ] Mark each dependency as:
      already covered locally, foundation only, missing, intentionally deferred,
      or out of scope for this repo.
- [ ] Keep source references to the local Zig checkout and LLVM 22 checkout.

Deliverables:

- [ ] `docs/inventory/zig_llvm_api_inventory.md`
- [ ] `docs/inventory/zig_llvm_pass_pipeline_inventory.md`
- [ ] `docs/inventory/zig_emitted_ir_inventory.md`
- [ ] fixture list tying Zig source examples to emitted LLVM IR features

## Phase 2: Zig-Emitted IR Semantic Corpus

Goal: build a small but honest corpus of real Zig-emitted LLVM IR, normalized
into the subset this project can inspect.

- [ ] Add tiny Zig source fixtures for:
      scalar arithmetic, branching, loops, stack locals, calls, globals,
      error paths, optionals, slices, simple structs, debug statements, and
      safety-check differences.
- [ ] Capture Zig LLVM backend output for relevant modes:
      `Debug`, `ReleaseFast`, `ReleaseSafe`, and `ReleaseSmall`.
- [ ] Normalize LLVM output only enough to remove irrelevant noise.
- [ ] Preserve target triple, datalayout, calling conventions, attributes, and
      memory metadata when they matter.
- [ ] Record which IR constructs this project can parse, verify, optimize, or
      deliberately reject.
- [ ] Add rejected fixtures for unsupported constructs instead of silently
      dropping them.

Deliverables:

- [ ] `test/zig/inputs/*.zig`
- [ ] `test/zig/expected/*.ll`
- [ ] `docs/fixtures/zig_emitted_ir.md`
- [ ] `docs/unsupported_ir.md` updates

## Phase 3: LLVM-Compatible IR Semantics Before More Passes

Goal: make the local IR safe enough to support optimizer work without hiding
semantic gaps.

- [ ] Strengthen verifier coverage:
      dominance, use-before-def, phi incoming validity, call signature validity,
      terminator rules, declaration references, and memory instruction legality.
- [ ] Document poison, `undef`, `freeze`, `nsw`, `nuw`, and `exact` behavior for
      every transform that touches them.
- [ ] Expand DataLayout-backed type size and offset queries only where fixtures
      require them.
- [ ] Expand function declarations, calls, attributes, globals, and metadata
      preservation before implementing passes that depend on them.
- [ ] Keep aggregate, vector, atomics, exceptions, inline asm, and debug metadata
      explicit when unsupported.

Deliverables:

- [ ] `Verifier Foundation Epic`
- [ ] semantic docs under `docs/ir_*.md`
- [ ] verifier accepted/rejected fixtures
- [ ] updated `docs/unsupported_ir.md`

## Phase 4: Required Optimizer Slices From Zig's LLVM Pipeline

Goal: reproduce the mandatory and canonicalization behavior Zig relies on before
performance-quality passes.

- [ ] Pull work from
      `docs/roadmap/all_discovered_llvm_optimizations_implementation_plan.md`.
- [ ] Start with P0 passes:
      verifier, mem2reg, SROA, InstSimplify, InstCombine, SimplifyCFG.
- [ ] Then implement P1 foundations:
      EarlyCSE, GVN, SCCP, ADCE, DSE, alias/mod-ref, loop canonicalization.
- [ ] For every pass, complete the LLVM Algorithm Contract before marking the
      implementation complete.
- [ ] Compare `LLVM-equivalent for listed fixtures` cases with `opt-22`.
- [ ] Keep local conservative divergences explicit and tested.
- [ ] Avoid vectorization, broad IPO, sanitizer instrumentation, coroutine
      lowering, and post-link LTO until the IR surface supports them.

Deliverables:

- [ ] pass docs under `docs/passes/`
- [ ] analysis docs under `docs/analysis/`
- [ ] `test/opt/fixtures.tsv` entries
- [ ] named local pipelines matching Zig mode intent:
      `debug-o0`, `release-o3-foundation`, `release-oz-foundation`

## Phase 5: Native-Backend Handoff Strategy

Goal: avoid duplicating Zig's native backends unnecessarily. Prove where this
project can hand optimized IR or semantic results back toward Zig-owned codegen.

- [x] Document the boundary between Zig AIR, this project's LLVM-compatible IR,
      and Zig native backend inputs.
- [x] Identify which optimizer results can be represented in a Zig-owned IR
      form without round-tripping through LLVM IR text.
- [x] Add a `Zig Native Backend Handoff` roadmap doc before expanding MC/object
      work.
- [x] Treat this repo's codegen/MC/object path as a verification aid and
      subsystem study, not the primary replacement for Zig native backends.
- [x] Prefer adding optimizer fixtures that can be validated either against
      LLVM `opt-22` or against Zig native backend behavior where practical.

Deliverables:

- [x] `docs/roadmap/08_native_backend_handoff_study.md`
- [x] `docs/codegen/zig_native_backend_handoff.md`
- [x] a list of optimizer outputs that are AIR/MIR-compatible in principle

## Phase 6: Backend Boundary Experiments Only Where Useful

Goal: use backend experiments to understand LLVM responsibilities, but keep them
secondary to Zig-aligned optimizer and IR work.

- [x] Keep MC/Object Bootstrap and Calls/Stack Frame Codegen scoped to tiny
      x86_64 SysV fixtures.
- [x] Use those backend fixtures to validate that optimized IR still lowers to
      real assembly/object output.
- [x] Do not generalize register allocation, scheduling, debug info, linking,
      multiple object formats, or multiple architectures until a Zig-aligned
      need is documented.
- [x] Prefer studying Zig native backend code before implementing overlapping
      backend features locally.

Deliverables:

- [x] tiny codegen fixtures as regression checks
- [x] docs mapping LLVM `TargetMachine.emitToFile` responsibilities
- [x] explicit deferred list for full backend replacement work

## Phase 7: Optional LLVM IR/Bitcode Compatibility Track

Goal: support Zig's possible path of emitting LLVM IR/bitcode without linking
libLLVM, while keeping this separate from native optimization work.

- [ ] Track what it would take to write LLVM-compatible bitcode or textual IR
      directly.
- [ ] Keep text IR parsing/printing useful for comparison and migration.
- [ ] Do not block native optimizer work on full bitcode compatibility.
- [ ] Add bitcode work only when a concrete Zig use case is selected.

Deliverables:

- [ ] `docs/roadmap/llvm_ir_bitcode_compatibility_epic.md`
- [ ] bitcode inventory entry in `docs/inventory/zig_llvm_api_inventory.md`

## Phase 8: Upstream-Useful Artifacts

Goal: make this repo produce outputs that are useful even if its code is never
copied directly into Zig.

- [ ] Keep fixtures tiny, named, and reproducible.
- [ ] Record exact Zig source, emitted LLVM IR, LLVM pass command, local command,
      and expected output for every comparison.
- [ ] Keep algorithm docs short enough to be useful as implementation notes.
- [ ] Track local conservative gaps against LLVM clearly.
- [ ] Prefer patches or designs that can be ported into Zig's self-hosted
      compiler architecture.

Deliverables:

- [ ] fixture corpus
- [ ] pass algorithm contracts
- [ ] gap tables
- [ ] minimal reproducer docs

## Immediate Next Work

- [ ] Promote the verifier-only first slice from
      `docs/roadmap/all_discovered_llvm_optimizations_implementation_plan.md`.
- [ ] Implement from `docs/roadmap/03_llvm_compatible_ir_verifier_foundation.md`.
- [ ] Add `docs/inventory/zig_emitted_ir_inventory.md`.
- [ ] Add more real Zig-emitted IR fixtures before broadening optimizer passes.
- [ ] Keep codegen epics paused unless they are needed for optimizer validation.

## Success Criteria

This plan succeeds if the project becomes a reliable map and proof harness for
Zig's LLVM removal work:

- [ ] Every optimizer implementation is tied to Zig's actual LLVM pipeline.
- [ ] Every semantic claim is backed by fixtures.
- [ ] Every LLVM-equivalent claim is compared with LLVM 22.
- [ ] Every divergence from LLVM is documented and tested.
- [ ] The project can explain which LLVM pieces Zig still needs, which local
      pieces cover them, and which pieces should be handled by Zig's native
      backend or other upstream work.
