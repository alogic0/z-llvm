# Cycle 01: Debug Intrinsic Variable Location Boundary

## Goal

Accept the debug intrinsics that block real Zig Debug-mode rows without
pretending to implement full debug-info salvage.

## Plan

- [x] Inventory every `llvm.dbg.*` intrinsic present in current Zig-emitted
      Debug rows.
- [x] Add parser support for the smallest required `llvm.dbg.value` and
      `llvm.dbg.declare` spellings.
- [x] Preserve intrinsic operands, metadata references, and call position
      through parse, print, verify, and no-op optimizer paths.
- [x] Keep transformations that would need variable-location salvage disabled
      for functions containing accepted debug value intrinsics.
- [x] Add accepted and rejected reduced fixtures for supported and unsupported
      debug intrinsic forms.
- [x] Update `docs/debug/metadata_inventory.md`, `docs/unsupported_ir.md`, and
      the Zig IR manifest.
- [x] Run the readiness gate and record whether new Debug rows move from
      `future` to `optimizer-input` or only to `parse,verify`.

## Exit Criteria

- [x] At least one previously future-only Debug fixture is accepted through
      parse and verify.
- [x] Unsupported debug intrinsic forms fail closed with named diagnostics.
- [x] Optimizer behavior remains conservative and documented.

## Completed Slice

Cycle 01 accepts `llvm.dbg.value` and `llvm.dbg.declare` as preservation-only
variable-location intrinsics. Raw operands are retained through parse, print,
and verify, while the pass manager skips transform passes for modules that
contain them until debug value salvage is implemented. The accepted reduced
fixtures moved from `unsupported,future` to `parse,verify`; they are not
`optimizer-input`.
