# Epic 2: Zig-Emitted IR Corpus

## Goal

Build a fixture corpus from real LLVM IR emitted by Zig, so local parser,
verifier, optimizer, and comparison work starts from Zig's actual behavior
instead of hand-written LLVM examples alone.

## Inputs

- `../inventory/zig_llvm_pass_pipeline_inventory.md`
- Existing fixtures under `../fixtures`
- Small Zig programs that exercise language and target features

## Plan

- [ ] Define fixture layout by source feature, optimization mode, target triple,
      and expected LLVM comparison mode.
- [ ] Add a fixture manifest format that records:
      Zig version, target, optimization mode, command used, IR file, expected
      parser/verifier status, and comparison notes.
- [ ] Add initial source groups:
      integers, pointers, arrays, structs, optionals, error unions, slices,
      loops, calls, comptime constants, globals, atomics, volatile, inline asm,
      and debug-info examples.
- [ ] Capture IR for Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall where
      supported.
- [ ] Add target coverage starting with the native host target, then one extra
      non-host target used by Zig's LLVM path.
- [ ] Classify each fixture as:
      `must parse`, `must verify`, `optimizer input`, `debug-info only`,
      `unsupported but documented`, or `future`.
- [ ] Keep synthetic LLVM fixtures only when they isolate a behavior not easily
      emitted from Zig.

## Deliverables

- [ ] `../fixtures/zig_ir/README.md`
- [ ] Fixture manifest files.
- [ ] Initial Zig source fixture set.
- [ ] Captured LLVM IR files.
- [ ] Corpus coverage table.

## Exit Criteria

- [ ] Parser/verifier work can be driven from real Zig-emitted IR.
- [ ] Each optimizer epic has at least one Zig-originated fixture family.
- [ ] Unsupported IR forms are documented instead of silently ignored.
