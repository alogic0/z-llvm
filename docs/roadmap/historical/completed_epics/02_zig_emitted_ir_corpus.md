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

- [x] Define fixture layout by source feature, optimization mode, target triple,
      and expected LLVM comparison mode.
- [x] Add a fixture manifest format that records:
      Zig emitter version/revision, Zig source revision, target, optimization
      mode, command used, IR file, expected parser/verifier status, and
      comparison notes.
- [x] Regenerate authoritative fixtures with a Zig executable built from the
      same `../ziglang` checkout used by the inventory source anchors.
- [x] Add initial source groups:
      integers, pointers, arrays, structs, optionals, error unions, slices,
      loops, calls, comptime constants, globals, atomics, volatile, inline asm,
      and debug-info examples.
- [x] Capture IR for Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall where
      supported.
- [x] Add target coverage starting with the native host target, then one extra
      non-host target used by Zig's LLVM path.
- [x] Classify each fixture as:
      `parse`, `verify`, `optimizer-input`, `debug-info-only`, `unsupported`,
      or `future`.
- [x] Keep synthetic LLVM fixtures only when they isolate a behavior not easily
      emitted from Zig.

## Deliverables

- [x] `../fixtures/zig_ir/README.md`
- [x] Fixture manifest files.
- [x] Initial Zig source fixture set.
- [x] Captured LLVM IR files.
- [x] Corpus coverage table.

## Exit Criteria

- [x] Parser/verifier work can be driven from real Zig-emitted IR.
- [x] Each optimizer epic has at least one Zig-originated fixture family.
- [x] Unsupported IR forms are documented instead of silently ignored.
- [x] Fixture emitter revision and inventory source revision match for
      authoritative rows, or the mismatch is explicitly classified as
      `legacy-bootstrap`.

## Completed Slices

### Slice 1: Zig-Emitted IR Corpus Bootstrap

- [x] Created `../fixtures/zig_ir/README.md`.
- [x] Created `../fixtures/zig_ir/manifest.tsv`.
- [x] Added first fixture group: `tiny_scalar`.
- [x] Covered Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall in the manifest.
- [x] Recorded Zig emitter, source revision status, target triple, optimize
      mode, command used, emitted IR path, checked IR path, and fixture
      classification.
- [x] Classified fixtures as `parse`, `verify`, `optimizer-input`,
      `unsupported`, or `future`.
- [x] Added notes connecting each fixture row back to the LLVM pass inventory.

### Slice 2: Initial Corpus Completion

- [x] Added source groups beyond `tiny_scalar`:
      `integers`, `pointers_memory`, `aggregates`, `control_flow_calls`,
      `globals_comptime`, and `atomics_inline_asm_debug`.
- [x] Checked in captured stripped LLVM IR files where they do not contain
      machine-local paths or excessive unrelated std/debug support.
- [x] Added enough Zig-originated fixture families for every active optimizer
      epic to have at least one source-backed input family.
- [x] Added non-host target coverage with `integers.ReleaseFast.aarch64.ll`.
- [x] Left Debug and ReleaseSafe raw IR as generated-but-untracked when the
      emitted files were too broad for a checked fixture.

### Slice 3: Align Fixture Emitter With Inventory Source

- [x] Selected `../ziglang/build/stage4/bin/zig`.
- [x] Regenerated the captured corpus with that executable.
- [x] Updated `manifest.tsv` so authoritative rows record the matching source
      revision.
- [x] Replaced the previous `0.16.0` captured fixtures with current
      `../ziglang` output.

## Completion Notes

Epic 2 is complete as an authoritative corpus bootstrap for `../ziglang`
revision `f35e38f6a6`, not as exhaustive Zig language coverage. Future epics
should extend and refresh this corpus from the same Zig source revision used by
the inventories.
