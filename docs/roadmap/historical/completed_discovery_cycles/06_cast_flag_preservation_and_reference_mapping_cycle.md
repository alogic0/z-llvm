# Cycle 06: Cast Flag Preservation and LLVM Reference Tightening

## Goal

Close the review findings from Cycle 05 before starting another corpus sweep:
preserve source-backed cast flags during parse/verify/print, and tighten the
LLVM reference mapping for the Discover 2 gap closure documentation.

This is a small corrective cycle. It should not expand into new parser grammar
coverage beyond the cast flags already observed in Zig-emitted IR.

## Source-Backed Evidence

Cycle 05 accepted `trunc nuw` syntax from the Discover 2 fixture, but the
verifier-preserve expected output drops the flag:

```text
test/zig/expected/discover2_gap_closure.reduced.ll
test/opt/expected/z_llvm/discover2_gap_closure_verify_preserve.ll
```

Observed difference:

```diff
-%t = trunc nuw i32 %x to i8
+%t = trunc i32 %x to i8
```

Relevant local paths:

```text
src/ir/core.zig
src/ir/parser.zig
src/ir/printer.zig
src/ir/verifier.zig
src/tests.zig
docs/fixtures/zig_ir/discover_2_gap_summary.md
```

## LLVM Reference Mapping

Before marking implementation items complete, record the exact upstream LLVM
source entry points used for the behavior:

- `llvm/lib/AsmParser/LLParser.cpp`
  - cast instruction parsing;
  - overflow or no-negation flag spelling accepted for casts.
- `llvm/lib/IR/AsmWriter.cpp`
  - cast instruction printing with preserved flags.
- `llvm/lib/IR/Verifier.cpp`
  - verifier rules for cast flags and invalid flag placements.
- `llvm/docs/LangRef.rst`
  - `trunc` instruction flags and their semantics.

Update the durable Discover 2 summary with function-level references, not only
file-level references.

## Plan

- [x] Add a small cast-flag representation to `core.CastInst`.
- [x] Parse source-backed cast flags instead of skipping them.
- [x] Preserve at least the observed `trunc nuw` spelling through the printer.
- [x] Add verifier checks for supported cast-flag placement.
- [x] Reject duplicate or unsupported cast flags with explicit parser/verifier
      errors.
- [x] Update
      `test/opt/expected/z_llvm/discover2_gap_closure_verify_preserve.ll` so
      `trunc nuw` remains present.
- [x] Add focused parser/printer tests for cast-flag preservation.
- [x] Add focused negative tests for invalid or duplicate cast flags.
- [x] Tighten `docs/fixtures/zig_ir/discover_2_gap_summary.md` with exact LLVM
      reference functions for the Cycle 05 sub-slices.
- [x] Rerun the normal gates.

## Acceptance Criteria

- [x] `trunc nuw` in
      `test/zig/expected/discover2_gap_closure.reduced.ll` survives
      verify-preserve output unchanged.
- [x] Cast flags are represented in the local IR instead of being silently
      discarded.
- [x] Invalid cast-flag forms fail with intentional local errors, not accidental
      parse fallout.
- [x] Cycle 05's durable Discover 2 summary cites exact upstream LLVM source
      functions or entry points for the implemented sub-slices.
- [x] The normal gates pass:

```text
zig build test
bash scripts/compare_opt.sh
bash scripts/run_readiness_checks.sh
```

## Non-Goals

- Full LLVM cast-instruction grammar coverage.
- Enabling new optimizer facts from cast flags.
- Changing binary, arithmetic, GEP, or fast-math flag handling.
- Raising the normal CLI input-size limit.
- Running a new full corpus sweep before this corrective cycle is closed.

## Close-Out Notes

- [x] Record final fixture diff.
- [x] Record final LLVM reference mapping updates.
- [x] Archive this cycle under
      `docs/roadmap/historical/completed_discovery_cycles/` after
      implementation and verification.

Final fixture diff:

- `test/opt/expected/z_llvm/discover2_gap_closure_verify_preserve.ll` now
  preserves `%t = trunc nuw i32 %x to i8`.
- `test/opt/expected/z_llvm/globaldce_switch_table_root.ll` now preserves
  `%wide = zext nneg i8 %idx to i64`.

Final LLVM reference mapping updates:

- `docs/fixtures/zig_ir/discover_2_gap_summary.md` records function-level
  anchors for `LLParser.cpp`, `AsmWriter.cpp`, `Verifier.cpp`,
  `Attributes.cpp`, and `Type.cpp`, plus the relevant LangRef surface.
