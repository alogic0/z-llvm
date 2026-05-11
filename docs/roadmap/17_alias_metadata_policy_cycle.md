# Cycle 17: Alias Metadata Policy

## Goal

Define how the local IR treats LLVM alias metadata such as `noalias`,
`alias.scope`, and `tbaa`, then accept only source-backed forms that can be
preserved or interpreted safely.

## Source Anchors

- Future Zig captures containing alias metadata
- LLVM IR metadata: `!tbaa`, `!alias.scope`, `!noalias`
- Local analysis: alias/mod-ref and memory effects
- Docs: unsupported IR, alias analysis

## Plan

- [x] Inventory alias metadata in current and refreshed Zig captures.
- [x] Preserve metadata textually first where parser support is needed.
- [x] Reject metadata-driven noalias reasoning until verifier and alias analysis
      can prove it.
- [x] Add reduced fixtures for accepted preservation and rejected interpretation.
- [x] Document how metadata affects, or does not affect, each memory pass.
- [x] Avoid unsound optimization based on metadata until compared with LLVM.

## Exit Criteria

- [x] Alias metadata is not silently dropped when present in accepted rows.
- [x] No pass consumes alias metadata without tests.
- [x] Unsupported metadata behavior is explicit in docs.

## Completed Slice

- Added opaque parser/printer preservation for `!tbaa`, `!alias.scope`, and
  `!noalias` instruction metadata attachments.
- Kept metadata out of alias, mod/ref, MemorySSA, DSE, EarlyCSE, GVN, and LICM
  reasoning until an LLVM-compared metadata-aware AA slice exists.
- Added unit and opt fixture coverage for alias metadata preservation plus an
  unsupported metadata rejection test.
