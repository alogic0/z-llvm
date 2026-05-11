# Cycle 3: Pointer And Memory Corpus

## Goal

Move the pointer/memory Zig corpus row from unsupported toward accepted
optimizer input by expanding parser, verifier, memory-effect, alias, and
volatile/atomic handling only for source-backed IR shapes.

## Source Anchors

- Corpus row: `pointers_memory_release_fast`
- Local analyses: `src/analysis/memory_effect.zig`,
  `src/analysis/memory_location.zig`, `src/analysis/alias.zig`,
  `src/analysis/memory_ssa.zig`
- Local passes: `src/passes/dse.zig`, `src/passes/gvn.zig`,
  `src/passes/early_cse.zig`, `src/passes/licm.zig`

## Plan

- [x] Inventory unsupported syntax in `pointers_memory.ReleaseFast.x86_64.ll`.
- [x] Parse pointer parameter attrs used by Zig without overclaiming semantics.
- [x] Extend memory locations for accepted pointer/GEP shapes from the corpus.
- [x] Add volatile load/store corpus-shaped fixtures across DCE, DSE, GVN, and
      EarlyCSE.
- [x] Add atomic syntax parsing as barrier classification only; do not model
      orderings or atomic RMW transforms yet.
- [x] Confirm LICM still refuses memory movement without proof.
- [x] Promote a reduced pointer/memory corpus fixture to
      `parse,verify,optimizer-input`.

## Exit Criteria

- [x] Pointer/memory corpus behavior is represented by at least one accepted
      checked fixture.
- [x] Volatile and atomic barriers are tested through every memory client pass.
- [x] Unknown pointer cases remain conservative.

## Implementation Notes

- `src/ir/parser.zig` now splits parameter, declaration, and call argument
  lists on top-level commas, so Zig attrs such as `initializes((0, 4))` are
  preserved as raw parameter attributes instead of breaking the signature.
- The raw `pointers_memory_release_fast` corpus row now parses, verifies, and
  runs through the local corpus pipeline.
- Existing volatile and atomic barrier tests cover DCE, GVN, EarlyCSE, LICM,
  mem2reg, SROA, and memory-effect classification; this cycle adds an explicit
  DSE volatile-barrier `opt-22` fixture.
