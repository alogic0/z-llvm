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

- [ ] Inventory module flags and linkage records in Zig captured IR.
- [ ] Parse and preserve module flags as opaque records where possible.
- [ ] Parse COMDAT syntax as preserved metadata before optimizing with it.
- [ ] Extend global/linkage verifier checks for accepted forms.
- [ ] Ensure GlobalDCE treats unknown linkage conservatively.
- [ ] Add round-trip fixtures for module-level records.

## Exit Criteria

- [ ] Module-level records no longer block harmless corpus parsing.
- [ ] Global optimization does not discard linkage-sensitive symbols unsafely.
- [ ] Unsupported linkage forms are documented.

