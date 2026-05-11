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

- [ ] Inventory debug metadata records emitted by Zig Debug and ReleaseSafe
      corpus rows.
- [ ] Parse and preserve top-level `DICompileUnit`, `DISubprogram`, `DILocation`,
      and type metadata records as opaque metadata first.
- [ ] Add instruction-level metadata attachment parsing for `!dbg` without using
      it for optimization decisions.
- [ ] Preserve or drop debug attachments according to documented local pass
      policy when instructions are removed or replaced.
- [ ] Add rejected fixtures for debug metadata forms that imply value salvage
      the local optimizer cannot perform.
- [ ] Promote a reduced Debug corpus fixture to parse/verify status.
- [ ] Document the gap from LLVM debug value salvage and assignment tracking.

## Exit Criteria

- [ ] Debug metadata can be round-tripped for at least one reduced Zig Debug
      fixture.
- [ ] Optimizer passes have a documented debug attachment policy.
- [ ] Unsupported debug-info behavior is explicitly classified.

