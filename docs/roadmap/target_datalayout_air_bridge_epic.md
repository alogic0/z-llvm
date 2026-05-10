# Next Epic After Pipeline-Ready Optimizer

Goal: move from optimizing hand-written LLVM-like IR fixtures toward replacing
the first real Zig LLVM backend boundary: target-aware IR semantics and a small
AIR-to-IR lowering bridge. This epic should start only after the
Pipeline-Ready Optimizer Epic has produced a stable scalar/memory optimization
pipeline.

This is not object emission yet. The output contract is still normalized IR,
but the input should become closer to what Zig's LLVM backend actually lowers.

## Relationship To Other Epics

Roadmap order:

```text
Pipeline-Ready Optimizer Epic
  -> Target DataLayout and AIR-to-IR Bridge Epic
  -> MC/Object Bootstrap Epic
```

- Previous epic: [Pipeline-Ready Optimizer Epic](pipeline_ready_optimizer_epic.md).
- This epic anchors the optimizer to Zig-like, target-aware IR input.
- Next epic: [MC/Object Bootstrap Epic](mc_object_bootstrap_epic.md).
- Do not start MC/object emission until this epic can produce verified,
  target-aware, optimized IR for small scalar functions.

## Suggestions Before Starting

- Treat this as the bridge from optimizer prototype to Zig-backed evidence. The
  first slices should be driven by tiny Zig examples and
  `ziglang/src/codegen/llvm/FuncGen.zig`, not by generic LLVM IR features that
  are not yet proven necessary for Zig.
- Keep the initial target matrix as a documentation and parser goal, but make
  implementation slices land one target first, preferably `x86_64-linux-gnu` or
  `x86_64-linux-musl`. Adding four targets at once will blur whether failures
  come from parsing, ABI rules, DataLayout, or the AIR-like bridge.
- Do module records before AIR lowering. Triple, datalayout, linkage, function
  attributes, and parameter attributes need to round-trip before lowered
  Zig-like functions can be compared honestly with Zig-emitted LLVM IR.
- Add a fixture taxonomy before adding many fixtures: `zig-equivalent`,
  `opt-equivalent`, `local-conservative`, and `parse-preserve-only`. The last
  category is important for attributes and records that are not semantically
  consumed yet.
- Keep the AIR-like input bridge deliberately synthetic. It should model the
  small subset needed to compare against Zig-emitted IR, but it should not
  become a second frontend or a replacement for Zig AIR semantics.
- Every implementation slice should name the exact Zig LLVM backend entry points
  it is replacing or approximating, then link the resulting docs back to
  `docs/inventory/zig_llvm_api_inventory.md`.

## 1. Target Triple and DataLayout Foundation

Status: initial target matrix implemented and verified in Cycle 22.

- [x] Add a `src/target/` module for target triple parsing and target identity.
- [x] Parse LLVM `target triple` module records and preserve them through printing.
- [x] Parse LLVM `target datalayout` module records and preserve them through printing.
- [x] Add a minimal `DataLayout` query API for pointer size, pointer alignment, integer ABI alignment, and aggregate alignment placeholders.
- [x] Support a small initial target matrix: `x86_64-linux-gnu`, `x86_64-linux-musl`, `aarch64-linux-gnu`, and `wasm32-wasi`.
- [x] Compare parsed/query results against LLVM for the target matrix with unit tests or fixture-generated expectations.
- [x] Document the mapping to LLVM `DataLayout`, `Triple`, `TargetMachine`, and Zig's `Compilation/Config.zig` backend selection.

Suggested slice boundary:

- [ ] First land parse/preserve for `target triple` and `target datalayout`
      without interpreting every field.
- [x] Then add one target's pointer-size and integer-alignment queries with
      tests against LLVM.
- [x] Only after that, expand the target matrix.

## 2. Module-Level IR Surface

Status: scalar global preservation implemented and verified in Cycle 23.

- [x] Add module-level target records to the IR model: triple, datalayout, source filename if useful for round-tripping.
- [x] Add global variables and constant global initializers for the subset emitted by tiny Zig examples.
- [x] Add linkage parsing for the first supported forms: `internal`, `private`, `external`, and default external definitions.
- [x] Add visibility parsing for the first supported forms emitted by tiny Zig examples.
- [x] Add function attributes as parsed-and-preserved metadata where transforms do not understand them yet.
- [x] Add parameter attributes as parsed-and-preserved metadata for simple ABI-significant cases.
- [x] Update verifier rules so unsupported module-level constructs fail explicitly instead of being silently ignored.
- [x] Add normalized round-trip fixtures for module-level records emitted by Zig's LLVM backend.

Suggested slice boundary:

- [ ] Split parse-and-preserve metadata from verifier-enforced semantics. For
      example, function attributes can initially be preserved and documented as
      not consumed by transforms.
- [ ] Add explicit unsupported diagnostics for globals or attributes that would
      affect optimization correctness if silently ignored.

## 3. ABI-Aware Function Signature Foundation

Status: scalar ABI classification implemented and verified in Cycle 24.

- [ ] Add a target-aware function type model for scalar integer, pointer, void, and simple aggregate placeholder returns.
- [x] Add `void` return type support.
- [x] Add basic calling convention parsing and preservation for the calling conventions Zig emits in small examples.
- [x] Add ABI classification docs for scalar parameters and returns on the initial target matrix.
- [ ] Add tests comparing tiny function signatures against Zig-emitted LLVM IR.
- [ ] Keep full aggregate ABI lowering out of scope until target layout support is strong enough.

Suggested slice boundary:

- [x] Start with scalar integer and pointer parameters/returns only.
- [x] Add `void` because Zig-emitted LLVM IR needs it for realistic tiny
      functions, but keep aggregate classification as documentation-only until
      the target layout model can support it.

## 4. AIR-Like Input Bridge

- [x] Define a tiny AIR-like test input format or helper builder inside `src/tools/` or tests, not a full Zig frontend.
- [x] Lower scalar integer arithmetic into the project IR: add/sub/mul/bitwise/shift/casts.
- [x] Lower control flow into the project IR: blocks, conditional branch, return, unreachable.
- [x] Lower stack memory into the project IR: alloca/load/store/GEP for scalar stack slots.
- [x] Lower loops in the canonical form expected by current LoopInfo/LICM where possible.
- [ ] Add a small bridge driver that can print pre-optimization IR and run named optimizer pipelines.
- [ ] Keep comptime, generics, full AIR semantics, error unions, optionals, async, and debug info out of scope.

Suggested slice boundary:

- [x] Define the bridge input as a test/build helper format with a stable
      printer, so failures can be reduced without invoking the whole Zig
      compiler every time.
- [ ] Add bridge output before optimization and after the named optimizer
      pipeline, so lowering bugs and optimizer bugs are easier to separate.

## 5. Zig-Emitted IR Comparison Harness

- [ ] Add scripts or docs for producing tiny Zig LLVM IR fixtures with the local Zig compiler.
- [ ] Normalize Zig-emitted LLVM IR into the subset this project can compare.
- [ ] Add fixture pairs: tiny Zig source, Zig-emitted pre-optimization LLVM IR, project-lowered IR if available, and optimized output.
- [ ] Compare structure rather than raw text: same function signatures, CFG, def-use shape, memory operations, and optimizer-visible scalar instructions.
- [ ] Mark each fixture as `zig-equivalent`, `opt-equivalent`, or `local-conservative`.
- [ ] Document every mismatch as either unsupported IR, target ABI gap, optimizer gap, or intentional normalization difference.

Suggested slice boundary:

- [ ] Start with checked-in tiny Zig sources and checked-in normalized LLVM IR
      outputs generated by a documented command.
- [ ] Make regeneration explicit and manual at first. Automatic regeneration can
      come later after normalization is stable.

## 6. Pipeline Integration

- [ ] Add a named `zig-scalar-foundation` pipeline that runs target parsing, AIR-like lowering, verifier, optimizer pipeline, and normalized output.
- [ ] Add command-line flags for selecting target triple and datalayout when they are not present in the input.
- [ ] Add diagnostics that explain when a target feature is missing rather than failing with generic parse or verifier errors.
- [ ] Keep the old LLVM-IR-input optimizer path intact for pass-level development and regression tests.
- [ ] Add tests proving both entry paths produce equivalent IR for small scalar examples.

## 7. Documentation and Inventory Updates

- [ ] Update `docs/inventory/zig_llvm_api_inventory.md` for target triple, datalayout, ABI query, and AIR lowering coverage.
- [ ] Add `docs/target/datalayout.md` with LLVM references, supported targets, implemented queries, and known gaps.
- [ ] Add `docs/codegen/air_lowering.md` for the tiny AIR-like bridge and how it maps to Zig's `FuncGen.zig`.
- [ ] Add `docs/ir_module.md` for module-level records, globals, linkage, and attributes.
- [ ] Update `docs/testing.md` with Zig-emitted fixture generation and comparison policy.
- [ ] Keep this epic separate from MC/object emission; link to a future object-emission epic instead of expanding scope.

## 8. Verification Gate

- [ ] Run `zig fmt` on touched Zig files.
- [ ] Run `zig build test`.
- [ ] Run `bash scripts/compare_opt.sh`.
- [ ] Run Zig-emitted IR comparison fixtures.
- [ ] Verify the initial target matrix.
- [ ] Confirm docs list all unsupported target, ABI, module, and AIR constructs before marking implementation slices complete.

## Out of Scope

- Native instruction selection.
- Register allocation.
- Assembly or object emission.
- DWARF or CodeView generation.
- Full Zig AIR semantics.
- Full aggregate ABI lowering.
- LLVM bitcode parsing.
- LTO.
- Sanitizer instrumentation.

## Why This Epic Should Follow The Optimizer Epic

The optimizer epic makes the project useful on a richer IR subset. This epic
then anchors that optimizer to Zig's actual LLVM backend boundary. It should
answer: can we take small Zig-like compiler input, lower it into our IR with
target-aware semantics, optimize it, and compare it against what Zig currently
asks LLVM to optimize?

If yes, the next epic after this can be an **MC/Object Bootstrap Epic** for one
target and a tiny scalar function subset.
