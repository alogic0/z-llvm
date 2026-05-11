# Cycle 1: Raw Zig IR Parser Surface

## Goal

Accept the smallest useful raw Zig-emitted LLVM IR surface that currently keeps
captured corpus rows classified as `unsupported`: aliases, raw function
attributes, attribute groups, selected module records, and parser-preserved
syntax that should not affect local optimizer behavior yet.

## Source Anchors

- Zig source: `../ziglang/src/codegen/llvm.zig`
- Local corpus: `docs/fixtures/zig_ir/manifest.tsv`
- Local parser: `src/ir/parser.zig`
- Local printer/verifier: `src/ir/printer.zig`, `src/ir/verifier.zig`
- Inventory: `docs/inventory/zig_llvm_pass_pipeline_inventory.md`

## Plan

- [x] Inventory every parser rejection in the checked raw corpus rows.
- [x] Add parser support for exported/internal aliases as preserved module-level
      records before optimizing through them.
- [x] Parse and preserve function attribute groups used by Zig ReleaseFast and
      ReleaseSmall fixtures.
- [x] Parse raw parameter/function attributes needed to classify memory effects
      and calling conventions conservatively.
- [x] Preserve unsupported module records that can be printed round-trip without
      affecting local passes.
- [x] Reject attribute forms that imply semantics the optimizer cannot model.
- [x] Add fixture rows that move one `tiny_scalar` captured raw row from
      `unsupported` to `parse,verify,optimizer-input`.
- [x] Keep normalized fixtures distinct from raw captured fixtures.

## Exit Criteria

- [x] At least one currently unsupported raw `tiny_scalar` captured row runs
      through `scripts/run_zig_corpus.sh`.
- [x] Aliases and attr groups are either parsed/preserved or rejected with a
      precise error.
- [x] Parser, printer, verifier, and optimizer fixture tests pass.

## Implementation Notes

- `src/ir/parser.zig` now accepts Zig-emitted global aliases such as
  `@add = alias i32 (i32, i32), ptr @tiny_scalar.add` as preserved
  module-level records.
- `src/ir/parser.zig` preserves `attributes #N = { ... }` groups and rejects
  sanitizer-style groups until the optimizer models their semantics.
- `src/ir/printer.zig` round-trips aliases, attribute groups, and raw module
  metadata separately from normalized scalar fixtures.
- `docs/fixtures/zig_ir/manifest.tsv` now classifies the stripped
  `tiny_scalar` `ReleaseFast` and `ReleaseSmall` captured rows as
  `parse,verify,optimizer-input`; the normalized fixture remains distinct.
- Remaining checked raw corpus rejections are inventoried in
  `docs/fixtures/zig_ir/README.md`.
