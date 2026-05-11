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

- Preserve `tail call` on direct calls. `musttail` and `notail` remain
  unsupported because their verifier and lowering semantics are stricter.
- Resolve function and declaration attribute group references such as `#0`
  for call memory-effect classification.
- Treat `memory(none)` and `readnone` calls as no-memory-effect.
- Treat `memory(read)` and `readonly` calls as read-only memory effects.
- Keep unknown calls and unknown intrinsics conservative.
- Fold integer min/max intrinsics only for source-backed scalar cases:
  `llvm.smin.*`, `llvm.smax.*`, `llvm.umin.*`, and `llvm.umax.*`.

## Corpus Coverage

- `integers_release_fast` now parses and verifies raw Zig-emitted
  `llvm.smin.i32` plus `tail call`.
- `integers_release_fast_aarch64` now parses and verifies the same intrinsic
  shape for the non-host target fixture, but stays future-only for optimizer
  runner selection.

## Fixture Coverage

- `test/opt/inputs/instcombine_intrinsic_minmax.ll`
- `test/opt/expected/z_llvm/instcombine_intrinsic_minmax.ll`
- `test/opt/fixtures.tsv` row `instcombine_intrinsic_minmax`

Comparison command:

```sh
bash scripts/compare_opt.sh
```

## Remaining Gaps

- `llvm.assume` is not represented with operand attributes such as
  `i1 noundef` yet.
- Indirect calls, `invoke`, `callbr`, `musttail`, operand bundles, and inline
  asm remain unsupported.
- Attribute groups are parsed only as preserved IR records with conservative
  memory-effect extraction, not as a full LLVM attribute model.

