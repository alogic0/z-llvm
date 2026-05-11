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

- [ ] Inventory unsupported syntax in `pointers_memory.ReleaseFast.x86_64.ll`.
- [ ] Parse pointer parameter attrs used by Zig without overclaiming semantics.
- [ ] Extend memory locations for accepted pointer/GEP shapes from the corpus.
- [ ] Add volatile load/store corpus-shaped fixtures across DCE, DSE, GVN, and
      EarlyCSE.
- [ ] Add atomic syntax parsing as barrier classification only; do not model
      orderings or atomic RMW transforms yet.
- [ ] Confirm LICM still refuses memory movement without proof.
- [ ] Promote a reduced pointer/memory corpus fixture to
      `parse,verify,optimizer-input`.

## Exit Criteria

- [ ] Pointer/memory corpus behavior is represented by at least one accepted
      checked fixture.
- [ ] Volatile and atomic barriers are tested through every memory client pass.
- [ ] Unknown pointer cases remain conservative.

