# Cycle 02: Debug Metadata Graph Verification

## Goal

Verify enough of the debug metadata graph to avoid accepting malformed Zig
Debug rows while still preserving opaque metadata that is not semantically
modeled yet.

## Plan

- [ ] Inventory metadata node kinds used by accepted and future Debug corpus
      rows.
- [ ] Add structural checks for compile units, files, subprograms, lexical
      scopes, local variables, expressions, and location records where present.
- [ ] Reject broken references, wrong operand counts, and impossible metadata
      root shapes.
- [ ] Keep unknown-but-preserved metadata nodes explicitly classified.
- [ ] Add reduced fixtures for valid graphs, dangling references, wrong node
      kinds, and unknown preserved nodes.
- [ ] Document the supported graph subset and remaining LLVM DIBuilder gaps.
- [ ] Compare preservation against the input text and, where meaningful,
      `opt-22 -S`.

## Exit Criteria

- [ ] Accepted Debug rows have metadata graph validation instead of opaque-only
      preservation.
- [ ] Invalid metadata fixtures fail with stable diagnostics.
- [ ] Debug metadata docs identify every deliberately opaque node kind.
