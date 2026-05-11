# Cycle 05: Strict FP Fold Legality

## Goal

Teach scalar simplification the strict FP identities that are always legal, and
keep unsafe identities rejected.

## Plan

- [x] Inventory LLVM InstSimplify and InstCombine strict FP folds relevant to
      accepted Zig ReleaseFast and ReleaseSmall rows.
- [x] Implement only folds proven legal with NaN, signed zero, infinity, and
      exception behavior.
- [x] Add explicit reject tests for locally unsupported `x + 0.0`, `x * 1.0`,
      `x - 0.0`, `x / 1.0`, and self-compare cases until the exact LLVM
      legality rules are reproduced.
- [x] Add accepted fixtures for constant-only folds that match LLVM strict
      behavior.
- [x] Wire FP legality through shared helper APIs instead of pass-local string
      checks.
- [x] Update `docs/passes/inst_simplify.md` and `docs/passes/instcombine.md`.
- [x] Compare matching fixtures against `opt-22`.

## Exit Criteria

- [x] Strict FP folds are enabled only where the semantic model proves legality.
- [x] Locally unsupported algebraic identities remain unchanged and tested.
- [x] Pass docs separate strict behavior from fast-math behavior.

## Completed Slice

Cycle 05 adds the first strict-FP simplification boundary:

- `fcmp false` and `fcmp true` fold to constant `i1` values without requiring
  fast-math facts.
- `fcmp ord` and `fcmp uno` fold only when both operands are classified scalar
  FP literals and NaN-orderedness is known.
- Strict `fadd x, 0.0`, `fsub x, 0.0`, `fmul x, 1.0`, `fdiv x, 1.0`, and
  ordinary self-compare folds remain rejected locally until each LLVM legality
  proof is reproduced.
- Fixtures are compared with `bash scripts/compare_opt.sh`; local-conservative
  orderedness coverage documents the narrower APFloat model.
