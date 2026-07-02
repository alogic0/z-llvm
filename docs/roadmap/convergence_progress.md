# Convergence Progress Checklist

Worker-facing tracker for
[`end_to_end_convergence_plan.md`](end_to_end_convergence_plan.md). The plan
is the frozen strategy reference; this file is the live "what to do next"
list and the visible record of progress. Evidence summaries under
`docs/evidence/` are the proof layer.

## How To Use This File

1. Work top to bottom: the next goal is the first unchecked item, with one
   exception — once `distribution-real-rows` exists, a failing real row or a
   failing real-program gate always outranks the next unchecked item here.
2. One item per working cycle. Implement it, validate it, commit it, check
   it off in the same commit.
3. An item is closed only by a pointer to a tracked evidence summary (or,
   for docs-only items, the commit that landed the change). No prose-only
   closure. No closure by reclassification alone.
4. When counters move, update the Ratchet State table below in the same
   commit. Never lower a counter without a ratchet-migration note in the
   cited evidence summary.
5. On stopping mid-phase, record the first failing real row and current
   counter values in `docs/next_steps.md`.

## Adoption Cycles (Phase 0)

- [x] 1. Docs adoption patch: relabel
  `docs/roadmap/project_finish_statement.md` as an optimizer/IR-layer
  milestone finish pointing at the convergence plan; update the Current
  Operating Rule in `docs/next_steps.md` and Goal Selection in
  `docs/working-cycle.md` to the new selector; update the Documentation
  Rule to include real-row ratchet state. Commit the convergence plan and
  this file as adopted.

  Closed by the docs adoption commit that introduced this file (docs-only
  cycle; evidence is the commit itself).
- [x] 2. Evidence tooling: `tools/summarize_gate_log.zig` emitting the
  summary schema (command, z_llvm commit, ziglang pin, exit status,
  summary lines, first failure line, ratchet metadata); backfill summaries
  for currently cited logs that still exist under `tmp/`.

  Closed by `docs/evidence/frontier_packed_call_arg_finish.summary`, which
  validates the tool on the completed Cycle A frontier gate. Legacy gate-log
  summaries for checklist-cited `tmp/` logs that still existed and contained
  `summary ...` lines were backfilled under `docs/evidence/`.
- [x] 3. Ziglang pin: tracked pin file (`docs/evidence/ziglang_pin.txt`)
  plus stage4 emitter check against the pin; mismatch path validated via a
  temporary override or fixture pin, tracked pin untouched.

  Closed by `docs/evidence/ziglang_pin_stage4_check.summary`; the mismatch
  path is recorded in `docs/evidence/ziglang_pin_stage4_mismatch.summary`.
- [x] 4. Close the interrupted vector-family inventory refresh
  (ReleaseFast compiler-core-module) and check off the last vector item in
  the family checklist.

  Closed pre-adoption by worker commit `70a8ce3d` ("Refresh vector
  inventory status"), which checked off the last vector-family item and
  refreshed `x86_64_compiler_core_inventory_priorities.md`. Completed out
  of order relative to items 2-3 because the worker was still operating
  under the old selector; evidence is the commit and its cited log (a
  tracked summary should be backfilled by item 2).

## Phase 1 — First Real Rows

- [x] 5. Candidate selector v1: inventory scanner emits the ranked
  real-candidate TSV/JSON (signature class, call_class, global_refs,
  runtime_refs, determinism, harnessable_reason/exclusion reason);
  conservative marks allowed, `proven_unharnessable` distinguished from
  `not_yet_analyzed`; first candidate file committed as evidence.

  Closed by `docs/evidence/real_candidates_releasefast_v1.summary`, with
  candidate rows in `docs/evidence/real_candidates_releasefast_v1.tsv`.
- [x] 6. `distribution-real-rows --limit=1` gate exists and is wired into
  `distribution-all`, reporting the staged `real_*` counters.

  Closed by `docs/evidence/real_rows_limit1.summary`, which validates rank
  1 (`../ziglang/src/main.zig/math.raiseInvalid`) through typed lowering,
  x86_64 object emission, and native link in ReleaseFast, ReleaseSafe, and
  ReleaseSmall. Execution is skipped for this row because the candidate is
  marked `assumed_nondeterministic`.
- [ ] 7. First real compiler-core function green through its applicable
  stages in all three release modes (expect multiple fix cycles; each fix
  cycle is its own commit, this box closes on the first green run).
- [ ] 8. Ratchet to `--limit=10`, green in all three release modes.
- [ ] 9. Ratchet to `--limit=25`, green. Start the syscall-hello track
  (item 11) in parallel from here.
- [ ] 10. Phase 1 exit: 100 real functions green through applicable
  stages, all three release modes, sustained (ratchets enforced by
  `distribution-all`).

## Phase 2 — First Real Program

- [ ] 11. Milestone 2a, syscall hello: `export _start`, no std, direct
  `write`/`exit` syscalls, target `x86_64-linux-gnu`, patched Zig with
  z_llvm codegen, Zig native linker, no LLD; gate
  (`distribution-zig-integrated-exe`) runs the binary and checks stdout and
  exit code. Includes the budgeted minimal inline-asm `syscall` form.
- [ ] 12. Milestone 2a', std hello: same program via `std.debug.print`
  with default `_start`; separate acceptance, all modes.
- [ ] 13. Milestone 2b, one real std test file (e.g. a `std.mem` subset)
  builds, links natively, runs, exits 0 in Debug + all three release modes.

## Phase 3 — Generalize

- [ ] 14. Width/type-parametric scalar lowering replaces the per-width
  accepted subsets (overflow ops, shifts, exact ops); subset carve-outs
  deleted as subsumed; boundary gate still green.
- [ ] 15. Incremental generic instruction selection for the generic CFG
  path (per-instruction selection, then liveness/pressure, then spills as
  real rows prove the need); `shape_recognizer_functions=0` held on the
  real-row gate.
- [ ] 16. ABI-level differential harness: same real function compiled by
  stock LLVM Zig and z_llvm behind a shared input-generating C harness;
  outputs, exit codes, and ReleaseSafe panic behavior compared; runs on
  every harnessable `distribution-real-rows` function.
- [ ] 17. Phase 3 exit: all three above sustained; `real_executed` growing
  at the same rate as `real_functions_lowered`.

## Phase 4 — Bulk Coverage

- [ ] 18. Inventory emits per-category blocking counts; family priority is
  computed from what blocks the most real functions.
- [ ] 19. Families 10-16 (packed aggregates, float math, select, x87,
  varargs, inline asm, debug metadata) implemented or boundary-justified in
  computed order.
- [ ] 20. Phase 4 exit: `unsupported_functions < 1000` in ReleaseFast on
  compiler-core-module, every remaining function attributable to a
  documented boundary category.

## Phase 5 — Self-Host

- [ ] 21. Milestone 5a: full Zig compiler builds through z_llvm; binary
  starts (`zig version`).
- [ ] 22. Milestone 5b: z_llvm-built stage compiler passes the Zig
  behavior test suite for x86_64-linux in all release modes.
- [ ] 23. Milestone 5c: fixed point — the z_llvm-built compiler rebuilds
  itself with functionally identical results.

## Ratchet State

Latest recorded counters. Update in the same commit as the change; the
authoritative history with denominator metadata lives in the cited evidence
summaries.

| Counter | Value | Modes | Evidence | Denominator (candidate hash / selector / pin) |
| --- | ---: | --- | --- | --- |
| real_functions_lowered | 1 | ReleaseFast, ReleaseSafe, ReleaseSmall | `docs/evidence/real_rows_limit1.summary` | candidate=`eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204`; selector=`real-candidate-selector-v1`; pin=`141bfce0883017ff7ebe03e3af3db07fff0c5dc3` |
| real_objects_emitted | 1 | ReleaseFast, ReleaseSafe, ReleaseSmall | `docs/evidence/real_rows_limit1.summary` | candidate=`eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204`; selector=`real-candidate-selector-v1`; pin=`141bfce0883017ff7ebe03e3af3db07fff0c5dc3` |
| real_native_linked | 1 | ReleaseFast, ReleaseSafe, ReleaseSmall | `docs/evidence/real_rows_limit1.summary` | candidate=`eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204`; selector=`real-candidate-selector-v1`; pin=`141bfce0883017ff7ebe03e3af3db07fff0c5dc3` |
| real_executed | 0 | ReleaseFast, ReleaseSafe, ReleaseSmall | `docs/evidence/real_rows_limit1.summary` | candidate=`eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204`; selector=`real-candidate-selector-v1`; pin=`141bfce0883017ff7ebe03e3af3db07fff0c5dc3` |
| real_programs_ok | 0 | ReleaseFast, ReleaseSafe, ReleaseSmall | `docs/evidence/real_rows_limit1.summary` | candidate=`eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204`; selector=`real-candidate-selector-v1`; pin=`141bfce0883017ff7ebe03e3af3db07fff0c5dc3` |
| unsupported_functions (ReleaseFast, compiler-core-module) | 55479 | ReleaseFast | `docs/evidence/real_candidates_releasefast_v1.summary` | candidate=`eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204`; selector=`real-candidate-selector-v1`; pin=`141bfce0883017ff7ebe03e3af3db07fff0c5dc3` |

Fixture-frontier counters (`generic_cfg_functions=753`,
`executable_ok_rows=14`) remain tracked by the family checklist and gate
logs; they are debugging-corpus health, not convergence progress, and are
deliberately not ratcheted here.
