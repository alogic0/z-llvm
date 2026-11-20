# Pipeline-Ready Optimizer Epic

Goal: move from isolated pass slices to a named, documented scalar/memory
optimization pipeline over a richer IR subset. This is intentionally larger
than one development cycle. Pull one bounded slice from this roadmap into
`docs/next_steps.md` at a time.

## Relationship To Other Epics

Historical roadmap order:

```text
Pipeline-Ready Optimizer Epic
  -> Target DataLayout and AIR-to-IR Bridge Epic
  -> MC/Object Bootstrap Epic
```

- This epic is the current optimizer foundation.
- Next epic: [Target DataLayout and AIR-to-IR Bridge Epic](target_datalayout_air_bridge_epic.md).
- Later codegen experiment: [MC/Object Bootstrap Epic](mc_object_bootstrap_epic.md).
- Do not use this optimizer epic to absorb target/DataLayout, AIR lowering, or
  MC/object-emission work; those belong in the later epics.
- Current strategic direction is
  [Zig-Aligned LLVM Removal Plan](../zig_aligned_llvm_removal_plan.md): optimizer
  work should be selected from Zig's real LLVM dependency inventories and
  Zig-emitted IR fixtures before broadening backend work.

## 1. Pipeline and Pass Infrastructure

- Add named pipeline aliases to the CLI, starting with `scalar-foundation` and `memory-foundation`, while keeping explicit comma-separated pass lists supported.
- Document each named pipeline's pass order, LLVM upstream analogue, intended optimization level, and known conservative differences.
- Add pass timing instrumentation behind a CLI flag, with stable output suitable for local debugging.
- Add an opt-bisect-style pass limit option that stops after N pass executions and documents the mapping to LLVM's opt-bisect concept.
- Add a minimal analysis invalidation contract to the pass manager docs, even if the implementation still rebuilds analyses conservatively.
- Add trace fixtures or tests proving named pipelines run the expected pass sequence.

## 2. Scalar IR Expansion

- Add integer cast IR support for `trunc`, `zext`, and `sext`: parsing, printing, verification, def-use, normalization, and unsupported-form errors.
- Add integer division and remainder IR support for `udiv`, `sdiv`, `urem`, and `srem`, with conservative verifier checks and no unsafe folding.
- Parse and preserve selected instruction flags where needed for round-tripping, starting with `nsw`, `nuw`, and `exact`, without using them for transforms until documented safe.
- Add `freeze` parsing/printing/verification if needed to make undef/poison-sensitive LLVM comparison fixtures honest; otherwise document why it remains out of scope.
- Update `unsupported_ir.md`, `ir_values.md`, and scalar pass docs for the new scalar surface and remaining poison/flag gaps.

## 3. InstCombine and InstSimplify Foundation

- Extend `instcombine` with safe identities for casts that do not require target data layout or poison-sensitive reasoning.
- Add conservative constant folding for division/remainder only for defined cases, rejecting or preserving divide-by-zero and overflow-sensitive cases.
- Add an `instsimplify`-style helper layer for reusable local simplifications shared by `instcombine`, GVN, and future passes.
- Move duplicated scalar equivalence and operand canonicalization helpers out of individual passes where doing so reduces pass-local rules.
- Add `opt-22` equivalent fixtures for every accepted fold and local-only fixtures for deliberately conservative non-folds.

## 4. Memory Location and Alias Precision

- Introduce a `MemoryLocation` representation for pointer value plus optional known size/offset, documenting the LLVM `MemoryLocation` mapping.
- Extend GEP analysis to compute simple constant byte/element offsets where the current type model makes that unambiguous.
- Extend alias analysis from stack-slot roots to non-overlapping known-offset stack locations where sizes are known; otherwise keep `may_alias`.
- Keep address spaces, target `DataLayout`, globals, calls, captures, and partial aliasing explicitly out of scope unless their docs and tests are added in the same implementation cycle.
- Add unit tests for alias and mod/ref queries: same slot, distinct slot, zero-offset GEP, known disjoint offset, unknown offset, volatile/atomic barrier.
- Add `docs/analysis/memory_effect.md` if not already present, with LLVM references, entry points, implemented subset, fixture coverage, and known gaps.

## 5. Memory-Aware Optimization Slices

- Add a DSE foundation pass or DSE mode that removes an overwritten stack-slot store only when alias/mod-ref proves no intervening read or barrier.
- Add GVN load value-numbering only for stack loads proven safe by alias/mod-ref and memory-effect rules; keep all ambiguous memory as local-only conservative.
- Extend LICM to hoist readonly loads only when loop memory effects and alias/mod-ref prove safety; otherwise preserve the current rejection behavior.
- Extend SROA/mem2reg interaction for simple known-offset stack accesses only when the current type/offset model proves scalar replacement is valid.
- Add negative fixtures for each memory-aware pass: intervening read, may-alias pointer, volatile load, volatile store, atomic barrier, unknown pointer, and unsupported GEP.
- Add positive fixtures for each memory-aware pass where stack-slot reasoning is precise enough to match LLVM.

## 6. Loop and CFG Canonicalization Support

- Add a small LoopSimplify-style preheader creation pass for simple single-latch loops when it preserves phi operands and CFG validity.
- Add dedicated-exit detection and documentation; create dedicated exits only if the implementation remains small and testable.
- Extend LICM fixtures to cover loops that require the new preheader pass before hoisting.
- Keep irreducible loops, multi-latch canonicalization, LCSSA insertion, and loop rotation out of scope unless explicitly promoted with fixtures.

## 7. Fixture Matrix and LLVM Comparison Policy

- Expand `test/opt/fixtures.tsv` to group fixtures by pipeline/pass family and mark each as `opt-equivalent` or `local-conservative`.
- Update `scripts/compare_opt.sh` or add a companion mode so local-conservative fixtures compare against checked-in expected output without requiring byte-for-byte LLVM equivalence.
- Add end-to-end pipeline fixtures for `scalar-foundation` and `memory-foundation`.
- Add reduced fixtures generated from real Zig-emitted LLVM IR where possible, keeping them small and normalized.
- For every local-conservative fixture, document the LLVM behavior gap and the missing analysis or IR feature that explains it.

## 8. Documentation and Inventory Updates

- Update the Zig LLVM API inventory current-coverage table for scalar casts, division/remainder, memory locations, named pipelines, and any new memory-aware transforms.
- Add or refresh upstream algorithm docs for InstSimplify-style helpers, DSE, MemoryLocation, and any new loop canonicalization pass.
- Add fixture coverage sections to all touched pass and analysis docs.
- Update `testing.md` with named pipeline commands, local-conservative fixture policy, and the broader comparison matrix.
- Keep `docs/next_steps.md` accurate as subtasks land; do not mark a cycle complete until docs and fixtures match implementation.

## 9. Verification Gate

- Run `zig fmt` on touched Zig files.
- Run `zig build test`.
- Run `bash scripts/compare_opt.sh`.
- Run any new local-conservative fixture mode.
- Record any deliberate LLVM mismatch in the relevant docs before marking the cycle complete.
