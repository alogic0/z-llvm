# Cycle 2: Switch Table Global Constants

## Goal

Accept the source-backed switch corpus blocker by parsing the private aggregate
global constant shape Zig emits for dense switch lookup tables.

## Source Anchors

- Corpus: `switch_control_release_fast`
- Zig source: `test/zig/inputs/switch_control.zig`
- Captured IR: `test/zig/captured/switch_control.ReleaseFast.x86_64.ll`
- Local code: `src/ir/parser.zig`, `src/ir/core.zig`, `src/ir/verifier.zig`,
  `src/passes/globaldce.zig`

## Plan

- [x] Represent scalar array constants narrowly enough for Zig switch lookup
      tables.
- [x] Parse and print private `unnamed_addr constant [N x i32] [...]` globals.
- [x] Verify GEP/load users of accepted global array constants.
- [x] Keep arbitrary aggregate initializers unsupported unless the corpus
      requires them.
- [x] Add a corpus runner row update that moves `switch_control_release_fast`
      from `unsupported,future` to `parse,verify,optimizer-input` only after the
      captured IR passes the local accepted pipeline.
- [x] Add opt fixtures for lookup-table preservation through GlobalDCE and
      scalar cleanup.

## Exit Criteria

- [x] `switch_control_release_fast` parses and verifies from captured IR.
- [x] Switch-table globals are not dropped unsafely.
- [x] Unsupported aggregate global forms still fail closed.

## Completion Notes

- Added a narrow `GlobalInitializer.array` shape for scalar array constants.
- Accepted Zig's source-backed `zext nneg` spelling by dropping `nneg` during
  parse/print normalization.
- Added GlobalDCE function-to-global operand edges so lookup-table constants
  referenced by live functions remain live.
