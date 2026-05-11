# Cycle 7: Debug Metadata Corpus Expansion

## Goal

Broaden debug metadata preservation from the current reduced fixture toward
source-backed Debug captures, without implementing debug value salvage or full
DWARF emission.

## Source Anchors

- Manifest row: `debug_metadata_reduced`
- Zig Debug captures under `tmp/zig_ir/raw/` or future reduced fixtures
- LLVM metadata: `DICompileUnit`, `DISubprogram`, `DILocation`, module flags
- Local docs: debug metadata and unsupported IR docs

## Plan

- [x] Select one or two small Debug source-backed shapes and reduce them to
      manageable metadata fixtures.
- [x] Preserve compile-unit, subprogram, lexical location, and line metadata
      needed by accepted instructions.
- [x] Reject or defer debug intrinsics, debug value salvage, and full variable
      location tracking unless explicitly reduced.
- [x] Add parser, printer, verifier, and pass preservation tests for accepted
      metadata.
- [x] Keep optimizer behavior conservative when debug metadata is attached.
- [x] Update docs to distinguish metadata preservation from debug-info quality.

## Exit Criteria

- [x] Debug metadata coverage has at least one new source-backed reduced fixture.
- [x] Accepted metadata survives parse/print and no-op optimizer pipelines.
- [x] Unsupported debug constructs fail closed or are documented as future.

## Completed Slice

Cycle 7 adds `debug_scope_branch_reduced`, a reduced Debug fixture that
preserves `DICompileUnit`, `DISubprogram`, `DILexicalBlock`, instruction
`!dbg`, and branch `!dbg` metadata opaquely. The accepted Debug corpus path
remains verifier-only (`zig-debug-accepted`), and debug value intrinsics,
location salvage, variable tracking, and emitted debug-info quality remain
future work.
