# Cycle 6: Next Source-Backed Fixture Wave

## Goal

Choose and capture the next small set of Zig source fixtures based on upstream
LLVM-removal relevance, then classify them honestly before implementing more
parser or optimizer behavior.

## Source Anchors

- Zig source checkout: `../ziglang`
- Current corpus docs: `docs/fixtures/zig_ir/README.md`
- Upstream path: `docs/roadmap/zig_upstream_llvm_removal_path.md`
- Readiness report: `docs/upstream_integration_readiness.md`

## Plan

- [x] Select three to five new source groups that cover real Zig lowering
      surfaces not already represented.
- [x] Prefer small exported functions that avoid stdlib pull-in unless the
      blocker being studied is Debug or safety support.
- [x] Capture ReleaseFast first, then ReleaseSmall/ReleaseSafe/Debug only when
      mode differences matter.
- [x] Add manifest rows as `unsupported,future` first unless local parse,
      verify, and accepted pipeline runs are proven.
- [x] Promote only source-backed blockers into future implementation cycles.

## Exit Criteria

- [x] New rows have source, captured IR, emitter revision, command, and honest
      classification.
- [x] The next implementation cycle is selected from observed blockers, not
      generic LLVM pass inventory.
- [x] `scripts/run_zig_corpus.sh` and readiness checks pass after the update.

## Completion Notes

- Rebuilt `../ziglang` stage3/stage4 so fixture capture uses
  `0.17.0-dev.304+9787df942`, matching `../ziglang` HEAD `9787df9421`.
- Added four ReleaseFast source-backed groups: `float_compare`,
  `aggregate_abi`, `packed_bits`, and `error_switch`.
- Classified `aggregate_abi`, `packed_bits`, and `error_switch` as accepted
  optimizer-input rows after the local ReleaseFast pipeline ran.
- Kept `float_compare` as `unsupported,future`; it is the next source-backed
  implementation candidate because it exposes concrete `fmul` and `fcmp`
  blockers.
