# Cycle 18: Function And Call ModRef Precision

## Goal

Use Zig-emitted function and parameter attributes to improve call mod/ref
classification conservatively.

## Source Anchors

- Corpus rows with `memory(none)`, `readonly`, `writeonly`, `nonnull`,
      `captures(none)`, and function declarations
- Local code: function attribute parser, memory effect analysis, alias/mod-ref
- LLVM: Attributor, FunctionAttrs, BasicAA mod/ref behavior
- Passes: DCE, ADCE, GVN, EarlyCSE, LICM, DSE

## Plan

- [x] Inventory call and parameter attributes in accepted corpus rows.
- [x] Interpret only attributes already preserved and verified by the local IR.
- [x] Improve call memory-effect classification for safe `memory(none)` and
      readonly cases.
- [x] Add fixtures proving calls block or allow memory optimizations correctly.
- [x] Keep interprocedural inference and Attributor-like derivation out of scope.
- [x] Document local attribute semantics versus LLVM's richer model.

## Exit Criteria

- [x] At least one source-backed call mod/ref precision improvement lands.
- [x] Unknown calls remain conservative barriers.
- [x] Pass docs list which attributes they trust.

## Completed Slice

- Extended local function attribute classification to include write-only call
  effects from `writeonly`, `memory(write)`, and `memory(argmem: write)`.
- Added `gvn_readonly_call_no_clobber` to prove `memory(read)` calls do not
  block repeated-load value numbering.
- Added `gvn_unknown_call_clobber_reject` to prove unknown calls remain
  conservative clobbers.
- Documented that this is preserved-attribute interpretation only, not LLVM
  Attributor or interprocedural inference.
