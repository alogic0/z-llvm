# Cycle 05: Strict FP Fold Legality

## Goal

Teach scalar simplification the strict FP identities that are always legal, and
keep unsafe identities rejected.

## Plan

- [ ] Inventory LLVM InstSimplify and InstCombine strict FP folds relevant to
      accepted Zig ReleaseFast and ReleaseSmall rows.
- [ ] Implement only folds proven legal with NaN, signed zero, infinity, and
      exception behavior.
- [ ] Add explicit reject tests for unsafe `x + 0.0`, `x * 1.0`, `x - 0.0`,
      `x / 1.0`, and self-compare cases where LLVM requires flags or stronger
      facts.
- [ ] Add accepted fixtures for constant-only folds that match LLVM strict
      behavior.
- [ ] Wire FP legality through shared helper APIs instead of pass-local string
      checks.
- [ ] Update `docs/passes/inst_simplify.md` and `docs/passes/instcombine.md`.
- [ ] Compare matching fixtures against `opt-22`.

## Exit Criteria

- [ ] Strict FP folds are enabled only where the semantic model proves legality.
- [ ] Unsafe algebraic identities remain unchanged and tested.
- [ ] Pass docs separate strict behavior from fast-math behavior.
