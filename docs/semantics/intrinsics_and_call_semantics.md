# Intrinsics And Call Semantics

This document tracks the local subset of LLVM intrinsic and direct-call
semantics needed by Zig-emitted IR corpus rows.

## Upstream Mapping

- LLVM intrinsic definitions: `llvm/include/llvm/IR/Intrinsics.td`
- LLVM call memory classification shape: `llvm::CallBase`,
  `llvm::MemoryEffects`, and function attribute queries in LLVM IR analysis
- Local representation: `src/ir/core.zig` `CallInst`
- Local parsing: `src/ir/parser.zig`
- Local call effects: `src/analysis/function_attrs.zig`
- Local folds: `src/passes/inst_simplify.zig`, used by InstCombine and SCCP

## Implemented Slice

- Preserve `tail`, `musttail`, and `notail` markers on direct calls as
  parser/printer facts. Their strict LLVM verifier and lowering semantics are
  not modeled yet.
- Preserve return attributes before the return type on function headers and
  call sites, such as Zig-emitted `range(i32 ...)` and
  `call range(i16 0, 17) i16 @llvm.ctpop.i16(...)`, without interpreting them
  in optimizer legality yet.
- Preserve `or disjoint` as a poison-affecting binary flag and avoid folding
  flagged operations unless the local fold explicitly models the flag.
- Resolve function and declaration attribute group references such as `#0`
  for call memory-effect classification.
- Treat `memory(none)` and `readnone` calls as no-memory-effect.
- Treat `memory(read)` and `readonly` calls as read-only memory effects.
- Preserve a small LLVM `MemoryEffects`-shaped model for direct calls:
  all-memory `read`/`write`/`readwrite`, `argmem: ...`, and
  `inaccessiblemem: ...`.
- Treat `memory(argmem: ...)` direct calls as argument-memory-only for alias
  ModRef queries when pointer arguments can be compared with the queried local
  memory location.
- Treat `memory(inaccessiblemem: ...)` direct calls as no-mod-ref for ordinary
  LLVM IR-accessible memory queries while preserving their overall side-effect
  classification.
- Keep unknown calls and unknown intrinsics conservative.
- Parse `llvm.assume` as a direct void call. Its Zig-emitted
  `memory(inaccessiblemem: write)` attribute keeps it side-effecting in the
  local optimizer, so it is preserved rather than treated as a free no-op.
- Parse `llvm.trap` as a direct void call. It remains a side-effecting
  intrinsic boundary and is preserved before `unreachable`; no trap lowering is
  modeled in the optimizer.
- Parse indirect calls through pointer SSA values conservatively. The verifier
  checks only the callee pointer and argument values because opaque pointers do
  not carry a full callable signature locally.
- Accept source-backed calls with register arguments to zero-parameter `naked`
  function definitions, such as Zig's x86_64 clone shim, while continuing to
  reject ordinary direct-call signature mismatches.
- Fold integer min/max intrinsics only for source-backed scalar cases:
  `llvm.smin.*`, `llvm.smax.*`, `llvm.umin.*`, and `llvm.umax.*`.

## Corpus Coverage

- `integers_release_fast` now parses and verifies raw Zig-emitted
  `llvm.smin.i32` plus `tail call`.
- `integers_release_fast_aarch64` now parses and verifies the same intrinsic
  shape for the non-host target fixture, but stays future-only for optimizer
  runner selection.
- `control_flow_calls_release_fast` now parses and verifies raw Zig-emitted
  `llvm.assume`, return `range` attributes, `or disjoint`, unnamed entry-block
  references, and loop backedge metadata. Loop metadata is accepted and dropped
  until the dedicated loop metadata cycle.

## Fixture Coverage

- `test/opt/inputs/instcombine_intrinsic_minmax.ll`
- `test/opt/expected/z_llvm/instcombine_intrinsic_minmax.ll`
- `test/opt/fixtures.tsv` row `instcombine_intrinsic_minmax`

Comparison command:

```sh
bash scripts/compare_opt.sh
```

## Remaining Gaps

- `llvm.assume` is represented conservatively as a side-effecting call, not as
  an assumption cache input.
- `llvm.trap` is represented conservatively as a side-effecting noreturn
  intrinsic-shaped call, not as a target trap instruction.
- Indirect calls are represented only as conservative call boundaries; no
  devirtualization, signature refinement, inlining, or native lowering is
  modeled.
- `invoke`, `callbr`, full `musttail` legality/lowering, operand bundle
  semantics, and inline asm lowering remain unsupported.
- Attribute groups are parsed only as preserved IR records with conservative
  memory-effect extraction, not as a full LLVM attribute model. Operand bundles,
  indirect calls, target-library effects, and intrinsic-specific call effects
  remain conservative.
- Loop instruction metadata is accepted only as parser input and is not
  preserved by the printer yet.
