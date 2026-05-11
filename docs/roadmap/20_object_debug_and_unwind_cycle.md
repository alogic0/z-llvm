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

- [ ] Inventory which object/debug facts optimizer tests actually need.
- [ ] Add assembly/object smoke tests only for accepted scalar handoff cases.
- [ ] Keep DWARF emission separate from debug metadata preservation.
- [ ] Document unwind/CFI as out of scope until call/frame lowering requires it.
- [ ] Add relocation and symbol tests only for direct-call fixtures.

## Exit Criteria

- [ ] Object/debug work is bounded by optimizer validation needs.
- [ ] No docs imply broad MC replacement is complete.
- [ ] Existing object experiments have clear activation criteria.

