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

- [ ] Parse Zig-emitted target datalayout strings into structured local facts.
- [ ] Add pointer size, ABI alignment, preferred alignment, and aggregate layout
      queries needed by memory-location and SROA.
- [ ] Validate host and non-host target triples from the corpus.
- [ ] Replace hard-coded type-size assumptions where DataLayout should decide.
- [ ] Add aarch64 corpus-derived tests for layout-sensitive behavior.
- [ ] Keep target features, vector register classes, and full ABI lowering out
      of scope unless a fixture requires them.
- [ ] Document which optimizer decisions depend on target facts.

## Exit Criteria

- [ ] Memory-location and SROA offset calculations use parsed target facts for
      accepted layouts.
- [ ] Non-host corpus fixtures are classified by target/DataLayout support.
- [ ] Target-sensitive unsupported behavior fails closed.

