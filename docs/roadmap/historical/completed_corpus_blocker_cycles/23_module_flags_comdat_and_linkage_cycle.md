# Cycle 23: Module Flags, COMDAT, And Linkage

## Goal

Preserve and reason conservatively about module-level linkage constructs that
matter for object/linker correctness and global optimization legality.

## Source Anchors

- LLVM IR: module flags, comdat, aliases, linkage, visibility, unnamed_addr,
  dso_local, section, align
- Local parser/verifier/printer: `src/ir/`
- Local globals: `src/passes/globaldce.zig`

## Plan

- [x] Inventory module flags and linkage records in Zig captured IR.
- [x] Parse and preserve module flags as opaque records where possible.
- [x] Parse COMDAT syntax as preserved metadata before optimizing with it.
- [x] Extend global/linkage verifier checks for accepted forms.
- [x] Ensure GlobalDCE treats unknown linkage conservatively.
- [x] Add round-trip fixtures for module-level records.

## Exit Criteria

- [x] Module-level records no longer block harmless corpus parsing.
- [x] Global optimization does not discard linkage-sensitive symbols unsafely.
- [x] Unsupported linkage forms are documented.

## Completion Notes

- Added top-level COMDAT record preservation for supported LLVM selection kinds.
- Existing top-level metadata preservation covers opaque module flag records.
- GlobalDCE now treats raw COMDAT-bearing local functions/globals as roots
  rather than interpreting COMDAT selection semantics.
- Added unit coverage for module flags, COMDAT round-trip, and conservative
  GlobalDCE COMDAT preservation, plus a local-conservative opt fixture.
