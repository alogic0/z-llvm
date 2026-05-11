# Cycle 02: Debug Metadata Graph Verification

## Goal

Verify enough of the debug metadata graph to avoid accepting malformed Zig
Debug rows while still preserving opaque metadata that is not semantically
modeled yet.

## Plan

- [x] Inventory metadata node kinds used by accepted and future Debug corpus
      rows.
- [x] Add structural checks for compile units, files, subprograms, lexical
      scopes, local variables, expressions, and location records where present.
- [x] Reject broken references, wrong operand counts, and impossible metadata
      root shapes.
- [x] Keep unknown-but-preserved metadata nodes explicitly classified.
- [x] Add reduced fixtures for valid graphs, dangling references, wrong node
      kinds, and unknown preserved nodes.
- [x] Document the supported graph subset and remaining LLVM DIBuilder gaps.
- [x] Compare preservation against the input text and, where meaningful,
      `opt-22 -S`.

## Exit Criteria

- [x] Accepted Debug rows have metadata graph validation instead of opaque-only
      preservation.
- [x] Invalid metadata fixtures fail with stable diagnostics.
- [x] Debug metadata docs identify every deliberately opaque node kind.

## Completed Slice

Cycle 02 adds verifier-side debug metadata graph checks for the local DI subset:
`llvm.dbg.cu`, `DICompileUnit`, `DIFile`, `DISubprogram`, `DILexicalBlock`,
`DILocalVariable`, `DIExpression`, `DILocation`, `DISubroutineType`,
`DIBasicType`, and `DIDerivedType`. Unknown metadata records remain preserved
when their numeric references resolve. Invalid fixtures now fail with
`UnknownMetadata` or `InvalidDebugMetadata`.
