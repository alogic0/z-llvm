# Cycle 9: Target DataLayout And ABI Semantics

## Goal

Make target-sensitive IR facts precise enough for optimizer legality: pointer
sizes, integer alignment, aggregate layout, non-host target triples, and the ABI
facts Zig's native backends need at optimizer handoff.

## Source Anchors

- Zig source: `../ziglang/src/target.zig`, `../ziglang/src/codegen/llvm.zig`
- LLVM: `llvm/lib/IR/DataLayout.cpp`
- Local code: `src/target/datalayout.zig`, `src/target/triple.zig`,
  `src/analysis/memory_location.zig`, `src/target/abi.zig`
- Corpus row: `integers_release_fast_aarch64`

## Plan

- [x] Parse Zig-emitted target datalayout strings into structured local facts.
- [x] Add pointer size, ABI alignment, preferred alignment, and aggregate layout
      queries needed by memory-location and SROA.
- [x] Validate host and non-host target triples from the corpus.
- [x] Replace hard-coded type-size assumptions where DataLayout should decide.
- [x] Add aarch64 corpus-derived tests for layout-sensitive behavior.
- [x] Keep target features, vector register classes, and full ABI lowering out
      of scope unless a fixture requires them.
- [x] Document which optimizer decisions depend on target facts.

## Exit Criteria

- [x] Memory-location and SROA offset calculations use parsed target facts for
      accepted layouts.
- [x] Non-host corpus fixtures are classified by target/DataLayout support.
- [x] Target-sensitive unsupported behavior fails closed.

## Completion Notes

- `src/target/datalayout.zig` now exposes pointer preferred alignment, integer
  preferred alignment, type store-size, type alignment, aggregate field-offset,
  and simple aggregate size queries.
- `src/analysis/memory_location.zig` has DataLayout-aware pointer/access/GEP
  helpers, and SROA/DSE use module DataLayout when present.
- The aarch64 corpus row is explicitly classified as `target-layout,future`:
  parsed and verified for target facts, but not yet optimizer-input.
- Target features, vector register classes, packed/scalable aggregates, full
  ABI lowering, and address-space-specific pointer queries remain out of scope.
