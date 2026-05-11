# Cycle 8: Debug Metadata Preservation

## Goal

Preserve enough Zig-emitted debug metadata and instruction attachment structure
that optimizer passes can avoid corrupting Debug and ReleaseSafe IR while still
being honest about debug-info gaps.

## Source Anchors

- Zig source: `../ziglang/src/codegen/llvm.zig`
- LLVM: `llvm/lib/IR/DebugInfoMetadata.cpp`
- LLVM: `llvm/lib/Transforms/Utils/Local.cpp`
- Local docs: `docs/debug/metadata_inventory.md`,
  `docs/passes/instrumentation_metadata.md`,
  `docs/fixtures/zig_ir/README.md`
- Local IR: `src/ir/parser.zig`, `src/ir/printer.zig`, `src/ir/verifier.zig`

## Plan

- [x] Inventory debug metadata records emitted by Zig Debug and ReleaseSafe
      corpus rows.
- [x] Parse and preserve top-level `DICompileUnit`, `DISubprogram`, `DILocation`,
      and type metadata records as opaque metadata first.
- [x] Add instruction-level metadata attachment parsing for `!dbg` without using
      it for optimization decisions.
- [x] Preserve or drop debug attachments according to documented local pass
      policy when instructions are removed or replaced.
- [x] Add rejected fixtures for debug metadata forms that imply value salvage
      the local optimizer cannot perform.
- [x] Promote a reduced Debug corpus fixture to parse/verify status.
- [x] Document the gap from LLVM debug value salvage and assignment tracking.

## Exit Criteria

- [x] Debug metadata can be round-tripped for at least one reduced Zig Debug
      fixture.
- [x] Optimizer passes have a documented debug attachment policy.
- [x] Unsupported debug-info behavior is explicitly classified.

## Completion Notes

- Added `test/zig/expected/debug_metadata.reduced.ll` as a reduced Debug
  parse/verify fixture that preserves `DICompileUnit`, `DISubprogram`,
  `DILocation`, `llvm.dbg.cu`, module flags, function `!dbg`, and instruction
  `!dbg` attachment syntax.
- Instruction `!dbg` metadata is stored and printed as opaque text. Passes do
  not inspect it for optimization decisions.
- Current pass policy is preservation-only for unchanged instructions and
  drop-on-delete/drop-on-replace for transformed instructions. LLVM debug value
  salvage, assignment tracking, discriminator updates, and inline scopes remain
  unsupported.
