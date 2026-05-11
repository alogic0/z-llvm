# Cycle 10: Error, Optional, And Aggregate ABI Expansion

## Goal

Use source-backed Zig rows to expand support for lowered errors, optionals, and
small aggregate ABI shapes without attempting full frontend or ABI coverage.

## Source Anchors

- Corpus rows: `error_switch_release_fast`, `aggregate_abi_release_fast`,
      `packed_bits_release_fast`, older aggregate fixtures
- Local code: parser, verifier, InstCombine, SCCP, SROA, DataLayout helpers
- Docs: aggregate IR, target ABI, unsupported IR

## Plan

- [x] Inventory accepted error, optional, packed, and aggregate ABI patterns in
      current captures.
- [x] Add one or two new source-backed rows that expose a concrete missing
      aggregate or optional lowering form.
- [x] Extend parser/verifier support only for observed shapes.
- [x] Add SROA/InstCombine/SCCP fixtures where local behavior is intended to
      match LLVM.
- [x] Keep full target ABI classification, byval/sret, varargs, and vector ABI
      deferred unless the selected rows require them.
- [x] Update docs with accepted ABI-shaped IR and remaining gaps.

## Exit Criteria

- [x] At least one new source-backed aggregate/error/optional blocker is closed.
- [x] Accepted rows run through the appropriate local pipeline.
- [x] ABI-related unsupported behavior remains explicit and tested.

## Completed Slice

Cycle 10 adds the source-backed `optional_pointer_release_fast` row generated
from `test/zig/inputs/optional_pointer.zig`. The missing IR surface was the
LLVM null pointer constant used in `icmp eq ptr %p, null`; the local IR now
parses, prints, verifies, and preserves `null` only for pointer-typed values.
The row runs through `zig-release-fast-accepted`, and
`optional_pointer_null_preserve` compares scalar cleanup behavior with
`opt-22`. Full aggregate ABI, `byval`/`sret`, varargs, vectors, and broad
optional/error-union lowering stay deferred.
