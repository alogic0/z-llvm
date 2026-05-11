# Cycle 4: Atomic And Inline-Asm Fixture Closure

## Goal

Close the known Cycle 22 documentation/coverage mismatch by adding or narrowing
atomic and inline-asm barrier fixture claims.

## Source Anchors

- Corpus: `atomics_inline_asm_debug_release_fast`
- Docs: `docs/roadmap/historical/completed_corpus_blocker_cycles/22_inline_asm_and_atomics_cycle.md`,
  `docs/ir_atomics_inline_asm.md`
- Local code: `src/analysis/memory_effect.zig`, `src/ir/parser.zig`
- Existing fixture: `memory_atomic_barrier_reject`

## Plan

- [x] Add pass-specific atomic barrier fixtures for ADCE, GVN, EarlyCSE, LICM,
      and DSE where the local parser accepts the IR.
- [x] Keep inline asm rejected before optimization until constraints and memory
      clobbers are represented.
- [x] If a pass-specific fixture is not meaningful, update the docs to say so
      explicitly.
- [x] Compare accepted atomic barrier cases with `opt-22` where equivalent, and
      mark local-conservative differences separately.
- [x] Update `docs/ir_atomics_inline_asm.md` and historical Cycle 22 notes to
      match actual fixture coverage.

## Exit Criteria

- [x] No roadmap or atomics doc overclaims pass fixture coverage.
- [x] Atomic load/store barriers have named tests for each relevant optimizer
      client or a documented reason for omission.
- [x] Unsupported atomic forms and inline asm remain fail-closed.

## Completion Notes

- Added local-conservative atomic barrier fixtures for ADCE, GVN, EarlyCSE,
  LICM, and DSE.
- Kept inline asm as parser-rejected, so no optimizer fixture is meaningful yet.
- Existing parser/unit coverage remains the fail-closed check for unsupported
  atomic forms and inline asm.
