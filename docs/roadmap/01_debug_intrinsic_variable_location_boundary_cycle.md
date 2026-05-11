# Cycle 01: Debug Intrinsic Variable Location Boundary

## Goal

Accept the debug intrinsics that block real Zig Debug-mode rows without
pretending to implement full debug-info salvage.

## Plan

- [ ] Inventory every `llvm.dbg.*` intrinsic present in current Zig-emitted
      Debug rows.
- [ ] Add parser support for the smallest required `llvm.dbg.value` and
      `llvm.dbg.declare` spellings.
- [ ] Preserve intrinsic operands, metadata references, and call position
      through parse, print, verify, and no-op optimizer paths.
- [ ] Keep transformations that would need variable-location salvage disabled
      for functions containing accepted debug value intrinsics.
- [ ] Add accepted and rejected reduced fixtures for supported and unsupported
      debug intrinsic forms.
- [ ] Update `docs/debug/metadata_inventory.md`, `docs/unsupported_ir.md`, and
      the Zig IR manifest.
- [ ] Run the readiness gate and record whether new Debug rows move from
      `future` to `optimizer-input` or only to `parse,verify`.

## Exit Criteria

- [ ] At least one previously future-only Debug fixture is accepted through
      parse and verify.
- [ ] Unsupported debug intrinsic forms fail closed with named diagnostics.
- [ ] Optimizer behavior remains conservative and documented.
