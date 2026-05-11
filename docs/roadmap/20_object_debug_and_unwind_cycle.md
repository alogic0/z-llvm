# Cycle 20: Object, Debug, And Unwind Boundary

## Goal

Define the minimum object/debug/unwind behavior needed to validate optimizer
output without attempting to replace LLVM MC broadly.

## Source Anchors

- LLVM: MC object writers, DWARF emission, CFI/unwind info
- Local docs: `docs/mc/elf_object_writer.md`,
  `docs/mc/assembly_printer.md`, `docs/debug/metadata_inventory.md`
- Local code: `src/mc/`

## Plan

- [x] Inventory which object/debug facts optimizer tests actually need.
- [x] Add assembly/object smoke tests only for accepted scalar handoff cases.
- [x] Keep DWARF emission separate from debug metadata preservation.
- [x] Document unwind/CFI as out of scope until call/frame lowering requires it.
- [x] Add relocation and symbol tests only for direct-call fixtures.

## Exit Criteria

- [x] Object/debug work is bounded by optimizer validation needs.
- [x] No docs imply broad MC replacement is complete.
- [x] Existing object experiments have clear activation criteria.

## Completion Notes

- Added `docs/mc/object_debug_unwind_boundary.md` to define the object,
  debug-metadata, DWARF, and unwind boundaries.
- Added objdump and readelf object checks to the handoff validation script.
- Kept object work to accepted tiny scalar/direct-call fixtures; DWARF,
  CodeView, CFI, unwind tables, and broad MC replacement remain out of scope.
