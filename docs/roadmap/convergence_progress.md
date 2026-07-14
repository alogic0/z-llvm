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
6. Granularity sections (append/update in the same commit as the work):
   append one Progress Log line per completed cycle; update the Discovered
   State table when report-mode green counts change; keep the Cluster Board
   current from item 9a onward. Ratchet State stays strict-evidence only —
   report-mode progress belongs in Discovered State, never in Ratchet State.

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
- [x] 7. First real compiler-core function green through its applicable
  stages in all three release modes (expect multiple fix cycles; each fix
  cycle is its own commit, this box closes on the first green run).

  Closed by `docs/evidence/real_rows_strict_limit1.summary`, which confirms
  the rank-1 real row stays strict-green in ReleaseFast, ReleaseSafe, and
  ReleaseSmall with counters unchanged at `1/1/1/0/0`. The ratchet value did
  not move; enforcement did, by wiring `distribution-all` to
  `distribution-real-rows --strict --limit=1`.
- [x] 8. Ratchet to `--limit=10`, green in all three release modes.

  Closed by `docs/evidence/real_rows_strict_limit10.summary`, which confirms
  ranks 1-10 stay strict-green in ReleaseFast, ReleaseSafe, and ReleaseSmall
  with counters `10/10/10/0/0`. The ratchet values moved upward for lowering,
  object emission, and native link; `real_executed` and `real_programs_ok`
  remain 0 because the v1 candidates are still marked
  `assumed_nondeterministic`.
- [x] 8a. Gate-run AIR export cache (infrastructure, do before item 9):
  cache the exported real-module AIR keyed on ziglang pin
  (`docs/evidence/ziglang_pin.txt`), exporter-relevant z_llvm state, mode,
  and slice; `distribution-real-rows` reuses cache hits instead of
  re-exporting the compiler module every run. Fail closed: any key
  mismatch or missing/corrupt entry means full re-export, never a stale
  read. The cache lives under `tmp/` (speedup, not evidence). Validate by
  proving a cached run and a fresh-export run produce identical gate
  summary lines; record both timings in
  `docs/evidence/real_rows_export_cache.summary`. Rationale: at
  `--limit=10` each fix cycle spent hours re-exporting; at 25 and 100 the
  export dominates wall-clock entirely. While iterating on fixes, run
  single-mode (ReleaseFast) gates; all three modes at cycle close only.

  Closed by `docs/evidence/real_rows_export_cache.summary`, which compares
  a fresh strict `--limit=10` export run with a cached strict `--limit=10`
  run and records `comparison_summary_lines_match=true` plus fresh and
  cached timings for ReleaseFast, ReleaseSafe, and ReleaseSmall.
- [x] 9. Ratchet to `--limit=25`, green. Start the syscall-hello track
  (item 11) after the strict close (single-worker mode: the tracks run
  sequentially, but every stop report still states both). Fix-cycle rules
  carry over from item 8 unchanged: one fix per commit, no
  source/function-name admission, no weakening captured rows or golden files
  without behavioral verification, recognizer three-strikes escalation per
  the item 15 note (count stands at 1), and `real_executed=0` remains correct
  until a selector version lifts determinism marks via a ratchet-migration
  note.
  Historical validation note: this item originally required
  `distribution-all` before every commit. That rule was superseded on
  2026-07-11 by `docs/validation_tiers.md` and is not current worker policy.
  Finish the two open item-9 issues (ReleaseSafe native-link for
  `debug.SafetyLock.assertUnlocked`; ReleaseSmall rank-1 `air-export`
  recheck — reproduce it once with the cache bypassed to rule the cache
  in or out) and close the strict `--limit=25` ratchet.

  Closed by `docs/evidence/real_rows_strict_limit25_v2.summary`, which
  confirms selector-v2 ranks 1-25 stay strict-green in ReleaseFast,
  ReleaseSafe, and ReleaseSmall with counters `25/25/25/0/0`.
  `docs/evidence/real_candidates_release_v2.summary` records the denominator
  migration from v1 hash
  `eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204`
  to v2 hash
  `83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d`,
  filtering v1 rows to functions present in all three release-mode AIR
  exports whose leaf claims hold in all three modes. The syscall-hello track
  is now open per item 11; no implementation work has started there.
- [x] 9a. Cluster discovery (fix-selection method change, effective after
  item 9 closes): run one report-mode discovery at `--limit=200` in
  ReleaseFast, group the failing rows by `first_failing_stage` plus
  failure diagnostic, and record the clusters (size, representative rows,
  suspected shared cause) in a tracked discovery summary. From then on,
  each fix cycle targets the **largest remaining cluster**, not the first
  failing rank; validate a cluster fix against several member rows, not
  one. The strict ratchet keeps prefix semantics: `--strict --limit=N`
  covers ranks 1..N, so the enforced limit advances to the longest green
  prefix after each cluster lands, while report-mode counters record total
  green rows beyond the prefix. Re-cluster from a fresh discovery whenever
  the current cluster list is exhausted or stale.

  Closed by `docs/evidence/real_rows_releasefast_limit200_discovery.summary`,
  which records ReleaseFast report-mode `--limit=200` counts at
  `42/33/33/0/0` and groups the 167 failing rows into three clusters.
  Follow-on real-row fix cycles target the largest remaining open cluster.
- [x] 10. Phase 1 exit: 100 real functions green through applicable
  stages, all three release modes, sustained (ratchets enforced by
  `distribution-all`), reached by cluster-order fixing per item 9a.

  Closed by
  `docs/evidence/real_rows_strict_limit100_after_intcast_safe.summary`, which
  records strict `--limit=100` green in ReleaseFast, ReleaseSafe, and
  ReleaseSmall with counters `100/100/100/0/0`. `distribution-all` now
  enforces `distribution-real-rows --strict --limit=100`. The denominator is
  selector-v2 hash
  `83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d` under
  patched Zig pin `bdee02bc0c7f227c0f11bc9a449df673fe803540`.

## Phase 2 — First Real Program

- [x] 11. Milestone 2a, syscall hello: `export _start`, no std, direct
  `write`/`exit` syscalls, target `x86_64-linux-gnu`, patched Zig with
  z_llvm codegen, Zig native linker, no LLD; gate
  (`distribution-zig-integrated-exe`) runs the binary and checks stdout and
  exit code. Includes the budgeted minimal inline-asm `syscall` form.

  Closed by `docs/evidence/zig_integrated_exe_syscall_hello.summary`, which
  confirms patched Zig plus z_llvm object emission and Zig native
  `build-exe -fno-lld` produce a no-std `_start` executable in ReleaseFast,
  ReleaseSafe, and ReleaseSmall; each binary prints `hello\n` and exits 0.
- [ ] 12. Milestone 2a', std hello: same program via `std.debug.print`
  with default `_start`; separate acceptance, all modes.

  Method annotation (2026-07-05): after the per-width ctz cycles, remaining
  compiler_rt builtin families are fixed width-parametrically where the IR
  shape matches. One model-owned family lowering should cover i32, i64, and
  i128 (and float formats where applicable), deleting/subsuming existing
  per-width special cases in the same commit. Each parametric family closure
  records partial item-14 credit, with `distribution-all` and the real-program
  boundary gate as proof. If a soft-float f80/f128 arithmetic family needs
  more than one new generic-CFG shape, stop for item-15 architectural review
  instead of stacking shapes.

  Method annotation (2026-07-07): extend the parametric rule across operation
  families too. When family members differ only by the inner operation, own
  one model shape with an operation parameter rather than one lowering per
  operation. Width-parametric plus operation-parametric is the default for the
  remaining item-12 compiler_rt cycles; unsupported operations and variants
  remain fail-closed.

  Estimate update (2026-07-07 report-all inventory): Debug std-hello
  compiler_rt has 340 remaining object-emission failures after 443 selected
  functions and 103 emitting functions. After separating ordinary tail-call ABI
  work from selector/codegen work, the open buckets are: soft-float/libm/
  conversion selector candidates 236 rows, integer helper selector candidates
  45 rows, tail-call ABI 44 rows, and limb64 loops 15 rows. The item-15
  validation order pulls the generic selector forward on limb64 first, then
  the integer helper cluster, before attempting soft-float.
- [x] 12a. tmp hygiene (small infrastructure cycle; may be taken between
  item-12 cluster cycles when a short cycle fits): a Zig tool
  `tools/clean_tmp.zig`, wired as `zig build clean-tmp`, that (a) deletes
  export-cache `.meta`/`.air` pairs whose recorded `ziglang_pin` differs
  from the current `docs/evidence/ziglang_pin.txt` (provably unreachable
  under the fail-closed key), (b) deletes per-run scratch directories
  matching the known patterns (`distribution_real_rows_*`,
  `distribution_zig_air_inventory_*`, `uncurated_zig_air_*`,
  `zig_integrated_object_*`, `handoff_validation_*`, and similar) older
  than a threshold (default 2 hours, flag-adjustable), and (c) never
  touches current-pin cache entries, `*.log`, or `*.txt` files. Dry-run is
  the default; `--delete` is required to act; print per-item sizes and a
  bytes-reclaimed summary; refuse to run if the cache layout is not the
  expected `.meta`/`.air` pair shape. Additionally, make the export cache
  self-pruning: on a pin-mismatch key miss inside the real-rows gate,
  delete entries whose meta cites a pin other than the current one, so
  each pin bump reclaims the previous generation (~1.4 GB per entry)
  automatically. Validate with a dry-run/delete pair on a fixture cache
  dir and record the evidence summary. Context: a manual cleanup on
  2026-07-04 reclaimed ~61 GB, most of it old-pin cache generations; every
  hook-contract pin bump recreates the problem.

  Closed by `docs/evidence/clean_tmp.summary`, which records a fixture
  dry-run/delete pair: dry-run reported one old-pin cache pair and one
  scratch directory with zero deletions, while `--delete` removed both and
  preserved the current-pin cache pair plus `*.log` file. The real-row export
  cache now self-prunes old-pin entries after a fail-closed key miss.
- [x] 12b. Export-cache storage key dedup (small infrastructure cycle; may
  be taken between selector buckets when a short cycle fits): the cache
  currently keys stored artifacts on the full gate-run identity (pin,
  stage4 version, exporter state, mode, selector version, candidate-file
  hash, limit, slice hash), but the stored artifact — the whole-module AIR
  descriptor for one mode — depends only on (pin, exporter state, mode).
  The extra components fragment identical exports into duplicate ~1.3 GB
  entries per (limit, selector) combination: 10 current-pin entries where
  3 suffice (observed 13 GB where ~4 GB is the true footprint). Re-key the
  *storage* on (pin, exporter-relevant z_llvm state, mode) only; keep
  selector version, candidate hash, limit, and slice validation at the
  gate's read layer, which already checks them, so "any mismatch means
  re-export, never a stale read" is preserved for every content-relevant
  component. Migrate by letting old-key entries age out via the existing
  pin-bump self-pruning or one `clean-tmp` sweep; no compatibility shim.
  Optionally add a `--keep-newest-per-mode` sweep to `tools/clean_tmp.zig`
  as an upper bound on cache growth. Validate by proving a re-keyed cache
  hit and a fresh export produce identical gate summary lines (same
  standard as item 8a) and record the evidence summary.

  Closed by `docs/evidence/real_rows_cache_rekey.summary`: schema-2 cache
  storage is keyed only by Zig pin, exporter-relevant z_llvm state, and
  release mode; selector version, candidate-file hash, limit, and slice
  checks remain read-layer validation. The fresh-export strict limit-100
  all-mode run and the re-keyed cache-hit run produced identical
  `summary distribution-real-rows` lines. `tools/clean_tmp.zig` gained
  `--keep-newest-per-mode`; the close used one `clean-tmp --delete` sweep to
  remove old-key current-pin duplicates, leaving exactly one cache entry per
  mode.
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

  Priority evidence (2026-07-02): the very first real row
  (`math.raiseInvalid`, item 6, commit `9d591215`) regressed the captured
  `control_flow_calls.call_chain` distribution row through a recognizer
  conflict; the fix required reordering the recognizer chain plus a new
  whole-function pre-pass. Each such ordering constraint is fragility debt.
  If real-row fix cycles keep producing recognizer reorders or pre-pass
  special cases, pull this item forward instead of continuing
  recognizer-by-recognizer.

  Design option to evaluate before implementing: upstream Zig's self-hosted
  x86_64 backend (`../ziglang/src/codegen/x86_64/` — `CodeGen.zig`,
  `Emit.zig`, `encoder.zig` + `encodings.zon`, `abi.zig`) is MIT-licensed,
  written in Zig, and already solves instruction encoding tables, selection
  scaffolding, and register handling. Adapting its encoder/encoding tables
  and lowering machinery may be far cheaper than building selection from
  scratch; z_llvm's differentiation stays in the optimizing release path,
  not in encoder tables. Assess reuse vs. rewrite at this item's
  architectural review.

  Architectural decision (2026-07-07): pull item 15 forward before
  implementing the soft-float/libm/conversion cluster. The report-all
  compiler_rt inventory shows 259 soft-float-adjacent failures when tail-call
  ABI rows are included, or 236 selector/codegen rows after separating the
  ordinary tail-call ABI family. That scale is too broad for more
  recognizer-specific generic-CFG shapes.

  The replacement direction is an incremental instruction-selection layer for
  the generic CFG path over z_llvm IR. It is designed from the start around
  liveness and eventual spilling, even though delivery stays incremental:
  first, select individual z_llvm IR instructions to target operations inside
  each generic-CFG block without changing the existing block recognizer
  contract; second, compute per-block and cross-edge live-in/live-out sets and
  track register pressure while still rejecting rows that exceed the proven
  no-spill envelope; third, add spill-slot allocation, reload/store insertion,
  and frame-size accounting once real rows force it. Unsupported instruction
  forms, clobbers, calling-convention edges, and pressure states continue to
  fail closed.

  Upstream self-hosted backend reuse assessment: reuse the x86_64 instruction
  encoding data and operand modeling where practical (`encoder.zig`,
  `Encoding.zig`, `encodings.zon`, and compatible pieces of `bits.zig`) so
  z_llvm does not maintain a divergent encoding table. Treat upstream
  `CodeGen.zig`, `Lower.zig`, `Mir.zig`, `Emit.zig`, and `abi.zig` as
  reference-first rather than drop-in components: they are tightly coupled to
  Zig AIR, `Zcu`, `InternPool`, linker/debug-info state, and Zig's MIR
  pipeline, while z_llvm's selector consumes z_llvm IR after the local
  optimizer and must preserve z_llvm's explicit ownership boundaries. Reuse
  algorithms and tested ABI/register ideas from those files when they fit, but
  keep the z_llvm selector, liveness model, and fail-closed diagnostics local.

  Migration plan: keep the existing shape-recognizer path as a transitional
  fallback while the selector proves coverage. Every migrated family records
  selector-owned rows and remaining recognizer-owned rows in report output;
  `shape_recognizer_functions` ratchets down on the real-program gate and must
  eventually reach zero before item 15 closes. Do not add new recognizer-chain
  ordering constraints or whole-function pre-passes as part of this migration;
  such a need means the selector contract is missing a typed fact or CFG
  capability.

  Validation sequence: prove the selector first on the 15-row limb64 loop
  bucket, then on the integer helper cluster before soft-float. The historical
  66-row integer helper cluster contains 21 `UnsupportedTailCallAbi` rows; the
  selector proof targets the 45 non-tail-call rows, while the 44 total
  `UnsupportedTailCallAbi` rows across compiler_rt are tracked as a separate
  ordinary ABI family rather than a selector concern. Only after limb64 and
  integer selector rows are green should the migration attempt the 236-row
  soft-float/libm/conversion selector bucket. Validation follows
  `docs/validation_tiers.md`: focused commits use the selector/allocator route,
  while capability-closing, ratchet-moving, ABI-affecting, and milestone
  commits require `distribution-all`. If captured rows regress, use the
  loop-sum bisect discipline before proceeding.

  Stage-two allocator design note (2026-07-09): the composed selector's value
  model is virtual registers, not opportunistic physical-register ownership.
  Per-instruction selection should assign each z_llvm IR value a deterministic
  virtual register in SSA/block order, attach register-class constraints to
  each selected operation, and attach fixed-register constraints for SysV
  arguments, returns, machine instructions with fixed operands, and explicit
  clobbers. Allocation runs over the existing stage-two live sets with a
  linear-scan-or-equivalent algorithm chosen for implementability and
  deterministic output. Physical assignment must be liveness-aware: intervals
  expire by program point, fixed/clobber registers reserve their points, and
  unsupported register-class or pressure states fail closed with the row and
  diagnostic recorded. Spill capacity is frame-sized rather than the old
  six-slot envelope: spilled virtual registers get deterministic stack slots,
  reloads/stores are inserted at selected instruction boundaries, and frame
  size/accounting replaces ad hoc local spill slots. Acceptance order is
  binding: keep the existing nine composed rows green as the regression set,
  then close `compiler_rt.mulXi3.__multi3` through composed selection, then
  retry the parked pressure-boundary rows `__udivei5` and `__umodei4` with the
  saved diagnostics as expected-pressure checks. Terminal templates remain
  frozen except for the documented sub-ten-instruction leaf exception.
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

## Discovered State (report mode)

Latest report-mode green counts per mode at the current discovery limit —
progress that is real but not yet strict-enforced. Update when a fix cycle
changes the counts; cite the discovery/fix evidence summary.

| Mode | Limit | Lowered | Objects | Linked | Evidence |
| --- | ---: | ---: | ---: | ---: | --- |
| ReleaseFast | 200 | 200 | 200 | 200 | `docs/evidence/real_rows_releasefast_limit200_after_optional_layout.summary` |
| ReleaseSafe | 100 | 100 | 100 | 100 | `docs/evidence/real_rows_strict_limit100_after_intcast_safe.summary` |
| ReleaseSmall | 100 | 100 | 100 | 100 | `docs/evidence/real_rows_strict_limit100_after_intcast_safe.summary` |
| Debug compiler_rt | std-hello | 443 selected | 248 emitting | 195 failures | `docs/evidence/std_debug_hello_f32x4_mulsc3_acceptance.summary` |

## Cluster Board (item 9a onward)

Filled from each wide discovery run; one row per failure cluster. A cluster
closes when its member rows are report-green; "rows unlocked" records the
count that turned green when the fix landed.

| Cluster (stage + diagnostic) | Size | Status | Rows unlocked | Fix commit / evidence |
| --- | ---: | --- | ---: | --- |
| `object-emission x86_64-lower:UnsupportedCodegenInstruction` | 0 | Closed | 146 | Opaque-bitcast typed lowering moved 16 rows into emitted/linked status; i8 unsigned less-than return emission unlocked rank 36 `ascii.isAscii`; i64 terminal shifts with model-owned extended shift-count constants unlocked ranks 39-43 `bit_set.*.maskIndex`; narrow enum `zext` emission unlocked rank 59 `Air.VectorCmp.encodeOp`; nominal enum bool less-than returns unlocked ranks 61-62 `codegen.*.bits.FrameIndex.isNamed`, ranks 66-182 `hash_map.*.Metadata.*`, and rank 184 `os.linux.W.IFEXITED`; sub-byte unsigned greater-than-zero bool returns unlocked rank 183 `link.Diags.Flags.anySet`; model-owned `i16` masked equality bool returns unlocked ranks 186-187 `unicode.utf16Is*Surrogate`. Evidence `docs/evidence/real_rows_releasefast_limit200_after_i16_masked_cmp.summary` |
| `typed-lowering unsupported:function_type:function-type` | 0 | Closed | 157 | Opaque nominal type-surface parsing now accepts pointer sigils inside balanced generic argument lists, so existing typed-bitcast inference unlocked ranks 63-65 `hash_map.*.Metadata.*`; preserving module aggregate-layout facts in real-row slices plus direct `aggregate_init` register-aggregate lowering unlocked rank 185 `sort.block.Range.init`; fact-owned `Air.ShuffleTwoMask` u32 nominal enum parsing unlocked rank 189 `Air.ShuffleTwoMask.aElem`; opaque nominal `bitcast` + `intcast` scalar inference unlocked ranks 191-200 `InternPool.*`/related optional-index wrappers; hook-contract v1 aggregate-layout facts for optional payload/slice fields plus fact-owned sret aggregate field-wrapper lowering/emission unlocked rank 190 `Build.Cache.Path.fmtEscapeString`. Evidence `docs/evidence/real_rows_releasefast_limit200_after_optional_layout.summary` |
| `typed-lowering unsupported:instruction_type:lowering` | 0 | Closed | 1 | Fact-owned pointer register-aggregate construction from `ret_ptr` field-store/`ret_load` plus x86_64 pointer aggregate return emission unlocked rank 188 `Air.Liveness.fmtInstSet`. Evidence `docs/evidence/real_rows_releasefast_limit200_after_ptr_aggregate.summary` |
| `real-program object-emission compiler_rt parser:UnsupportedGlobalVariable weak_odr hidden alias` | 0 | Closed | 479 | Item 12 std-hello Debug discovery moved past compiler_rt `weak_odr hidden alias` declarations by parsing alias visibility as model IR and preserving ELF symbol visibility; the next open cluster is `UnsupportedInstruction` on `fneg x86_fp80`. Evidence `tmp/std_debug_hello_debug_build_after_alias_visibility.log` |
| `real-program object-emission compiler_rt parser:UnsupportedInstruction fneg` | 0 | Closed | 76 | Item 12 std-hello Debug discovery now parses LLVM `fneg` as a model-owned `fsub` from negative zero, preserving fast-math flags; the next open cluster is `InvalidFunctionHeader` on `define internal half @compiler_rt.__neghf2(...)`. Evidence `tmp/std_debug_hello_debug_build_after_fneg_parse.log` |
| `real-program object-emission compiler_rt parser:InvalidFunctionHeader half` | 0 | Closed | 55 | Item 12 std-hello Debug discovery now models LLVM `half` as a first-class scalar type with parser, verifier, layout, and fail-closed lowering support; the next open cluster is `UnsupportedType` while parsing `<4 x half>` vector elements in compiler_rt complex half multiplication. Evidence `tmp/std_debug_hello_debug_build_after_half_type.log` |
| `real-program object-emission compiler_rt parser:UnsupportedType vector floating elements` | 0 | Closed | 2 | Item 12 std-hello Debug discovery now models LLVM vector element types `half` and `fp128` with parser, verifier, layout, cost, and fail-closed lowering support, unlocking compiler_rt `mulhc3` and `multc3`; the next open cluster is verifier `InvalidDebugMetadata` on a `!DILocalVariable` without `name`. Evidence `tmp/std_debug_hello_debug_build_after_vector_fp_elements.log` |
| `real-program object-emission compiler_rt verifier:InvalidDebugMetadata unnamed DILocalVariable arg` | 0 | Closed | 2 | Item 12 std-hello Debug discovery now accepts LLVM `!DILocalVariable(arg: ...)` records without a `name` field while still requiring `scope` and `type`; the next open cluster is verifier `UnsupportedType` on vector floating binary operations. Evidence `tmp/std_debug_hello_debug_build_after_unnamed_dilocalvariable.log` |
| `real-program object-emission compiler_rt verifier:UnsupportedType vector floating binary ops` | 0 | Closed | 16 | Item 12 std-hello Debug discovery now verifies fixed-vector floating binary operations for modeled `half`, `float`, `double`, and `fp128` element types, preserving fail-closed lowering; the next open cluster is verifier `UnsupportedFloatingPointLiteral` on vector floating literal lanes. Evidence `tmp/std_debug_hello_debug_build_after_vector_fp_binary.log` |
| `real-program object-emission compiler_rt verifier:UnsupportedFloatingPointLiteral vector fneg splat` | 0 | Closed | 2 | Item 12 std-hello Debug discovery now lowers vector `fneg` through a model-owned vector negative-zero splat instead of a scalar FP literal, resolving the two vector `fneg <2 x double>` rows; the next open cluster is verifier `UnsupportedInlineAsm` on non-sideeffect compiler_rt inline asm. Evidence `tmp/std_debug_hello_debug_build_after_vector_fneg_splat.log` |
| `real-program object-emission compiler_rt verifier:UnsupportedInlineAsm pure register outputs` | 0 | Closed | 3 | Item 12 std-hello Debug discovery now admits pure non-sideeffect inline asm when the modeled constraints have no memory effects, while keeping memory-effecting asm without `sideeffect` rejected; the next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.strlen`. Evidence `tmp/std_debug_hello_debug_build_after_pure_inline_asm.log` |
| `real-program object-emission compiler_rt cfg:byte scan len loop` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned byte-scan length loop shape used by `compiler_rt.strlen` through generic CFG without function-name admission; the next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.bcmp`. Evidence `tmp/std_debug_hello_debug_build_after_byte_scan_len.log` |
| `real-program object-emission compiler_rt cfg:byte compare equal loop` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned two-pointer byte equality loop shape used by `compiler_rt.bcmp` through generic CFG without function-name admission; the next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.memcmp`. Evidence `tmp/std_debug_hello_debug_build_after_byte_compare_equal.log` |
| `real-program object-emission compiler_rt cfg:byte compare diff loop` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned two-pointer byte difference loop shape used by `compiler_rt.memcmp` through generic CFG without function-name admission; the next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.__memset`. Evidence `tmp/std_debug_hello_debug_build_after_byte_compare_diff.log` |
| `real-program object-emission compiler_rt cfg:guarded byte memset loop` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned guarded byte-store loop shape used by `compiler_rt.__memset` through generic CFG without function-name admission; the next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.memset`. Evidence `tmp/std_debug_hello_debug_build_after_guarded_byte_memset.log` |
| `real-program object-emission compiler_rt cfg:byte memset loop` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned byte-store loop shape used by `compiler_rt.memset` through generic CFG without function-name admission; the next open cluster is object-emission `UnsupportedCodegenType` in `compiler_rt.__negxf2`. Evidence `tmp/std_debug_hello_debug_build_after_byte_memset.log` |
| `real-program object-emission compiler_rt fp:x86_fp80 fneg` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned x86_fp80 `fsub -0.0, param` shape through the SysV long-double stack argument and x87 return convention without function-name admission; the next open cluster is object-emission `UnsupportedCodegenType` in `compiler_rt.__negtf2`. Evidence `tmp/std_debug_hello_debug_build_after_x86_fp80_fneg.log` |
| `real-program object-emission compiler_rt fp:fp128 fneg` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned fp128 `fsub -0.0, param` shape by toggling the high-lane sign bit in the SysV XMM return value without function-name admission; the next open cluster is object-emission `UnsupportedCodegenType` in `compiler_rt.__negdf2`. Evidence `tmp/std_debug_hello_debug_build_after_fp128_fneg.log` |
| `real-program object-emission compiler_rt fp:f32/f64 fneg negative-zero spelling` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lets the generic CFG float/double negation matcher accept the parser-normalized `fsub -0.0, param` spelling, moving the same model-owned sign-bit toggle path through `compiler_rt.__negdf2` without function-name admission; the next open cluster is object-emission `UnsupportedCodegenType` in `compiler_rt.__neghf2`. Evidence `tmp/std_debug_hello_debug_build_after_fp_neg_zero.log` |
| `real-program object-emission compiler_rt fp:half fneg` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned half `fsub -0.0, param` shape by toggling the low-half sign bit in the SysV XMM return value without function-name admission; the next open cluster is object-emission `UnsupportedCodegenType` in `compiler_rt.__negti2`. Evidence `tmp/std_debug_hello_debug_build_after_half_fneg.log` |
| `real-program object-emission compiler_rt int:i128 neg` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned `sub i128 0, param` shape through the SysV `rdx:rax` return pair without function-name admission; the next open cluster is object-emission `UnsupportedCodegenType` in `compiler_rt.__negdi2`. Evidence `tmp/std_debug_hello_debug_build_after_i128_neg.log` |
| `real-program object-emission compiler_rt int:i64 neg` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned `sub i64 0, param` shape through a generic GPR `negq` return path without function-name admission; the next open cluster is object-emission `UnsupportedCodegenInstruction` in `compiler_rt.count0bits.clzsi2_generic`. Evidence `tmp/std_debug_hello_debug_build_after_i64_neg.log` |
| `real-program object-emission compiler_rt int:i32 clz ladder` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned branchless i32 clz ladder shape to the existing `clz_i32_edi_eax` backend op without function-name admission; the next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.count0bits.__ffsti2`. Evidence `tmp/std_debug_hello_debug_build_after_clzsi2_ladder.log` |
| `real-program object-emission compiler_rt int:i128 ffs ladder` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned i128 ffs zero/low/high-bit ladder shape through a SysV `rsi:rdi` backend op without function-name admission; the next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.count0bits.__ffsdi2`. Evidence `tmp/std_debug_hello_debug_build_after_ffsti2.log` |
| `real-program object-emission compiler_rt int:i64 ffs ladder` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned i64 ffs zero/low/high-bit ladder shape through a SysV `rdi` backend op without function-name admission; the next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.count0bits.__ffssi2`. Evidence `tmp/std_debug_hello_debug_build_after_ffsdi2.log` |
| `real-program object-emission compiler_rt int:i32 ffs ladder` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned i32 ffs zero/low/high-bit ladder shape through a SysV `edi` backend op without function-name admission; the next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.count0bits.__ctzti2`. Evidence `tmp/std_debug_hello_debug_build_after_ffssi2.log` |
| `real-program object-emission compiler_rt int:i128 ctz ladder` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned i128 ctz zero/low/high-bit ladder shape through a SysV `rsi:rdi` backend op without function-name admission; the next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.count0bits.__ctzdi2`. Evidence `tmp/std_debug_hello_debug_build_after_ctzti2.log` |
| `real-program object-emission compiler_rt int:i64 ctz ladder` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned i64 ctz zero/low/high-bit ladder shape through a SysV `rdi` backend op without function-name admission; the next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.count0bits.__ctzsi2`. Evidence `tmp/std_debug_hello_debug_build_after_ctzdi2.log` |
| `real-program object-emission compiler_rt int:i32 ctz ladder` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned i32 ctz zero/low/high-bit ladder shape through the existing SysV `edi` backend op without function-name admission; the next open cluster is object-emission `UnsupportedCodegenInstruction` in `compiler_rt.count0bits.__clzti2`. Evidence `tmp/std_debug_hello_debug_build_after_ctzsi2.log` |
| `real-program object-emission compiler_rt int:clz ladder width-parametric` | 0 | Closed | 2 | Item 12 std-hello Debug discovery now lowers the model-owned clz ladder family width-parametrically for i32/i64/i128; it subsumes the former i32-only ladder recognizer, adds SysV `rdi`/`rsi:rdi` backend ops for i64/i128, and moves Debug std-hello from object-emission `UnsupportedCodegenInstruction` in `compiler_rt.count0bits.__clzti2` to object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.ssp.__memmove_chk` without function-name admission. Partial item-14 credit recorded for deleting the per-width i32 special-case entry point. Evidence `tmp/std_debug_hello_debug_build_after_clz_family.log` |
| `real-program object-emission compiler_rt cfg:guarded memmove direct call` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned guard/trap/direct-call wrapper shape used by `compiler_rt.ssp.__memmove_chk` through generic CFG without function-name admission, preserving the returned destination pointer across the internal `memmoveFast` call. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.ssp.__memcpy_chk`, whose guarded copy body is inlined rather than a direct call. Evidence `tmp/std_debug_hello_debug_build_after_memmove_chk.log` |
| `real-program object-emission compiler_rt cfg:guarded memcpy body` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned guarded copy-wrapper semantics used by `compiler_rt.ssp.__memcpy_chk`: the matcher validates the guard/trap entry, source-derived loads, destination-derived stores, metadata-only intrinsics, and `ret dst`, then emits a guarded `rep movsb` copy without function-name admission. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.ssp.__strncat_chk`. Evidence `tmp/std_debug_hello_debug_build_after_memcpy_chk.log` |
| `real-program object-emission compiler_rt cfg:guarded strncat append body` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned checked string append body shape used by `compiler_rt.ssp.__strncat_chk`: the matcher validates destination NUL scanning, source-derived byte loads, destination-derived source-byte and terminator stores, trap exits, max-bound use, and `ret dst`, then emits a guarded append loop without function-name admission. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.ssp.__strcat_chk`. Evidence `tmp/std_debug_hello_debug_build_after_strncat_chk.log` |
| `real-program object-emission compiler_rt cfg:guarded strcat append body` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned checked unbounded string append body shape used by `compiler_rt.ssp.__strcat_chk`: the matcher validates destination NUL scanning, source-derived byte loads, destination-derived source-byte and terminator stores, trap exits, and `ret dst`, then emits a guarded append loop without weakening the separate `strncat` max-bound model. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.ssp.__strncpy_chk`. Evidence `tmp/std_debug_hello_debug_build_after_strcat_chk.log` |
| `real-program object-emission compiler_rt cfg:checked string copy family` | 0 | Closed | 2 | Item 12 std-hello Debug discovery now lowers the model-owned checked string copy family used by `compiler_rt.ssp.__strncpy_chk` and `compiler_rt.ssp.__strcpy_chk`: bounded `strncpy` validates `guard >= len`, copies source bytes up to the bound, and zero-pads the tail; unbounded `strcpy` validates the object-size guard, copies source bytes until NUL, and writes the terminator. The next open cluster is object-emission `UnsupportedCodegenInstruction` in `compiler_rt.ssp.__chk_fail`. Evidence `tmp/std_debug_hello_debug_build_after_strncpy_chk.log` |
| `real-program object-emission compiler_rt cfg:noreturn trap stub` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned single-block noreturn trap stub used by `compiler_rt.ssp.__chk_fail`: straight-line unreachable lowering now admits the metadata-debug plus `llvm.trap` form and emits `ud2` without function-name admission, while preserving the existing inline-asm unreachable path. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.memmove.memmoveFast`. Evidence `tmp/std_debug_hello_debug_build_after_chk_fail.log` |
| `real-program object-emission compiler_rt cfg:byte copy fast family` | 0 | Closed | 2 | Item 12 std-hello Debug discovery now lowers the model-owned unguarded byte-copy fast family used by `compiler_rt.memmove.memmoveFast` and `compiler_rt.memcpy.memcpyFast`: `memmove` validates the overlap split, temporary 16-byte copy buffers, source-derived loads, destination-derived stores including aligned `ptrtoint`/`inttoptr` address derivation, and `ret dst`; `memcpy` validates the same source-to-destination copy body without overlap temporaries. The next open cluster is object-emission `InstructionNeedsResult` in `compiler_rt.stack_probe.zig_probe_stack`. Evidence `tmp/std_debug_hello_debug_build_after_memmoveFast.log` |
| `real-program object-emission compiler_rt cfg:naked stack probe inline asm` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned naked stack-probe inline-asm/unreachable body used by `compiler_rt.stack_probe.zig_probe_stack`: the matcher requires the void no-arg side-effecting stack-probe template and explicit clobbers, emits a bounded x86_64 stack-probe machine op plus normal return, and keeps other inline-asm unreachable bodies fail-closed. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_load`. Evidence `tmp/std_debug_hello_debug_build_after_zig_probe_stack.log` |
| `real-program object-emission compiler_rt cfg:spinlocked variable memcpy` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned spinlock-protected variable-length copy shape used by compiler_rt `atomics.__atomic_load`: the matcher validates the `(src >> 3) & 63` spinlock-table index, `atomicrmw xchg` acquire loop, inline memcpy from source to destination using the zexted size parameter, and release store before emitting a symbol-relocated x86_64 spinlocked copy op. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_compare_exchange_16`. Evidence `tmp/std_debug_hello_debug_build_after_atomic_load.log` |
| `real-program object-emission compiler_rt atomics:compare-exchange family` | 0 | Closed | 5 | Item 12 std-hello Debug discovery now lowers the model-owned atomic compare-exchange family for compiler_rt `atomics.__atomic_compare_exchange_{1,2,4,8,16}`: scalar widths validate the `cmpxchg` result/update CFG and emit width-specific x86_64 `lock cmpxchg` primitives; the i128 form validates the spinlock slot, acquire loop, load/compare/store branches, and release store before emitting a symbol-relocated spinlocked compare-exchange primitive. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_exchange_16`. Evidence `tmp/std_debug_hello_debug_build_after_atomic_cmpxchg.log` |
| `real-program object-emission compiler_rt atomics:exchange family` | 0 | Closed | 5 | Item 12 std-hello Debug discovery now lowers the model-owned atomic exchange family for compiler_rt `atomics.__atomic_exchange_{1,2,4,8,16}`: scalar widths validate the single-block `atomicrmw xchg seq_cst` CFG and emit width-specific x86_64 `xchg` primitives that return the old value; the i128 form validates the spinlock slot, acquire loop, old-value load, replacement store, and release store before emitting a symbol-relocated spinlocked exchange primitive. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_store_16`. Evidence `tmp/std_debug_hello_debug_build_after_atomic_exchange.log` |
| `real-program object-emission compiler_rt atomics:store family` | 0 | Closed | 5 | Item 12 std-hello Debug discovery now lowers the model-owned atomic store family for compiler_rt `atomics.__atomic_store_{1,2,4,8,16}`: scalar widths validate the single-block `store atomic ... seq_cst` CFG and reuse width-specific x86_64 `xchg` primitives so the old value is discarded but seq_cst ordering is preserved; the i128 form validates the spinlock slot, acquire loop, replacement store, and release store before emitting a symbol-relocated spinlocked store primitive. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_load_16`. Evidence `tmp/std_debug_hello_debug_build_after_atomic_store.log` |
| `real-program object-emission compiler_rt atomics:load family` | 0 | Closed | 5 | Item 12 std-hello Debug discovery now lowers the model-owned atomic load family for compiler_rt `atomics.__atomic_load_{1,2,4,8,16}`: scalar widths validate the single-block `load atomic ... seq_cst` CFG and emit width-specific x86_64 loads from the pointer argument; the i128 form validates the spinlock slot, acquire loop, load, and release store before emitting a symbol-relocated spinlocked load primitive. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_fetch_umin_16`. Evidence `tmp/std_debug_hello_debug_build_after_atomic_load16.log` |
| `real-program object-emission compiler_rt atomics:fetch-umin family` | 0 | Closed | 5 | Item 12 std-hello Debug discovery now lowers the model-owned atomic fetch unsigned-min family for compiler_rt `atomics.__atomic_fetch_umin_{1,2,4,8,16}`: scalar widths validate the single-block `atomicrmw umin seq_cst` CFG and emit width-specific x86_64 `cmpxchg` loops that return the old value; the i128 form validates the spinlock slot, acquire loop, old-value load, `llvm.umin.i128`, value store, and release store before emitting a symbol-relocated spinlocked fetch-umin primitive. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_fetch_umax_16`. Evidence `tmp/std_debug_hello_debug_build_after_fetch_umin.log` |
| `real-program object-emission compiler_rt atomics:fetch-umax family` | 0 | Closed | 5 | Item 12 std-hello Debug discovery now lowers the model-owned atomic fetch unsigned-max family for compiler_rt `atomics.__atomic_fetch_umax_{1,2,4,8,16}`: scalar widths validate the single-block `atomicrmw umax seq_cst` CFG and emit width-specific x86_64 `cmpxchg` loops that return the old value; the i128 form validates the spinlock slot, acquire loop, old-value load, `llvm.umax.i128`, value store, and release store before emitting a symbol-relocated spinlocked fetch-umax primitive. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_fetch_nand_16`. Evidence `tmp/std_debug_hello_debug_build_after_fetch_umax.log` |
| `real-program object-emission compiler_rt atomics:fetch-nand family` | 0 | Closed | 5 | Item 12 std-hello Debug discovery now lowers the model-owned atomic fetch NAND family for compiler_rt `atomics.__atomic_fetch_nand_{1,2,4,8,16}`: scalar widths validate the single-block `atomicrmw nand seq_cst` CFG and emit width-specific x86_64 `cmpxchg` loops that return the old value; the i128 form validates the spinlock slot, acquire loop, old-value load, `and` with the replacement, `xor -1`, value store, and release store before emitting a symbol-relocated spinlocked fetch-nand primitive. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_fetch_xor_16`. Evidence `tmp/std_debug_hello_debug_build_after_fetch_nand.log` |
| `real-program object-emission compiler_rt atomics:fetch-xor family` | 0 | Closed | 5 | Item 12 std-hello Debug discovery now lowers the model-owned atomic fetch XOR family for compiler_rt `atomics.__atomic_fetch_xor_{1,2,4,8,16}`: scalar widths validate the single-block `atomicrmw xor seq_cst` CFG and emit width-specific x86_64 `cmpxchg` loops that return the old value; the i128 form validates the spinlock slot, acquire loop, old-value load, `xor` with the replacement, value store, and release store before emitting a symbol-relocated spinlocked fetch-xor primitive. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_fetch_or_16`. Evidence `tmp/std_debug_hello_debug_build_after_fetch_xor.log` |
| `real-program object-emission compiler_rt atomics:fetch-or family` | 0 | Closed | 5 | Item 12 std-hello Debug discovery now lowers the model-owned atomic fetch OR family for compiler_rt `atomics.__atomic_fetch_or_{1,2,4,8,16}`: scalar widths validate the single-block `atomicrmw or seq_cst` CFG and emit width-specific x86_64 `cmpxchg` loops that return the old value; the i128 form validates the spinlock slot, acquire loop, old-value load, `or` with the replacement, value store, and release store before emitting a symbol-relocated spinlocked fetch-or primitive. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_fetch_and_16`. Evidence `tmp/std_debug_hello_debug_build_after_fetch_or.log` |
| `real-program object-emission compiler_rt atomics:fetch-and family` | 0 | Closed | 5 | Item 12 std-hello Debug discovery now lowers the model-owned atomic fetch AND family for compiler_rt `atomics.__atomic_fetch_and_{1,2,4,8,16}`: scalar widths validate the single-block `atomicrmw and seq_cst` CFG and emit width-specific x86_64 `cmpxchg` loops that return the old value; the i128 form validates the spinlock slot, acquire loop, old-value load, `and` with the replacement, value store, and release store before emitting a symbol-relocated spinlocked fetch-and primitive. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_fetch_sub_16`. Evidence `tmp/std_debug_hello_debug_build_after_fetch_and.log` |
| `real-program object-emission compiler_rt atomics:fetch-sub family` | 0 | Closed | 5 | Item 12 std-hello Debug discovery now lowers the model-owned atomic fetch SUB family for compiler_rt `atomics.__atomic_fetch_sub_{1,2,4,8,16}`: scalar widths validate the single-block `atomicrmw sub seq_cst` CFG and emit width-specific x86_64 `cmpxchg` loops that return the old value; the i128 form validates the spinlock slot, acquire loop, old-value load, `sub` with the replacement, value store, and release store before emitting a symbol-relocated spinlocked fetch-sub primitive. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_fetch_add_16`. Evidence `tmp/std_debug_hello_debug_build_fetch_sub16_after.log` |
| `real-program object-emission compiler_rt atomics:fetch-add family` | 0 | Closed | 5 | Item 12 std-hello Debug discovery now lowers the model-owned atomic fetch ADD family for compiler_rt `atomics.__atomic_fetch_add_{1,2,4,8,16}`: scalar widths validate the single-block `atomicrmw add seq_cst` CFG and emit width-specific x86_64 `cmpxchg` loops that return the old value; the i128 form validates the spinlock slot, acquire loop, old-value load, `add` with the replacement, value store, and release store before emitting a symbol-relocated spinlocked fetch-add primitive. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_compare_exchange`. Evidence `tmp/std_debug_hello_debug_build_fetch_add16_after.log` |
| `real-program object-emission compiler_rt atomics:variable compare-exchange` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned variable-size spinlocked compare-exchange wrapper used by compiler_rt `atomics.__atomic_compare_exchange`: the matcher validates the size-to-spinlock slot derivation, acquire loop, zero-size success path, bytewise object/expected compare loop, desired-to-object success copy, object-to-expected fail copy, release store, and `i32` success result before emitting a symbol-relocated x86_64 primitive. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_exchange`. Evidence `tmp/std_debug_hello_debug_build_atomic_compare_exchange_after.log` |
| `real-program object-emission compiler_rt atomics:variable exchange` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned variable-size spinlocked exchange wrapper used by compiler_rt `atomics.__atomic_exchange`: the matcher validates the size-to-spinlock slot derivation, acquire loop, object-to-output old-value copy, desired-to-object replacement copy, release store, and `void` result before emitting a symbol-relocated x86_64 primitive. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_store`. Evidence `tmp/std_debug_hello_debug_build_atomic_exchange_after.log` |
| `real-program object-emission compiler_rt atomics:variable store` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned variable-size spinlocked store wrapper used by compiler_rt `atomics.__atomic_store`: the matcher validates the size-to-spinlock slot derivation, acquire loop, desired-to-object replacement copy, release store, and `void` result before emitting a symbol-relocated x86_64 primitive. The next open cluster is object-emission `UnsupportedCodegenInstruction` in `compiler_rt.clear_cache.clear_cache`. Evidence `tmp/std_debug_hello_debug_build_atomic_store_after.log` |
| `real-program object-emission compiler_rt cfg:valgrind discard-translations client request` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned Valgrind discard-translations client-request block reached through compiler_rt `clear_cache`: the matcher validates the two `usize` parameters, request-block alloca, length subtraction, six-word request payload, exact side-effecting client-request inline-asm template/constraints, lifetime calls, and `ret void`, then emits a no-op return for the x86_64 cache-clear path without function-name admission. `distribution-all` now enforces strict real-row limit 100 through explicit ReleaseFast, ReleaseSafe, and ReleaseSmall invocations, avoiding the quiet implicit all-mode runner stall while preserving the same three-mode coverage. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.limb64.__abs_limb64`. Evidence `tmp/std_debug_hello_debug_build_clear_cache_after.log`; `tmp/distribution_all_after_clear_cache.log` |
| `real-program object-emission compiler_rt cfg:limb64 abs twos-complement body` | 0 | Closed | 1 | Item 12 std-hello Debug discovery now lowers the model-owned limb64 absolute-value body used by compiler_rt `limb64.__abs_limb64`: the matcher validates the limb count derived from the bit count, high-limb sign test, positive memcpy path, and negative xor-plus-carry loop with separate overflow and carry byte slots, then emits a qword copy/two's-complement loop without function-name admission. The next open cluster is object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.limb64.__mulo_limb64`. Evidence `tmp/std_debug_hello_debug_build_abs_limb64_after.log`; `tmp/distribution_all_after_abs_limb64.log` |
| `real-program object-emission compiler_rt soft-float/libm/conversion selector candidates` | 228 | Open | 9 | Report-all object emission on the current Debug std-hello compiler_rt module found the largest remaining selector/codegen bucket in soft-float, libm-style, complex-float, comparison, and float/int conversion helpers after separating advisory call-marker rows. Type-driven half and double truncation cycles close `compiler_rt.trunc.__trunch` and `compiler_rt.trunc.trunc`; the double-width forms also make `compiler_rt.extendhfdf2.__extendhfdf2` and `compiler_rt.extendsfdf2.__extendsfdf2` emit without nominal admission. Scalar SSE direct-call ABI support closes `compiler_rt.tan.tanh`; scalar widening/narrowing/multiplication, subtraction/division, predicate-complete comparison, bounded f64x2/f32x2 packed shapes, and typed FP stack memory then advance the trig and log families without nominal admission. Scalar float/double selects and source-safe FP phi edges close `compiler_rt.tan.tanf`; eight precomputed exact native cases cover zeros, minimum subnormals, and finite polynomial/range branches without calling the controlled reducer. Exact named ABI pointer provenance now permits scalar FP stores through direct or spilled pointer parameters, advancing `sincosf`; `sinf`, `cosf`, and `sincosf` all stop at unsupported switch terminators. Fresh report-all is 199 emitting / 244 failing. `compiler_rt.fma.fmaf`, four round-family rows, `compiler_rt.int.__udivdi3`, `compiler_rt.floatunsidf.__floatunsidf`, and scalar `fmin`/`fmax` emissions remain collateral without separate semantic claims. `truncl`, `truncq`, `__truncx`, unbounded vector forms, switch lowering, derived/unproven external FP stores, and wider-format rows remain explicit boundaries. Evidence `docs/evidence/std_debug_hello_compiler_rt_report_all.summary`, `docs/evidence/std_debug_hello_trunch_acceptance.summary`, `docs/evidence/std_debug_hello_trunc_acceptance.summary`, `docs/evidence/std_debug_hello_tanh_call_abi_acceptance.summary`, `docs/evidence/std_debug_hello_tanf_scalar_fp_acceptance.summary`, `docs/evidence/std_debug_hello_scalar_fsub_fdiv_acceptance.summary`, `docs/evidence/std_debug_hello_scalar_fcmp_acceptance.summary`, `docs/evidence/std_debug_hello_vector_f64x2_acceptance.summary`, `docs/evidence/std_debug_hello_scalar_fp_stack_memory_acceptance.summary`, `docs/evidence/std_debug_hello_vector_f32x2_acceptance.summary`, `docs/evidence/std_debug_hello_scalar_fp_select_phi_acceptance.summary`, and `docs/evidence/std_debug_hello_scalar_fp_pointer_store_acceptance.summary`; full log `tmp/inbox26_fp_pointer_store_report.log` |
| `real-program object-emission compiler_rt integer helper selector candidates` | 0 | Closed | 43 | Report-all object emission found the integer helper selector/codegen bucket after separating 21 tail-call ABI rows from the historical 66-row integer helper cluster. Composed-selection proofs now emit all three parity rows, `compiler_rt.parity.__paritysi2`, `compiler_rt.parity.__paritydi2`, `compiler_rt.parity.__parityti2`, `compiler_rt.mulo.__mulosi4`, `compiler_rt.int.__umoddi3`, `compiler_rt.int.__moddi3`, `compiler_rt.udivmod.__umodti3`, `compiler_rt.udivmod.__modti3`, `compiler_rt.mulXi3.__mulsi3`, and `compiler_rt.mulXi3.__multi3` through block-local per-instruction selection with explicit operand and register assignment. `compiler_rt.udivmodei4.__udivei5` and `compiler_rt.udivmodei4.__umodei4` now close as the eleventh and twelfth composed-selection rows; no stage-two pressure boundary remains. The first allocator acceptance row, `__multi3`, established that INBOX-4 identified the executable failure as a frame-layout collision, and the composed selector now assigns non-overlapping 8-byte spill slots under one frame authority so the z_llvm-emitted `__multi3`/`__modti3` object computes correct results in the integrated executable proof. INBOX-5 then hardened the same proof by adding disp32 frame-slot encodings for offsets past 127, correcting high-register instruction-size accounting so ELF relocations target the actual call immediate, making integrated-exe exit-code mismatches fail closed, and clobbering `rcx` before RHS spill64 reloads from the single value-location map. INBOX-6 is acknowledged by generalizing machine frame indexes from a fixed enum namespace into data slots while keeping spill objects inside the same frame authority as LLVM RegAllocFast `StackSlotForVirtReg` / `MFI->CreateSpillStackObject`. INBOX-7 is acknowledged by materializing scalar spill locations at operand use for 32-bit and 64-bit operands through that same single value-location map. The proof prebuilds the no-std `_start` harness as a normal patched-Zig object and links it with selector-emitted compiler_rt objects, keeping the row closure on the composed compiler_rt bodies rather than a wrapper CFG dependency. The parked `__udivei5` retry now uses the corrected 32-slot frame envelope, pointer-phi support, `llvm.assume` no-op lowering, exact `tail fastcc i16 @zig.target.intByteSize(i16 ...)` helper-call lowering, data-backed frame indexes, allocation-plan-sized spill reservation, scalar spill-location consumption, narrow-to-i64 zext lowering through a 32-bit accumulator write, dynamic byte-pointer GEP lowering, i64 immediate AND lowering through RCX and RAX, nonzero i64 equality-immediate lowering, named i64 equality lowering, width-correct i16 inequality-with-zero lowering, dynamic `[4 x i8]` GEP lowering for i32 element pointers, i32 loads through argument or scratch pointer registers, named pointer equality, i32 loads through spilled pointers, CFG-edge-aware phi incoming intervals, named i64 unsigned-greater comparison, signed i6 nonnegative comparison, i64 immediate unsigned-greater comparison, signed i64 less-than-zero comparison, i64 inequality with zero, exact `llvm.ctlz.i32` lowering, wrapping i6 immediate-lhs subtraction, and spill64 branch-condition consumption; Debug compiler_rt report-all now emits 154 functions with 289 failures, and the global first failure is `compiler_rt.trunc.__trunch` at `unsupported_type` / `unsupported-return-type`; continue the separately tracked integer-helper bucket by rank. Continue the integer-helper bucket in rank order while keeping intervening tail-call rows in the separate ABI family and recording each row's envelope fit or live-value count. Current item-15 accounting is composed-selection rows 43, terminal-template rows 17 (15 limb64 plus `__udivei4` and `__umodei5`), stage-two-boundary rows 0, allocator-acceptance rows 0 pending, and open integer-helper fallback candidates 0. The 45-row non-tail integer bucket is closed; remaining integer-family failures belong to the separate tail-call ABI family. Evidence `docs/evidence/std_debug_hello_udivei5_pressure.tsv`; `docs/evidence/std_debug_hello_umodei4_pressure.tsv`; `docs/evidence/std_debug_hello_udivei5_frame32_pointer_phi.summary`; `docs/evidence/std_debug_hello_umodti3_composed.summary`; `docs/evidence/std_debug_hello_modti3_composed.summary`; `docs/evidence/std_debug_hello_mulsi3_composed.summary`; `docs/evidence/std_debug_hello_multi3_pressure.tsv`; `docs/evidence/std_debug_hello_multi3_gap_inventory.tsv`; `docs/evidence/zig_integrated_exe_i128_arithmetic.summary`; `docs/evidence/distribution_all_after_multi3_single_frame.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_inbox5.summary`; `docs/evidence/distribution_all_after_inbox5.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_inbox7.summary`; `docs/evidence/distribution_all_after_inbox7.summary`; `docs/evidence/std_debug_hello_udivei5_zext_width.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_zext_width.summary`; `docs/evidence/distribution_all_after_zext_width.summary`; `docs/evidence/std_debug_hello_udivei5_gep_source.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_gep_source.summary`; `docs/evidence/distribution_all_after_gep_source.summary`; `docs/evidence/std_debug_hello_udivei5_and64_imm.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_and64_imm.summary`; `docs/evidence/distribution_all_after_and64_imm.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_eq_imm.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_eq_imm.summary`; `docs/evidence/distribution_all_after_icmp_eq_imm.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_eq_values.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_eq_values.summary`; `docs/evidence/distribution_all_after_icmp_eq_values.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_ne_zero.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_ne_zero.summary`; `docs/evidence/distribution_all_after_icmp_ne_zero.summary`; `docs/evidence/std_debug_hello_udivei5_gep_i32_source.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_gep_i32_source.summary`; `docs/evidence/distribution_all_after_gep_i32_source.summary`; `docs/evidence/std_debug_hello_udivei5_load_i32_ptr.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_load_i32_ptr.summary`; `docs/evidence/selector_tier2_load_i32_ptr.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_ptr_eq.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_ptr_eq.summary`; `docs/evidence/selector_tier2_icmp_ptr_eq.summary`; `docs/evidence/std_debug_hello_udivei5_load_i32_spill_ptr.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_load_i32_spill_ptr.summary`; `docs/evidence/selector_tier2_load_i32_spill_ptr.summary`; `docs/evidence/std_debug_hello_udivei5_phi_edge_liveness.summary`; `docs/evidence/zig_integrated_exe_phi_edge_liveness.summary`; `docs/evidence/distribution_all_after_phi_edge_liveness.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_ugt_values.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_ugt_values.summary`; `docs/evidence/selector_tier2_icmp_ugt_values.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_sgt_i6.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_sgt_i6.summary`; `docs/evidence/selector_tier2_icmp_sgt_i6.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_ugt_imm.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_ugt_imm.summary`; `docs/evidence/selector_tier2_icmp_ugt_imm.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_slt_zero.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_slt_zero.summary`; `docs/evidence/selector_tier2_icmp_slt_zero.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_ne_i64_zero.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_ne_i64_zero.summary`; `docs/evidence/selector_tier2_icmp_ne_i64_zero.summary`; `docs/evidence/std_debug_hello_udivei5_ctlz_i32.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_ctlz_i32.summary`; `docs/evidence/selector_tier2_ctlz_i32.summary`; `docs/evidence/std_debug_hello_udivei5_sub_i6.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_sub_i6.summary`; `docs/evidence/selector_tier2_sub_i6.summary`; `docs/evidence/std_debug_hello_udivei5_spill_cond.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_spill_cond.summary`; `docs/evidence/selector_tier2_spill_cond.summary` Acceptance evidence `docs/evidence/std_debug_hello_udivei5_acceptance.summary`; fresh pressure evidence `docs/evidence/std_debug_hello_udivei5_acceptance_pressure.tsv`; executable proof `docs/evidence/zig_integrated_exe_udivei5_acceptance.summary`; Tier 3 evidence `docs/evidence/distribution_all_after_udivei5_acceptance.summary`. Acceptance evidence `docs/evidence/std_debug_hello_umodei4_acceptance.summary`; fresh pressure evidence `docs/evidence/std_debug_hello_umodei4_acceptance_pressure.tsv`; executable proof `docs/evidence/zig_integrated_exe_umodei4_acceptance.summary`; Tier 3 evidence `docs/evidence/distribution_all_after_umodei4_acceptance.summary`. Acceptance evidence `docs/evidence/std_debug_hello_divei4_acceptance.summary`; fresh pressure evidence `docs/evidence/std_debug_hello_divei4_acceptance_pressure.tsv`; executable proof `docs/evidence/zig_integrated_exe_divei4_acceptance.summary`; Tier 3 evidence `docs/evidence/distribution_all_after_divei4_acceptance.summary`. Acceptance evidence `docs/evidence/std_debug_hello_modei4_acceptance.summary`; fresh pressure evidence `docs/evidence/std_debug_hello_modei4_acceptance_pressure.tsv`; executable proof `docs/evidence/zig_integrated_exe_modei4_acceptance.summary`; Tier 3 evidence `docs/evidence/distribution_all_after_modei4_acceptance.summary`. Acceptance evidence `docs/evidence/std_debug_hello_modei5_divei5_acceptance.summary`; fresh pressure evidence `docs/evidence/std_debug_hello_modei5_acceptance_pressure.tsv` and `docs/evidence/std_debug_hello_divei5_acceptance_pressure.tsv`; executable proof `docs/evidence/zig_integrated_exe_modei5_divei5_acceptance.summary`; Tier 3 evidence `docs/evidence/distribution_all_after_modei5_divei5_acceptance.summary`. `compiler_rt.mulo.__muloti4` now closes as the seventeenth composed row with exact native-link, executable signed-overflow, and pressure acceptance. Acceptance evidence `docs/evidence/std_debug_hello_muloti4_acceptance.summary`; pressure evidence `docs/evidence/std_debug_hello_muloti4_acceptance_pressure.tsv`; executable proof `docs/evidence/zig_integrated_exe_muloti4_acceptance.summary`; Tier 3 evidence `docs/evidence/distribution_all_after_muloti4_acceptance.summary`. `compiler_rt.mulo.__mulodi4` now closes as the eighteenth composed row with exact native-link, executable signed-overflow, and pressure acceptance. Acceptance evidence `docs/evidence/std_debug_hello_mulodi4_acceptance.summary`; pressure evidence `docs/evidence/std_debug_hello_mulodi4_acceptance_pressure.tsv`; executable proof `docs/evidence/zig_integrated_exe_mulodi4_acceptance.summary`; Tier 3 evidence `docs/evidence/distribution_all_after_mulodi4_acceptance.summary`. `compiler_rt.mulvsi3.__mulvsi3` now closes as the nineteenth composed row with exact native-link, executable normal/trap paths, and pressure acceptance. Acceptance evidence `docs/evidence/std_debug_hello_mulvsi3_acceptance.summary`; pressure evidence `docs/evidence/std_debug_hello_mulvsi3_acceptance_pressure.tsv`; executable proof `docs/evidence/zig_integrated_exe_mulvsi3_acceptance.summary`; Tier 3 evidence `docs/evidence/distribution_all_after_mulvsi3_acceptance.summary`. Generic multi-use accumulator relocation closes `compiler_rt.subvdi3.__subvdi3`, `compiler_rt.subvsi3.__subvsi3`, `compiler_rt.addvdi3.__addvdi3`, and `compiler_rt.addvsi3.__addvsi3` as composed rows 20-23. Acceptance evidence `docs/evidence/std_debug_hello_overflow_addsub_acceptance.summary`; pressure evidence `docs/evidence/std_debug_hello_subvdi3_acceptance_pressure.tsv`; executable proof `docs/evidence/zig_integrated_exe_overflow_addsub_acceptance.summary`; Tier 3 evidence `docs/evidence/distribution_all_after_overflow_addsub_acceptance.summary`. `compiler_rt.negv.__negvsi2` now closes as the twenty-fourth composed row with exact native-link, executable positive/negative negation, and pressure acceptance. Acceptance evidence `docs/evidence/std_debug_hello_negvsi2_acceptance.summary`; pressure evidence `docs/evidence/std_debug_hello_negvsi2_acceptance_pressure.tsv`; executable proof `docs/evidence/zig_integrated_exe_negvsi2_acceptance.summary`; Tier 3 evidence `docs/evidence/distribution_all_after_negvsi2_acceptance.summary`. Zero-left i128 subtraction and framed terminal-trap verification close `compiler_rt.negv.__negvti2` and `compiler_rt.absvti2.__absvti2` as composed rows 25-26. Acceptance evidence `docs/evidence/std_debug_hello_negvti2_absvti2_acceptance.summary`; pressure evidence `docs/evidence/std_debug_hello_negvti2_acceptance_pressure.tsv` and `docs/evidence/std_debug_hello_absvti2_acceptance_pressure.tsv`; executable proof `docs/evidence/zig_integrated_exe_negvti2_acceptance.summary`; Tier 3 evidence `docs/evidence/distribution_all_after_negvti2_acceptance.summary`. Immediate-left i64 subtraction and live-RAX preservation close `compiler_rt.negv.__negvdi2` and `compiler_rt.absvdi2.__absvdi2` as composed rows 27-28. Acceptance evidence `docs/evidence/std_debug_hello_negvdi2_absvdi2_acceptance.summary`; pressure evidence `docs/evidence/std_debug_hello_negvdi2_acceptance_pressure.tsv` and `docs/evidence/std_debug_hello_absvdi2_acceptance_pressure.tsv`; executable proof `docs/evidence/zig_integrated_exe_negvdi2_acceptance.summary`; Tier 3 evidence `docs/evidence/distribution_all_after_negvdi2_acceptance.summary`. Width-correct i32 absolute value and live-EAX preservation close `compiler_rt.absvsi2.__absvsi2` as composed row 29. Acceptance evidence `docs/evidence/std_debug_hello_absvsi2_acceptance.summary`; pressure evidence `docs/evidence/std_debug_hello_absvsi2_acceptance_pressure.tsv`; executable proof `docs/evidence/zig_integrated_exe_absvsi2_acceptance.summary`; Tier 3 evidence `docs/evidence/distribution_all_after_absvsi2_acceptance.summary`. Named i32 multiplication and generalized EAX preservation close `compiler_rt.mulXi3.__muldi3` as composed row 30. Acceptance evidence `docs/evidence/std_debug_hello_muldi3_acceptance.summary`; pressure evidence `docs/evidence/std_debug_hello_muldi3_acceptance_pressure.tsv`; executable proof `docs/evidence/zig_integrated_exe_muldi3_acceptance.summary`; Tier 3 evidence `docs/evidence/distribution_all_after_muldi3_acceptance.summary`. i32 zero-inequality plus allocator/frame hardening close `compiler_rt.int.__udivmodsi4`, `compiler_rt.int.__udivsi3`, and `compiler_rt.int.__umodsi3`; acceptance evidence `docs/evidence/std_debug_hello_udivmodsi4_acceptance.summary`, pressure evidence `docs/evidence/std_debug_hello_udivmodsi4_acceptance_pressure.tsv`, executable evidence `docs/evidence/zig_integrated_exe_udivmodsi4_acceptance.summary`, and Tier 3 evidence `docs/evidence/distribution_all_after_udivmodsi4_acceptance.summary`. |
| `real-program object-emission compiler_rt stage-two pressure boundary rows` | 0 | Closed | 2 | Both parked pressure-boundary rows are closed through composed selection and native-link acceptance: `compiler_rt.udivmodei4.__udivei5` and `compiler_rt.udivmodei4.__umodei4`. The corrected frame authority made the stage-two spill envelope allocation-plan-sized while preserving the historical 32-slot floor for existing stack-array rows. The closed rows pass the old pressure gate, pointer phi binding, well-formed `llvm.assume` calls, the exact `tail fastcc i16 @zig.target.intByteSize(i16 ...)` helper call, the old fixed frame-slot namespace cap, scalar spill-location consumption, narrow-to-i64 zext lowering, dynamic byte-pointer GEP lowering, i64 immediate AND lowering, nonzero i64 equality-immediate lowering, named i64 equality lowering, width-correct i16 inequality-with-zero lowering, dynamic `[4 x i8]` GEP lowering for i32 element pointers, i32 loads through argument or scratch pointer registers, named pointer equality, i32 loads through spilled pointers, CFG-edge-aware phi incoming intervals, named i64 unsigned-greater comparison, signed i6 nonnegative comparison, i64 immediate unsigned-greater comparison, signed i64 less-than-zero comparison, i64 inequality with zero, exact `llvm.ctlz.i32` lowering, wrapping i6 immediate-lhs subtraction, and spill64 branch-condition consumption, then clears selection after trunc location classes are narrowed correctly and framed multi-block returns share one epilogue. Fresh 32-slot acceptance diagnostics report `__udivei5` at max live values `19` / spill slots `13` and `__umodei4` at max live values `24` / spill slots `18`; both have zero over-envelope slots and no first exceedance. Saved old pressure data remains useful as the historical six-slot boundary: `__udivei5` max live values `16`, old spill slots needed `10`, first six-slot-envelope exceedance `Then8.prol` / `live_out` at live values `13`; `__umodei4` max live values `21`, old spill slots needed `15`, first six-slot-envelope exceedance `Then9.prol` / `live_out` at live values `13`. Evidence `docs/evidence/std_debug_hello_udivei5_pressure.tsv`; `docs/evidence/std_debug_hello_umodei4_pressure.tsv`; `docs/evidence/std_debug_hello_udivei5_frame32_pointer_phi.summary`; `docs/evidence/std_debug_hello_udivei5_zext_width.summary`; `docs/evidence/std_debug_hello_udivei5_gep_source.summary`; `docs/evidence/std_debug_hello_udivei5_and64_imm.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_eq_imm.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_eq_values.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_ne_zero.summary`; `docs/evidence/std_debug_hello_udivei5_gep_i32_source.summary`; `docs/evidence/std_debug_hello_udivei5_load_i32_ptr.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_ptr_eq.summary`; `docs/evidence/std_debug_hello_udivei5_load_i32_spill_ptr.summary`; `docs/evidence/std_debug_hello_udivei5_phi_edge_liveness.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_ugt_values.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_sgt_i6.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_ugt_imm.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_slt_zero.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_ne_i64_zero.summary`; `docs/evidence/std_debug_hello_udivei5_ctlz_i32.summary`; `docs/evidence/std_debug_hello_udivei5_sub_i6.summary`; `docs/evidence/std_debug_hello_udivei5_spill_cond.summary` Acceptance evidence `docs/evidence/std_debug_hello_udivei5_acceptance.summary`; fresh pressure evidence `docs/evidence/std_debug_hello_udivei5_acceptance_pressure.tsv`. Acceptance evidence `docs/evidence/std_debug_hello_umodei4_acceptance.summary`; fresh pressure evidence `docs/evidence/std_debug_hello_umodei4_acceptance_pressure.tsv`. |
| `real-program object-emission compiler_rt advisory tail-marker inventory` | 32 | Open | 10 | The fresh INBOX-19 baseline has 42 unique `UnsupportedTailCallAbi` rows, correcting the older 44-row estimate. Captured-IR inspection classifies all 42 as advisory `tail` rows and finds zero tracked `notail` or genuine `musttail` rows. INBOX-20 lowers advisory `tail` and `notail` as ordinary calls while keeping `musttail` fail-closed. Ten tracked rows now emit as ordinary calls and 32 expose their actual ABI, type, frame, or selector frontier; this does not implement tail-call ABI and the ten emissions are not separate semantic acceptance claims. Evidence `docs/evidence/std_debug_hello_tail_marker_inventory_inbox20.tsv` and `docs/evidence/std_debug_hello_tanh_call_abi_acceptance.summary`; full logs `tmp/inbox19_trunc_final_report.log` and `tmp/inbox20_tanh_final_report.log` |
| `real-program object-emission compiler_rt limb64 loops` | 0 | Closed | 15 | Item 15 stage-one selector emission now lowers all 15 model-owned limb64 loop envelopes through the opt-in selector path without function-name admission: multiply, byte-swap/reverse, arithmetic right shift, bit reverse, population count, trailing-zero count, leading-zero count, shift-left-with-overflow, unary not, operation-parametric binary bitwise (`xor`/`or`/`and`), signed/unsigned compare, and operation-parametric add/sub overflow. The terminal selector primitives validate the real IR envelopes and emit call-free, relocation-free x86_64 routines for their SysV ABIs. Stage-one checkpoint: limb64 selector coverage is 15/15; report-all selected functions stayed 443 while emitting functions moved to 118 and remaining failures moved to 325; the next selector bucket starts at `compiler_rt.udivmodei4.__udivei4`; no no-spill envelope rejections were introduced because the limb64 proofs use terminal selector routines; recognizer fallback remains untouched. Evidence `tmp/std_debug_hello_debug_mulo_selector_after.log`; `tmp/std_debug_hello_debug_byteswap_selector_after.log`; `tmp/std_debug_hello_debug_shr_selector_after.log`; `tmp/std_debug_hello_debug_bitreverse_selector_after.log`; `tmp/std_debug_hello_debug_popcount_selector_after.log`; `tmp/std_debug_hello_debug_ctz_selector_after.log`; `tmp/std_debug_hello_debug_clz_selector_after.log`; `tmp/std_debug_hello_debug_shlo_selector_after_clean.log`; `tmp/std_debug_hello_debug_not_selector_after.log`; `tmp/std_debug_hello_debug_bitwise_selector_after.log`; `tmp/std_debug_hello_debug_cmp_selector_after.log`; `tmp/std_debug_hello_debug_addsub_selector_after.log` |
| `real-program object-emission compiler_rt udivmodei4 quotient selector` | 0 | Closed | 1 | Item 15 integer-helper selector bucket now lowers the model-owned unsigned extended-int quotient envelope used by `compiler_rt.udivmodei4.__udivei4`: the matcher validates the four-argument void ABI, exactly the two scratch quotient/divisor i32 array allocas, the `zig.target.intByteSize` and `llvm.ctlz.i32` calls, quotient-only `i16` limb-count and `i64` byte-count derivations, and unsigned i64 divide/remainder operations before emitting the split terminal selector routine with relocatable calls to `zig.target.intByteSize` and `memset`. At closure time the related remainder and signed rows stayed fail-closed and the next open integer-helper failure was `compiler_rt.udivmodei4.__umodei5`. Evidence `tmp/std_debug_hello_debug_udivei4_selector_after.log`; `tmp/distribution_all_after_udivei4_selector.log` |
| `real-program object-emission compiler_rt udivmodei4 remainder terminal-template selector` | 0 | Closed | 1 | Item 15 integer-helper selector bucket now lowers the model-owned unsigned extended-int remainder envelope used by `compiler_rt.udivmodei4.__umodei5`: the matcher validates the five-argument void ABI, exactly the two scratch quotient/divisor i32 array allocas, the `zig.target.intByteSize`, `llvm.ctlz.i32`, and inline-memcpy calls, remainder-only absence of the quotient-form `i16` limb-count shift, and unsigned i64 divide/remainder operations before emitting the split terminal selector routine with relocatable calls to `zig.target.intByteSize`, `memset`, and the embedded tail jump to `memcpy`. This is an honest terminal-template closure from the interrupted cycle, not the block-local composed-selection proof; the related quotient-five and signed rows stay fail-closed, and the next open integer-helper failure is `compiler_rt.udivmodei4.__udivei5`. Evidence `tmp/std_debug_hello_debug_umodei5_selector_after.log`; `tmp/distribution_all_after_umodei5_selector_rerun.log` |

## Progress Log

One line per completed cycle, append-only, newest last. This is the
"what we achieved" record; details live in the cited commits/summaries.

- 2026-07-02 `f860ba86` Convergence plan adopted; docs selector switched.
- 2026-07-02 `258fc996` Packed-aggregate call-arg row finished (frontier 755).
- 2026-07-02 `40ec8bc3` Evidence tooling; ~60 gate summaries backfilled.
- 2026-07-02 `4e6fec67` Ziglang pin + stage4 check (mismatch path proven).
- 2026-07-02 `6489fffc` Candidate selector v1: 61,386 real functions ranked.
- 2026-07-02 `9d591215` Real-rows gate; first real function
  (`math.raiseInvalid`) lowered/emitted/linked, all modes.
- 2026-07-02 `841ee26f` Strict enforcement on in `distribution-all` (limit 1).
- 2026-07-03 `d8f0982a`+`80cef1b7`+`36bcc91e` Rows 2-10 green via named-enum,
  unused-opaque-param, and const-i1 generalizations; strict ratchet to 10.
- 2026-07-03 `bf0b6aa5` AIR export cache: ~9 min -> ~15 s per mode, identical
  summaries proven.
- 2026-07-03 `a2bac7c6` Limit-25 discovery: 20/25 green, 5 failures mapped.
- 2026-07-03 `686015c7`..`eb34afdb` Eight fix cycles: null-ptr returns,
  atomic enum/monotonic stores, union tag-only signatures, sub-byte GPR
  returns, comptime void rows, single-field aggregate layout inference,
  aggregate param field loads. ReleaseFast 25/25; ReleaseSafe 24/25 linked.
  Recognizer count still 1.
- 2026-07-03 (this commit) ReleaseSafe limit-25 native-link fixed for
  `debug.SafetyLock.assertUnlocked` by model-owned `debug.assert` lowering;
  ReleaseSmall cache-bypassed recheck still fails at AIR export. Recognizer
  count still 1.
- 2026-07-03 (this commit) Selector-v2 denominator migration filters v1 rows
  to all-mode-present, all-mode-leaf real functions; strict limit-25 is green
  in all release modes and `distribution-all` now enforces
  `distribution-real-rows --strict --limit=25`. Recognizer count still 1.
- 2026-07-03 (this commit) Item 9a cluster discovery: ReleaseFast
  report-mode `--limit=200` reached `42/33/33/0/0`; 167 failing rows grouped
  into three clusters, led by 157 typed-lowering function-type failures.
  Recognizer count still 1.
- 2026-07-03 (this commit) Item 10 cluster fix: model-owned opaque nominal
  bitcast inference moved ReleaseFast report-mode `--limit=200` to
  `179/49/49/0/0`, unlocking 137 typed-lowering rows from the former
  function-type cluster. The largest open cluster is now object emission
  `UnsupportedCodegenInstruction`. Recognizer count still 1.
- 2026-07-03 (this commit) Item 10 cluster fix: generic CFG x86_64 emission
  for unsigned `i8 < imm8` boolean returns moved ReleaseFast report-mode
  `--limit=200` to `179/50/50/0/0`, making rank 36 `ascii.isAscii`
  object/link green. Recognizer count still 1.
- 2026-07-03 (this commit) Item 10 cluster fix: generic CFG terminal i64
  shifts now accept model-owned extended shift-count constants, moving
  ReleaseFast report-mode `--limit=200` to `179/55/55/0/0` and making ranks
  39-43 `bit_set.*.maskIndex` object/link green. Recognizer count still 1
  (no recognizer reorder or pre-pass).
- 2026-07-03 (this commit) Item 10 cluster fix: generic CFG scalar emission
  now handles model-owned narrow enum identity bitcasts followed by `zext` to
  `i32`, moving ReleaseFast report-mode `--limit=200` to `179/56/56/0/0` and
  making rank 59 `Air.VectorCmp.encodeOp` object/link green. Recognizer count
  still 1 (no recognizer reorder or pre-pass).
- 2026-07-03 (this commit) Item 10 cluster fix: generic CFG scalar emission
  now handles model-owned nominal enum bitcasts feeding unsigned `i32`
  less-than bool returns, moving ReleaseFast report-mode `--limit=200` to
  `179/176/176/0/0` and making ranks 61-62, 66-182, and 184 object/link
  green. Recognizer count still 1 (no recognizer reorder or pre-pass).
- 2026-07-03 (this commit) Item 10 cluster fix: fact-owned 64-bit nominal
  enum surfaces plus generic CFG i64 eq/ne bool-return emission moved
  ReleaseFast report-mode `--limit=200` to `182/179/179/0/0`, making ranks
  32-33 `Io.Limit.*` and rank 51 `http.Reader.RemainingChunkLen.init`
  typed/object/link green. Recognizer count still 1 (no recognizer reorder or
  pre-pass).
- 2026-07-03 (this commit) Item 10 cluster fix: fact-owned
  `zig.Ast.OptionalTokenIndex` u32 nominal enum surface moved ReleaseFast
  report-mode `--limit=200` to `183/180/180/0/0`, making rank 58
  `zig.Ast.OptionalTokenIndex.fromToken` typed/object/link green. Recognizer
  count still 1 (no recognizer reorder or pre-pass).
- 2026-07-03 (this commit) Item 10 cluster fix: opaque nominal type-surface
  parsing now accepts pointer sigils inside balanced generic argument lists,
  moving ReleaseFast report-mode `--limit=200` to `186/183/183/0/0` and
  making ranks 63-65 `hash_map.*.Metadata.*` typed/object/link green.
  Recognizer count still 1 (no recognizer reorder or pre-pass).
- 2026-07-03 (this commit) Item 10 cluster fix: generic CFG x86_64 emission
  now handles model-owned sub-byte unsigned greater-than-zero bool returns,
  moving ReleaseFast report-mode `--limit=200` to `186/184/184/0/0` and
  making rank 183 `link.Diags.Flags.anySet` object/link green. Recognizer
  count still 1 (no recognizer reorder or pre-pass).
- 2026-07-03 (this commit) Item 10 cluster fix: real-row descriptor slices
  now preserve module-carried aggregate-layout facts, and direct
  `aggregate_init` register-aggregate returns lower through the fact-owned
  SysV layout model, moving ReleaseFast report-mode `--limit=200` to
  `187/185/185/0/0` and making rank 185 `sort.block.Range.init`
  typed/object/link green. Recognizer count still 1 (no recognizer reorder
  or pre-pass).
- 2026-07-03 (this commit) Item 10 cluster fix: fact-owned
  `Air.ShuffleTwoMask` u32 nominal enum parsing moved ReleaseFast report-mode
  `--limit=200` to `188/186/186/0/0` and made rank 189
  `Air.ShuffleTwoMask.aElem` typed/object/link green. Recognizer count still
  1 (no recognizer reorder or pre-pass).
- 2026-07-04 (this commit) Item 10 cluster fix: model-owned opaque nominal
  `bitcast` + `intcast` scalar inference moved ReleaseFast report-mode
  `--limit=200` to `198/196/196/0/0` and made ranks 191-200
  `InternPool.*`/related optional-index wrappers typed/object/link green.
  Recognizer count still 1 (no recognizer reorder or pre-pass).
- 2026-07-04 (this commit) Item 10 cluster fix: generic CFG x86_64 emission
  now handles model-owned `i16` masked equality bool returns, moving
  ReleaseFast report-mode `--limit=200` to `198/198/198/0/0` and making
  ranks 186-187 `unicode.utf16Is*Surrogate` object/link green. Recognizer
  count still 1 (no recognizer reorder or pre-pass).
- 2026-07-04 (this commit) Item 10 cluster fix: fact-owned pointer
  register-aggregate construction from `ret_ptr` field-store/`ret_load` now
  lowers and emits through the SysV INTEGER return path, moving ReleaseFast
  report-mode `--limit=200` to `199/199/199/0/0` and making rank 188
  `Air.Liveness.fmtInstSet` typed/object/link green. Recognizer count still 1
  (no recognizer reorder or pre-pass).
- 2026-07-04 (this commit) Item 10 hook-contract cycle: patched Zig commit
  `bdee02bc` keeps the `zllvm-aggregate-layout-facts-v1` schema and
  additively emits optional payload/slice aggregate layout facts, including
  `?[]const u8` layouts needed by `Build.Cache.Path`; z_llvm consumes those
  model-owned facts with sret aggregate field-wrapper lowering and generic CFG
  field-offset copy emission, moving ReleaseFast report-mode `--limit=200` to
  `200/200/200/0/0` and making rank 190 `Build.Cache.Path.fmtEscapeString`
  typed/object/link green. Strict `--limit=100` then exposed the next
  ReleaseSafe-only typed-lowering cluster, `unsupported:opcode:intcast_safe`
  at ranks 32, 51, and 58; no ratchet move yet. Recognizer count still 1 (no
  recognizer reorder or pre-pass).
- 2026-07-04 (this commit) Item 10 cluster fix: typed scalar lowering now
  admits `intcast_safe` through the same model-owned integer cast semantics as
  `intcast`, moving ReleaseSafe report-mode `--limit=100` to
  `100/100/100/0/0` and making ranks 32 `Io.Limit.limited`, 51
  `http.Reader.RemainingChunkLen.init`, and 58
  `zig.Ast.OptionalTokenIndex.fromToken` typed/object/link green. Recognizer
  count still 1 (no recognizer reorder or pre-pass).
- 2026-07-04 (this commit) Item 10 strict close: strict
  `distribution-real-rows --limit=100` is green in ReleaseFast, ReleaseSafe,
  and ReleaseSmall with `100/100/100/0/0`; `distribution-all` now enforces
  `distribution-real-rows --strict --limit=100`. The strict ratchet moved
  from 25 to 100 under selector-v2 and Zig pin `bdee02bc`. Recognizer count
  still 1 (no recognizer reorder or pre-pass).
- 2026-07-04 (this commit) Item 11 syscall-hello milestone: patched Zig plus
  z_llvm object emission and Zig native `build-exe -fno-lld` now build and
  run the no-std `_start` program in ReleaseFast, ReleaseSafe, and
  ReleaseSmall; the gate verifies `hello\n` on stdout and exit code 0. The
  budgeted minimal inline-asm `syscall` form is supported only for fixed
  register integer inputs, return register, and explicit clobbers. Recognizer
  count still 1 (no recognizer reorder or pre-pass).
- 2026-07-04 (this commit) Docs-only ratchet bookkeeping: `real_programs_ok`
  is raised from 0 to 1 for the syscall-hello executable milestone, enforced
  by `distribution-zig-integrated-exe` and evidenced by
  `docs/evidence/zig_integrated_exe_syscall_hello.summary`. Real-row strict
  counters stay at `100/100/100/0`; recognizer count still 1.
- 2026-07-04 (this commit) Item 12 std-hello discovery fix: compiler_rt
  `weak_odr hidden alias` declarations now parse as model-owned global
  aliases with preserved hidden/protected visibility through IR printing and
  ELF symbol emission. Debug std-hello moved from
  `UnsupportedGlobalVariable` to the next compiler_rt parser cluster,
  `UnsupportedInstruction` on `fneg x86_fp80`; strict real-row enforcement
  remains at 100. Recognizer count still 1 (no recognizer reorder or
  pre-pass).
- 2026-07-04 (this commit) Item 12 std-hello discovery fix: LLVM `fneg`
  instructions now normalize into model-owned `fsub` from negative zero,
  preserving fast-math flags and moving Debug std-hello from
  `UnsupportedInstruction` on compiler_rt `fneg` to the next parser cluster,
  `InvalidFunctionHeader` on `define internal half
  @compiler_rt.__neghf2(...)`; strict real-row enforcement remains at 100.
  Recognizer count still 1 (no recognizer reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: LLVM `half`
  is now a model-owned scalar type across parsing, verification, layout, and
  fail-closed lowering/type helpers, moving Debug std-hello from
  `InvalidFunctionHeader` on compiler_rt `__neghf2` to `UnsupportedType` while
  parsing the first `<4 x half>` vector instruction in compiler_rt complex half
  multiplication; strict real-row enforcement remains at 100. Recognizer count
  still 1 (no recognizer reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: LLVM vector
  element types `half` and `fp128` are now model-owned for parsing,
  verification, layout, analysis cost/hash helpers, and fail-closed typed
  vector lowering, moving Debug std-hello from compiler_rt vector element
  `UnsupportedType` to verifier `InvalidDebugMetadata` on a `!DILocalVariable`
  without `name`; strict real-row enforcement remains at 100. Recognizer count
  still 1 (no recognizer reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: debug metadata
  verification now accepts unnamed `!DILocalVariable(arg: ...)` records as
  valid parameter metadata while retaining `scope` and `type` checks, moving
  Debug std-hello from `InvalidDebugMetadata` to verifier `UnsupportedType` on
  vector floating binary operations; strict real-row enforcement remains at
  100. Recognizer count still 1 (no recognizer reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: fixed-vector
  floating binary operations now verify for modeled floating element types, and
  Debug std-hello moves from vector binary `UnsupportedType` to verifier
  `UnsupportedFloatingPointLiteral` on vector floating literal lanes; strict
  real-row enforcement remains at 100. Recognizer count still 1 (no recognizer
  reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: vector `fneg`
  now rewrites to a vector negative-zero splat for modeled floating element
  types instead of a scalar FP literal, moving Debug std-hello from
  `UnsupportedFloatingPointLiteral` to verifier `UnsupportedInlineAsm` on
  compiler_rt inline asm without `sideeffect`; strict real-row enforcement
  remains at 100. Recognizer count still 1 (no recognizer reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: pure inline asm
  without `sideeffect` now verifies when constraint-derived memory effects are
  empty, keeping memory-effecting non-sideeffect asm fail-closed and moving
  Debug std-hello from verifier `UnsupportedInlineAsm` to object-emission
  `UnsupportedCodegenControlFlow` in `compiler_rt.strlen`; strict real-row
  enforcement remains at 100. Recognizer count still 1 (no recognizer reorder
  or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned byte-scan length loop shape used by compiler_rt
  `strlen` without function-name admission, moving Debug std-hello from
  object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.strlen` to
  the same stage/diagnostic in `compiler_rt.bcmp`; strict real-row enforcement
  remains at 100. Recognizer count still 1 (no recognizer reorder or
  pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned two-pointer byte equality loop shape used by
  compiler_rt `bcmp` without function-name admission, moving Debug std-hello
  from object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.bcmp`
  to the same stage/diagnostic in `compiler_rt.memcmp`; strict real-row
  enforcement remains at 100. Recognizer count still 1 (no recognizer reorder
  or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned two-pointer byte difference loop shape used by
  compiler_rt `memcmp` without function-name admission, moving Debug std-hello
  from object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.memcmp`
  to the same stage/diagnostic in `compiler_rt.__memset`; strict real-row
  enforcement remains at 100. Recognizer count still 1 (no recognizer reorder
  or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned guarded byte-store loop shape used by compiler_rt
  `__memset` without function-name admission, moving Debug std-hello from
  object-emission `UnsupportedCodegenControlFlow` in `compiler_rt.__memset` to
  the same stage/diagnostic in `compiler_rt.memset`; strict real-row
  enforcement remains at 100. Recognizer count still 1 (no recognizer reorder
  or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned byte-store loop shape used by `compiler_rt.memset`
  without function-name admission, moving Debug std-hello from object-emission
  `UnsupportedCodegenControlFlow` in `compiler_rt.memset` to object-emission
  `UnsupportedCodegenType` in `compiler_rt.__negxf2`; strict real-row
  enforcement remains at 100. Recognizer count still 1 (no recognizer reorder
  or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: the x86_64
  backend now lowers the model-owned `x86_fp80` negation shape by loading the
  SysV stack-passed long-double argument into x87 `st0` and applying `fchs`,
  moving Debug std-hello from object-emission `UnsupportedCodegenType` in
  `compiler_rt.__negxf2` to the same stage/diagnostic in
  `compiler_rt.__negtf2`; strict real-row enforcement remains at 100.
  Recognizer count still 1 (no recognizer reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: the x86_64
  backend now lowers the model-owned `fp128` negation shape by toggling the
  high-lane sign bit in the SysV XMM0 value, moving Debug std-hello from
  object-emission `UnsupportedCodegenType` in `compiler_rt.__negtf2` to the
  same stage/diagnostic in `compiler_rt.__negdf2`; strict real-row enforcement
  remains at 100. Recognizer count still 1 (no recognizer reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: the generic CFG
  float/double negation matcher now accepts the parser-normalized negative-zero
  spelling, moving Debug std-hello from object-emission `UnsupportedCodegenType`
  in `compiler_rt.__negdf2` to the same stage/diagnostic in
  `compiler_rt.__neghf2`; strict real-row enforcement remains at 100.
  Recognizer count still 1 (no recognizer reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: the generic CFG
  negation matcher now lowers the model-owned half `fsub -0.0, param` shape by
  toggling the low-half sign bit in XMM0, moving Debug std-hello from
  object-emission `UnsupportedCodegenType` in `compiler_rt.__neghf2` to the
  same stage/diagnostic in `compiler_rt.__negti2`; strict real-row enforcement
  remains at 100. Recognizer count still 1 (no recognizer reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: the generic CFG
  lowering now recognizes the model-owned `sub i128 0, param` shape and returns
  the two's-complement negated value in SysV `rdx:rax`, moving Debug std-hello
  from object-emission `UnsupportedCodegenType` in `compiler_rt.__negti2` to
  the same stage/diagnostic in `compiler_rt.__negdi2`; strict real-row
  enforcement remains at 100. Recognizer count still 1 (no recognizer reorder
  or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: the generic CFG
  lowering now recognizes the model-owned `sub i64 0, param` shape and emits a
  generic GPR `negq` return path, moving Debug std-hello from object-emission
  `UnsupportedCodegenType` in `compiler_rt.__negdi2` to object-emission
  `UnsupportedCodegenInstruction` in `compiler_rt.count0bits.clzsi2_generic`;
  strict real-row enforcement remains at 100. Recognizer count still 1 (no
  recognizer reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: the generic CFG
  lowering now recognizes the model-owned branchless i32 clz ladder emitted for
  compiler-rt and maps it to the existing `clz_i32_edi_eax` backend op, moving
  Debug std-hello from object-emission `UnsupportedCodegenInstruction` in
  `compiler_rt.count0bits.clzsi2_generic` to object-emission
  `UnsupportedCodegenControlFlow` in `compiler_rt.count0bits.__ffsti2`; strict
  real-row enforcement remains at 100. Recognizer count still 1 (no recognizer
  reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: the generic CFG
  lowering now recognizes the model-owned i128 ffs zero/low/high-bit ladder and
  lowers it through a SysV `rsi:rdi` backend op, moving Debug std-hello from
  object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.count0bits.__ffsti2` to object-emission
  `UnsupportedCodegenControlFlow` in `compiler_rt.count0bits.__ffsdi2`; strict
  real-row enforcement remains at 100. Recognizer count still 1 (no recognizer
  reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: the generic CFG
  lowering now recognizes the model-owned i64 ffs zero/low/high-bit ladder and
  lowers it through a SysV `rdi` backend op, moving Debug std-hello from
  object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.count0bits.__ffsdi2` to object-emission
  `UnsupportedCodegenControlFlow` in `compiler_rt.count0bits.__ffssi2`; strict
  real-row enforcement remains at 100. Recognizer count still 1 (no recognizer
  reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: the generic CFG
  lowering now recognizes the model-owned i32 ffs zero/low/high-bit ladder and
  lowers it through a SysV `edi` backend op, moving Debug std-hello from
  object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.count0bits.__ffssi2` to object-emission
  `UnsupportedCodegenControlFlow` in `compiler_rt.count0bits.__ctzti2`; strict
  real-row enforcement remains at 100. Recognizer count still 1 (no recognizer
  reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: the generic CFG
  lowering now recognizes the model-owned i128 ctz zero/low/high-bit ladder and
  lowers it through a SysV `rsi:rdi` backend op, moving Debug std-hello from
  object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.count0bits.__ctzti2` to object-emission
  `UnsupportedCodegenControlFlow` in `compiler_rt.count0bits.__ctzdi2`; strict
  real-row enforcement remains at 100. Recognizer count still 1 (no recognizer
  reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: the generic CFG
  lowering now recognizes the model-owned i64 ctz zero/low/high-bit ladder and
  lowers it through a SysV `rdi` backend op, moving Debug std-hello from
  object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.count0bits.__ctzdi2` to object-emission
  `UnsupportedCodegenControlFlow` in `compiler_rt.count0bits.__ctzsi2`; strict
  real-row enforcement remains at 100. Recognizer count still 1 (no recognizer
  reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: the generic CFG
  lowering now recognizes the model-owned i32 ctz zero/low/high-bit ladder and
  lowers it through the existing SysV `edi` backend op, moving Debug std-hello
  from object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.count0bits.__ctzsi2` to object-emission
  `UnsupportedCodegenInstruction` in `compiler_rt.count0bits.__clzti2`; strict
  real-row enforcement remains at 100. Recognizer count still 1 (no recognizer
  reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello method change + discovery fix:
  remaining compiler_rt builtin families now use width-parametric lowering
  where the model-owned shape matches. The clz ladder family covers
  i32/i64/i128, subsumes the previous i32-only ladder entry point, adds i64
  and i128 SysV backend ops, and moves Debug std-hello from object-emission
  `UnsupportedCodegenInstruction` in `compiler_rt.count0bits.__clzti2` to
  object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.ssp.__memmove_chk`; partial item-14 credit recorded for the
  per-width subsumption. Strict real-row enforcement remains at 100.
  Recognizer count still 1 (no recognizer reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned guarded trap/direct-call wrapper shape used by
  compiler_rt `ssp.__memmove_chk`, including the `guard_len >= len` check and
  destination-pointer return preservation across the internal call. Debug
  std-hello moved from object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.ssp.__memmove_chk` to the same stage/diagnostic in
  `compiler_rt.ssp.__memcpy_chk`; strict real-row enforcement remains at 100.
  Recognizer count still 1 (no recognizer reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned checked-copy body shape used by compiler_rt
  `ssp.__memcpy_chk`, validating source-derived loads and destination-derived
  stores before emitting a guarded `rep movsb` copy that returns the original
  destination pointer. Debug std-hello moved from object-emission
  `UnsupportedCodegenControlFlow` in `compiler_rt.ssp.__memcpy_chk` to the
  same stage/diagnostic in `compiler_rt.ssp.__strncat_chk`; strict real-row
  enforcement remains at 100. Recognizer count still 1 (no recognizer reorder
  or pre-pass).
- 2026-07-05 (this commit) Item 12a tmp hygiene cycle: `zig build clean-tmp`
  now defaults to dry-run, requires `--delete` to reclaim stale tmp entries,
  validates `.meta`/`.air` export-cache pairs before acting, preserves
  current-pin cache entries plus `*.log`/`*.txt` files, and reports per-item
  sizes plus reclaimed bytes. `distribution-real-rows` now self-prunes
  old-pin cache generations after a fail-closed cache miss; fixture evidence
  is `docs/evidence/clean_tmp.summary`. Strict real-row enforcement remains
  at 100. Recognizer count still 1 (no recognizer reorder or pre-pass).
- 2026-07-05 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned checked string append shape used by compiler_rt
  `ssp.__strncat_chk`, validating destination scanning, source-byte copying,
  terminator storage, trap exits, and max-bound use before emitting a guarded
  append loop that returns the original destination pointer. Debug std-hello
  moved from object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.ssp.__strncat_chk` to the same stage/diagnostic in
  `compiler_rt.ssp.__strcat_chk`; strict real-row enforcement remains at 100.
  Recognizer count still 1 (no recognizer reorder or pre-pass).
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned no-max checked string append shape used by
  compiler_rt `ssp.__strcat_chk`, keeping it separate from the bounded
  `strncat` matcher so the max-bound contract remains fail-closed. Debug
  std-hello moved from object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.ssp.__strcat_chk` to the same stage/diagnostic in
  `compiler_rt.ssp.__strncpy_chk`; strict real-row enforcement remains at
  100. Recognizer count still 1 (no recognizer reorder or pre-pass).
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned checked string copy family for compiler_rt
  `ssp.__strncpy_chk` and `ssp.__strcpy_chk`, keeping bounded copy/pad and
  unbounded copy/terminator semantics separate but in one family cycle. Debug
  std-hello moved from object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.ssp.__strncpy_chk` to object-emission
  `UnsupportedCodegenInstruction` in `compiler_rt.ssp.__chk_fail`; strict
  real-row enforcement remains at 100. Recognizer count still 1 (no
  recognizer reorder or pre-pass).
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: straight-line
  unreachable lowering now admits the model-owned noreturn trap-stub shape
  used by compiler_rt `ssp.__chk_fail`, accepting the metadata-debug plus
  `llvm.trap` form and lowering it to `ud2` without function-name admission
  while preserving the existing inline-asm unreachable path. Debug std-hello
  moved from object-emission
  `UnsupportedCodegenInstruction` in `compiler_rt.ssp.__chk_fail` to
  object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.memmove.memmoveFast`; strict real-row enforcement remains at
  100. Recognizer count still 1 (no recognizer reorder or pre-pass).
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned unguarded byte-copy fast family for compiler_rt
  `memmove.memmoveFast` and `memcpy.memcpyFast`, using separate overlap-safe
  memmove and forward-only memcpy backend primitives while sharing the same
  source-to-destination copy-family validation style. Debug std-hello moved
  from object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.memmove.memmoveFast` to object-emission `InstructionNeedsResult`
  in `compiler_rt.stack_probe.zig_probe_stack`; strict real-row enforcement
  remains at 100. Recognizer count still 1 (no recognizer reorder or
  pre-pass). Partial item-14 credit recorded for handling the remaining
  byte-copy compiler_rt builtin family parametrically instead of one symbol at
  a time.
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: straight-line
  unreachable lowering now admits the model-owned naked stack-probe inline
  asm shape used by compiler_rt `stack_probe.zig_probe_stack`, requiring the
  exact void no-arg side-effecting template and explicit clobbers before
  emitting an x86_64 stack-probe machine op plus normal return. Debug
  std-hello moved from object-emission `InstructionNeedsResult` in
  `compiler_rt.stack_probe.zig_probe_stack` to object-emission
  `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_load`;
  strict real-row enforcement remains at 100. Recognizer count still 1 (no
  recognizer reorder or pre-pass).
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned spinlocked variable memcpy shape used by compiler_rt
  `atomics.__atomic_load`, validating the source-derived spinlock slot,
  acquire `atomicrmw xchg` loop, zexted runtime length, inline memcpy, and
  release store before emitting a symbol-relocated x86_64 spinlocked-copy
  primitive. Debug std-hello moved from object-emission
  `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_load` to
  the same stage/diagnostic in
  `compiler_rt.atomics.__atomic_compare_exchange_16`; strict real-row
  enforcement remains at 100. Recognizer count still 1 (no recognizer reorder
  or pre-pass).
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned atomic compare-exchange family for compiler_rt
  `atomics.__atomic_compare_exchange_{1,2,4,8,16}`. Widths 1/2/4/8 bytes
  share the `cmpxchg` result/update CFG matcher and width-specific
  `lock cmpxchg` backend primitives; the 16-byte form shares the spinlock
  acquire/release validation style and emits a symbol-relocated i128
  compare-exchange primitive. Debug std-hello moved from object-emission
  `UnsupportedCodegenControlFlow` in
  `compiler_rt.atomics.__atomic_compare_exchange_16` to the same
  stage/diagnostic in `compiler_rt.atomics.__atomic_exchange_16`; strict
  real-row enforcement remains at 100. Recognizer count still 1 (no
  recognizer reorder or pre-pass). Partial item-14 credit recorded for
  handling the compare-exchange builtin family parametrically instead of by
  width.
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned atomic exchange family for compiler_rt
  `atomics.__atomic_exchange_{1,2,4,8,16}`. Widths 1/2/4/8 bytes share the
  single-block `atomicrmw xchg seq_cst` matcher and width-specific `xchg`
  backend primitives; the 16-byte form shares the spinlock acquire/release
  validation style and emits a symbol-relocated i128 exchange primitive. Debug
  std-hello moved from object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.atomics.__atomic_exchange_16` to the same stage/diagnostic in
  `compiler_rt.atomics.__atomic_store_16`; strict real-row enforcement remains
  at 100. Recognizer count still 1 (no recognizer reorder or pre-pass).
  Partial item-14 credit recorded for handling the exchange builtin family
  parametrically instead of by width.
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned atomic store family for compiler_rt
  `atomics.__atomic_store_{1,2,4,8,16}`. Widths 1/2/4/8 bytes share the
  single-block `store atomic ... seq_cst` matcher and reuse the existing
  width-specific `xchg` backend primitives so ordering stays seq_cst while
  the old value is discarded; the 16-byte form shares the spinlock
  acquire/release validation style and emits a symbol-relocated i128 store
  primitive. Debug std-hello moved from object-emission
  `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_store_16`
  to the same stage/diagnostic in `compiler_rt.atomics.__atomic_load_16`;
  strict real-row enforcement remains at 100. Recognizer count still 1 (no
  recognizer reorder or pre-pass). Partial item-14 credit recorded for
  handling the store builtin family parametrically instead of by width.
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned atomic load family for compiler_rt
  `atomics.__atomic_load_{1,2,4,8,16}`. Widths 1/2/4/8 bytes share the
  single-block `load atomic ... seq_cst` matcher and emit width-specific
  x86_64 loads from the pointer argument; the 16-byte form shares the
  spinlock acquire/release validation style and emits a symbol-relocated
  i128 load primitive. Debug std-hello moved from object-emission
  `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_load_16`
  to the same stage/diagnostic in
  `compiler_rt.atomics.__atomic_fetch_umin_16`; strict real-row enforcement
  remains at 100. Recognizer count still 1 (no recognizer reorder or
  pre-pass). Partial item-14 credit recorded for handling the load builtin
  family parametrically instead of by width.
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned atomic fetch unsigned-min family for compiler_rt
  `atomics.__atomic_fetch_umin_{1,2,4,8,16}`. Widths 1/2/4/8 bytes share the
  single-block `atomicrmw umin seq_cst` matcher and width-specific x86_64
  `cmpxchg` loops; the 16-byte form shares the spinlock acquire/release
  validation style and emits a symbol-relocated i128 fetch-umin primitive
  after validating `llvm.umin.i128`. Debug std-hello moved from
  object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.atomics.__atomic_fetch_umin_16` to the same stage/diagnostic
  in `compiler_rt.atomics.__atomic_fetch_umax_16`; strict real-row
  enforcement remains at 100. Recognizer count still 1 (no recognizer reorder
  or pre-pass). Partial item-14 credit recorded for handling the fetch-umin
  builtin family parametrically instead of by width.
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned atomic fetch unsigned-max family for compiler_rt
  `atomics.__atomic_fetch_umax_{1,2,4,8,16}`. Widths 1/2/4/8 bytes share the
  single-block `atomicrmw umax seq_cst` matcher and width-specific x86_64
  `cmpxchg` loops; the 16-byte form shares the spinlock acquire/release
  validation style and emits a symbol-relocated i128 fetch-umax primitive
  after validating `llvm.umax.i128`. Debug std-hello moved from
  object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.atomics.__atomic_fetch_umax_16` to the same stage/diagnostic
  in `compiler_rt.atomics.__atomic_fetch_nand_16`; strict real-row
  enforcement remains at 100. Recognizer count still 1 (no recognizer reorder
  or pre-pass). Partial item-14 credit recorded for handling the fetch-umax
  builtin family parametrically instead of by width.
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned atomic fetch NAND family for compiler_rt
  `atomics.__atomic_fetch_nand_{1,2,4,8,16}`. Widths 1/2/4/8 bytes share the
  single-block `atomicrmw nand seq_cst` matcher and width-specific x86_64
  `cmpxchg` loops; the 16-byte form shares the spinlock acquire/release
  validation style and emits a symbol-relocated i128 fetch-nand primitive
  after validating the `and` plus `xor -1` update. Debug std-hello moved from
  object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.atomics.__atomic_fetch_nand_16` to the same stage/diagnostic
  in `compiler_rt.atomics.__atomic_fetch_xor_16`; strict real-row enforcement
  remains at 100. Recognizer count still 1 (no recognizer reorder or
  pre-pass). Partial item-14 credit recorded for handling the fetch-nand
  builtin family parametrically instead of by width.
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned atomic fetch XOR family for compiler_rt
  `atomics.__atomic_fetch_xor_{1,2,4,8,16}`. Widths 1/2/4/8 bytes share the
  single-block `atomicrmw xor seq_cst` matcher and width-specific x86_64
  `cmpxchg` loops; the 16-byte form shares the spinlock acquire/release
  validation style and emits a symbol-relocated i128 fetch-xor primitive after
  validating the `xor` update. Debug std-hello moved from object-emission
  `UnsupportedCodegenControlFlow` in
  `compiler_rt.atomics.__atomic_fetch_xor_16` to the same stage/diagnostic in
  `compiler_rt.atomics.__atomic_fetch_or_16`; strict real-row enforcement
  remains at 100. Recognizer count still 1 (no recognizer reorder or
  pre-pass). Partial item-14 credit recorded for handling the fetch-xor
  builtin family parametrically instead of by width.
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned atomic fetch OR family for compiler_rt
  `atomics.__atomic_fetch_or_{1,2,4,8,16}`. Widths 1/2/4/8 bytes share the
  single-block `atomicrmw or seq_cst` matcher and width-specific x86_64
  `cmpxchg` loops; the 16-byte form shares the spinlock acquire/release
  validation style and emits a symbol-relocated i128 fetch-or primitive after
  validating the `or` update. Debug std-hello moved from object-emission
  `UnsupportedCodegenControlFlow` in
  `compiler_rt.atomics.__atomic_fetch_or_16` to the same stage/diagnostic in
  `compiler_rt.atomics.__atomic_fetch_and_16`; strict real-row enforcement
  remains at 100. Recognizer count still 1 (no recognizer reorder or
  pre-pass). Partial item-14 credit recorded for handling the fetch-or
  builtin family parametrically instead of by width.
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned atomic fetch AND family for compiler_rt
  `atomics.__atomic_fetch_and_{1,2,4,8,16}`. Widths 1/2/4/8 bytes share the
  single-block `atomicrmw and seq_cst` matcher and width-specific x86_64
  `cmpxchg` loops; the 16-byte form shares the spinlock acquire/release
  validation style and emits a symbol-relocated i128 fetch-and primitive
  after validating the `and` update. Debug std-hello moved from
  object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.atomics.__atomic_fetch_and_16` to the same stage/diagnostic in
  `compiler_rt.atomics.__atomic_fetch_sub_16`; strict real-row enforcement
  remains at 100. Recognizer count still 1 (no recognizer reorder or
  pre-pass). Partial item-14 credit recorded for handling the fetch-and
  builtin family parametrically instead of by width.
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned atomic fetch SUB family for compiler_rt
  `atomics.__atomic_fetch_sub_{1,2,4,8,16}`. Widths 1/2/4/8 bytes share the
  single-block `atomicrmw sub seq_cst` matcher and width-specific x86_64
  `cmpxchg` loops; the 16-byte form shares the spinlock acquire/release
  validation style and emits a symbol-relocated i128 fetch-sub primitive
  after validating the `sub` update. Debug std-hello moved from
  object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.atomics.__atomic_fetch_sub_16` to the same stage/diagnostic in
  `compiler_rt.atomics.__atomic_fetch_add_16`; strict real-row enforcement
  remains at 100. Recognizer count still 1 (no recognizer reorder or
  pre-pass). Partial item-14 credit recorded for handling the fetch-sub
  builtin family parametrically instead of by width.
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned atomic fetch ADD family for compiler_rt
  `atomics.__atomic_fetch_add_{1,2,4,8,16}`. Widths 1/2/4/8 bytes share the
  single-block `atomicrmw add seq_cst` matcher and width-specific x86_64
  `cmpxchg` loops; the 16-byte form shares the spinlock acquire/release
  validation style and emits a symbol-relocated i128 fetch-add primitive
  after validating the `add` update. Debug std-hello moved from
  object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.atomics.__atomic_fetch_add_16` to the same stage/diagnostic in
  `compiler_rt.atomics.__atomic_compare_exchange`; strict real-row
  enforcement remains at 100. Recognizer count still 1 (no recognizer reorder
  or pre-pass). Partial item-14 credit recorded for handling the fetch-add
  builtin family parametrically instead of by width.
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned variable-size spinlocked compare-exchange wrapper used
  by compiler_rt `atomics.__atomic_compare_exchange`. The matcher validates the
  size-to-spinlock slot derivation, acquire loop, bytewise object/expected
  compare loop, success copy from desired to object, failure copy from object to
  expected, release store, and `i32` success result before emitting a
  symbol-relocated x86_64 primitive. Debug std-hello moved from object-emission
  `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_compare_exchange`
  to the same stage/diagnostic in `compiler_rt.atomics.__atomic_exchange`;
  strict real-row enforcement remains at 100. Recognizer count still 1 (no
  recognizer reorder or pre-pass). Partial item-14 credit recorded for keeping
  the atomics wrapper handling model-owned and shape-parametric.
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned variable-size spinlocked exchange wrapper used by
  compiler_rt `atomics.__atomic_exchange`. The matcher validates the
  size-to-spinlock slot derivation, acquire loop, old-value copy from object to
  output, replacement copy from desired to object, release store, and `void`
  result before emitting a symbol-relocated x86_64 primitive. Debug std-hello
  moved from object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.atomics.__atomic_exchange` to the same stage/diagnostic in
  `compiler_rt.atomics.__atomic_store`; strict real-row enforcement remains at
  100. Recognizer count still 1 (no recognizer reorder or pre-pass). Partial
  item-14 credit recorded for keeping the atomics wrapper handling model-owned
  and shape-parametric.
- 2026-07-06 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned variable-size spinlocked store wrapper used by
  compiler_rt `atomics.__atomic_store`. The matcher validates the
  size-to-spinlock slot derivation, acquire loop, replacement copy from desired
  to object, release store, and `void` result before emitting a
  symbol-relocated x86_64 primitive. Debug std-hello moved from object-emission
  `UnsupportedCodegenControlFlow` in `compiler_rt.atomics.__atomic_store` to
  object-emission `UnsupportedCodegenInstruction` in
  `compiler_rt.clear_cache.clear_cache`; strict real-row enforcement remains at
  100. Recognizer count still 1 (no recognizer reorder or pre-pass). Partial
  item-14 credit recorded for keeping the atomics wrapper handling model-owned
  and shape-parametric.
- 2026-07-07 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned Valgrind discard-translations client-request shape
  reached from compiler_rt `clear_cache`: the matcher validates the request
  block, lifetime calls, exact side-effecting inline asm, and `ret void`, then
  emits a no-op return for the x86_64 cache-clear path without function-name
  admission. `distribution-all` now runs the strict real-row limit as three
  explicit mode invocations (`ReleaseFast`, `ReleaseSafe`, `ReleaseSmall`) to
  preserve enforcement while avoiding the quiet implicit all-mode runner stall.
  Debug std-hello moved from object-emission `UnsupportedCodegenInstruction` in
  `compiler_rt.clear_cache.clear_cache` to object-emission
  `UnsupportedCodegenControlFlow` in `compiler_rt.limb64.__abs_limb64`; strict
  real-row enforcement remains at 100. Recognizer count still 1 (no recognizer
  reorder or pre-pass). Partial item-14 credit recorded for keeping the
  compiler_rt helper shape model-owned.
- 2026-07-07 (this commit) Item 12 std-hello discovery fix: generic CFG now
  lowers the model-owned limb64 absolute-value helper body used by compiler_rt
  `limb64.__abs_limb64`. The matcher validates the bit-count to limb-count
  derivation, high-limb sign test, positive memcpy path, and negative
  xor-plus-carry two's-complement loop before emitting a qword copy/negation
  x86_64 primitive without function-name admission. Debug std-hello moved from
  object-emission `UnsupportedCodegenControlFlow` in
  `compiler_rt.limb64.__abs_limb64` to the same stage/diagnostic in
  `compiler_rt.limb64.__mulo_limb64`; strict real-row enforcement remains at
  100. Recognizer count still 1 (no recognizer reorder or pre-pass). Partial
  item-14 credit recorded for keeping the compiler_rt limb helper shape
  model-owned.
- 2026-07-07 (this commit) Item 12 process-improvement cycle: z_llvm object
  emission now has opt-in report-all codegen failure mode
  (`--report-all-codegen-failures` or `ZLLVM_CODEGEN_REPORT_ALL=1`). It
  records each selected per-function codegen diagnostic, continues inventory,
  and exits before writing object/assembly output when any selected function
  failed. A Debug std-hello compiler_rt run reports 443 selected functions,
  103 emitting functions, and 340 remaining failures. The Cluster Board is
  reordered largest-first: soft-float/libm/conversion helpers 259, integer
  helper families 66, limb64 loops 15. Soft-float has 180 mechanical
  family/diagnostic buckets, so the stop state recommends pulling item 15
  forward before implementing that cluster. Recognizer count still 1 (no
  recognizer reorder or pre-pass). Method annotation extended item 12 from
  width-parametric to width-plus-operation-parametric lowering by default.
- 2026-07-07 (this commit) Item 15 architectural-review cycle: item 15 is
  pulled forward before soft-float implementation. The decision is an
  incremental generic instruction-selection layer over z_llvm IR for the
  generic CFG path: per-instruction selection first, then liveness and
  register-pressure tracking, then spill support, designed from the start for
  liveness/spilling while remaining fail-closed at each step. Upstream Zig's
  self-hosted x86_64 backend will be reused where practical for encoding data
  and operand modeling, while its AIR/Zcu/MIR-coupled lowering pipeline remains
  reference-only. Existing shape recognizers stay as a transitional fallback,
  with `shape_recognizer_functions` ratcheting toward zero on real-program
  gates. Validation order is limb64 selector bucket, then the integer helper
  selector bucket, then soft-float; the 44 `UnsupportedTailCallAbi` rows are a
  separate ordinary ABI family, not a selector concern. Recognizer count still
  1 (no new recognizer reorder or pre-pass).
- 2026-07-07 (this commit) Item 15 stage-one selector skeleton: added an
  opt-in generic-CFG selector probe behind `--generic-cfg-selector` /
  `ZLLVM_GENERIC_CFG_SELECTOR=1`, wired through the shared codegen emission
  path while keeping existing shape recognizers as fallback. The skeleton
  returns structured fail-closed diagnostics for unsupported control-flow,
  instruction, type, value, pressure, and no-emitter cases, but emits no rows
  yet, so existing route behavior and ratchets are unchanged. Recognizer count
  still 1 (no new recognizer reorder or pre-pass); `shape_recognizer_functions`
  is unchanged for this skeleton slice.
- 2026-07-07 (this commit) Item 15 stage-one selector planning slice: the
  opt-in selector inspection now admits scalar phi nodes, direct scalar helper
  calls, `llvm.assume`, and the `{ i64, i1 }` overflow-intrinsic/extractvalue
  pair used by the first limb64 proof target, while keeping unsupported
  aggregate extracts, indirect calls, inline asm calls, raw call args, and
  operand bundles fail-closed. The selector still emits zero rows and existing
  recognizers remain the fallback, so `shape_recognizer_functions` and all
  real-row ratchets are unchanged. Recognizer count still 1 (no new recognizer
  reorder or pre-pass).
- 2026-07-07 (this commit) Item 15 stage-one first limb64 selector emission:
  the opt-in selector now admits and emits the real
  `compiler_rt.limb64.__mulo_limb64` limb multiply envelope through a
  model-owned structural check, without source-name admission and without
  changing recognizer fallback behavior. The focused report-all proof moved
  Debug std-hello compiler_rt from 103 emitted / 340 failed to 104 emitted /
  339 failed, and advanced the first limb64 failure to
  `compiler_rt.limb64.__byteswap_limb64`. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged
  outside this opt-in selector proof slice.
- 2026-07-07 (this commit) Item 15 stage-one limb64 byteswap selector emission:
  the opt-in selector now admits and emits the real
  `compiler_rt.limb64.__byteswap_limb64` byte-swap/reverse envelope through a
  model-owned structural check, including the `llvm.bswap.i64` loop and
  partial-limb signed shift tail, without source-name admission and without
  changing recognizer fallback behavior. The focused report-all proof moved
  Debug std-hello compiler_rt from 104 emitted / 339 failed to 105 emitted /
  338 failed, and advanced the first limb64 failure to
  `compiler_rt.limb64.__shr_limb64`. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged
  outside this opt-in selector proof slice.
- 2026-07-07 (this commit) Item 15 stage-one limb64 shift-right selector
  emission: the opt-in selector now admits and emits the real
  `compiler_rt.limb64.__shr_limb64` arithmetic right-shift envelope through a
  model-owned structural check, including shift assertion/decomposition,
  signed top-limb extension, whole-limb displacement, bit-shift carry, and
  `fixLastLimb` ABI-limb extension, without source-name admission and without
  changing recognizer fallback behavior. The focused report-all proof moved
  Debug std-hello compiler_rt from 105 emitted / 338 failed to 106 emitted /
  337 failed, and advanced the first limb64 failure to
  `compiler_rt.limb64.__bitreverse_limb64`. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged
  outside this opt-in selector proof slice.
- 2026-07-07 (this commit) Item 15 stage-one limb64 bitreverse selector
  emission: the opt-in selector now admits and emits the real
  `compiler_rt.limb64.__bitreverse_limb64` bit-reverse envelope through a
  model-owned structural check, including `llvm.bitreverse.i64` limb reversal,
  partial-width signed right-shift tail, and `fixLastLimb` ABI-limb extension,
  without source-name admission and without changing recognizer fallback
  behavior. The focused report-all proof moved Debug std-hello compiler_rt from
  106 emitted / 337 failed to 107 emitted / 336 failed, and advanced the first
  limb64 failure to `compiler_rt.limb64.__popcount_limb64`. Recognizer count
  still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged outside this opt-in selector proof
  slice.
- 2026-07-07 (this commit) Item 15 stage-one limb64 popcount selector
  emission: the opt-in selector now admits and emits the real
  `compiler_rt.limb64.__popcount_limb64` population-count envelope through a
  model-owned structural check, including the `i16` limb-count arithmetic,
  `zig.target.intByteSize` descriptor fact, prefix-loop `llvm.ctpop.i64`,
  final partial-limb left shift, and final `llvm.ctpop.i64`, without
  source-name admission and without changing recognizer fallback behavior. The
  focused report-all proof moved Debug std-hello compiler_rt from 107 emitted /
  336 failed to 108 emitted / 335 failed, and advanced the first limb64 failure
  to `compiler_rt.limb64.__ctz_limb64`. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged
  outside this opt-in selector proof slice.
- 2026-07-07 (this commit) Item 15 stage-one limb64 ctz selector emission:
  the opt-in selector now admits and emits the real
  `compiler_rt.limb64.__ctz_limb64` trailing-zero-count envelope through a
  model-owned structural check, including the `i16` limb-count arithmetic,
  `zig.target.intByteSize` descriptor fact, prefix zero-limb branch, prefix
  and tail `llvm.cttz.i64` forms, and partial-tail zero case, without
  source-name admission and without changing recognizer fallback behavior. The
  focused report-all proof moved Debug std-hello compiler_rt from 108 emitted /
  335 failed to 109 emitted / 334 failed, and advanced the first limb64 failure
  to `compiler_rt.limb64.__clz_limb64`. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged
  outside this opt-in selector proof slice.
- 2026-07-07 (this commit) Item 15 stage-one limb64 clz selector emission:
  the opt-in selector now admits and emits the real
  `compiler_rt.limb64.__clz_limb64` leading-zero-count envelope through a
  model-owned structural check, including the `i16` limb-count arithmetic,
  `zig.target.intByteSize` descriptor fact, high partial-limb remainder mask,
  reverse full-limb scan, prefix zero-limb branch, and partial/full
  `llvm.ctlz.i64` forms, without source-name admission and without changing
  recognizer fallback behavior. The focused report-all proof moved Debug
  std-hello compiler_rt from 109 emitted / 334 failed to 110 emitted / 333
  failed, and advanced the first limb64 failure to
  `compiler_rt.limb64.__shlo_limb64`. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged
  outside this opt-in selector proof slice.
- 2026-07-07 (this commit) Item 15 stage-one limb64 shift-left-overflow
  selector emission: the opt-in selector now admits and emits the real
  `compiler_rt.limb64.__shlo_limb64` envelope through a model-owned structural
  check, including the `i16` limb-count arithmetic, `zig.target.intByteSize`
  descriptor fact, left-shift carry chain, partial high-limb mask/sign wrap,
  expected-carry comparison, overflow selects, and sign-extension tail fixup,
  without source-name admission and without changing recognizer fallback
  behavior. The selected terminal routine is call-free and relocation-free;
  a scratch prototype covered upstream limb64 shift-left-overflow cases before
  the bytes were wired. The focused report-all proof moved Debug std-hello
  compiler_rt from 110 emitted / 333 failed to 111 emitted / 332 failed, and
  advanced the first limb64 failure to `compiler_rt.limb64.__not_limb64`.
  Recognizer count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged outside this opt-in selector proof
  slice.
- 2026-07-08 (this commit) Item 15 stage-one limb64 unary-not selector
  emission: the opt-in selector now admits and emits the real
  `compiler_rt.limb64.__not_limb64` envelope through a model-owned structural
  check, including the `i16` limb-count arithmetic, `zig.target.intByteSize`
  descriptor fact, unary `xor -1` limb loop, unsigned partial-limb mask,
  signed high-limb fill, and fix-last-limb stores, without source-name
  admission and without changing recognizer fallback behavior. The terminal
  routine is call-free and relocation-free; a scratch prototype covered
  upstream limb64 signed/unsigned width cases before the bytes were wired. The
  focused report-all proof moved Debug std-hello compiler_rt from 111 emitted /
  332 failed to 112 emitted / 331 failed, and advanced the first limb64 failure
  to `compiler_rt.limb64.__xor_limb64`. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged
  outside this opt-in selector proof slice.
- 2026-07-08 (this commit) Item 15 stage-one limb64 binary-bitwise selector
  family: the opt-in selector now admits and emits the real
  `compiler_rt.limb64.__xor_limb64`, `compiler_rt.limb64.__or_limb64`, and
  `compiler_rt.limb64.__and_limb64` envelopes through one model-owned
  operation-parametric structural check, including the `i16` true-limb-count
  derivation from `zig.target.intByteSize`, `llvm.umax.i16` minimum limb
  clamp, epilogue assumption, repeated i64 loads/stores, and the selected
  i64 bitwise operation, without source-name admission and without changing
  recognizer fallback behavior. The terminal routines are call-free and
  relocation-free; a scratch prototype covered upstream limb64 true-limb
  cases before the bytes were wired. The focused report-all proof moved Debug
  std-hello compiler_rt from 112 emitted / 331 failed to 115 emitted / 328
  failed, and advanced the first limb64 failure to
  `compiler_rt.limb64.__cmp_limb64`. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged
  outside this opt-in selector proof slice.
- 2026-07-08 (this commit) Item 15 stage-one limb64 compare selector
  emission: the opt-in selector now admits and emits the real
  `compiler_rt.limb64.__cmp_limb64` envelope through a model-owned structural
  check, including the used-limb-count select, `zig.target.intByteSize`
  descriptor fact, signed high-limb comparison for signed inputs, reverse
  unsigned limb loop, and `i8` -1/0/1 return convention, without source-name
  admission and without changing recognizer fallback behavior. The terminal
  routine is call-free and relocation-free; a scratch prototype covered the
  upstream signed/unsigned width cases before the bytes were wired. The
  focused report-all proof moved Debug std-hello compiler_rt from 115 emitted /
  328 failed to 116 emitted / 327 failed, and advanced the first limb64 failure
  to `compiler_rt.limb64.__subo_limb64`. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged
  outside this opt-in selector proof slice.
- 2026-07-08 (this commit) Item 15 stage-one limb64 add/sub overflow selector
  family and checkpoint: the opt-in selector now admits and emits the real
  `compiler_rt.limb64.__addo_limb64` and `compiler_rt.limb64.__subo_limb64`
  envelopes through one model-owned operation-parametric structural check,
  including the used-limb-count select, `zig.target.intByteSize` descriptor
  fact, unsigned and signed `llvm.*.with.overflow.i64` chains, partial-limb
  sign/zero wrap, and fix-last-limb fill, without source-name admission and
  without changing recognizer fallback behavior. The terminal routines are
  call-free and relocation-free; a scratch prototype covered upstream
  signed/unsigned limb64 overflow cases before the bytes were wired. The
  focused report-all proof moved Debug std-hello compiler_rt from 116 emitted /
  327 failed to 118 emitted / 325 failed, closed the 15/15 limb64 selector
  bucket, and advanced the first failure to `compiler_rt.udivmodei4.__udivei4`
  for the integer-helper selector bucket. Stage-one results: 15 limb64 rows
  through selector, 0 limb64 rows through fallback, and 0 no-spill envelope
  rejections. Recognizer count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged outside this opt-in selector proof
  slice.
- 2026-07-08 (this commit) Item 12b export-cache storage re-key: real-row AIR
  export cache schema 2 stores artifacts by content identity only (Zig pin,
  exporter-relevant z_llvm state, release mode), while selector version,
  candidate-file hash, limit, and slice membership stay as read-layer
  validation. Fresh-export and cache-hit strict limit-100 all-mode summaries
  matched, with fresh export timings of 512197/531795/425464 ms and cache-hit
  timings of 15686/17114/12541 ms for ReleaseFast/ReleaseSafe/ReleaseSmall.
  `clean-tmp --keep-newest-per-mode --delete` removed 10 duplicate current-pin
  cache pairs and left exactly one cache entry per mode. Evidence
  `docs/evidence/real_rows_cache_rekey.summary`.
- 2026-07-08 (this commit) Item 15 integer-helper selector slice: the opt-in
  selector now admits and emits the real unsigned extended-int quotient
  envelope for `compiler_rt.udivmodei4.__udivei4` through model-owned
  structural checks: four-argument void ABI, exactly two scratch quotient and
  divisor i32 array allocas, `zig.target.intByteSize`, `llvm.ctlz.i32`,
  quotient-only limb-count and byte-count derivations, unsigned i64
  divide/remainder operations, and split terminal bytes with relocatable calls
  to `zig.target.intByteSize` and `memset`. The related remainder and signed
  extended-int rows stay fail-closed; the focused report-all proof moved Debug
  std-hello compiler_rt from 118 emitted / 325 failed to 119 emitted / 324
  failed and advanced the first integer-helper failure to
  `compiler_rt.udivmodei4.__umodei5`. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged
  outside this opt-in selector proof slice. Evidence
  `tmp/std_debug_hello_debug_udivei4_selector_after.log`;
  `tmp/distribution_all_after_udivei4_selector.log`.
- 2026-07-08 (this commit) Item 15 integer-helper selector slice: the opt-in
  selector now admits and emits the real unsigned extended-int remainder
  envelope for `compiler_rt.udivmodei4.__umodei5` through model-owned
  structural checks: five-argument void ABI, exactly two scratch quotient and
  divisor i32 array allocas, `zig.target.intByteSize`, `llvm.ctlz.i32`,
  inline memcpy, absence of the quotient-form `i16` limb-count shift,
  unsigned i64 divide/remainder operations, and split terminal bytes with
  relocatable calls to `zig.target.intByteSize`, `memset`, and an embedded
  tail jump to `memcpy`. This closes the interrupted cycle as a
  terminal-template routine, not composed per-instruction selection: item-15
  accounting is now composed-selection rows 0, terminal-template rows 17
  (15 limb64 plus `__udivei4` and `__umodei5`), and open integer-helper
  fallback candidates 43. The quotient-five and signed extended-int rows stay
  fail-closed; the focused report-all proof moved Debug std-hello compiler_rt
  from 119 emitted / 324 failed to 120 emitted / 323 failed and advanced the
  first integer-helper failure to `compiler_rt.udivmodei4.__udivei5`.
  Recognizer count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged outside this opt-in selector proof
  slice. No further row templating is allowed before a block-local composed
  selection proof, and if that proof immediately needs liveness or spilling it
  triggers item-15 stage two. Evidence
  `tmp/std_debug_hello_debug_umodei5_selector_after.log`;
  `tmp/distribution_all_after_umodei5_selector_rerun.log`.
- 2026-07-08 (this commit) Item 15 composition machinery slice: the opt-in
  selector now has a block-local composed selection path for single-block i32
  integer operations, with explicit parameter-to-SysV-register binding,
  accumulator ownership, machine-instruction emission through the normal x86_64
  instruction layer, rollback before fallback on rejected rows, and a
  fail-closed no-spill-envelope diagnostic when a row needs another live
  accumulator copy. This is machinery only, not a real-row closure:
  composed-selection rows remain 0, terminal-template rows remain 17, and open
  integer-helper fallback candidates remain 43. Recognizer count still 1 (no
  new recognizer reorder or pre-pass); `shape_recognizer_functions` is
  unchanged outside this opt-in selector proof slice. Verification:
  `zig build test`; `tmp/distribution_all_after_composed_block_skeleton.log`.
  The next required proof remains a real integer-helper row through composed
  per-instruction selection, with no terminal byte spans.
- 2026-07-08 (this commit) Item 15 composition proof slice: the opt-in
  selector now closes the first real integer-helper row through composed
  per-instruction selection, `compiler_rt.parity.__paritysi2`, with no
  terminal byte span and no whole-function envelope. The selector walks the
  block-local IR, assigns the live accumulator to EAX and the scratch/count
  value to ECX, emits machine instructions for each owned `lshr`, `xor`,
  `and`, `trunc`, and `zext`, and fail-closes on unowned instruction forms,
  operand kinds, or no-spill envelope pressure. Debug std-hello compiler_rt
  report-all moved from 120 emitted / 323 failed to 121 emitted / 322 failed.
  Item-15 accounting is now composed-selection rows 1, terminal-template rows
  17, and open integer-helper fallback candidates 42; the remaining parity
  widths stay fail-closed for later width-parametric composition. Recognizer
  count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged outside this opt-in selector proof
  slice. Evidence `tmp/std_debug_hello_debug_paritysi2_composed.log`;
  `tmp/distribution_all_after_paritysi2_composed.log`.
- 2026-07-08 (this commit) Item 15 width-parametric composition slice: the
  same block-local parity selector now owns the i64 variant
  `compiler_rt.parity.__paritydi2` without a terminal byte span or
  whole-function envelope. The selector tracks 64-bit argument/scratch/RAX
  locations, emits normal machine instructions for `lshr i64` and `xor i64`,
  then narrows into the existing i16 table lookup path; unsupported i128
  parity remains fail-closed because it needs a two-register value model rather
  than the current single accumulator/scratch envelope. Debug std-hello
  compiler_rt report-all moved from 121 emitted / 322 failed to 122 emitted /
  321 failed. Item-15 accounting is now composed-selection rows 2,
  terminal-template rows 17, and open integer-helper fallback candidates 41.
  Recognizer count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged outside this opt-in selector proof
  slice. Evidence `tmp/std_debug_hello_debug_paritydi2_composed.log`;
  `tmp/distribution_all_after_paritydi2_composed.log`.
- 2026-07-08 (this commit) Item 15 two-limb composition slice: the
  block-local parity selector now owns the i128 variant
  `compiler_rt.parity.__parityti2` with two explicit register-pair slots
  (`rcx`/`rdx` and `r8`/`r9`) rather than a terminal byte span or
  whole-function envelope. The selector composes `lshr i128`, `xor i128`,
  trunc-to-low-limb, and the existing i16 table lookup path through ordinary
  machine instructions, and rejects unproved pair operations fail-closed.
  Debug std-hello compiler_rt report-all moved from 122 emitted / 321 failed
  to 123 emitted / 320 failed. Item-15 accounting is now composed-selection
  rows 3, terminal-template rows 17, and open integer-helper fallback
  candidates 40. Recognizer count still 1 (no new recognizer reorder or
  pre-pass); `shape_recognizer_functions` is unchanged outside this opt-in
  selector proof slice. Evidence
  `tmp/std_debug_hello_debug_parityti2_composed.log`;
  `tmp/distribution_all_after_parityti2_composed.log`.
- 2026-07-08 (this commit) Item 15 stage-two trigger slice: the opt-in
  selector now computes per-block live-in/live-out sets, PHI edge live-outs,
  CFG edge counts, and no-spill register pressure for multi-block generic-CFG
  candidates before any composed emission attempt. Multi-block rows that stay
  inside the no-spill envelope now fail closed with `stage2-liveness-required`
  until cross-block emission materializes the analyzed values; rows above the
  envelope continue to reject as `stage2-register-pressure`. This unlocks no
  new compiler_rt row: Debug std-hello compiler_rt report-all remains 123
  emitted / 320 failed, with first failure
  `compiler_rt.udivmodei4.__udivei5`. Item-15 accounting remains
  composed-selection rows 3, terminal-template rows 17, and open
  integer-helper fallback candidates 40. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged
  outside this opt-in selector stage-two groundwork. Evidence
  `tmp/std_debug_hello_debug_stage2_pressure.log`;
  `tmp/distribution_all_after_stage2_liveness.log`.
- 2026-07-08 (this commit) Item 15 composed mulo slice: the block-local
  selector now closes `compiler_rt.mulo.__mulosi4` through composed
  per-instruction selection, not a terminal byte span or whole-function
  envelope. The selector assigns the sign-extended operands to explicit
  scratch registers, emits ordinary machine instructions for 64-bit `mul`,
  add-immediate overflow biasing, unsigned compare, boolean `setb`, the
  overflow-flag store through the pointer argument, truncation, and the i32
  return; unsupported wider mulo variants remain fail-closed. Debug std-hello
  compiler_rt report-all moved from 123 emitted / 320 failed to 124 emitted /
  319 failed, with first failure still `compiler_rt.udivmodei4.__udivei5`.
  Item-15 accounting is now composed-selection rows 4, terminal-template rows
  17, and open integer-helper fallback candidates 39. Recognizer count still
  1 (no new recognizer reorder or pre-pass); `shape_recognizer_functions` is
  unchanged outside this opt-in selector proof slice. Evidence
  `tmp/std_debug_hello_debug_mulosi4_composed.log`;
  `tmp/distribution_all_after_mulosi4_composed.log`.
- 2026-07-08 (this commit) Item 15 composed stack out-param call slice: the
  block-local selector now closes `compiler_rt.int.__umoddi3` through composed
  per-instruction selection, not a terminal byte span or whole-function
  envelope. The selector owns one `alloca i64` stack slot, validates direct
  scalar-call argument registers without permutation, passes the stack slot
  pointer as the third SysV argument, invalidates caller-clobbered register
  values after the call, reloads the i64 result from the stack slot, restores
  the frame, and returns i64. Debug std-hello compiler_rt report-all moved from
  124 emitted / 319 failed to 125 emitted / 318 failed, with first failure
  still `compiler_rt.udivmodei4.__udivei5`. Item-15 accounting is now
  composed-selection rows 5, terminal-template rows 17, and open integer-helper
  fallback candidates 38. Recognizer count still 1 (no new recognizer reorder
  or pre-pass); `shape_recognizer_functions` is unchanged outside this opt-in
  selector proof slice. Evidence
  `tmp/std_debug_hello_debug_umoddi3_composed.log`;
  `tmp/distribution_all_after_umoddi3_composed.log`.
- 2026-07-08 (this commit) Item 15 stage-two composed spill slice: the
  block-local selector now closes `compiler_rt.int.__moddi3` through composed
  per-instruction selection with bounded spill/reload support, not a terminal
  byte span or whole-function envelope. The selector reserves a 24-byte frame
  for a stack out-param plus two i64 spill slots, lowers `ashr i64` sign masks
  with a real SAR instruction, lowers `llvm.abs.i64` as an intrinsic operation,
  reloads scalar direct-call arguments into their SysV registers, preserves the
  pre-call sign mask and magnitude through explicit frame slots, and restores
  the signed remainder after the call. Debug std-hello compiler_rt report-all
  moved from 125 emitted / 318 failed to 126 emitted / 317 failed, with first
  failure still `compiler_rt.udivmodei4.__udivei5`. Item-15 accounting is now
  composed-selection rows 6, terminal-template rows 17, and open integer-helper
  fallback candidates 37. Recognizer count still 1 (no new recognizer reorder
  or pre-pass); `shape_recognizer_functions` is unchanged outside this opt-in
  selector proof slice. Evidence
  `tmp/std_debug_hello_debug_moddi3_composed.log`;
  `tmp/distribution_all_after_moddi3_composed.log`.
- 2026-07-08 (this commit) Item 15 stage-two CFG machinery slice: the opt-in
  selector now has a tested composed cross-block path for acyclic no-PHI CFGs.
  It emits block labels, reuses the per-block instruction selector inside each
  block, lowers owned i1 branch conditions through `test` plus conditional
  branches, and emits fallthrough-aware `jmp`s through the machine-instruction
  layer. Loops, PHIs, unsupported terminators, and pressure above the current
  no-spill envelope stay fail-closed; the real rank-order row
  `compiler_rt.udivmodei4.__udivei5` still fails first because it needs PHI
  edge materialization and loop/backedge support. Debug std-hello compiler_rt
  report-all stayed at 443 selected / 126 emitted / 317 failed. Item-15
  accounting remains composed-selection rows 6, terminal-template rows 17, and
  open integer-helper fallback candidates 37. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged.
  Evidence `tmp/std_debug_hello_debug_stage2_cfg_branch.log`.
- 2026-07-08 (this commit) Item 15 stage-two PHI edge machinery slice: the
  composed selector now assigns fixed scratch locations to owned scalar i32/i64
  PHI results and emits predecessor-edge PHI copies for unconditional edges in
  acyclic CFGs. Conditional edges needing path-specific PHI copies, loop
  backedges, unsupported PHI widths/types, and pressure beyond the no-spill
  envelope still fail closed. Debug std-hello compiler_rt report-all stayed at
  443 selected / 126 emitted / 317 failed, with first failure still
  `compiler_rt.udivmodei4.__udivei5`. Item-15 accounting remains
  composed-selection rows 6, terminal-template rows 17, and open integer-helper
  fallback candidates 37. Recognizer count still 1 (no new recognizer reorder
  or pre-pass); `shape_recognizer_functions` is unchanged. Evidence
  `tmp/std_debug_hello_debug_stage2_phi_edges.log`.
- 2026-07-08 (this commit) Item 15 stage-two loop/conditional PHI edge
  machinery slice: the composed selector now allows owned backedges, emits
  synthetic conditional-edge PHI move blocks, and rebinds fixed PHI registers at
  block entry so loop headers can be modeled without source-name admission.
  Unsupported loop operands and pressure beyond the no-spill envelope still fail
  closed. Debug std-hello compiler_rt report-all stayed at 443 selected / 126
  emitted / 317 failed, with first failure still
  `compiler_rt.udivmodei4.__udivei5`. Item-15 accounting remains
  composed-selection rows 6, terminal-template rows 17, and open integer-helper
  fallback candidates 37. Recognizer count still 1 (no new recognizer reorder
  or pre-pass); `shape_recognizer_functions` is unchanged. Evidence
  `tmp/std_debug_hello_debug_stage2_loop_phi.log`.
- 2026-07-08 (this commit) Item 15 stage-two void-return CFG slice: the
  composed selector now admits `.void` as an owned return type for single-block
  and cross-block CFG selection, shares return-epilogue emission for scalar and
  void returns, and rejects malformed value-bearing void returns fail-closed.
  This closes no compiler_rt row yet: Debug std-hello compiler_rt report-all
  stayed at 443 selected / 126 emitted / 317 failed, with first failure still
  `compiler_rt.udivmodei4.__udivei5`. That row now remains blocked on broader
  extended-division loop and stack-array memory-object instruction support, not
  a terminal template. Item-15 accounting remains composed-selection rows 6,
  terminal-template rows 17, and open integer-helper fallback candidates 37.
  Recognizer count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged. Evidence
  `tmp/std_debug_hello_debug_stage2_void_ret.log`.
- 2026-07-08 (this commit) Item 15 stage-two stack-array memory-object slice:
  the composed selector now owns a first local `[N x i32]` stack-object form
  with aligned stack-frame allocation, constant GEP to an i32 element, i32
  stack load/store emission, and new x86_64 machine encodings for immediate
  `sub rsp` plus stack-displacement `store eax`. Dynamic stack-array indices
  and multiple local stack objects remain fail-closed rather than falling back
  to a terminal template. This closes no compiler_rt row yet: Debug std-hello
  compiler_rt report-all stayed at 443 selected / 126 emitted / 317 failed,
  with first failure still `compiler_rt.udivmodei4.__udivei5`. Item-15
  accounting remains composed-selection rows 6, terminal-template rows 17, and
  open integer-helper fallback candidates 37. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged.
  Evidence `tmp/std_debug_hello_debug_stage2_stack_i32_array.log`.
- 2026-07-08 (this commit) Item 15 stage-two multi-stack-array frame-planning
  slice: the composed selector now preplans one aligned stack frame for
  multiple local `[N x i32]` stack arrays, assigns each array a stable
  displacement inside that frame, and keeps constant GEP load/store selection
  through the machine-instruction layer. Dynamic stack-array indices still fail
  closed, so this closes no compiler_rt row yet: Debug std-hello compiler_rt
  report-all stayed at 443 selected / 126 emitted / 317 failed, with first
  failure still `compiler_rt.udivmodei4.__udivei5`. Item-15 accounting remains
  composed-selection rows 6, terminal-template rows 17, and open integer-helper
  fallback candidates 37. Recognizer count still 1 (no new recognizer reorder
  or pre-pass); `shape_recognizer_functions` is unchanged. Evidence
  `tmp/std_debug_hello_debug_stage2_multi_stack_i32_arrays.log`.
- 2026-07-08 (this commit) Item 15 stage-two dynamic stack-array index slice:
  the composed selector now lowers named i64 `[N x i32]` GEP element indices by
  materializing the index in `%rcx`, carrying the index name in the stack
  pointer location, validating that cache at load/store use, and emitting
  first-class `%rsp + %rcx*4 + disp` machine load/store instructions with
  assembly, encoding, sizing, and verifier coverage. This closes no compiler_rt
  row yet: Debug std-hello compiler_rt report-all stayed at 443 selected / 126
  emitted / 317 failed, with first failure still
  `compiler_rt.udivmodei4.__udivei5`. Item-15 accounting remains
  composed-selection rows 6, terminal-template rows 17, and open integer-helper
  fallback candidates 37. Recognizer count still 1 (no new recognizer reorder
  or pre-pass); `shape_recognizer_functions` is unchanged. Evidence
  `tmp/std_debug_hello_debug_stage2_dynamic_stack_i32_index.log`.
- 2026-07-08 (this commit) Item 15 stage-two scalar freeze identity slice:
  the composed selector now admits scalar `freeze` and lowers i32/i64 freeze as
  an identity over the existing model-owned value location in both single-block
  and cross-block selection. Unsupported freeze widths, types, and locations
  still fail closed. This closes no compiler_rt row yet: Debug std-hello
  compiler_rt report-all stayed at 443 selected / 126 emitted / 317 failed,
  with first failure still `compiler_rt.udivmodei4.__udivei5`. Item-15
  accounting remains composed-selection rows 6, terminal-template rows 17, and
  open integer-helper fallback candidates 37. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged.
  Evidence `tmp/std_debug_hello_debug_stage2_freeze_identity.log`.
- 2026-07-08 (this commit) Item 15 stage-two block-envelope slice: the
  composed selector now names and raises its no-spill CFG block cap from the
  initial 16-block scaffold to 64 blocks, with tests proving a 17-block chain
  composes and a 65-block chain still fails closed at `stage2-block-count`.
  Liveness and register-pressure checks remain the real no-spill guard. This
  closes no compiler_rt row yet: Debug std-hello compiler_rt report-all stayed
  at 443 selected / 126 emitted / 317 failed, with first failure still
  `compiler_rt.udivmodei4.__udivei5`. Item-15 accounting remains
  composed-selection rows 6, terminal-template rows 17, and open integer-helper
  fallback candidates 37. Recognizer count still 1 (no new recognizer reorder
  or pre-pass); `shape_recognizer_functions` is unchanged. Evidence
  `tmp/std_debug_hello_debug_stage2_block64_envelope.log`.
- 2026-07-08 (this commit) Item 15 selector diagnostics slice: the object
  emission report-all path now carries the selector's structured tag/detail on
  each failed function and on the summary's first failure while preserving the
  existing fail-closed coarse diagnostic. This closes no compiler_rt row, but it
  moves the next `compiler_rt.udivmodei4.__udivei5` action from the old generic
  `UnsupportedCodegenControlFlow` bucket to the exact selector boundary
  `unsupported_instruction` / `udiv`. Debug std-hello compiler_rt report-all
  stayed at 443 selected / 126 emitted / 317 failed. Item-15 accounting remains
  composed-selection rows 6, terminal-template rows 17, and open integer-helper
  fallback candidates 37. Recognizer count still 1 (no new recognizer reorder
  or pre-pass); `shape_recognizer_functions` is unchanged. Evidence
  `tmp/std_debug_hello_debug_selector_diagnostics.log`.
- 2026-07-08 (this commit) Item 15 composed unsigned div/rem slice: the
  composed selector now lowers selector-owned i64 `udiv` and `urem` through
  explicit `%rax:%rdx` dividend setup, `%rdx` zeroing, x86_64 `divq`, and
  ordinary machine-instruction assembly/encoding/verifier paths. This closes no
  compiler_rt row yet, but moves the first remaining failure
  `compiler_rt.udivmodei4.__udivei5` from `unsupported_instruction` / `udiv` to
  `no_spill_envelope` / `stage2-register-pressure`, making stage-two pressure
  handling the next rank-order boundary rather than unsigned division support
  or a terminal template. Debug std-hello compiler_rt report-all stayed at 443
  selected / 126 emitted / 317 failed. Item-15 accounting remains
  composed-selection rows 6, terminal-template rows 17, and open integer-helper
  fallback candidates 37. Recognizer count still 1 (no new recognizer reorder
  or pre-pass); `shape_recognizer_functions` is unchanged. Evidence
  `docs/evidence/std_debug_hello_selector_udiv.summary`.
- 2026-07-09 (this commit) Item 15 stage-two pressure accounting slice: the
  stage-two liveness preflight now excludes frame-resident `alloca` values and
  stack-derived GEP names from the register-pressure budget, with a unit test
  proving such stack-object names do not consume the no-spill GPR envelope.
  This closes no compiler_rt row yet: Debug std-hello compiler_rt report-all
  stayed at 443 selected / 126 emitted / 317 failed, with first failure still
  `compiler_rt.udivmodei4.__udivei5` at `no_spill_envelope` /
  `stage2-register-pressure`. Item-15 accounting remains composed-selection
  rows 6, terminal-template rows 17, and open integer-helper fallback
  candidates 37. Recognizer count still 1 (no new recognizer reorder or
  pre-pass); `shape_recognizer_functions` is unchanged. Evidence
  `docs/evidence/std_debug_hello_stage2_pressure_exempt.summary`.
- 2026-07-09 (this commit) Item 15 stage-two spill-frame envelope slice: the
  composed selector now models a bounded six-slot 64-bit spill area for
  stage-two frames and reserves that area before stack-array payloads so spills
  cannot overlap stack-backed arrays. Unit coverage now distinguishes
  no-spill pressure from the bounded spill envelope and proves rows above the
  envelope still fail closed before emission. This closes no compiler_rt row:
  Debug std-hello compiler_rt report-all stayed at 443 selected / 126 emitted /
  317 failed, with first failure still `compiler_rt.udivmodei4.__udivei5` at
  `no_spill_envelope` / `stage2-register-pressure`. This is the third
  consecutive no-move attempt on that row, so the hard-stop rule is recorded in
  `docs/next_steps.md`. Item-15 accounting remains composed-selection rows 6,
  terminal-template rows 17, and open integer-helper fallback candidates 37.
  Recognizer count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged. Evidence
  `docs/evidence/std_debug_hello_stage2_spill_frame.summary`.
- 2026-07-09 (this commit) Item 15 stage-two pressure diagnostic slice: the
  selector now reports the max pressure point and first six-slot-envelope
  exceedance for stage-two rows. The real `compiler_rt.udivmodei4.__udivei5`
  evidence row records `blocks=51`, `edges=93`, `max_live_values=16`,
  `max_block=Then14`, `max_boundary=live_out`, `max_spill_slots_needed=10`,
  `max_spill_slots_over_envelope=4`, `first_exceed_block=Then8.prol`,
  `first_exceed_boundary=live_out`, `first_exceed_live_values=13`,
  `first_exceed_spill_slots_needed=7`, and
  `first_exceed_spill_slots_over_envelope=1`. This closes no compiler_rt row
  and skips `__udivei5` as a recorded stage-two-boundary row while the
  remaining integer-helper rows are measured/fixed in rank order. Item-15
  accounting remains composed-selection rows 6, terminal-template rows 17, open
  integer-helper fallback candidates 37, with stage-two-boundary rows now 1.
  Recognizer count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged. Evidence
  `docs/evidence/std_debug_hello_udivei5_pressure.tsv`.
- 2026-07-09 (this commit) Item 15 rank-order pressure diagnostic slice:
  `compiler_rt.udivmodei4.__umodei4` is skipped as the second stage-two
  pressure-boundary row. The evidence row records `blocks=65`, `edges=115`,
  `max_live_values=21`, `max_block=Then15`, `max_boundary=live_out`,
  `max_spill_slots_needed=15`, `max_spill_slots_over_envelope=9`,
  `first_exceed_block=Then9.prol`, `first_exceed_boundary=live_out`,
  `first_exceed_live_values=13`, `first_exceed_spill_slots_needed=7`, and
  `first_exceed_spill_slots_over_envelope=1`. This closes no compiler_rt row
  and moves the next rank-order integer-helper candidate to
  `compiler_rt.udivmod.__umodti3`. Item-15 accounting remains
  composed-selection rows 6 and terminal-template rows 17, with
  stage-two-boundary rows now 2 and open integer-helper fallback candidates 36.
  Recognizer count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged. Evidence
  `docs/evidence/std_debug_hello_umodei4_pressure.tsv`.
- 2026-07-09 (this commit) Item 15 composed i128 out-param call slice: the
  block-local selector now closes `compiler_rt.udivmod.__umodti3` through
  composed selection, not a terminal template. The selector owns the generic
  i128 stack out-param wrapper shape: a 16-byte stack slot, default/`fastcc`
  direct-call argument assignment where i128 operands consume two SysV integer
  registers, pointer out-param forwarding to the next ABI register, and i128
  return from the loaded stack slot via `rdx:rax`. Unsupported i128 stack uses
  outside that proven path remain fail-closed. The row fits the current
  envelope with no stage-two pressure boundary. Debug std-hello compiler_rt
  report-all moved to 443 selected, 127 emitted, and 316 failed; the first
  failure remains `compiler_rt.udivmodei4.__udivei5` because recorded
  stage-two-boundary rows still appear before the next active integer-helper
  candidate. Item-15 accounting is now composed-selection rows 7,
  terminal-template rows 17, stage-two-boundary rows 2, and open integer-helper
  fallback candidates 35. Recognizer count still 1 (no new recognizer reorder
  or pre-pass); `shape_recognizer_functions` is unchanged. Evidence
  `docs/evidence/std_debug_hello_umodti3_composed.summary`.
- 2026-07-09 (this commit) Item 15 composed signed i128 remainder slice: the
  block-local selector now closes `compiler_rt.udivmod.__modti3` through
  composed selection, not a terminal template. The selector owns i128 sign-mask
  lowering from `ashr 127`, pairwise i128 `xor`/`sub` with carry propagation
  through `sbbq`, `llvm.abs.i128` intrinsic lowering, and bounded pair spills
  around the i128 stack out-param direct helper call. Unsupported i128 pair
  locations, stack uses, and call forms outside the proven path remain
  fail-closed. Debug std-hello compiler_rt report-all moved to 443 selected,
  128 emitted, and 315 failed; the first failure remains
  `compiler_rt.udivmodei4.__udivei5` because recorded stage-two-boundary rows
  still appear before the next active integer-helper candidate. The next active
  composed-selector candidate after intervening tail-call ABI rows is
  `compiler_rt.mulXi3.__mulsi3`. Item-15 accounting is now
  composed-selection rows 8, terminal-template rows 17, stage-two-boundary rows
  2, and open integer-helper fallback candidates 34. Recognizer count still 1
  (no new recognizer reorder or pre-pass); `shape_recognizer_functions` is
  unchanged. Evidence `docs/evidence/std_debug_hello_modti3_composed.summary`.
- 2026-07-09 (this commit) Item 15 composed i32 multiply-loop slice: the
  block-local selector now closes `compiler_rt.mulXi3.__mulsi3` through
  composed selection, not a terminal template. The selector owns the generic
  three-block i32 multiply loop shape with per-block PHI register assignment,
  eq-zero boolean materialization, scalar `select` emission, and scratch-backed
  immediate left-shift emission while keeping unsupported value/register states
  fail-closed and rolled back for fallback recognizers. The row fits the
  current envelope with max live values 3, zero spill slots needed, and no
  six-slot-envelope exceedance. Debug std-hello compiler_rt report-all moved
  to 443 selected, 129 emitted, and 314 failed; the first failure remains
  `compiler_rt.udivmodei4.__udivei5` because recorded stage-two-boundary rows
  still appear before the next active integer-helper candidate. The next active
  composed-selector candidate after intervening tail-call ABI rows is
  `compiler_rt.mulXi3.__multi3`. Item-15 accounting is now composed-selection
  rows 9, terminal-template rows 17, stage-two-boundary rows 2, and open
  integer-helper fallback candidates 33. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged.
  Evidence `docs/evidence/std_debug_hello_mulsi3_composed.summary`.
- 2026-07-09 (this commit) Item 15 pressure diagnostic slice: stage-two
  pressure accounting now includes intra-block live values, so single-block
  integer helpers no longer report zero pressure merely because they have no
  block-boundary live sets. The diagnostic proof for
  `compiler_rt.mulXi3.__multi3` records max live values 10 at block `Entry`,
  boundary `13`, spill slots needed 4, and no six-slot-envelope exceedance;
  the row remains open for composed instruction selection, not a terminal
  template. Debug compiler_rt report-all remains 443 selected, 129 emitted, and
  314 failed. Item-15 accounting remains composed-selection rows 9,
  terminal-template rows 17, stage-two-boundary rows 2, and open integer-helper
  fallback candidates 33. Recognizer count still 1 (no new recognizer reorder
  or pre-pass); `shape_recognizer_functions` is unchanged. Evidence
  `docs/evidence/std_debug_hello_multi3_pressure.tsv`.
- 2026-07-09 (this commit) Item 15 allocator-boundary stop: the focused
  composed-selection attempt for `compiler_rt.mulXi3.__multi3` reached `%10`
  but hit the same-row three-attempt stop rule. At the decisive point, all six
  local spill slots held values still needed later, and preserving `%9` for its
  later `%11` use required another scalar spill. The next slice is the reviewed
  real register allocator with `__multi3` as the acceptance row; do not add
  more ad hoc preservation rules. Item-15 accounting remains
  composed-selection rows 9, terminal-template rows 17, stage-two-boundary rows
  2, and open integer-helper fallback candidates 33, with one allocator
  acceptance row pending. Recognizer count still 1 (no new recognizer reorder
  or pre-pass); `shape_recognizer_functions` is unchanged. Focused log
  `tmp/std_debug_hello_debug_multi3_composed_after_liveness_preserve.log`;
  failed patch saved at `tmp/generic_cfg_selector_failed_multi3_attempt.patch`.
- 2026-07-09 (this commit) Item 15 register-allocator design note: the
  approved stage-two allocator slice is now binding on the tracker. The
  composed selector moves to virtual registers as its value model, allocation
  is liveness-aware over the existing stage-two live sets with a
  linear-scan-or-equivalent algorithm, spill capacity is frame-sized instead of
  the six-slot envelope, calling-convention and clobber requirements are
  expressed as register-class or fixed-assignment constraints, and output must
  be deterministic. Acceptance order is the nine existing composed rows,
  `compiler_rt.mulXi3.__multi3`, then the parked `__udivei5` and `__umodei4`
  pressure-boundary rows. Recognizer count still 1 (no new recognizer reorder
  or pre-pass); `shape_recognizer_functions` is unchanged.
- 2026-07-09 (this commit) Item 15 register-allocator implementation slice:
  the composed selector now records each named value as a virtual-register
  binding plus its current physical/frame assignment. This is the first
  virtual-register rewrite step and intentionally preserves the existing
  emitted instruction stream: allocation and spill insertion still use the
  current assignments, while later slices can allocate from the recorded
  virtual value model. The nine composed rows remain the regression set, and
  the acceptance order is unchanged (`__multi3`, then `__udivei5` and
  `__umodei4`). Item-15 accounting remains composed-selection rows 9,
  terminal-template rows 17, stage-two-boundary rows 2, open integer-helper
  fallback candidates 33, and one allocator acceptance row pending. Recognizer
  count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged.
- 2026-07-09 (this commit) Item 15 register-allocator implementation slice:
  the composed selector now builds a deterministic linear-scan allocation plan
  from named scalar live intervals before emission. The plan uses virtual
  registers as the value model, assigns fixed register classes in stable order,
  and records frame-sized spill indices instead of rejecting at the old
  six-slot envelope; this commit keeps emission on the current assignments so
  the nine composed rows remain the regression set for the next consumption
  slice. Item-15 accounting remains composed-selection rows 9,
  terminal-template rows 17, stage-two-boundary rows 2, open integer-helper
  fallback candidates 33, and one allocator acceptance row pending. Recognizer
  count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged.
- 2026-07-09 (this commit) Item 15 register-allocator implementation slice:
  the composed selector's stage-two frame now reserves seven qword spill slots
  when liveness pressure exceeds the register-only envelope, and the x86_64
  frame-index encoding/assembly tables cover the resulting `slot14` spill
  address. This is the first frame-sized spill-capacity step after the
  allocator plan; emission still uses current assignments, so the nine composed
  rows remain the regression set and `compiler_rt.mulXi3.__multi3` remains the
  allocator acceptance row for the next instruction/admission slice. Item-15
  accounting remains composed-selection rows 9, terminal-template rows 17,
  stage-two-boundary rows 2, open integer-helper fallback candidates 33, and
  one allocator acceptance row pending. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged.
- 2026-07-09 (this commit; acknowledges INBOX-1) Item 15
  allocator-consumption slice: composed selector result binding now consults
  the deterministic allocation plan for no-spill planned locations and records
  the binding through the virtual-register value model. This first consumption
  slice only accepts planned locations that match the current proven producer
  location; mismatched planned registers and planned spills remain deferred so
  hardcoded temporaries do not silently clobber live values before the
  allocator owns reload/spill insertion. The nine composed rows remain the
  regression set, and Debug std-hello compiler_rt report-all stayed at
  443 selected, 129 emitted, and 314 failed; `compiler_rt.mulXi3.__multi3`
  remains the allocator acceptance row. Item-15 accounting remains
  composed-selection rows 9, terminal-template rows 17, stage-two-boundary rows
  2, open integer-helper fallback candidates 33, and one allocator acceptance
  row pending. Recognizer count still 1 (no new recognizer reorder or
  pre-pass); `shape_recognizer_functions` is unchanged. Evidence
  `tmp/std_debug_hello_debug_allocator_plan_consumption.log`; distribution-all
  proof `tmp/distribution_all_after_allocator_plan_consumption.log`.
- 2026-07-09 (this commit) Item 15 allocator-consumption slice: planned
  scalar spills now materialize into deterministic stage-two frame slots when
  the composed selector already owns a pressure frame. Unsupported widths,
  aggregate values, spill indexes outside the deterministic frame, and rows
  without a proven pressure frame still fail closed or defer to the existing
  path instead of guessing. The nine composed rows remain the regression set,
  and Debug std-hello compiler_rt report-all stayed at 443 selected, 129
  emitted, and 314 failed; `compiler_rt.mulXi3.__multi3` remains the allocator
  acceptance row. Item-15 accounting remains composed-selection rows 9,
  terminal-template rows 17, stage-two-boundary rows 2, open integer-helper
  fallback candidates 33, and one allocator acceptance row pending. Recognizer
  count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged. Evidence
  `tmp/std_debug_hello_debug_scalar_planned_spill.log`; distribution-all proof
  `tmp/distribution_all_after_scalar_planned_spill.log`.
- 2026-07-09 (this commit) Item 15 allocator-consumption slice: planned
  128-bit value spills now consume two deterministic stage-two frame slots and
  materialize pair stores when the composed selector already owns a pressure
  frame. The allocator plan now counts pair spills as two slots so following
  scalar spills cannot alias the pair, while rows without a pressure frame and
  spill indexes outside the deterministic frame remain fail-closed. The nine
  composed rows remain the regression set, and Debug std-hello compiler_rt
  report-all stayed at 443 selected, 129 emitted, and 314 failed;
  `compiler_rt.mulXi3.__multi3` remains the allocator acceptance row. Item-15
  accounting remains composed-selection rows 9, terminal-template rows 17,
  stage-two-boundary rows 2, open integer-helper fallback candidates 33, and
  one allocator acceptance row pending. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged.
  Evidence `tmp/std_debug_hello_debug_pair_planned_spill.log`;
  distribution-all proof `tmp/distribution_all_after_pair_planned_spill.log`.
- 2026-07-09 (this commit) Item 15 allocator-consumption slice: the selector
  allocation plan now records interval end positions, and the composed path can
  consume a mismatched planned register only when the current lowering position
  proves every conflicting value in that register has expired. The expiry check
  is non-destructive, so value bindings remain available for fail-closed reload
  and use validation, and production reuse is limited to pure i128 arithmetic
  rows while call-shaped and established smaller composed rows keep their
  current placement. The nine composed rows remain the regression set, and
  Debug std-hello compiler_rt report-all stayed at 443 selected, 129 emitted,
  and 314 failed; `compiler_rt.mulXi3.__multi3` remains the allocator
  acceptance row. Item-15 accounting remains composed-selection rows 9,
  terminal-template rows 17, stage-two-boundary rows 2, open integer-helper
  fallback candidates 33, and one allocator acceptance row pending. Recognizer
  count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged. Evidence
  `tmp/std_debug_hello_debug_expired_plan_reuse.log`; distribution-all proof
  `tmp/distribution_all_after_expired_plan_reuse.log`.
- 2026-07-09 (this commit) Item 15 composed i64 immediate bit-assembly slice:
  the block-local selector now lowers the model-owned i64 low-32 mask form
  `and i64 x, 0xffffffff` through the zero-extending `and eax, imm32`
  encoding, and the adjacent `shl i64 x, imm6` form through the existing
  `shl rax, imm6` machine instruction. Other i64 immediate bitwise masks and
  unsupported shift amounts remain fail-closed. The nine composed rows remain
  the regression set, and Debug std-hello compiler_rt report-all stayed at
  443 selected, 129 emitted, and 314 failed; `compiler_rt.mulXi3.__multi3`
  remains the allocator acceptance row. Item-15 accounting remains
  composed-selection rows 9, terminal-template rows 17, stage-two-boundary rows
  2, open integer-helper fallback candidates 33, and one allocator acceptance
  row pending. Recognizer count still 1 (no new recognizer reorder or
  pre-pass); `shape_recognizer_functions` is unchanged. Evidence
  `tmp/std_debug_hello_debug_i64_immediate_bit_assembly.log`; distribution-all
  proof `tmp/distribution_all_after_i64_immediate_bit_assembly.log`.
- 2026-07-09 (this commit) Item 15 composed i128 materialization slice: the
  block-local selector now lowers the model-owned `zext i64 -> i128` form by
  materializing the low lane and zeroing the high lane through existing pair
  value machinery; other widened casts remain fail-closed. Zeroing a pair lane
  now clears any stale scalar binding for that register so later pair moves do
  not observe an obsolete scalar fact. The nine composed rows remain the
  regression set, and Debug std-hello compiler_rt report-all stayed at
  443 selected, 129 emitted, and 314 failed; `compiler_rt.mulXi3.__multi3`
  remains the allocator acceptance row. Item-15 accounting remains
  composed-selection rows 9, terminal-template rows 17, stage-two-boundary rows
  2, open integer-helper fallback candidates 33, and one allocator acceptance
  row pending. Recognizer count still 1 (no new recognizer reorder or
  pre-pass); `shape_recognizer_functions` is unchanged. Evidence
  `tmp/std_debug_hello_debug_zext64_to_i128_pair.log`; distribution-all proof
  `tmp/distribution_all_after_zext64_to_i128_pair.log`.
- 2026-07-09 (this commit) Item 15 composed i128 lane-shift slice: the
  block-local selector now lowers the model-owned `shl i128 x, 64` form by
  moving the low lane into the high lane and zeroing the low lane in the
  existing register pair; other i128 left-shift amounts remain fail-closed.
  This composes with the prior `zext i64 -> i128` materialization for the
  high-half construction used by `compiler_rt.mulXi3.__multi3`. The nine
  composed rows remain the regression set, and Debug std-hello compiler_rt
  report-all stayed at 443 selected, 129 emitted, and 314 failed;
  `compiler_rt.mulXi3.__multi3` remains the allocator acceptance row. Item-15
  accounting remains composed-selection rows 9, terminal-template rows 17,
  stage-two-boundary rows 2, open integer-helper fallback candidates 33, and
  one allocator acceptance row pending. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged.
  Evidence `tmp/std_debug_hello_debug_i128_shl64_pair.log`; distribution-all
  proof `tmp/distribution_all_after_i128_shl64_pair.log`.
- 2026-07-09 (this commit) Item 15 composed i128 pair-OR slice: the
  block-local selector now lowers the model-owned `or i128` pair form through
  lane-wise `or` emission, with operand materialization ordered to avoid
  clobbering overlapping SysV i128 argument registers or an already-owned
  `pair_b` value. This covers the final high/low lane join shape in
  `compiler_rt.mulXi3.__multi3` while unsupported pair binary operations
  remain fail-closed. The nine composed rows remain the regression set, and
  Debug std-hello compiler_rt report-all stayed at 443 selected, 129 emitted,
  and 314 failed; `compiler_rt.mulXi3.__multi3` remains the allocator
  acceptance row. Item-15 accounting remains composed-selection rows 9,
  terminal-template rows 17, stage-two-boundary rows 2, open integer-helper
  fallback candidates 33, and one allocator acceptance row pending. Recognizer
  count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged. Evidence
  `tmp/std_debug_hello_debug_i128_pair_or.log`; distribution-all proof
  `tmp/distribution_all_after_i128_pair_or.log`.
- 2026-07-09 (this commit) Item 15 allocator-consumption slice: the
  single-block composed selector now enables deterministic allocation-plan
  expired-register reuse, and i128 trunc/bitcast results route through
  `bindResultLoc` so planned registers and spills can own those low-lane
  values instead of bypassing the allocator. This is an allocator-consumption
  step, not a row closure: Debug std-hello compiler_rt report-all stayed at
  443 selected, 129 emitted, and 314 failed; `compiler_rt.mulXi3.__multi3`
  remains the allocator acceptance row. Item-15 accounting remains
  composed-selection rows 9, terminal-template rows 17, stage-two-boundary rows
  2, open integer-helper fallback candidates 33, and one allocator acceptance
  row pending. Recognizer count still 1 (no new recognizer reorder or
  pre-pass); `shape_recognizer_functions` is unchanged. Evidence
  `tmp/std_debug_hello_debug_trunc_plan_reuse.log`; distribution-all proof
  `tmp/distribution_all_after_trunc_plan_reuse.log`.
- 2026-07-09 (this commit) Item 15 allocator-consumption slice: the composed
  selector now materializes non-scratch i64 multiply lhs values into a
  deterministic planned result register when available, reloads spill64 rhs
  operands through an available scratch register, and keeps existing scratch-lhs
  composed rows unchanged. This is an allocator-consumption step, not a row
  closure: Debug std-hello compiler_rt report-all stayed at 443 selected, 129
  emitted, and 314 failed; `compiler_rt.mulXi3.__multi3` remains the allocator
  acceptance row. Item-15 accounting remains composed-selection rows 9,
  terminal-template rows 17, stage-two-boundary rows 2, open integer-helper
  fallback candidates 33, and one allocator acceptance row pending. Recognizer
  count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged. Evidence
  `tmp/std_debug_hello_debug_mul64_plan_materialize.log`; distribution-all proof
  `tmp/distribution_all_after_mul64_plan_materialize.log`.
- 2026-07-09 (this commit) Item 15 allocator-consumption slice: 128-bit
  immediate shift lowering now reloads planned `spill128` values through the
  existing pair materializer before `lshr i128 ..., 64` and `shl i128 ..., 64`,
  so allocator-assigned pair spills are consumed by composed selection instead
  of failing at pair resolution. This is an allocator-consumption step, not a
  row closure: Debug std-hello compiler_rt report-all stayed at 443 selected,
  129 emitted, and 314 failed; `compiler_rt.mulXi3.__multi3` remains the
  allocator acceptance row. Item-15 accounting remains composed-selection rows
  9, terminal-template rows 17, stage-two-boundary rows 2, open integer-helper
  fallback candidates 33, and one allocator acceptance row pending. Recognizer
  count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged. Evidence
  `tmp/std_debug_hello_debug_pair_shift_spill_reload.log`; distribution-all
  proof `tmp/distribution_all_after_pair_shift_spill_reload.log`.
- 2026-07-10 (this commit) Item 15 allocator-consumption diagnostic slice: the
  selector now reports composed `.no_emitter` diagnostics when the only
  alternative was the generic skeleton fallback, making report-all expose the
  actual composed boundary for skeleton rows. The same slice teaches i128
  trunc/bitcast lowering to materialize only the low lane of planned pair
  locations, including `spill128`, into the planned scalar destination instead
  of rejecting allocator-assigned pair spills. This is an
  allocator-consumption/diagnostic step, not a row closure: Debug std-hello
  compiler_rt report-all stayed at 443 selected, 129 emitted, and 314 failed;
  `compiler_rt.mulXi3.__multi3` moved from `composed-block-cast-width` to
  `composed-block-unsupported-value` and remains the allocator acceptance row.
  Item-15 accounting remains composed-selection rows 9, terminal-template rows
  17, stage-two-boundary rows 2, open integer-helper fallback candidates 33,
  and one allocator acceptance row pending. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged.
  Evidence `tmp/std_debug_hello_debug_i128_trunc_spill_reload.log`;
  distribution-all proof `tmp/distribution_all_after_i128_trunc_spill_reload.log`.
- 2026-07-10 (this commit; acknowledges INBOX-2) Item 15 `__multi3` gap
  inventory cycle: a focused Debug std-hello compiler_rt attempt with temporary
  full tracing recorded the current composed failure at `%2`
  (`and i64 ..., 4294967295`) and the tracked inventory enumerates the finite
  remaining `__multi3` gaps: the mask-immediate planned-value form, downstream
  same-form masks, i128 return from planned `spill128`, i128 return overlap
  moves, and raw helper diagnostic collapse. No row closes in this cycle:
  Debug compiler_rt report-all remains 443 selected, 129 emitted, and 314
  failed; item-15 accounting remains composed-selection rows 9,
  terminal-template rows 17, stage-two-boundary rows 2, open integer-helper
  fallback candidates 33, and one allocator acceptance row pending. Recognizer
  count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged. Evidence
  `docs/evidence/std_debug_hello_multi3_gap_inventory.tsv`; focused trace
  `tmp/std_debug_hello_debug_multi3_gap_inventory_trace.log`.
- 2026-07-10 (this commit) Item 15 allocator-consumption partial slice:
  composed 64-bit multiply now preserves a live scratch lhs before destructive
  use, can multiply through RAX when the lhs and/or rhs are in selector spill
  slots, and reuses expired scalar spill slots from the allocation plan. This is
  still not a row closure: `compiler_rt.mulXi3.__multi3` advances to
  `composed-block-unknown-rhs`, with the diagnostic probe identifying
  `%23 = add i64 %22, %10` as losing `%10` at position 29; the same-row
  three-attempt stop rule is now active. Debug compiler_rt report-all remains
  443 selected, 129 emitted, and 314 failed. Item-15 accounting remains
  composed-selection rows 9, terminal-template rows 17, stage-two-boundary rows
  2, open integer-helper fallback candidates 33, and one allocator acceptance
  row pending. Recognizer count still 1 (no new recognizer reorder or
  pre-pass); `shape_recognizer_functions` is unchanged. Evidence
  `tmp/multi3_only_after_allocator_partial.log`;
  `tmp/multi3_only_unknown_rhs_probe.log`;
  `tmp/std_debug_hello_debug_multi3_allocator_partial.log`; distribution-all
  proof `tmp/distribution_all_after_multi3_allocator_partial.log`.
- 2026-07-10 (this commit; acknowledges INBOX-4) Item 15 single-frame
  allocator correction: the composed selector now gives scalar and pair spills
  non-overlapping 8-byte-aligned frame slots, reserves stack objects after the
  spill area when the allocator/phi path needs it, and routes nonzero stack
  object arguments and wide stack loads through displacement-capable machine
  ops. This follows the INBOX-4 upstream mapping to LLVM
  `RegAllocFast.cpp` `StackSlotForVirtReg` lines 481-500, specifically
  `MFI->CreateSpillStackObject(Size, Alignment)` on line 497: spill slots are
  ordinary frame objects, not a parallel offset namespace. The focused
  integrated executable proof now links selector-emitted `__multi3` and
  `__modti3` with a no-std harness and verifies both computed results at
  runtime, closing `compiler_rt.mulXi3.__multi3` as the first allocator
  acceptance row. Item-15 accounting is now composed-selection rows 10,
  terminal-template rows 17, stage-two-boundary rows 2, open integer-helper
  fallback candidates 32, and no allocator acceptance row pending. Recognizer
  count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged. Evidence
  `docs/evidence/zig_integrated_exe_i128_arithmetic.summary`; distribution-all
  proof `docs/evidence/distribution_all_after_multi3_single_frame.summary`.
- 2026-07-10 (this commit; acknowledges INBOX-5 with INBOX-4) Item 15
  follow-up hardening: x86_64 frame-slot spill/reload encodings now use disp32
  for offsets past 127 while preserving the compact slot0 form, high-register
  binary-to-rax and 64-bit frame-slot size accounting now matches emitted bytes
  so ELF relocations land on the call immediate, the integrated-exe runner now
  fails on expected-exit mismatches, and the composed selector clobbers `rcx`
  before RHS spill64 reloads through the single value-location map. Item-15
  accounting is unchanged at composed-selection rows 10, terminal-template rows
  17, stage-two-boundary rows 2, open integer-helper fallback candidates 32,
  and no allocator acceptance row pending. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged.
  Evidence `docs/evidence/zig_integrated_exe_i128_arithmetic_inbox5.summary`;
  distribution-all proof `docs/evidence/distribution_all_after_inbox5.summary`.
- 2026-07-10 (this commit; acknowledges INBOX-5 with INBOX-4) Item 15
  parked-boundary retry: the stage-two pressure envelope now follows the
  single 32-slot frame authority, and phi result binding uses selector scalar
  metadata so `phi ptr` materializes as a 64-bit GPR phi. The focused
  `compiler_rt.udivmodei4.__udivei5` retry moves past the old
  `stage2-register-pressure` and `stage2-phi-type` stops to the next
  fail-closed frontier, `no_emitter` / `composed-block-call-form`. Debug
  compiler_rt report-all moved to 443 selected, 130 emitted, and 313 failed.
  Item-15 accounting remains composed-selection rows 10, terminal-template rows
  17, stage-two-boundary rows 2, open integer-helper fallback candidates 32,
  and no allocator acceptance row pending. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged.
  Evidence `docs/evidence/std_debug_hello_udivei5_frame32_pointer_phi.summary`.
- 2026-07-10 (this commit; acknowledges INBOX-5 with INBOX-4) Item 15
  parked-boundary retry: the composed selector now ignores well-formed
  `llvm.assume` calls and lowers the exact `tail fastcc i16
  @zig.target.intByteSize(i16 ...)` helper call as a normal direct call with
  low-EAX result binding. The focused `compiler_rt.udivmodei4.__udivei5` retry
  moves past `no_emitter` / `composed-block-call-form` to the next fail-closed
  frontier, `no_spill_envelope` / `composed-block-spill-slots`. Debug
  compiler_rt report-all remains 443 selected, 130 emitted, and 313 failed.
  Item-15 accounting remains composed-selection rows 10, terminal-template rows
  17, stage-two-boundary rows 2, open integer-helper fallback candidates 32,
  and no allocator acceptance row pending. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged.
  Evidence `docs/evidence/std_debug_hello_udivei5_frame32_pointer_phi.summary`.
- 2026-07-10 (this commit; acknowledges INBOX-6 with INBOX-4) Item 15
  parked-boundary retry: x86_64 `FrameIndex` is now a data-backed frame slot
  instead of a fixed enum namespace, frame-slot printing/encoding derives RSP
  displacements through the existing disp8/disp32 path, and composed selector
  spill reservation grows from the allocation plan while preserving the
  single-frame authority invariant matching LLVM RegAllocFast
  `StackSlotForVirtReg` / `MFI->CreateSpillStackObject`. The focused
  `compiler_rt.udivmodei4.__udivei5` retry moves past `no_spill_envelope` /
  `composed-block-spill-slots` to the next fail-closed frontier, `no_emitter`
  / `composed-block-spill-loc`. Debug compiler_rt report-all remains 443
  selected, 130 emitted, and 313 failed. Item-15 accounting remains
  composed-selection rows 10, terminal-template rows 17, stage-two-boundary
  rows 2, open integer-helper fallback candidates 32, and no allocator
  acceptance row pending. Recognizer count still 1 (no new recognizer reorder
  or pre-pass); `shape_recognizer_functions` is unchanged. Evidence
  `docs/evidence/std_debug_hello_udivei5_frame32_pointer_phi.summary`.
- 2026-07-10 (this commit; acknowledges INBOX-7 with INBOX-4) Item 15
  parked-boundary retry: scalar spill locations now materialize at point of
  use for 32-bit and 64-bit operands through the single value-location map,
  preserving the INBOX-4 single-frame authority invariant. Remaining
  spill-location rejection diagnostics are split by operand kind for the next
  audit. The focused `compiler_rt.udivmodei4.__udivei5` retry moves past
  `no_emitter` / `composed-block-spill-loc` to the next fail-closed frontier,
  `no_emitter` / `composed-block-zext-width`. Debug compiler_rt report-all
  remains 443 selected, 130 emitted, and 313 failed. Item-15 accounting
  remains composed-selection rows 10, terminal-template rows 17,
  stage-two-boundary rows 2, open integer-helper fallback candidates 32, and
  no allocator acceptance row pending. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged.
  Evidence `docs/evidence/std_debug_hello_udivei5_frame32_pointer_phi.summary`;
  integrated-exe proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_inbox7.summary`;
  distribution-all proof
  `docs/evidence/distribution_all_after_inbox7.summary`.

- 2026-07-10 (this commit; acknowledges INBOX-8) Item 15 parked-boundary
  retry: the composed selector now lowers zero-extension from integer widths
  up to 32 bits into i64 through a 32-bit accumulator write, preserving
  fail-closed behavior for wider source forms. The focused
  `compiler_rt.udivmodei4.__udivei5` retry moves past `no_emitter` /
  `composed-block-zext-width` to `no_emitter` /
  `composed-block-gep-source`. Debug compiler_rt report-all remains 443
  selected, 130 emitted, and 313 failed. Item-15 accounting remains
  composed-selection rows 10, terminal-template rows 17,
  stage-two-boundary rows 2, open integer-helper fallback candidates 32, and
  no allocator acceptance row pending. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged.
  Evidence `docs/evidence/std_debug_hello_udivei5_zext_width.summary`;
  integrated-exe proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_zext_width.summary`;
  distribution-all proof
  `docs/evidence/distribution_all_after_zext_width.summary`.

- 2026-07-10 (this commit) Item 15 parked-boundary retry: the composed
  selector now lowers one-index `getelementptr i8` forms over ABI pointers,
  materializing constant or dynamic byte offsets in 64-bit scratch registers
  while preserving the existing typed stack-array GEP path. The focused
  `compiler_rt.udivmodei4.__udivei5` retry moves past `no_emitter` /
  `composed-block-gep-source` to `no_emitter` /
  `composed-block-binary-imm-rhs-width`. Debug compiler_rt report-all remains
  443 selected, 130 emitted, and 313 failed. Item-15 accounting remains
  composed-selection rows 10, terminal-template rows 17,
  stage-two-boundary rows 2, open integer-helper fallback candidates 32, and
  no allocator acceptance row pending. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged.
  Evidence `docs/evidence/std_debug_hello_udivei5_gep_source.summary`;
  integrated-exe proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_gep_source.summary`;
  distribution-all proof
  `docs/evidence/distribution_all_after_gep_source.summary`.

- 2026-07-10 (this commit) Item 15 parked-boundary retry: the composed
  selector now lowers i64 immediate AND forms by materializing the mask in RCX
  and applying the existing register-to-RAX binary emitter, while preserving
  the optimized `0xffffffff` zero-extension path. The focused
  `compiler_rt.udivmodei4.__udivei5` retry moves past `no_emitter` /
  `composed-block-binary-imm-rhs-width` to `no_emitter` /
  `composed-block-icmp-eq-rhs`. Debug compiler_rt report-all remains 443
  selected, 130 emitted, and 313 failed. Item-15 accounting remains
  composed-selection rows 10, terminal-template rows 17,
  stage-two-boundary rows 2, open integer-helper fallback candidates 32, and
  no allocator acceptance row pending. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged.
  Evidence `docs/evidence/std_debug_hello_udivei5_and64_imm.summary`;
  integrated-exe proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_and64_imm.summary`;
  distribution-all proof
  `docs/evidence/distribution_all_after_and64_imm.summary`.

- 2026-07-10 (this commit) Item 15 parked-boundary retry: the composed
  selector now lowers nonzero i64 equality-immediate comparisons through the
  existing 64-bit compare emitter plus `sete`, while zero comparisons retain
  their cheaper `test` path. The focused
  `compiler_rt.udivmodei4.__udivei5` retry moves past `no_emitter` /
  `composed-block-icmp-eq-rhs` to `no_emitter` /
  `composed-block-icmp-rhs`. Debug compiler_rt report-all remains 443 selected,
  130 emitted, and 313 failed. Item-15 accounting remains composed-selection
  rows 10, terminal-template rows 17, stage-two-boundary rows 2, open
  integer-helper fallback candidates 32, and no allocator acceptance row
  pending. Recognizer count still 1 (no new recognizer reorder or pre-pass);
  `shape_recognizer_functions` is unchanged. Evidence
  `docs/evidence/std_debug_hello_udivei5_icmp_eq_imm.summary`;
  integrated-exe proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_eq_imm.summary`;
  distribution-all proof
  `docs/evidence/distribution_all_after_icmp_eq_imm.summary`.

- 2026-07-10 (this commit; acknowledges INBOX-9) Item 15
  parked-boundary retry: the composed selector now lowers equality between two
  named i64 values by materializing them in RCX and R8 and using the existing
  register compare plus `sete` path. The focused
  `compiler_rt.udivmodei4.__udivei5` retry moves past `no_emitter` /
  `composed-block-icmp-rhs` to `no_emitter` /
  `composed-block-icmp-form`. Debug compiler_rt report-all remains 443
  selected, 130 emitted, and 313 failed. Item-15 accounting remains
  composed-selection rows 10, terminal-template rows 17,
  stage-two-boundary rows 2, open integer-helper fallback candidates 32, and
  no allocator acceptance row pending. Recognizer count still 1 (no new
  recognizer reorder or pre-pass); `shape_recognizer_functions` is unchanged.
  Evidence `docs/evidence/std_debug_hello_udivei5_icmp_eq_values.summary`;
  integrated-exe proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_eq_values.summary`;
  distribution-all proof
  `docs/evidence/distribution_all_after_icmp_eq_values.summary`.

- 2026-07-11 (this commit; acknowledges INBOX-10) P0 x86_64 MC correctness:
  fused `setb_eax`, `sete_eax`, and `setne_eax` now execute setcc before
  zero-extending AL into EAX, preserving the flags produced by the preceding
  compare. The MC audit found no other fused xor-between-compare-and-setcc
  sequence. A new integrated executable row builds an ELF object directly
  through the MC encoder and checks true and false outcomes for equality,
  inequality, unsigned-less, and unsigned-greater predicates; any wrong
  result changes the process exit status. The integrated executable gate now
  passes 5/5 rows, and strict all-mode distribution remains green. No selector
  form, report count, or ratchet counter changes in this correction slice.
  Evidence `docs/evidence/zig_integrated_exe_setcc_correctness.summary`;
  `docs/evidence/distribution_all_after_setcc_correctness.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: the composed
  selector now lowers i16 inequality with zero through a width-specific
  16-bit compare plus the corrected `setne` operation. The executable proof
  checks both zero and nonzero low-16-bit values whose upper bits are set,
  catching the incorrect 32-bit test used by the first implementation. The
  focused `compiler_rt.udivmodei4.__udivei5` retry moves from `no_emitter` /
  `composed-block-icmp-form` to `no_emitter` / `composed-block-gep-source`.
  Debug compiler_rt report-all remains 443 selected, 130 emitted, and 313
  failed. Item-15 accounting remains composed-selection rows 10,
  terminal-template rows 17, stage-two-boundary rows 2, open integer-helper
  fallback candidates 32, and no allocator acceptance row pending. Evidence
  `docs/evidence/std_debug_hello_udivei5_icmp_ne_zero.summary`;
  executable proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_ne_zero.summary`;
  distribution-all proof
  `docs/evidence/distribution_all_after_icmp_ne_zero.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: the composed
  selector now lowers a dynamic single-index `[4 x i8]` GEP as an i32
  element pointer by scaling the i64 index by four and adding it to the base
  pointer. The selector-emitted executable proof stores through index 1 and
  verifies that only the intended u32 lane changes. The focused
  `compiler_rt.udivmodei4.__udivei5` retry moves from `no_emitter` /
  `composed-block-gep-source` to `no_emitter` / `composed-block-load-ptr`.
  Debug compiler_rt report-all remains 443 selected, 130 emitted, and 313
  failed. Item-15 accounting remains composed-selection rows 10,
  terminal-template rows 17, stage-two-boundary rows 2, open integer-helper
  fallback candidates 32, and no allocator acceptance row pending. Evidence
  `docs/evidence/std_debug_hello_udivei5_gep_i32_source.summary`;
  executable proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_gep_i32_source.summary`;
  distribution-all proof
  `docs/evidence/distribution_all_after_gep_i32_source.summary`.

- 2026-07-11 (this commit; acknowledges INBOX-11) Item 15
  parked-boundary retry: the composed selector now lowers i32 loads through
  argument or scratch pointer registers after preserving any live accumulator
  value. The selector-emitted executable proof reads back the u32 lane written
  by the dynamic indexed-store proof. The focused
  `compiler_rt.udivmodei4.__udivei5` retry moves from `no_emitter` /
  `composed-block-load-ptr` to `no_emitter` / `composed-block-icmp-type`.
  Debug compiler_rt report-all remains 443 selected, 130 emitted, and 313
  failed. Validation follows the new user-approved Tier 2 selector route:
  unit tests, structural smoke, ReleaseFast captured object smoke, ReleaseSafe
  object rows, permanent executable canaries, focused frontier, and boundary
  gates are green; Tier 3 `distribution-all` is deferred until acceptance
  close or another Tier 3 trigger. Item-15 accounting remains unchanged.
  Evidence `docs/evidence/std_debug_hello_udivei5_load_i32_ptr.summary`;
  executable proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_load_i32_ptr.summary`;
  Tier 2 record `docs/evidence/selector_tier2_load_i32_ptr.summary`.

- 2026-07-11 (this commit; acknowledges INBOX-12) Tier 3 gate
  infrastructure Phase 0: `distribution-all` now reports per-subgate duration
  and cache status, ranks the five slowest gates, and accepts an explicit
  forced-fresh real-row baseline option. Identical-state fresh and cached runs
  remain semantically equivalent and green. Fresh wall time is 3,764.620 s
  with 3,764.298 s summed child time and 0.322 s orchestration overhead;
  cached wall time is 2,289.680 s with 2,289.633 s summed child time and
  0.047 s overhead. Phase 1 is a no-go: the evidence does not establish
  repeated tool compilation/startup at the required ten percent of cached
  wall time. No ratchet moves; capability work resumes at the `__udivei5`
  `composed-block-icmp-type` frontier. Evidence
  `docs/evidence/distribution_all_phase0_timing_baseline.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: the composed
  selector now lowers equality between two named opaque pointers by
  materializing 64-bit addresses in RCX and R8 and using the corrected `sete`
  operation. The selector-emitted executable proof checks both identical and
  distinct addresses. The focused `compiler_rt.udivmodei4.__udivei5` retry
  moves from `no_emitter` / `composed-block-icmp-type` to a later
  `no_emitter` / `composed-block-load-ptr`. Debug compiler_rt report-all
  remains 443 selected, 130 emitted, and 313 failed. Tier 2 selector
  validation is green; item-15 accounting remains unchanged. Evidence
  `docs/evidence/std_debug_hello_udivei5_icmp_ptr_eq.summary`; executable
  proof `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_ptr_eq.summary`;
  Tier 2 record `docs/evidence/selector_tier2_icmp_ptr_eq.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: the composed
  selector now reloads a spilled 64-bit pointer through the clobber-aware RCX
  path before an indirect i32 load. The executable proof creates seven live
  derived pointers so the loaded address is necessarily spilled, then checks
  the loaded value at runtime. The focused
  `compiler_rt.udivmodei4.__udivei5` retry moves from `no_emitter` /
  `composed-block-load-ptr` to `unsupported_value` / `stage2-phi-src`.
  Debug compiler_rt report-all remains 443 selected, 130 emitted, and 313
  failed. Tier 2 selector validation is green; item-15 accounting remains
  unchanged. Evidence
  `docs/evidence/std_debug_hello_udivei5_load_i32_spill_ptr.summary`;
  executable proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_load_i32_spill_ptr.summary`;
  Tier 2 record `docs/evidence/selector_tier2_load_i32_spill_ptr.summary`.

- 2026-07-11 (this commit) Item 15 allocation correctness: selector interval
  construction now records each phi incoming use at its predecessor
  terminator instead of the phi's textual position. This preserves values
  defined in blocks appearing after their phi block, matching CFG liveness
  and the single-location allocator invariant. A selector-emitted executable
  backward-layout phi returns the expected value. The focused `__udivei5`
  retry moves from `unsupported_value` / `stage2-phi-src` to `no_emitter` /
  `composed-block-icmp-form`, with report-all unchanged at 443 selected, 130
  emitted, and 313 failed. Tier 3 is green because shared allocation planning
  changed; no ratchet moves. Evidence
  `docs/evidence/std_debug_hello_udivei5_phi_edge_liveness.summary`;
  executable proof `docs/evidence/zig_integrated_exe_phi_edge_liveness.summary`;
  Tier 3 record `docs/evidence/distribution_all_after_phi_edge_liveness.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: the composed
  selector now lowers unsigned-greater comparisons between named i64 values
  by placing LHS in RCX and RHS in R8, then reusing `cmp_rcx_arg64` plus the
  corrected `setb`. Executable true and false cases caught and corrected an
  initially reversed operand order. The focused `__udivei5` retry clears the
  first named `ugt` and reaches a later `no_emitter` /
  `composed-block-icmp-form`; report-all remains 443 selected, 130 emitted,
  and 313 failed. Tier 2 is green; no ratchet moves. Evidence
  `docs/evidence/std_debug_hello_udivei5_icmp_ugt_values.summary`;
  executable proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_ugt_values.summary`;
  Tier 2 record `docs/evidence/selector_tier2_icmp_ugt_values.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: the composed
  selector now lowers `sgt i6 value, -1` by isolating bit 5 in EAX and using
  the corrected `sete` path. Executable values 31 and 32 prove the signed i6
  boundary. The focused `__udivei5` retry clears this form and reaches a later
  `no_emitter` / `composed-block-icmp-form`; report-all remains 443 selected,
  130 emitted, and 313 failed. Tier 2 is green; no ratchet moves. Evidence
  `docs/evidence/std_debug_hello_udivei5_icmp_sgt_i6.summary`; executable
  proof `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_sgt_i6.summary`;
  Tier 2 record `docs/evidence/selector_tier2_icmp_sgt_i6.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: the composed
  selector now lowers `ugt i64 value, immediate` by materializing LHS in RCX
  and the immediate in R8, making `cmpq %rcx, %r8` plus corrected `setb` test
  `immediate < value`. Executable checks cover the `2^32 - 1` boundary. The
  focused `__udivei5` retry reaches a later `no_emitter` /
  `composed-block-icmp-form`; report-all remains 443 selected, 130 emitted,
  and 313 failed. Tier 2 is green; no ratchet moves. Evidence
  `docs/evidence/std_debug_hello_udivei5_icmp_ugt_imm.summary`; executable
  proof `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_ugt_imm.summary`;
  Tier 2 record `docs/evidence/selector_tier2_icmp_ugt_imm.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: the composed
  selector now lowers `slt i64 value, 0` by shifting RAX's sign bit into bit
  zero. Executable values -1 and 0 prove both outcomes. The focused
  `__udivei5` retry reaches a later `no_emitter` /
  `composed-block-icmp-form`; report-all remains 443 selected, 130 emitted,
  and 313 failed. Tier 2 is green; no ratchet moves. Evidence
  `docs/evidence/std_debug_hello_udivei5_icmp_slt_zero.summary`; executable
  proof `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_slt_zero.summary`;
  Tier 2 record `docs/evidence/selector_tier2_icmp_slt_zero.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: the composed
  selector now lowers `ne i64 value, 0` through a 64-bit compare and corrected
  `setne`; executable one and zero cases prove both outcomes. This exhausts
  the currently encountered comparison cluster. The focused `__udivei5`
  retry advances to `no_emitter` / `composed-block-call-form`; report-all
  remains 443 selected, 130 emitted, and 313 failed. Tier 2 is green; no
  ratchet moves. Evidence
  `docs/evidence/std_debug_hello_udivei5_icmp_ne_i64_zero.summary`;
  executable proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_ne_i64_zero.summary`;
  Tier 2 record `docs/evidence/selector_tier2_icmp_ne_i64_zero.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: the composed
  selector now lowers the exact `llvm.ctlz.i32(value, true)` intrinsic through
  the existing x86_64 count-leading-zeros operation while accepting its tail
  and range attributes. Executable inputs 1 and 16 prove the results. The
  focused `__udivei5` retry advances to `no_emitter` /
  `composed-block-binary-width`; report-all remains 443 selected, 130 emitted,
  and 313 failed. Tier 2 is green; no ratchet moves. Evidence
  `docs/evidence/std_debug_hello_udivei5_ctlz_i32.summary`; executable proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_ctlz_i32.summary`; Tier 2
  record `docs/evidence/selector_tier2_ctlz_i32.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: the composed
  selector now lowers the exact wrapping i6 form `sub i6 -32, value` through
  32-bit accumulator subtraction, with the existing i6 zext mask restoring
  modulo-64 semantics. Executable RHS values 0, 1, and 32 prove wraparound.
  The focused `__udivei5` retry advances to `no_emitter` /
  `stage2-cond-loc`; report-all remains 443 selected, 130 emitted, and 313
  failed. Tier 2 is green; no ratchet moves. Evidence
  `docs/evidence/std_debug_hello_udivei5_sub_i6.summary`; executable proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_sub_i6.summary`; Tier 2
  record `docs/evidence/selector_tier2_sub_i6.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: stage-two branch
  emission now reloads spill64 i1 conditions through the clobber-aware RCX
  path and tests the low byte. An executable pressure case verifies both
  control-flow outcomes and the live values preserved across the spill. The
  focused `__udivei5` retry advances to `no_emitter` /
  `composed-block-binary-op`; report-all remains 443 selected, 130 emitted,
  and 313 failed. Tier 2 is green; no ratchet moves. Evidence
  `docs/evidence/std_debug_hello_udivei5_spill_cond.summary`; executable proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_spill_cond.summary`; Tier 2
  record `docs/evidence/selector_tier2_spill_cond.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: the composed
  selector now lowers variable i32 left and logical-right shifts through the
  x86_64 CL-count forms, including new assembly, encoding, size, and verifier
  coverage for `shll %cl, %eax`. Executable cases prove both directions. The
  focused `__udivei5` retry clears `composed-block-binary-op` and advances to
  `unsupported_value` / `composed-block-unknown-gep-ptr`; report-all remains
  443 selected, 130 emitted, and 313 failed. Tier 2 is green; no ratchet moves.
  Evidence `docs/evidence/std_debug_hello_udivei5_variable_i32_shifts.summary`;
  executable proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_variable_i32_shifts.summary`;
  Tier 2 record `docs/evidence/selector_tier2_variable_i32_shifts.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: local i32 stack
  pointers now compose constant byte offsets, direct optimized `[4 x i8]`
  element indices, and one chained dynamic index. Stack index expressions
  retain their SSA source names and rematerialize at each load/store; this
  fixes the stale-map runtime defect exposed when an older pointer reused a
  mutated `%rcx`. Executable cases prove all three forms. The focused
  `__udivei5` retry advances from the GEP cluster to `no_emitter` /
  `stage2-phi-dst-loc`; report-all remains 443 selected, 130 emitted, and 313
  failed. Tier 2 is green; no ratchet moves. Evidence
  `docs/evidence/std_debug_hello_udivei5_local_stack_gep.summary`; executable
  proof `docs/evidence/zig_integrated_exe_i128_arithmetic_local_stack_gep.summary`;
  Tier 2 record `docs/evidence/selector_tier2_local_stack_gep.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: stage-two PHIs now
  retain stable register destinations across loop iterations while temporary
  block-local clobbers spill/reload through the value map; non-PHI outgoing
  edges restore displaced destinations before condition testing or return.
  Executable pressure coverage also exposed and fixed a one-byte
  `cmp_rcx_arg64` high-register size overcount that previously misdirected a
  backedge into an instruction. The focused `__udivei5` retry advances from
  `stage2-phi-dst-loc` to `no_emitter` / `composed-block-store-ptr`;
  report-all remains 443 selected, 130 emitted, and 313 failed. Tier 2 is
  green; no ratchet moves. Evidence
  `docs/evidence/std_debug_hello_udivei5_phi_stable_dest.summary`; executable
  proof `docs/evidence/zig_integrated_exe_i128_arithmetic_phi_stable_dest.summary`;
  Tier 2 record `docs/evidence/selector_tier2_phi_stable_dest.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: composed i32 stores
  now consume spilled external pointers through the clobber-aware `%rcx`
  reload path and write directly to local i32 array base displacements.
  Executable cases verify the stored value and neighboring memory for both
  forms. The focused `__udivei5` retry advances from
  `composed-block-store-ptr` to `unsupported_value` /
  `stage2-unsupported-value`; report-all remains 443 selected, 130 emitted,
  and 313 failed. Tier 2 is green; no ratchet moves. Evidence
  `docs/evidence/std_debug_hello_udivei5_store_ptr_forms.summary`; executable
  proof `docs/evidence/zig_integrated_exe_i128_arithmetic_store_ptr_forms.summary`;
  Tier 2 record `docs/evidence/selector_tier2_store_ptr_forms.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: composed selects now
  preserve accumulator-resident true operands before materializing the false
  arm, using scratch when available and the planned frame spill otherwise.
  Executable true/false cases prove the exact `select cond, shifted, 0` shape.
  Escaped value errors are also reported by instruction family so the selector
  remains fail-closed with an actionable frontier. The focused `__udivei5`
  retry advances from opaque `stage2-unsupported-value` to `no_emitter` /
  `composed-block-binary-imm-rhs-width`; report-all remains 443 selected, 130
  emitted, and 313 failed. Tier 2 is green; no ratchet moves. Evidence
  `docs/evidence/std_debug_hello_udivei5_select_preserve.summary`; executable
  proof `docs/evidence/zig_integrated_exe_i128_arithmetic_select_preserve.summary`;
  Tier 2 record `docs/evidence/selector_tier2_select_preserve.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: composed i64
  immediate OR now preserves destructive `%rax`, materializes the full
  constant in `%rcx`, and emits register OR. Executable low-bit-clear and
  low-bit-set cases prove the operation. The focused `__udivei5` retry
  advances from `composed-block-binary-imm-rhs-width` to
  `unsupported_value` / `stage2-store-value`; report-all remains 443 selected,
  130 emitted, and 313 failed. Tier 2 is green; no ratchet moves. Evidence
  `docs/evidence/std_debug_hello_udivei5_or64_imm.summary`; executable proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_or64_imm.summary`; Tier 2
  record `docs/evidence/selector_tier2_or64_imm.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: value liveness now
  includes index and addend SSA dependencies retained by live local stack
  pointer descriptors. Fixed-register clobbers therefore spill those sources
  instead of dropping them before a later load/store rematerializes the
  address. An executable shift-clobber case proves the indexed store preserves
  element zero. The focused `__udivei5` retry advances from
  `stage2-store-value` to `no_spill_envelope` /
  `composed-block-two-address-rhs-accumulator`; report-all remains 443
  selected, 130 emitted, and 313 failed. Tier 2 is green; no ratchet moves.
  Evidence `docs/evidence/std_debug_hello_udivei5_stack_index_liveness.summary`;
  executable proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_stack_index_liveness.summary`;
  Tier 2 record `docs/evidence/selector_tier2_stack_index_liveness.summary`.

- 2026-07-11 (this commit) Item 15 parked-boundary retry: noncommutative
  binaries now preserve an accumulator RHS in a nonconflicting scratch before
  materializing the LHS, and every live accumulator alias is spilled before a
  destructive overwrite, including aliases retained through an in-place
  operand. Executable subtraction and load/zext/add cases prove operand order
  and alias survival. The focused `__udivei5` retry advances from
  `composed-block-two-address-rhs-accumulator` through repeated unrolled alias
  conflicts to `no_emitter` / `composed-block-rhs-width`; report-all remains
  443 selected, 130 emitted, and 313 failed. Tier 2 is green; no ratchet moves.
  Evidence `docs/evidence/std_debug_hello_udivei5_accumulator_aliases.summary`;
  executable proof
  `docs/evidence/zig_integrated_exe_i128_arithmetic_accumulator_aliases.summary`;
  Tier 2 record `docs/evidence/selector_tier2_accumulator_aliases.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-12) Item 15 parked-boundary
  acceptance: trunc results now carry their narrowed register class, and
  framed multi-block composed functions branch to one shared epilogue after
  materializing each return value. The exact captured `__udivei5` body emits
  as a 7,876-byte function, links through patched stage4 Zig with `-fno-lld`,
  and has no pressure exceedance under the 32-slot frame (`max_live_values=19`,
  `max_spill_slots_needed=13`). Executable canaries cover the trunc operation
  and both framed return paths. Report-all advances to `__umodei4` at
  `no_spill_envelope` / `stage2-block-count`, with 131 emitted and 312 failed.
  Tier 3 is green across 17 subgates. Item-15 accounting is now 11 composed
  rows, 17 terminal-template rows, one stage-two boundary row, and 32 open
  integer-helper fallback candidates. Evidence
  `docs/evidence/std_debug_hello_udivei5_acceptance.summary`,
  `docs/evidence/std_debug_hello_udivei5_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_udivei5_acceptance.summary`, and
  `docs/evidence/distribution_all_after_udivei5_acceptance.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-12) Item 15 remaining-boundary
  retry: the bounded stage-two CFG tier now admits up to 128 blocks while
  preserving fail-closed rejection at 129. The real `__umodei4` body has 65
  blocks and fits the existing 32-slot frame (`max_live_values=24`,
  `max_spill_slots_needed=18`, no exceedance). A 65-block executable canary
  passes. The focused retry advances from `stage2-block-count` to
  `no_emitter` / `composed-block-call-form`; report-all remains 443 selected,
  131 emitted, and 312 failed. Tier 2 is green; no tracker or ratchet moves.
  Evidence `docs/evidence/std_debug_hello_umodei4_block_count.summary`,
  `docs/evidence/zig_integrated_exe_umodei4_block_count.summary`, and
  `docs/evidence/selector_tier2_umodei4_block_count.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-12) Item 15 remaining-boundary
  retry: the composed selector now lowers the nonvolatile tail
  `llvm.memcpy.inline.p0.p0.i64` form through the existing x86_64 memcpy
  primitive after spilling live caller-clobbered values. An executable
  four-word copy proves the memory effect. The focused `__umodei4` retry
  advances from `composed-block-call-form` to `no_emitter` /
  `composed-block-cast-width`; report-all remains 443 selected, 131 emitted,
  and 312 failed. Tier 2 is green; no tracker or ratchet moves. Evidence
  `docs/evidence/std_debug_hello_umodei4_inline_memcpy.summary`,
  `docs/evidence/zig_integrated_exe_umodei4_inline_memcpy.summary`, and
  `docs/evidence/selector_tier2_umodei4_inline_memcpy.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-12) Item 15 remaining-boundary
  retry: no-op trunc and integer bitcast operations now preserve spill-backed
  locations, leaving downstream consumers responsible for width-correct
  reloads from the single frame authority. An executable value survives
  inline memcpy, truncates from i32 to i6, and returns the expected low bits.
  The focused `__umodei4` retry advances from `composed-block-cast-width` to
  `no_emitter` / `composed-block-load-ptr`; report-all remains 443 selected,
  131 emitted, and 312 failed. Tier 2 is green; no tracker or ratchet moves.
  Evidence `docs/evidence/std_debug_hello_umodei4_spilled_trunc.summary`,
  `docs/evidence/zig_integrated_exe_umodei4_spilled_trunc.summary`, and
  `docs/evidence/selector_tier2_umodei4_spilled_trunc.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-12) Item 15 remaining-boundary
  retry: i32 loads may now address element zero directly through a local
  stack-array alloca's frame-object base displacement, matching the existing
  direct store path. The executable stack-array-base case proves the stored
  value is read back correctly. The focused `__umodei4` retry advances from
  `composed-block-load-ptr` to `no_spill_envelope` /
  `composed-block-two-address-rhs-accumulator`; report-all remains 443
  selected, 131 emitted, and 312 failed. Tier 2 is green; no tracker or
  ratchet moves. Evidence
  `docs/evidence/std_debug_hello_umodei4_stack_array_load.summary`,
  `docs/evidence/zig_integrated_exe_umodei4_stack_array_load.summary`, and
  `docs/evidence/selector_tier2_umodei4_stack_array_load.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-12) Item 15 remaining-boundary
  acceptance: when both operands are live aliases of the accumulator, the
  composed selector now preserves one in scratch before the two-address
  operation. The exact captured `__umodei4` body emits as a 10,177-byte
  function, native-links with `-fno-lld`, and fits the 32-slot frame
  (`max_live_values=24`, `max_spill_slots_needed=18`, no exceedance). An
  executable double-use case proves the alias result. Report-all advances to
  `compiler_rt.divmodei4.__divei4` at `unsupported_type` / `call-ret`, with
  132 emitted and 311 failed. Tier 3 is green across 17 subgates. Item-15
  accounting is now 12 composed rows, 17 terminal-template rows, zero
  stage-two boundary rows, and 32 open integer-helper fallback candidates.
  Evidence `docs/evidence/std_debug_hello_umodei4_acceptance.summary`,
  `docs/evidence/std_debug_hello_umodei4_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_umodei4_acceptance.summary`, and
  `docs/evidence/distribution_all_after_umodei4_acceptance.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-12) Item 15 integer-helper
  retry: the composed selector now lowers the exact
  `llvm.uadd.with.overflow.i32` form into independently extractable wrapped
  value and carry locations while preserving live accumulator aliases and
  rejecting duplicate or reordered extraction fail closed. Executable cases
  prove both components for plain and wrapping additions. The focused
  `__divei4` retry advances from `unsupported_type` / `call-ret` to
  `no_emitter` / `composed-block-alloca-form`; report-all remains 443
  selected, 132 emitted, and 311 failed. Tier 2 is green; no tracker or
  ratchet moves. Evidence
  `docs/evidence/std_debug_hello_divei4_uadd_overflow.summary`,
  `docs/evidence/zig_integrated_exe_i128_arithmetic_uadd_overflow.summary`,
  and `docs/evidence/selector_tier2_divei4_uadd_overflow.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-12) Item 15 integer-helper
  retry: the single composed frame authority now lays out multiple typed
  scalar and i32-array allocas with per-object alignment, replacing the old
  one-scalar-or-few-arrays restriction. Executable near/far array checks prove
  non-overlap and disp32 access with interleaved aligned byte objects. The
  focused `__divei4` retry advances from `composed-block-alloca-form` to a
  later `composed-block-icmp-form`; report-all remains 443 selected, 132
  emitted, and 311 failed. Tier 3 is green across 17 subgates; no tracker or
  ratchet moves. Evidence
  `docs/evidence/std_debug_hello_divei4_mixed_frame.summary`,
  `docs/evidence/zig_integrated_exe_i128_arithmetic_mixed_frame.summary`, and
  `docs/evidence/distribution_all_after_divei4_mixed_frame.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-13) Item 15 integer-helper
  retry: signed i32 less-than-zero comparisons now lower through a bit-31
  extraction, with executable negative and zero cases. The focused `__divei4`
  retry advances from `composed-block-icmp-form` to
  `composed-block-store-width`; report-all remains 443 selected, 132 emitted,
  and 311 failed. Tier 2 is green; no tracker or ratchet moves. Evidence
  `docs/evidence/std_debug_hello_divei4_slt_i32.summary`,
  `docs/evidence/zig_integrated_exe_i128_arithmetic_slt_i32.summary`, and
  `docs/evidence/selector_tier2_divei4_slt_i32.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-13) Item 15 integer-helper
  retry: typed 8-bit frame objects now support byte-precise i1 stores and
  zero-extending i8 loads through disp8 and disp32 machine forms. Non-stack i1
  pointer stores remain fail-closed, and executable true/false roundtrips prove
  the memory effect. The focused `__divei4` retry advances from
  `composed-block-store-width` to `composed-block-binary-imm-rhs`; report-all
  remains 443 selected, 132 emitted, and 311 failed. Tier 2 is green; no
  tracker or ratchet moves. Evidence
  `docs/evidence/std_debug_hello_divei4_stack_i1.summary`,
  `docs/evidence/zig_integrated_exe_i128_arithmetic_stack_i1.summary`, and
  `docs/evidence/selector_tier2_divei4_stack_i1.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-13) Item 15 integer-helper
  retry: i32 XOR with an immediate now lowers through the existing register
  XOR operation after materializing the constant in scratch. An executable
  all-ones inversion check proves the arithmetic result. The focused
  `__divei4` retry advances from `composed-block-binary-imm-rhs` to
  `composed-block-binary-width`; report-all remains 443 selected, 132 emitted,
  and 311 failed. Tier 2 is green; no tracker or ratchet moves. Evidence
  `docs/evidence/std_debug_hello_divei4_xor_i32.summary`,
  `docs/evidence/zig_integrated_exe_i128_arithmetic_xor_i32.summary`, and
  `docs/evidence/selector_tier2_divei4_xor_i32.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-13) Item 15 integer-helper
  acceptance: the composed selector now admits only the exact i8 immediate-AND
  form needed by the row, leaving unrelated i8 binary operations fail-closed.
  Executable odd/even mask checks prove the arithmetic result. The exact
  captured `__divei4` body emits as an 8,096-byte function, native-links with
  patched Zig and `-fno-lld`, and fits the 32-slot frame
  (`max_live_values=22`, `max_spill_slots_needed=16`, no exceedance).
  Report-all advances to `compiler_rt.divmodei4.__modei5`, with 133 emitted and
  310 failed. Tier 3 is green across 17 subgates. Item-15 accounting is now 13
  composed rows, 17 terminal-template rows, zero stage-two boundary rows, and
  31 open integer-helper fallback candidates. Evidence
  `docs/evidence/std_debug_hello_divei4_acceptance.summary`,
  `docs/evidence/std_debug_hello_divei4_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_divei4_acceptance.summary`, and
  `docs/evidence/distribution_all_after_divei4_acceptance.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-13) Item 15 integer-helper
  retry: one-index `[1 x i8]` GEPs now reuse byte-pointer arithmetic. The
  executable address check exposed and repaired a pre-existing value-map bug:
  dynamic byte GEP recorded `%r8` even though `add_r8_rcx` writes `%rcx`.
  Correcting that binding makes the address check pass. The focused `__modei5`
  retry advances from `composed-block-gep-source` to
  `composed-block-icmp-form`; report-all remains 443 selected, 133 emitted, and
  310 failed. Tier 2 is green; no tracker or ratchet moves. Evidence
  `docs/evidence/std_debug_hello_modei5_gep_source.summary`,
  `docs/evidence/zig_integrated_exe_i128_arithmetic_modei5_gep_source.summary`,
  and `docs/evidence/selector_tier2_modei5_gep_source.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-13) Item 15 integer-helper
  acceptance: signed i32 nonnegative comparisons now lower through a sign-bit
  mask and `sete`, with executable zero and minus-one cases. The generic form
  advances `__modei5` from `composed-block-icmp-form` to
  `composed-block-select-type` and closes sibling `__modei4`. The exact sibling
  body emits as an 8,659-byte function, native-links with patched Zig and
  `-fno-lld`, and fits the 32-slot frame (`max_live_values=26`,
  `max_spill_slots_needed=20`, no exceedance). Report-all moves to 134 emitted
  and 309 failed. Tier 3 is green across 17 subgates. Item-15 accounting is now
  14 composed rows, 17 terminal-template rows, zero stage-two boundary rows,
  and 30 open integer-helper fallback candidates. Evidence
  `docs/evidence/std_debug_hello_modei4_acceptance.summary`,
  `docs/evidence/std_debug_hello_modei4_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_modei4_acceptance.summary`, and
  `docs/evidence/distribution_all_after_modei4_acceptance.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-13) Item 15 integer-helper
  acceptance: pointer selects now use the existing 64-bit location-select path,
  with executable true/false pointer checks. The generic form closes both
  remaining five-argument signed rows. Exact `__modei5` and `__divei5` bodies
  emit as 8,883 and 7,615 bytes, native-link together with patched Zig and
  `-fno-lld`, and fit the 32-slot frame respectively at live/spill/over values
  `26/20/0` and `22/16/0`. Report-all advances to 136 emitted and 307 failed;
  the global first failure is now outside this integer family. Tier 3 is green
  across 17 subgates. Item-15 accounting is now 16 composed rows, 17
  terminal-template rows, zero stage-two boundary rows, and 28 open
  integer-helper fallback candidates. Evidence
  `docs/evidence/std_debug_hello_modei5_divei5_acceptance.summary`,
  `docs/evidence/std_debug_hello_modei5_acceptance_pressure.tsv`,
  `docs/evidence/std_debug_hello_divei5_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_modei5_divei5_acceptance.summary`, and
  `docs/evidence/distribution_all_after_modei5_divei5_acceptance.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-13) Item 15 integer-helper
  retry: generic CFG inspection now recognizes the exact i128 signed-multiply
  overflow aggregate signature and its extractvalue result types. Arithmetic
  lowering remains fail-closed. The focused `__muloti4` row advances from
  `unsupported_type/call-ret` to `unsupported_value/stage2-unsupported-value`;
  report-all remains 443 selected, 136 emitted, and 307 failed. Tier 1 unit
  validation is green; no capability, tracker, or ratchet moves. Evidence
  `docs/evidence/std_debug_hello_muloti4_overflow_inspection.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-13) Item 15 integer-helper
  retry: stage-two planning now pressure-exempts the exact i128 signed-multiply
  overflow tuple, treating it as selector-side component locations rather than
  a scalar virtual register. The focused `__muloti4` row advances from
  `unsupported_value/stage2-unsupported-value` to
  `no_emitter/composed-block-freeze-width`; report-all remains 443 selected,
  136 emitted, and 307 failed. Tier 1 unit validation is green; no arithmetic
  capability, tracker, or ratchet moves. Evidence
  `docs/evidence/std_debug_hello_muloti4_overflow_planning.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-13) Item 15 integer-helper
  retry: i128 freeze now preserves proven pair-valued register, stack-value,
  and spill locations while rejecting frame-object pointer classes. An
  executable negative i128 roundtrip proves both lanes. The focused
  `__muloti4` row advances from `composed-block-freeze-width` to
  `composed-block-call-form`; report-all remains 443 selected, 136 emitted, and
  307 failed. Tier 2 is green; no tracker or ratchet moves. Evidence
  `docs/evidence/std_debug_hello_muloti4_freeze_i128.summary`,
  `docs/evidence/zig_integrated_exe_i128_arithmetic_freeze_i128.summary`, and
  `docs/evidence/selector_tier2_muloti4_freeze_i128.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  foundation: the machine and encoder layers now provide general one-operand
  unsigned and signed 64-by-64 full-product operations, with low and high
  definitions in RAX and RDX. Exact assembly and byte checks cover ordinary
  and extended registers; executable generated-code checks prove both result
  halves for unsigned and negative signed products. Tier 2 is green across
  unit, structural, captured-object, permanent-canary, and boundary gates.
  The focused `__muloti4` row remains at `no_emitter/composed-block-call-form`;
  report-all remains 443 selected, 136 emitted, and 307 failed. No tracker or
  ratchet moves. Evidence
  `docs/evidence/x86_64_full_product_machine_ops.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  allocation foundation: the composed selector now displaces live RAX/RDX
  owners before full-product definitions and relocates the resulting RDX:RAX
  pair into the allocation plan's ordinary register-pair or pair-spill
  location. Focused tests cover both destinations and live-owner preservation;
  selector-produced relocation code executes and returns both product halves.
  Tier 3 is green across 17 subgates and all three strict 100-row modes. The
  focused `__muloti4` row remains at `no_emitter/composed-block-call-form`;
  report-all remains 443 selected, 136 emitted, and 307 failed. No tracker or
  ratchet moves. Evidence
  `docs/evidence/x86_64_full_product_binding.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  arithmetic foundation: the machine and encoder layers now provide
  `adcq $0, %rax` for limb carry propagation. Exact assembly/byte checks and
  an executable wrapped-add case prove that CF survives into the increment.
  Tier 2 is green across unit, structural, captured-object, permanent-canary,
  and boundary gates. The focused `__muloti4` row remains at
  `no_emitter/composed-block-call-form`; report-all remains 443 selected, 136
  emitted, and 307 failed. No tracker or ratchet moves. Evidence
  `docs/evidence/x86_64_adc_rax_imm0.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  retry: the exact `llvm.smul.with.overflow.i128` intrinsic now expands into
  four allocator-visible 64-bit full products, carry-propagated schoolbook
  limbs, signed upper-half corrections, and LLVM's upper-half/sign-extension
  overflow invariant. Unit and permanent executable cases cover overflowing
  and non-overflowing products in both sign directions. The focused
  `__muloti4` row advances from `composed-block-call-form` to
  `composed-block-icmp-form`; report-all remains 443 selected, 136 emitted,
  and 307 failed. Tier 3 is green across 17 subgates and all three strict
  100-row modes. No tracker or ratchet moves. Evidence
  `docs/evidence/x86_64_smul_i128_overflow_expansion.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  retry: signed i128 less-than-zero comparisons now read the high-limb sign
  bit for pair, stack-value, and spill locations. Unit and permanent
  executable negative/zero cases are green. The focused `__muloti4` row
  advances from `composed-block-icmp-form` to
  `unsupported_value/stage2-icmp-value`; report-all remains 443 selected, 136
  emitted, and 307 failed. Tier 2 is green; no tracker or ratchet moves.
  Evidence `docs/evidence/x86_64_icmp_slt_i128_zero.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  retry: i128 minimum-value equality now compares both limbs through a
  combined XOR/OR zero test. Unit and permanent executable equal/adjacent
  cases are green. The focused `__muloti4` row advances from
  `stage2-icmp-value` to `composed-block-binary-width`; report-all remains 443
  selected, 136 emitted, and 307 failed. Tier 2 is green; no tracker or
  ratchet moves. Evidence `docs/evidence/x86_64_icmp_eq_min_i128.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  acceptance: named boolean conjunction now composes i128 predicate results,
  and wide comparisons reserve frame space before displacing overlapping ABI
  pairs. Exact `__muloti4` emission, native link, four signed product/overflow
  cases, and the pressure diagnostic are green. Report-all advances to 137
  emitted and 306 failed; the global frontier crosses into soft-float at
  `compiler_rt.trunc.__trunch`, while the separately ranked integer bucket
  continues at `compiler_rt.mulo.__mulodi4`. Tier 3 is green across 17
  subgates. Item-15 accounting is now 17 composed rows, 17 terminal-template
  rows, zero stage-two boundary rows, and 27 open integer-helper fallback
  candidates. Evidence `docs/evidence/std_debug_hello_muloti4_acceptance.summary`,
  `docs/evidence/std_debug_hello_muloti4_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_muloti4_acceptance.summary`, and
  `docs/evidence/distribution_all_after_muloti4_acceptance.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  retry: generic CFG inspection now recognizes the exact i64 signed-multiply
  overflow aggregate signature while rejecting mismatched argument widths.
  Arithmetic lowering remains fail-closed. The focused `__mulodi4` row advances
  from `unsupported_type/call-ret` to
  `unsupported_value/stage2-unsupported-value`; report-all remains 443
  selected, 137 emitted, and 306 failed. Tier 1 unit validation is green; no
  capability, tracker, or ratchet moves. Evidence
  `docs/evidence/std_debug_hello_mulodi4_overflow_inspection.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  retry: stage-two planning now pressure-exempts the exact i64 signed-multiply
  overflow tuple, assigning locations only to extracted components. The
  focused `__mulodi4` row advances from `stage2-unsupported-value` to
  `no_emitter/composed-block-call-form`; report-all remains 443 selected, 137
  emitted, and 306 failed. Tier 1 unit validation is green; no arithmetic
  capability, tracker, or ratchet moves. Evidence
  `docs/evidence/std_debug_hello_mulodi4_overflow_planning.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  acceptance: i64 signed multiply overflow now uses the fixed RDX:RAX full
  product and stores both tuple components before later instructions can
  clobber them. The exact harness caught and prevented a stale-EAX overflow
  result. Exact object emission, native link, four signed product/overflow
  cases, and pressure acceptance are green. Report-all advances to 138 emitted
  and 305 failed; the next ranked integer candidate is
  `compiler_rt.mulvsi3.__mulvsi3`. Tier 3 is green across 17 subgates. Item-15
  accounting is now 18 composed rows, 17 terminal-template rows, zero
  stage-two boundary rows, and 26 open integer-helper fallback candidates.
  Evidence `docs/evidence/std_debug_hello_mulodi4_acceptance.summary`,
  `docs/evidence/std_debug_hello_mulodi4_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_mulodi4_acceptance.summary`, and
  `docs/evidence/distribution_all_after_mulodi4_acceptance.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  retry: inspection and composed assume lowering now admit only the empty cold
  operand bundle attached to `llvm.assume`; ordinary bundled calls remain
  fail-closed. The focused `__mulvsi3` row advances from
  `unsupported_instruction/operand-bundle-call` to
  `unsupported_value/stage2-binary-value`; report-all remains 443 selected,
  138 emitted, and 305 failed. Tier 1 unit validation is green; no arithmetic
  capability, tracker, or ratchet moves. Evidence
  `docs/evidence/std_debug_hello_mulvsi3_cold_assume.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  retry: large i64 immediate adds now materialize constants outside signed
  imm32 range in a scratch register while retaining the compact encoding for
  smaller constants. A permanent executable canary verifies the arithmetic.
  The focused `__mulvsi3` row advances from `stage2-binary-value` to
  `no_emitter/composed-block-call-form`; report-all remains 443 selected, 138
  emitted, and 305 failed. Tier 2 is green; no tracker or ratchet moves.
  Evidence `docs/evidence/std_debug_hello_mulvsi3_add_i64_large.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  acceptance: exact zero-argument `llvm.trap` calls now emit `ud2`, and
  `unreachable` is owned only when the same block ends in that trap. Executable
  generated code proves the safe return and SIGILL paths. Exact object
  emission, native link, and pressure acceptance close `__mulvsi3`.
  Report-all advances to 139 emitted and 304 failed; the next ranked integer
  candidate is `compiler_rt.subvdi3.__subvdi3`. Tier 3 is green across 17
  subgates. Item-15 accounting is now 19 composed rows, 17 terminal-template
  rows, zero stage-two boundary rows, and 25 open integer-helper fallback
  candidates. Evidence `docs/evidence/std_debug_hello_mulvsi3_acceptance.summary`,
  `docs/evidence/std_debug_hello_mulvsi3_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_mulvsi3_acceptance.summary`, and
  `docs/evidence/distribution_all_after_mulvsi3_acceptance.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  acceptance: live accumulator-backed binary operands now relocate to free
  scratch registers using each binding's authoritative virtual-register width
  before destructive reuse. Progressive probes isolated the lifetime gap, and
  report-all caught and prevented an initial cross-width `__umodei4`
  regression. The generic fix closes `__subvdi3`, `__subvsi3`, `__addvdi3`,
  and `__addvsi3`; exact object, native-link, executable multi-use, and
  pressure evidence are green. Report-all advances to 143 emitted and 300
  failed; the next ranked integer candidate is `compiler_rt.negv.__negvsi2`.
  Tier 3 is green across 17 subgates. Item-15 accounting is now 23 composed
  rows, 17 terminal-template rows, zero stage-two boundary rows, and 21 open
  integer-helper fallback candidates. Evidence
  `docs/evidence/std_debug_hello_overflow_addsub_acceptance.summary`,
  `docs/evidence/std_debug_hello_subvdi3_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_overflow_addsub_acceptance.summary`, and
  `docs/evidence/distribution_all_after_overflow_addsub_acceptance.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  retry: nonzero immediate equality now lowers for integer widths up to 32 via
  EAX, with permanent executable i32 minimum/adjacent cases. The focused
  `__negvsi2` row advances from `composed-block-icmp-eq-rhs` to
  `composed-block-binary-imm-lhs`; report-all remains 443 selected, 143
  emitted, and 300 failed. Tier 2 is green; no tracker or ratchet moves.
  Evidence `docs/evidence/std_debug_hello_negvsi2_eq_min.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  acceptance: immediate-left subtraction now lowers for integer widths through
  i32, retaining explicit result masking below i32. Exact `__negvsi2` object
  emission, native link, executable positive/negative cases, and pressure
  acceptance are green. Report-all advances to 144 emitted and 299 failed;
  the next ranked integer candidate is `compiler_rt.negv.__negvti2`. Tier 3
  is green across 17 subgates. Item-15 accounting is now 24 composed rows, 17
  terminal-template rows, zero stage-two boundary rows, and 20 open
  integer-helper fallback candidates. Evidence
  `docs/evidence/std_debug_hello_negvsi2_acceptance.summary`,
  `docs/evidence/std_debug_hello_negvsi2_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_negvsi2_acceptance.summary`, and
  `docs/evidence/distribution_all_after_negvsi2_acceptance.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  acceptance: zero-left i128 subtraction now uses the established low-limb
  `sub` and high-limb `sbb` pair operation, and the machine verifier permits
  a live frame at terminal `ud2`. Exact executable-shape coverage validates
  positive and negative negation plus minimum-value SIGILL. This closes
  `__negvti2` and the already-selected `__absvti2` framed-trap sibling.
  Exact objects, native link, executable canaries, and both pressure checks are
  green. Report-all advances to 146 emitted and 297 failed; the next ranked
  integer candidate is `compiler_rt.negv.__negvdi2`. Tier 3 is green across
  17 subgates. Item-15 accounting is now 26 composed rows, 17 terminal-template
  rows, zero stage-two boundary rows, and 18 open integer-helper fallback
  candidates. Evidence
  `docs/evidence/std_debug_hello_negvti2_absvti2_acceptance.summary`,
  `docs/evidence/std_debug_hello_negvti2_acceptance_pressure.tsv`,
  `docs/evidence/std_debug_hello_absvti2_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_negvti2_acceptance.summary`, and
  `docs/evidence/distribution_all_after_negvti2_acceptance.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  acceptance: immediate-left i64 subtraction closes `__negvdi2`, while
  single-map relocation preserves live RAX values across destructive signed
  predicate generation and closes `__absvdi2`. The exact native harness
  initially exited 1 and caught the stale absolute-value binding before
  acceptance; after the fix, exact objects, native execution, permanent
  canaries, and both pressure checks are green. Report-all advances to 148
  emitted and 295 failed; the next ranked integer candidate is
  `compiler_rt.absvsi2.__absvsi2`. Tier 3 is green across 17 subgates.
  Item-15 accounting is now 28 composed rows, 17 terminal-template rows, zero
  stage-two boundary rows, and 16 open integer-helper fallback candidates.
  Evidence `docs/evidence/std_debug_hello_negvdi2_absvdi2_acceptance.summary`,
  `docs/evidence/std_debug_hello_negvdi2_acceptance_pressure.tsv`,
  `docs/evidence/std_debug_hello_absvdi2_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_negvdi2_acceptance.summary`, and
  `docs/evidence/distribution_all_after_negvdi2_acceptance.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  acceptance: the machine and encoder layers now provide width-correct i32
  conditional absolute value, and live EAX values relocate before destructive
  signed predicate generation. The exact native harness initially exited 1 and
  caught the stale absolute-value binding before acceptance. Exact object,
  native execution, permanent canaries, and pressure are now green.
  Report-all advances to 149 emitted and 294 failed; after excluding tail-call
  ABI rows, the next ranked integer candidate is
  `compiler_rt.mulXi3.__muldi3`. Tier 3 is green across 17 subgates. Item-15
  accounting is now 29 composed rows, 17 terminal-template rows, zero
  stage-two boundary rows, and 15 open integer-helper fallback candidates.
  Evidence `docs/evidence/std_debug_hello_absvsi2_acceptance.summary`,
  `docs/evidence/std_debug_hello_absvsi2_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_absvsi2_acceptance.summary`, and
  `docs/evidence/distribution_all_after_absvsi2_acceptance.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  acceptance: named i32 multiplication now has a width-correct machine and
  encoder form, and EAX preservation chooses any free mapped scratch register
  or the planned spill path. The exact `__muldi3` native harness initially
  failed its wrapping case and caught the stale shifted value before
  acceptance. Exact decomposed object, native execution, permanent canaries,
  and pressure are now green. Report-all advances to 150 emitted and 293
  failed; after excluding tail-call ABI rows, the next ranked integer
  candidate is `compiler_rt.int.__udivmodsi4`. Tier 3 is green across 17
  subgates. Item-15 accounting is now 30 composed rows, 17 terminal-template
  rows, zero stage-two boundary rows, and 14 open integer-helper fallback
  candidates. Evidence
  `docs/evidence/std_debug_hello_muldi3_acceptance.summary`,
  `docs/evidence/std_debug_hello_muldi3_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_muldi3_acceptance.summary`, and
  `docs/evidence/distribution_all_after_muldi3_acceptance.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  capability: phi blocks with more than three scalar results now place excess
  destinations in frame-backed slots owned by the same allocation and spill
  authority. Spill-to-spill restoration performs a real copy, and a permanent
  four-phi executable loop checks the edge semantics. The exact
  `compiler_rt.int.__udivmodsi4` row fits its pressure envelope and advances
  from `stage2-phi-registers` to `composed-block-select-width`; report-all
  remains 150 emitted and 293 failed, so item-15 accounting remains 30
  composed rows and 14 open integer-helper candidates. Evidence
  `docs/evidence/std_debug_hello_udivmodsi4_phi_spill.summary` and
  `docs/evidence/selector_tier2_udivmodsi4_phi_spill.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  capability: scalar selects from i1 through i32 now use the existing EAX
  value path, with permanent executable checks for true and false boolean
  outcomes. The exact `compiler_rt.int.__udivmodsi4` row advances from
  `composed-block-select-width` to `composed-block-ctlz-args`; report-all and
  item-15 counts remain unchanged. Evidence
  `docs/evidence/std_debug_hello_udivmodsi4_select_i1.summary` and
  `docs/evidence/selector_tier2_udivmodsi4_select_i1.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  capability: `llvm.ctlz.i32` now accepts both legal zero flags, backed by the
  existing machine form that returns 32 for zero. Permanent executable checks
  cover zero and nonzero inputs. The exact `compiler_rt.int.__udivmodsi4` row
  advances from `composed-block-ctlz-args` to `composed-block-icmp-form`;
  report-all and item-15 counts remain unchanged. Evidence
  `docs/evidence/std_debug_hello_udivmodsi4_ctlz_defined.summary` and
  `docs/evidence/selector_tier2_udivmodsi4_ctlz_defined.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  capability: i32 unsigned-greater comparisons against immediates now use the
  carry direction established by `immediate - lhs`. The executable canary
  rejected the initially reversed predicate before acceptance and also checks
  reuse of the compared value. The exact `compiler_rt.int.__udivmodsi4` row
  advances from `composed-block-icmp-form` to `composed-block-icmp-rhs`;
  report-all and item-15 counts remain unchanged. Evidence
  `docs/evidence/std_debug_hello_udivmodsi4_ugt_i32.summary` and
  `docs/evidence/selector_tier2_udivmodsi4_ugt_i32.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  capability: named scalar equality now supports widths through i32 using the
  existing ECX/R8D compare form, with executable equal, unequal, and
  post-compare operand reuse checks. The exact
  `compiler_rt.int.__udivmodsi4` row advances from `composed-block-icmp-rhs`
  to `composed-block-call-form` at `llvm.fshl.i32`; report-all and item-15
  counts remain unchanged. Evidence
  `docs/evidence/std_debug_hello_udivmodsi4_eq_i32.summary` and
  `docs/evidence/selector_tier2_udivmodsi4_eq_i32.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  capability: i32 funnel shifts now map to a general x86 `shldl` machine form
  with allocator-visible operands, low/high-register encoding coverage, and a
  permanent executable cross-bit check. The exact
  `compiler_rt.int.__udivmodsi4` row advances through all `llvm.fshl.i32`
  calls to `stage2-phi-src-spill64`; report-all and item-15 counts remain
  unchanged. Evidence
  `docs/evidence/std_debug_hello_udivmodsi4_fshl_i32.summary` and
  `docs/evidence/selector_tier2_udivmodsi4_fshl_i32.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  capability: spill materialization now validates each concrete frame index
  against the finalized frame size, so unrelated later spill allocation
  cannot invalidate an existing phi-edge slot. A focused regression fixes the
  frame at 16 bytes, advances the allocation cursor to slot 64, and verifies a
  write to slot 0. The exact `compiler_rt.int.__udivmodsi4` row advances from
  `stage2-phi-src-spill64` to `composed-block-icmp-form`; report-all and
  item-15 counts remain unchanged. Tier 3 is green across 17 subgates because
  this changes spill/frame acceptance. Evidence
  `docs/evidence/std_debug_hello_udivmodsi4_phi_spill_frame.summary` and
  `docs/evidence/distribution_all_after_udivmodsi4_phi_spill_frame.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  acceptance: i32 inequality against zero clears the final selector form, and
  exact native execution then catches both an out-of-frame spill write and a
  stale multi-alias register binding. Planned i32 spill homes, additive planned
  and emergency frame sizing, concrete frame bounds, width-correct spill
  copies, stable framed parameter homes, and parallel phi-edge preservation
  repair the single value map. The exact `__udivmodsi4` harness passes four
  quotient/remainder paths at max live values 11 and five required spill
  slots. Report-all advances to 153 emitted and 290 failed by also closing
  `__udivsi3` and `__umodsi3`; the next ranked non-tail integer candidate is
  `compiler_rt.int.__udivmoddi4`. Tier 3 is green across 17 subgates. Item-15
  accounting is now 33 composed rows, 17 terminal-template rows, zero
  stage-two boundary rows, and 11 open integer-helper fallback candidates.
  Evidence `docs/evidence/std_debug_hello_udivmodsi4_acceptance.summary`,
  `docs/evidence/std_debug_hello_udivmodsi4_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_udivmodsi4_acceptance.summary`, and
  `docs/evidence/distribution_all_after_udivmodsi4_acceptance.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  capability: `llvm.usub.with.overflow.i32` aggregate results now follow the
  existing overflow-tuple planning rule and are pressure-exempt, while their
  extracted value and carry components remain planned scalar values. The exact
  `compiler_rt.int.__udivmoddi4` row advances from the generic
  `stage2-unsupported-value` planner failure to `stage2-phi-restore-loc`;
  report-all and item-15 counts remain unchanged. Evidence
  `docs/evidence/std_debug_hello_udivmoddi4_usub_tuple.summary` and
  `docs/evidence/selector_tier2_udivmoddi4_usub_tuple.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  capability: framed composed functions now reserve the 32-slot emergency
  minimum or two possible home slots per planned value, whichever is larger.
  This bounds the current non-reusing spill-object model while concrete frame
  checks remain fail-closed. The exact `compiler_rt.int.__udivmoddi4` row
  advances from exhausted `stage2-phi-restore-loc` to
  `composed-block-icmp-rhs`; report-all and item-15 counts remain unchanged.
  Tier 3 is green across 17 subgates because frame behavior changed. Evidence
  `docs/evidence/std_debug_hello_udivmoddi4_frame_homes.summary` and
  `docs/evidence/distribution_all_after_udivmoddi4_frame_homes.summary`.

- 2026-07-11 (this commit, INBOX-9 and INBOX-14) Item 15 integer-helper
  capability: pointer equality with null now lowers through a 64-bit test and
  flag-preserving `sete`, with permanent executable checks for null and
  non-null pointers. The exact `compiler_rt.int.__udivmoddi4` row advances
  from `composed-block-icmp-rhs` to `composed-block-store-width`; report-all
  and item-15 counts remain unchanged. Evidence
  `docs/evidence/std_debug_hello_udivmoddi4_ptr_null.summary` and
  `docs/evidence/selector_tier2_udivmoddi4_ptr_null.summary`.

- 2026-07-12 (this commit, INBOX-9 and INBOX-15) Item 15 integer-helper
  capability: composed memory lowering now stores named i64 values through
  register or spilled pointers by materializing the pointer in RCX and the
  value in RAX through the single authoritative value-location map. The exact
  `compiler_rt.int.__udivmoddi4` row advances from
  `composed-block-store-width` to `composed-block-icmp-form`; report-all and
  item-15 counts remain unchanged. Tier 2 is green at 820 unit tests, 146
  integrated objects, and five executable canaries. Evidence
  `docs/evidence/std_debug_hello_udivmoddi4_store_i64.summary` and
  `docs/evidence/selector_tier2_udivmoddi4_store_i64.summary`.

- 2026-07-12 (this commit, INBOX-15) Generic-selector architecture closure:
  `composed_selector_impl.zig` is now a 297-line dispatch facade over explicit
  state, frame, scalar, memory, call, and CFG ownership modules. The split
  preserves the single authoritative value-location map and frame authority.
  Closing Tier 3 at current HEAD is green across 17 subgates, including all
  three 146-row captured-object pipelines, 100 source-owned objects, strict
  100-row ReleaseFast/ReleaseSafe/ReleaseSmall prefixes, and five executable
  canaries. No capability or ratchet counter moves. Evidence
  `docs/evidence/distribution_all_after_inbox15_selector_split.summary`.

- 2026-07-12 (this commit, INBOX-9) Item 15 integer-helper capability: named
  i32 unsigned less-than now materializes lhs in R8D and rhs in ECX so the
  existing `cmpl %ecx, %r8d` plus flag-preserving `setb` implements LLVM's
  unsigned predicate with the correct operand order. Executable checks cover
  both directions and values across the signed high-bit boundary. The exact
  `compiler_rt.int.__udivmoddi4` row advances from
  `composed-block-icmp-form` to `composed-block-binary-op`; report-all and
  item-15 counts remain unchanged. Evidence
  `docs/evidence/std_debug_hello_udivmoddi4_ult_i32_named.summary` and
  `docs/evidence/selector_tier2_udivmoddi4_ult_i32_named.summary`.

- 2026-07-12 (this commit, INBOX-9) Item 15 integer-helper capability: the
  selector's fixed RDX:RAX unsigned division/remainder protocol is now
  width-parametric, using EDX:EAX and a verified `divl` machine form for i32
  while preserving the existing i64 path. Executable checks cover quotient
  and remainder for ordinary and high-bit unsigned dividends. The exact
  `compiler_rt.int.__udivmoddi4` row advances from
  `composed-block-binary-op` to a later `composed-block-icmp-form`;
  report-all and item-15 counts remain unchanged. Evidence
  `docs/evidence/std_debug_hello_udivmoddi4_udiv_urem_i32.summary` and
  `docs/evidence/selector_tier2_udivmoddi4_udiv_urem_i32.summary`.

- 2026-07-12 (this commit, INBOX-9) Item 15 integer-helper capability: named
  unsigned greater-than now shares one i32/i64 selector branch with explicit
  width-correct materialization and compare order. Executable checks prove
  unsigned behavior across the i32 high-bit boundary. The exact
  `compiler_rt.int.__udivmoddi4` row advances from the later
  `composed-block-icmp-form` to `composed-block-call-form`; report-all and
  item-15 counts remain unchanged. Evidence
  `docs/evidence/std_debug_hello_udivmoddi4_ugt_i32_named.summary` and
  `docs/evidence/selector_tier2_udivmoddi4_ugt_i32_named.summary`.

- 2026-07-12 (this commit, INBOX-9) Item 15 integer-helper emission:
  `llvm.uadd.with.overflow.i32` and `llvm.usub.with.overflow.i32` now share
  operation-parametric add/sub lowering, preserving the wrapped value in EDX
  and the carry or borrow in EAX through flag-preserving `setb`. Executable
  checks cover non-borrowing, wrapping, and high-bit unsigned subtraction.
  `compiler_rt.int.__udivmoddi4` now emits; report-all advances to 154 emitted
  and 289 failed. Acceptance and item-15 accounting remain pending. Evidence
  `docs/evidence/std_debug_hello_udivmoddi4_usub_overflow_i32.summary` and
  `docs/evidence/selector_tier2_udivmoddi4_usub_overflow_i32.summary`.

- 2026-07-12 (this commit, INBOX-9 and INBOX-16) Item 15 integer-helper
  acceptance: checked lifetime markers clear exact linking, while CFG live-out
  intervals, planned phi spill assignments, and canonical frame-backed branch
  state repair path-dependent values exposed by native execution. The exact
  relocation-free `__udivmoddi4` object passes five quotient/remainder paths at
  17 live values and 11 required spill slots. Report-all remains 154 emitted
  and 289 failed; item-15 accounting advances to 34 composed rows and 10 open
  integer-helper fallback candidates. Tier 3 is green across 17 subgates.
  Evidence `docs/evidence/std_debug_hello_udivmoddi4_acceptance.summary`,
  `docs/evidence/std_debug_hello_udivmoddi4_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_udivmoddi4_acceptance.summary`, and
  `docs/evidence/distribution_all_after_udivmoddi4_acceptance.summary`.

- 2026-07-12 (this commit, INBOX-9) Item 15 integer-helper capability: signed
  i32 greater-than against an immediate now uses `cmpl` plus flag-preserving
  `setg` materialization, with encoding, assembly, and executable checks for
  negative, equal-boundary, and greater values. The exact
  `compiler_rt.shift.__ashlsi3` row advances to a later
  `composed-block-icmp-form`; report-all and item-15 counts remain unchanged.
  Evidence `docs/evidence/std_debug_hello_ashlsi3_sgt_i32_imm.summary` and
  `docs/evidence/selector_tier2_ashlsi3_sgt_i32_imm.summary`.

- 2026-07-12 (this commit, INBOX-9) Item 15 integer-helper capability:
  unsigned i32 less-than against an immediate now uses width-correct `cmpl`
  plus flag-preserving `setb`, with executable below/equal/high-bit checks.
  The exact `compiler_rt.shift.__ashlsi3` row advances from
  `composed-block-icmp-form` to `composed-block-binary-op`; report-all and
  item-15 counts remain unchanged. Evidence
  `docs/evidence/std_debug_hello_ashlsi3_ult_i32_imm.summary` and
  `docs/evidence/selector_tier2_ashlsi3_ult_i32_imm.summary`.

- 2026-07-12 (this commit, INBOX-9) Item 15 integer-helper capability: the
  EAX/CL variable-shift path now lowers i16 `shl` and `lshr` in addition to
  i32, with an executable truncate/left/right/zext roundtrip. The exact
  `compiler_rt.shift.__ashlsi3` row advances from `composed-block-binary-op`
  to `unsupported_value/stage2-phi-src-unknown`; report-all and item-15 counts
  remain unchanged. Evidence
  `docs/evidence/std_debug_hello_ashlsi3_variable_i16_shifts.summary` and
  `docs/evidence/selector_tier2_ashlsi3_variable_i16_shifts.summary`.

- 2026-07-12 (this commit, INBOX-9) Item 15 integer-helper acceptance:
  accumulator clobbering now honors current-position preservation during
  parallel phi-edge copies, preventing the first copy from deleting a later
  incoming value. Exact native `__ashlsi3` execution passes five shift counts
  at five live values and no required spill slots. The same generic repair
  closes `__lshrsi3`, `__lshrdi3`, and `__ashldi3`; report-all advances to 158
  emitted and 285 failed. Item-15 accounting is 38 composed rows and six open
  integer-helper candidates. Tier 3 is green across 17 subgates. Evidence
  `docs/evidence/std_debug_hello_ashlsi3_phi_acceptance.summary`,
  `docs/evidence/std_debug_hello_ashlsi3_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_ashlsi3_phi_acceptance.summary`, and
  `docs/evidence/distribution_all_after_ashlsi3_phi_acceptance.summary`.

- 2026-07-12 (this commit, INBOX-9) Item 15 integer-helper acceptance: verified
  i32 immediate and CL-variable `sarl` forms close `__ashrdi3` and sibling
  `__ashrsi3`. Exact native execution passes five signed cases at five live
  values and no spill demand. Report-all advances to 160 emitted / 283 failed;
  item-15 accounting reaches 40 composed rows and four open integer helpers.
  Tier 3 is green across 17 subgates. Evidence
  `docs/evidence/std_debug_hello_ashrdi3_acceptance.summary`,
  `docs/evidence/std_debug_hello_ashrdi3_acceptance_pressure.tsv`, and
  `docs/evidence/distribution_all_after_ashrdi3_acceptance.summary`.

- 2026-07-12 (this commit, INBOX-9) Item 15 integer-helper capability:
  i128 phi results now use frame-backed pair destinations, with named pair
  sources copied from registers or spill pairs through the authoritative
  value-location map. Pair-spill copies preserve both limbs under overlapping
  frame ranges, and executable checks cover both predecessor paths. The exact
  `__lshrti3`, `__ashrti3`, and `__ashlti3` rows advance from
  `stage2-phi-width` to `composed-block-binary-op`; report-all and item-15
  counts remain unchanged. Evidence
  `docs/evidence/std_debug_hello_lshrti3_i128_phi.summary` and
  `docs/evidence/selector_tier2_lshrti3_i128_phi.summary`.

- 2026-07-12 (this commit, INBOX-9) Item 15 integer-helper capability: named
  i64 logical-right shift counts now lower through a verified
  `shrq %cl, %rax` machine form, with executable high-bit checks. The exact
  i128 shift rows clear this limb operation but remain fail-closed at a later
  `composed-block-binary-op`; report-all and item-15 counts remain unchanged.
  Evidence `docs/evidence/std_debug_hello_lshrti3_variable_lshr_i64.summary`
  and `docs/evidence/selector_tier2_lshrti3_variable_lshr_i64.summary`.

- 2026-07-12 (this commit, INBOX-9) Item 15 integer-helper capability: named
  i64 left-shift counts now lower through a verified `shlq %cl, %rax` machine
  form, with executable high-bit checks. Fresh rebuilt report-all advances to
  162 emitted / 281 failed as `__lshrti3` and `__ashlti3` begin emitting;
  exact acceptance and item-15 accounting remain pending, while `__ashrti3`
  stays fail-closed at a later `composed-block-binary-op`. Evidence
  `docs/evidence/std_debug_hello_lshrti3_variable_shl_i64.summary` and
  `docs/evidence/selector_tier2_lshrti3_variable_shl_i64.summary`.

- 2026-07-12 (this commit, INBOX-9) Item 15 integer-helper emission: named
  i64 arithmetic-right shift counts now lower through a verified
  `sarq %cl, %rax` machine form, with executable positive and negative checks.
  `__ashrti3` joins `__lshrti3` and `__ashlti3` in emitting; fresh report-all
  reaches 163 emitted / 280 failed. Exact native execution, pressure
  diagnostics, Tier 3, and item-15 accounting remain pending. Evidence
  `docs/evidence/std_debug_hello_ashrti3_variable_ashr_i64.summary` and
  `docs/evidence/selector_tier2_ashrti3_variable_ashr_i64.summary`.

- 2026-07-12 (this commit, INBOX-9) Item 15 integer-helper acceptance:
  parallel phi-edge moves now stabilize all named incoming sources before
  copying destinations, fixing the native count-1 `__lshrti3` miscompile.
  Exact native execution passes 18 logical-right, arithmetic-right, and left
  shift cases at five, five, and six live values respectively, with no spill
  demand. `__lshrti3`, `__ashrti3`, and `__ashlti3` close; report-all remains
  163 emitted / 280 failed, while item-15 accounting advances to 43 composed
  rows and one open integer-helper fallback candidate. Tier 3 is green across
  17 subgates. Evidence
  `docs/evidence/std_debug_hello_i128_shift_acceptance.summary` and
  `docs/evidence/distribution_all_after_i128_shift_acceptance.summary`.

- 2026-07-12 (this commit, INBOX-9 and INBOX-16) Item 15 integer-helper bucket
  closure: fresh report-all contains no non-tail, non-soft-float selector
  failure after the i128 shift family. The original 45 non-tail rows reconcile
  to 43 composed-selection rows plus two integer terminal-template rows, so
  open integer-helper fallback candidates correct from the stale value one to
  zero. The 21 integer `UnsupportedTailCallAbi` rows remain in the separate
  ABI family. The next selector frontier is soft-float
  `compiler_rt.trunc.__trunch`; stop for user direction before crossing it.
  Evidence
  `docs/evidence/std_debug_hello_integer_helper_bucket_closure.summary`.

- 2026-07-12 (this commit, INBOX-18) Item 12 soft-float capability: type-driven
  half extension/truncation libcalls, exact FP/integer bitcasts, scalar float
  addition, FP phi edges, and the side-effect barrier close
  `compiler_rt.trunc.__trunch`. The in-module conversion helpers emit without
  recursion; a focused object links through their aliases and passes 14
  bit-exact native half cases. Report-all advances from 163 emitted / 280
  failed to 170 emitted / 273 failed. The next non-tail soft-float frontier is
  `compiler_rt.trunc.trunc` at typed `fadd`. Tier 2 is green. Evidence
  `docs/evidence/std_debug_hello_trunch_acceptance.summary`.

- 2026-07-12 (this commit, INBOX-19) Item 12 double truncation canary:
  width-driven double/i64 bitcasts, `addsd`, float/double barriers, variable
  i64 shift, and immediate i64 XOR close `compiler_rt.trunc.trunc`. Exact
  native execution passes 24 raw-bit cases and catches a live-accumulator
  predicate clobber before acceptance. Report-all advances from 170 emitted /
  273 failed to 173 emitted / 270 failed, including two collateral typed-form
  emissions. The next non-tail frontier is `compiler_rt.tan.tanh`; wider trunc
  forms remain untouched. Tier 2 is green. Evidence
  `docs/evidence/std_debug_hello_trunc_acceptance.summary`.

- 2026-07-13 (this commit, INBOX-20) Item 12 scalar SSE direct-call boundary:
  the SysV planner now drives independent GPR/XMM argument placement, parallel
  FP argument staging, scalar FP results in XMM0, and live GPR/XMM preservation.
  Advisory `tail` and `notail` markers lower as ordinary calls while `musttail`
  remains fail-closed. The real `compiler_rt.tan.tanh` emits and passes a
  controlled exact-symbol native caller test without implementing or claiming
  semantics for `compiler_rt.tan.tanf`. Report-all advances from 173 emitted /
  270 failed to 189 emitted / 254 failed. The corrected marker inventory has 42
  advisory `tail` rows: 10 emit ordinarily and 32 expose non-tail frontiers;
  no tracked `musttail` row exists in this corpus. Tier 3 passes all 17
  subgates. Evidence
  `docs/evidence/std_debug_hello_tanh_call_abi_acceptance.summary`.

- 2026-07-13 (this commit, INBOX-21) Item 12 scalar FP operation boundary:
  type-driven float-to-double widening, double-to-float narrowing, and scalar
  float/double multiplication now use register-parametric SSE forms with 38
  bit-exact executable cases. The real `compiler_rt.tan.tanf` advances through
  `fpext` and `fmul` to its first vector instruction, `insertelement`, where
  this cycle stops for architectural review. Report-all advances from 189
  emitted / 254 failed to 190 emitted / 253 failed; the newly emitting
  `compiler_rt.fma.fmaf` row is collateral and has no separate semantic claim.
  Tier 2 passes all 21 steps. Evidence
  `docs/evidence/std_debug_hello_tanf_scalar_fp_acceptance.summary`.

- 2026-07-13 (this commit, INBOX-23) Item 12 scalar FP arithmetic capability:
  type-driven float/double subtraction and division now use register-parametric
  SSE forms with explicit non-commutative operand preservation and 44
  bit-exact executable cases. Twelve directed compiler_rt rows advance from
  `fsub`/`fdiv` to `insertelement`; fresh report-all remains 190 emitted / 253
  failed with no collateral emission or regression. Tier 2 passes all 21
  steps. Evidence
  `docs/evidence/std_debug_hello_scalar_fsub_fdiv_acceptance.summary`.

- 2026-07-13 (this commit, INBOX-23 successor) Item 12 scalar FP comparison
  capability: all 16 float/double `fcmp` predicates now use parametric
  `ucomiss`/`ucomisd` plus parity-correct result materialization. Executable
  coverage passes 192 ordered/unordered outcomes, including NaN in either
  operand. Report-all advances from 190 emitted / 253 failed to 192 emitted /
  251 failed through two collateral round-family emissions without separate
  rounding-semantic claims. Tier 2 passes all 21 steps. The pre-authorized
  one-cycle pipeline is now exhausted. Evidence
  `docs/evidence/std_debug_hello_scalar_fcmp_acceptance.summary`.

- 2026-07-13 (this commit, INBOX-24) Item 12 Phase D vector capability: the
  existing XMM register bank now owns a typed `<2 x double>` packed shape with
  static defined-lane masks, bounded insertion/splat/add/multiply/extraction,
  and atomic pair-slot unaligned spills. A dual-construction pressure canary
  passes exact signed-zero, finite, subnormal, infinity, and NaN-payload cases
  while proving a vector spill/reload. Report-all remains 192 emitted / 251
  failed with no collateral emission or regression; directed rows advance to
  their next scalar, memory, CFG, non-splat, or excluded-type frontiers. Tier 2
  is green and final Tier 3 acceptance is recorded in the evidence summary.
  Stop for the plan's periodic review; no successor is authorized. Evidence
  `docs/evidence/std_debug_hello_vector_f64x2_acceptance.summary`.

- 2026-07-13 (this commit, INBOX-25) Item 12 scalar FP stack-memory and
  out-parameter capability: typed float/double frame objects, exact local
  loads/stores, narrow advisory pointer attributes, and the existing SysV
  GPR/XMM call planner now cover the rem_pio2f caller shape. A parametric
  `addss`/`addsd` repair removes the fixed-XMM alias false rejection exposed by
  the newly reachable bodies. Twelve exact round trips and a three-case native
  out-parameter canary pass. `tanf`/`sinf` advance to scalar FP select, `cosf`
  to an FP phi edge, and `sincosf` to the excluded external FP store. Report-all
  advances to 193 emitting / 250 failing through one unrelated collateral
  integer emission. Tier 2 is green; no directed trig row closes, so Tier 3 is
  not triggered. Evidence
  `docs/evidence/std_debug_hello_scalar_fp_stack_memory_acceptance.summary`.

- 2026-07-13 (this commit, INBOX-25 pre-authorized successor) Item 12 packed
  float vector capability: one shared typed fixed-vector constant parser and
  splat predicate replace selector-local lane and mask text parsing. The
  packed-XMM allocation class now carries both f64x2 and f32x2 typed shapes;
  f32x2 mirrors the bounded insertion/splat/add/multiply/extraction slice and
  uses pair-slot `movups` spills. A dual-construction pressure canary passes
  80/80 exact output words across zeros, finite values, subnormals, infinities,
  and NaN payloads. Six log rows advance to lane-shift shuffle and
  `__unordsf2` to vector `fabs`; report-all remains 193 emitting / 250 failing.
  Tier 2 and the policy-triggered Tier 3 are green. No third cycle is
  authorized; stop for review. Evidence
  `docs/evidence/std_debug_hello_vector_f32x2_acceptance.summary` and
  `docs/evidence/distribution_all_after_f32x2.summary`.

- 2026-07-13 (this commit, INBOX-26) Item 12 scalar FP CFG capability:
  type-driven float/double selects preserve exact source bits, FP constants
  flow through phi edges, and named FP phi sources are snapshotted before
  parallel destination writes. Executable coverage proves both select arms,
  signed zeros and NaN payloads, loop-carried f32 swaps, and an f64 constant
  edge. `compiler_rt.tan.tanf` closes and passes eight precomputed exact native
  cases without invoking its controlled reducer; `sinf` and `cosf` advance to
  unsupported switch terminators. Report-all advances to 199 emitting / 244
  failing; five non-directed emissions are collateral without semantic claims.
  Tier 2 and the row-closure Tier 3 are green. Evidence
  `docs/evidence/std_debug_hello_scalar_fp_select_phi_acceptance.summary` and
  `docs/evidence/distribution_all_after_scalar_fp_select_phi.summary`.

- 2026-07-13 (this commit, INBOX-26 pre-authorized successor) Item 12 scalar
  FP pointer-store capability: the selector now proves exact named ABI pointer
  parameters and stores scalar float/double values through either their GPR
  homes or stabilized 64-bit spills. Fifteen bit-exact executable cases cover
  direct f32/f64 and framed spilled-pointer stores; derived pointers remain
  fail-closed. `sincosf` advances to the unsupported switch terminator, while
  report-all remains 199 emitting / 244 failing with no collateral emissions.
  Tier 2 is green; no row closes, so Tier 3 is not triggered. The one-cycle
  pipeline is exhausted and work stops for review. Evidence
  `docs/evidence/std_debug_hello_scalar_fp_pointer_store_acceptance.summary`.

- 2026-07-13 (this commit, INBOX-27 Part 1) Standalone frame correctness
  repair: every alloca-bearing composed-selector function now reserves the
  convenience-spill range before frame payload layout, and instruction
  lowering consumes only the frame authority's preplanned alloca locations.
  The observed live-f32-spill/local-double-store collision now passes five
  exact executable cases. An audit of all 30 alloca-bearing functions in the
  accepted 199-emission report found that `compiler_rt.int.__moddi3` also hit
  the old aliasing envelope: its sign spill and out-parameter both used offset
  zero, so its prior structural closure was not semantic proof. The repaired
  stream separates the payload at displacement 256 from spill slots 0/2/4.
  Tier 2 and the shared-frame-layout Tier 3 are green; report counters are not
  moved by this correctness-only cycle. Evidence
  `docs/evidence/std_debug_hello_alloca_spill_collision_repair.summary` and
  `docs/evidence/distribution_all_after_inbox27_alloca_spill_collision.summary`.

- 2026-07-13 (this commit, INBOX-27 fix-forward) The permanent composed-selector
  executable canary now re-proves `compiler_rt.int.__moddi3` after the frame
  collision repair and covers the sibling `__umoddi3` shape. Three unsigned and
  four signed i64 remainder cases pass exactly through the alloca-backed
  `__udivmoddi4` call path, including a high-bit unsigned dividend and every
  dividend/divisor sign combination. Repository tests and all five permanent
  integrated executable canaries pass; report counters remain unchanged.
  Evidence
  `docs/evidence/zig_integrated_exe_moddi3_umoddi3_closure_reproof.summary`.

- 2026-07-13 (this commit, INBOX-27 Part 2) Item 12 typed integer switch
  capability: bounded i1-through-i32 compare chains normalize narrow
  conditions and case constants, while an explicit `and 3` proof admits only
  a complete 0/1/2/3 case set before omitting a plain unreachable default.
  Switch-to-phi edges, larger case sets, indirect branches, and unproved
  unreachable defaults remain fail-closed. Exact executable tests cover the
  exhaustive masked form and a reachable-default i16 form. `sinf`, `cosf`,
  and `sincosf` close through 12 bit-exact native cases each, including all
  four switch residues; report-all advances to 443 selected / 202 emitting /
  241 failing. One fma row and twelve conversion rows advance collaterally
  without semantic claims. Tier 2 and the row-closure Tier 3 are green. No
  third capability is authorized; stop for periodic review. Evidence
  `docs/evidence/std_debug_hello_typed_switch_acceptance.summary` and
  `docs/evidence/distribution_all_after_inbox27_typed_switch.summary`.

- 2026-07-13 (this commit, INBOX-28) Item 12 packed lane-shift capability:
  the shared typed shuffle classifier admits exact `<1, poison>` masks for
  f32x2 and f64x2, lowering through the existing `shufps`/`unpckhpd` forms
  while propagating only source lane 1 into defined output lane 0. Pressure
  canaries pass 170 exact words across signed zeros, finite values,
  subnormals, infinities, and NaN payloads; malformed near-miss masks remain
  fail-closed. The seven directed log rows and collateral double `log10`
  advance to concrete scalar `sitofp`; double `log` remains at packed `fsub`.
  Report-all therefore remains 443 selected / 202 emitting / 241 failing.
  Tier 2 is green and no Tier 3 trigger occurs. Evidence
  `docs/evidence/std_debug_hello_vector_lane_shift_acceptance.summary`.

- 2026-07-13 (this commit, INBOX-28 pre-authorized successor) Item 12 packed
  FP subtraction capability: register-parametric `subps`/`subpd` machine forms
  and type-driven f32x2/f64x2 lowering preserve operand order and intersect
  static defined-lane masks. The existing pressure canaries pass 210 exact
  output words, including 40 forward/reverse subtraction results across
  signed zeros, finite values, subnormals, infinities, and NaN payloads.
  `compiler_rt.log.log` advances from packed `fsub` to concrete `sitofp i12`
  without closing, so report-all remains 443 selected / 202 emitting / 241
  failing. Tier 2 is green and no Tier 3 trigger occurs. The one-cycle
  pipeline is exhausted; stop for periodic review. Evidence
  `docs/evidence/std_debug_hello_packed_fsub_acceptance.summary`.

- 2026-07-13 (this commit, INBOX-29) Item 12 scalar integer-to-FP capability:
  typed `sitofp`/`uitofp` from i8 through i64 to float or double now normalize
  narrow and odd widths explicitly. Unsigned i64 uses a high-half correction
  instead of signed reinterpretation. Twenty-seven executable cases prove 54
  precomputed result bit patterns across signed/unsigned width boundaries and
  mantissa rounding. Nine log rows advance to half `fcmp`, integer `icmp`, a
  cross-input shuffle, or a global-table GEP; none closes, so report-all
  remains 443 selected / 202 emitting / 241 failing. Tier 2 is green. The
  shared frame-reservation trigger required Tier 3; one infrastructure-hung
  full invocation plus narrow unchanged-input recovery accounts for all 17
  green subgates. Evidence
  `docs/evidence/std_debug_hello_scalar_int_to_fp_acceptance.summary` and
  `docs/evidence/distribution_all_after_inbox29_int_to_fp.summary`.

- 2026-07-13 (this commit, INBOX-29 pre-authorized successor) Item 12 scalar
  comparison capability: typed plain `icmp slt` with i32/i64 immediate right
  operands now lowers through width-correct compares and `setl`, while
  `samesign` and unsupported shapes remain fail-closed. Eight focused boundary
  outcomes and 32 precomputed-bit native log calls pass. Four directed log
  rows close; four soft-float arithmetic rows emit collaterally without
  separate semantic claims. Report-all advances to 443 selected / 210 emitting
  / 233 failing. Tier 2 and the row-closure Tier 3 are green. The one-cycle
  pipeline is exhausted; stop for review with three half wrappers at `fcmp`,
  double `log10` at cross-input shuffle, and double `log` at global-table GEP.
  Evidence `docs/evidence/std_debug_hello_slt_immediate_acceptance.summary`
  and
  `docs/evidence/distribution_all_after_inbox29_slt_immediate.summary`.

- 2026-07-13 (`f510d241`, INBOX-30) Item 12 exact half comparison capability:
  typed `fcmp oeq half` against either zero bit pattern lowers as
  `(bits & 0x7fff) == 0`, while named comparisons and all other half predicates
  remain fail-closed. Three directed half log wrappers close; `__sqrth`
  advances to unsupported half `fmul`. A 39-call precomputed-bit native matrix
  covers zeros, subnormals, normals, infinities, and quiet/signaling NaNs. Its
  first run exposed the stale framed-FP-phi destination repaired separately in
  `70c63cc4`. Report-all advances to 443 selected / 213 emitting / 230 failing.
  Tier 2 and the single row-closure Tier 3 are green. Evidence
  `docs/evidence/std_debug_hello_half_zero_fcmp_acceptance.summary` and
  `docs/evidence/distribution_all_after_inbox30_half_zero_fcmp.summary`.

- 2026-07-13 (this commit, INBOX-30 pre-authorized successor) Item 12 exact
  two-source vector shuffle capability: typed f64x2 `<0, 3>` lowers through a
  fixed `shufpd $2` form and propagates static definedness from A0 and B1.
  Other two-source masks and f32x2 `<0, 3>` remain fail-closed. A 15-case
  precomputed-bit native proof closes `compiler_rt.log10.log10`; report-all
  advances to 443 selected / 214 emitting / 229 failing with no collateral
  emissions. Tier 2 and the single row-closure Tier 3 are green. The pipeline
  is exhausted; stop for review, and do not begin global-table GEP work before
  its bounded architectural decision. Evidence
  `docs/evidence/std_debug_hello_f64x2_shuffle_0_3_acceptance.summary` and
  `docs/evidence/distribution_all_after_inbox30_f64x2_shuffle_0_3.summary`.

- 2026-07-13 (this commit, INBOX-31) Item 12 module-aware constant-table
  capability: one shared typed decoder now gives the selector and ELF writer a
  read-only view of four admitted captured table shapes. Typed table pointers
  remain in the existing value-location map; GPR index arithmetic feeds
  register-parametric RIP-relative address and i16/double load forms; ELF
  serialization reuses `.data`, global symbols, and `R_X86_64_PC32` with
  addend `-4`. An 18-call native canary and `readelf` prove first/interior/last
  accesses, pair offsets, exact object sizes, and all six relocations. All six
  directed rows advance, but none closes, so report-all remains 443 selected /
  214 emitting / 229 failing. Tier 2 is green; Tier 3 acceptance is recorded
  separately. The capability excludes `.rodata`, STB_LOCAL ordering, PIC,
  writable-table admission, and stores. Stop for the required architectural
  review; no successor is authorized. Evidence
  `docs/evidence/std_debug_hello_constant_table_acceptance.summary` and
  `docs/evidence/distribution_all_after_inbox31_constant_tables.summary`.

- 2026-07-13 (this commit, INBOX-32) Item 12 named predicate capability:
  exact typed `or i1 %a, %b` over named values now lowers through the existing
  scalar value-location model, while immediate and wider unadmitted OR forms
  remain fail-closed. Eight permanent truth-table calls cover both operand
  orders through branch and select consumers. Forty-six precomputed-bit native
  calls close `compiler_rt.log.log`, `compiler_rt.exp2.exp2f`, and
  `compiler_rt.exp2.__exp2h`. Four unsigned FP-to-int helpers emit
  collaterally without separate semantic claims. Report-all advances to 443
  selected / 221 emitting / 222 failing. Tier 2 and the row-closure Tier 3 are
  green. Continue with the pre-authorized exact `icmp sgt i64` immediate
  successor; no third cycle is authorized. Evidence
  `docs/evidence/std_debug_hello_named_i1_or_acceptance.summary` and
  `docs/evidence/distribution_all_after_inbox32_named_i1_or.summary`.

- 2026-07-13 (this commit, INBOX-32 pre-authorized successor) Item 12 signed
  comparison capability: exact plain `icmp sgt i64` with an immediate RHS now
  lowers through the existing 64-bit compare and `setg` forms, while
  `samesign` and unsupported shapes remain fail-closed. Five permanent
  executable boundary calls and 20 precomputed-bit native calls close
  `compiler_rt.exp2.exp2`; its captured `ldexp` helper body remains unsupported
  and is resolved by a separately compiled pinned-Zig dependency for native
  acceptance. Four scalar conversion/rounding rows emit collaterally without
  semantic claims. Report-all advances to 443 selected / 226 emitting / 217
  failing. Tier 2 and the row-closure Tier 3 are green. The pipeline is
  exhausted; stop for review before the noted multiply-location repair.
  Evidence `docs/evidence/std_debug_hello_sgt_i64_immediate_acceptance.summary`
  and
  `docs/evidence/distribution_all_after_inbox32_sgt_i64_immediate.summary`.

- 2026-07-13 (this commit, INBOX-33) Item 12 false-rejection repair:
  `lowerMul64` now consumes an i64 RHS already resident in RAX through the
  existing non-destructive `imul_arg64_rax` form. Two executable products and
  an EAX width near miss cover the exact location boundary. Eighteen
  precomputed-bit native calls close `compiler_rt.sqrt.sqrtf`; double `sqrt`
  advances to the explicitly excluded first i128 multiply. Report-all advances
  to 443 selected / 227 emitting / 216 failing with no collateral emissions.
  Tier 2 and the row-closure Tier 3 are green. Continue with one
  evidence-ranked bounded typed successor; no third cycle is authorized.
  Evidence `docs/evidence/std_debug_hello_mul64_rax_rhs_repair.summary` and
  `docs/evidence/distribution_all_after_inbox33_mul64_rax_rhs.summary`.

- 2026-07-13 (this commit, INBOX-33 evidence-ranked successor) Item 12 signed
  comparison capability: plain named `icmp slt/sgt` for i32/i64 now uses the
  existing typed scratch, compare, and setcc paths. Ten permanent boundary
  calls cover both widths, and two near misses preserve `samesign` and i16
  fail-closed behavior. The four initially ranked compare wrappers remain
  blocked by earlier `samesign ugt` immediate forms. Forty precomputed-bit
  native calls instead close `compiler_rt.fmod.fmod` and
  `compiler_rt.fmod.fmodf`, the only new emissions. Report-all advances to 443
  selected / 229 emitting / 214 failing. Tier 2 and the row-closure Tier 3 are
  green. The authorized pipeline is exhausted; stop for review before any
  further capability. Evidence
  `docs/evidence/std_debug_hello_signed_named_comparisons_acceptance.summary`
  and
  `docs/evidence/distribution_all_after_inbox33_signed_named_comparisons.summary`.

- 2026-07-13 (this commit, INBOX-34 prerequisite correctness repair) Item 12
  call-boundary correction: unimplemented `llvm.*` intrinsics now fail closed
  before ordinary scalar direct-call lowering, and exact typed
  `llvm.fabs.f64` clears only the payload sign bit. Executable cases preserve
  zero, subnormal, and quiet/signaling NaN payload bits. The accepted report
  baseline is corrected from 443 selected / 229 emitting / 214 failing to 443
  selected / 226 emitting / 217 failing: `__cmpti2`, `__ucmpti2`, and
  `__bitreversedi2` had retained unresolved LLVM intrinsic calls and were not
  valid emissions. Tier 2 and the shared-call-boundary Tier 3 are green.
  Resume INBOX-34's exact named i32/i64 inequality capability. Evidence
  `docs/evidence/std_debug_hello_llvm_intrinsic_boundary_repair.summary` and
  `docs/evidence/distribution_all_after_inbox34_llvm_intrinsic_boundary_repair.summary`.

- 2026-07-13 (this commit, INBOX-34) Item 12 named integer inequality:
  exact plain named `icmp ne` for i32/i64 now lowers through the existing typed
  scratch, compare, and `setne` paths. Branch and select consumers execute at
  both widths; i16 and `samesign` near misses remain fail-closed. Eighty
  precomputed-result native calls close `__gedf2`, `__gesf2`, `__cmpdf2`, and
  `__cmpsf2` from one relocation-free object. Against the corrected intrinsic
  baseline, report-all advances from 443 selected / 226 emitting / 217 failing
  to 443 selected / 230 emitting / 213 failing with no collateral emissions.
  Tier 2 and the row-closure Tier 3 are green. Continue with the pre-authorized
  exact immediate-left i32 shift successor. Evidence
  `docs/evidence/std_debug_hello_named_integer_inequality_acceptance.summary`
  and
  `docs/evidence/distribution_all_after_inbox34_named_integer_inequality.summary`.

- 2026-07-13 (this commit, INBOX-34 evidence fix-forward) Item 12 acceptance
  correction: the first named-inequality native harness incorrectly used a
  returning function as the ELF entrypoint and therefore could not prove row
  semantics. The corrected `-fno-lld` executable enters through Zig `_start`,
  runs the same 80 precomputed-result wrapper calls from `main`, traps on a
  mismatch, and exits successfully. Production, permanent tests, the exact row
  object, and gate inputs are unchanged; the acceptance artifact hash is
  corrected in
  `docs/evidence/std_debug_hello_named_integer_inequality_acceptance.summary`.

- 2026-07-13 (this commit, INBOX-34 pre-authorized successor) Item 12 typed
  immediate-left shift: exact i32 `shl imm, %named` now uses the existing CL
  count and EAX payload path; i16/i64 variants remain fail-closed. Five
  permanent executable count boundaries and 52 precomputed-bit native calls
  close `compiler_rt.floor_ceil.ceilf` and `floorf` from one relocation-free
  object. Report-all advances from 443 selected / 230 emitting / 213 failing
  to 443 selected / 232 emitting / 211 failing with no collateral emissions.
  Tier 2 and the row-closure Tier 3 are green. The INBOX-34 pipeline is
  exhausted; stop for review before the noted i6 comparison, half store, or
  `lowerIcmp` structural split. Evidence
  `docs/evidence/std_debug_hello_immediate_left_shl_acceptance.summary` and
  `docs/evidence/distribution_all_after_inbox34_immediate_left_shl.summary`.

- 2026-07-13 (this commit, INBOX-35 authorized interlude) Item 12 selector
  ownership: the complete `lowerIcmp` predicate matrix moves byte-for-byte from
  the scalar module to `composed_selector_icmp.zig`, while the scalar facade
  preserves all call sites. Focused unit tests and structural smoke are green;
  no Tier 3 was run under the move-only interlude contract. Continue with the
  directed narrow i6 unsigned-immediate comparison. Evidence
  `docs/evidence/inbox35_lower_icmp_ownership_split.summary`.

- 2026-07-13 (this commit, INBOX-35) Item 12 narrow comparison capability:
  exact `icmp samesign ult i6 %x, imm` now zero-extends the i6 source in EAX
  with an explicit `and 63` before the existing unsigned compare and `setb`.
  Eight permanent executable cases cover zero, the 24 boundary, the all-ones
  i6 value, and contaminated upper source bits; five nearby unadmitted forms
  remain fail-closed. The two expected conversion rows advance from
  `composed-block-icmp-form` to their concrete later `llvm.cttz.i32` frontier,
  so report-all remains 443 selected / 232 emitting / 211 failing and no row
  closure is claimed. Tier 2 is green and Tier 3 is not triggered. Continue
  with the pre-authorized half pointer-store successor. Evidence
  `docs/evidence/std_debug_hello_i6_samesign_ult_acceptance.summary`.

- 2026-07-13 (this commit, INBOX-35 pre-authorized successor) Item 12 scalar
  FP memory capability: exact half stores through ABI-proven pointer
  parameters now preserve the low 16 XMM payload bits through EAX and the
  existing `movw` pointer-store form. Fourteen permanent output words and 20
  precomputed row-exact `sincosh` outputs cover signed zeros, subnormals,
  finite values, infinities, and quiet/signaling NaN payloads; derived pointer
  forms remain fail-closed. `compiler_rt.sincos.sincosh` is the only new
  emission, advancing report-all to 443 selected / 233 emitting / 210 failing.
  Tier 2 and the row-closure Tier 3 are green. The INBOX-35 pipeline is
  exhausted; stop for the fresh inventory and vector-mask architectural
  checkpoint. Evidence
  `docs/evidence/std_debug_hello_half_pointer_store_acceptance.summary` and
  `docs/evidence/distribution_all_after_inbox35_half_pointer_store.summary`.

- 2026-07-13 (this commit, INBOX-36) Item 12 architectural inventory: a
  read-only scan of the accepted 443 / 233 / 210 report and pinned captured IR
  finds seven vector-mask functions and one additional vector-bitcast-only
  function. `__unordsf2` is the sole immediate mask candidate; complex divide
  rows demonstrate that a mask must serve both scalar extraction and packed
  vector select, while four multiply-complex rows consume `<4 x i1>` as `i4`.
  The recommended authority is full-width XMM lane masks with static
  definedness and explicit `movmsk` conversion at scalar consumers. The first
  bounded slice would close only `__unordsf2`; the scalar frontier still ranks
  a two-closure `llvm.cttz.i32` cycle ahead by effort. No code changed and no
  gate ran. Stop for the required vector-mask architectural review. Evidence
  `docs/evidence/vector_mask_checkpoint_inventory.md`.

- 2026-07-13 (this commit, INBOX-37 Part 1) Item 12 typed trailing-zero
  capability: exact `llvm.cttz.i32` now reuses the existing zero-defined
  machine/verifier operation while all wider, malformed, and non-literal
  variants remain fail-closed. Permanent execution covers zero, single-bit,
  and all-ones inputs. A relocation-free exact-row object executes 23
  precomputed conversion cases and closes exactly
  `compiler_rt.floatunsisf.__floatunsisf` and
  `compiler_rt.floatsisf.__floatsisf`; report-all advances from 443 selected /
  233 emitting / 210 failing to 443 / 235 / 208 with no collateral emissions.
  Tier 2 and the row-closure Tier 3 are green. Continue with INBOX-37's
  pre-authorized exact typed `llvm.ctlz.i64` successor. Evidence
  `docs/evidence/std_debug_hello_cttz_i32_acceptance.summary` and
  `docs/evidence/distribution_all_after_inbox37_cttz_i32.summary`.

- 2026-07-13 (this commit, INBOX-37 pre-authorized successor) Item 12 typed
  leading-zero capability: exact `llvm.ctlz.i64` now reuses the existing
  zero-defined machine/verifier form and records its i64 result in RAX.
  Permanent execution covers zero, single-bit, and all-ones inputs; malformed
  widths remain fail-closed. A full report diff advances exactly the four
  directed arithmetic and four conversion rows from the intrinsic boundary to
  `composed-block-binary-width`, with no closures or collateral changes;
  report-all remains 443 selected / 235 emitting / 208 failing. Tier 2 is
  green and Tier 3 is not triggered. The INBOX-37 pipeline is exhausted;
  `llvm.cttz.i64` requires its own directive. Evidence
  `docs/evidence/std_debug_hello_ctlz_i64_acceptance.summary`.

- 2026-07-13 (this commit, INBOX-38 Part 1) Item 12 narrow binary and CFG
  correctness capability: exact scalar i7 binary operations now cover the
  shared width exposed by four arithmetic and four conversion rows. Exact
  `__divdf3` execution caught a stale framed backward-phi register home before
  acceptance; framed scalar integer phi destinations now stabilize through
  the single frame authority before block emission. Permanent modulo-128 and
  backward-edge regressions are green. `compiler_rt.divdf3.__divdf3` closes,
  while the other seven directed rows advance to later typed frontiers with no
  collateral changes; report-all advances from 443 / 235 / 208 to 443 / 236 /
  207. Tier 2 and the single row-closure Tier 3 are green. Continue with the
  pre-authorized scalar `fptosi`-to-i32 successor, selected over signed i32
  divide-by-two because `exp` and `expf` share the exact existing SSE-shaped
  conversion frontier. Evidence
  `docs/evidence/std_debug_hello_i7_binary_phi_acceptance.summary` and
  `docs/evidence/distribution_all_after_inbox38_i7_phi.summary`.

- 2026-07-13 (this commit, INBOX-38 pre-authorized successor) Item 12 scalar
  conversion capability: exact `fptosi float|double -> i32` now preserves live
  EAX values and reuses the existing SSE conversion operations through the
  XMM value-location authority. Eight permanent defined-domain cases cover
  zeros, subnormals, signed fractional truncation, and both i32 boundaries;
  three nearby forms remain fail-closed. `exp` and `expf` both advance to the
  excluded function-local constant-table GEP boundary, with no closures or
  collateral report changes, so report-all remains 443 / 236 / 207. Tier 2 is
  green and Tier 3 is not triggered. The INBOX-38 pipeline is exhausted; stop
  for the next scalar-tranche directive. Evidence
  `docs/evidence/std_debug_hello_fptosi_i32_acceptance.summary`.

- 2026-07-13 (this commit, INBOX-39 Part 1) Item 12 exact signed division and
  CFG correctness: `sdiv i32 %named, 2` now implements truncation toward zero
  with sign correction before arithmetic shift; permanent execution includes
  negative odd values and four nearby forms remain fail-closed. Exact powi
  execution exposed a conditional-phi source that could be rebound to an
  edge-local spill before the sibling edge was emitted, so both successor
  source sets now stabilize before the conditional jump. A permanent framed
  two-successor regression and 22 precomputed-bit row calls are green.
  `__powidf2` and `__powisf2` are the only new emissions, advancing report-all
  from 443 / 236 / 207 to 443 / 238 / 205. Tier 2 and the single row-closure
  and shared-CFG Tier 3 are green. Continue with INBOX-39's pre-authorized
  half-to-double `fpext` composition successor targeting `__fmah`. Evidence
  `docs/evidence/std_debug_hello_sdiv_i32_by_two_acceptance.summary` and
  `docs/evidence/distribution_all_after_inbox39_sdiv2.summary`.

- 2026-07-13 (this commit, INBOX-39 pre-authorized successor) Item 12 scalar
  FP composition: exact `fpext half -> double` now calls the proven
  `__extendhfsf2` helper and applies the existing `cvtss2sd` operation to its
  XMM0 result. The first report honestly exposed a spill-frame boundary:
  admitted half casts synthesize scalar-SSE calls but frame preplanning only
  recognized explicit IR calls. These casts now reserve call-spill space
  through the existing frame authority. A permanent three-call preservation
  regression and 20 precomputed raw-half `__fmah` cases are green.
  `compiler_rt.fma.__fmah` is the sole closure, advancing report-all from
  443 / 238 / 205 to 443 / 239 / 204. Tier 2 and the row-closure/shared-frame
  Tier 3 are green. The INBOX-39 pipeline is exhausted; stop at the refreshed
  frontier before the agreed half-fcmp tranche. Evidence
  `docs/evidence/std_debug_hello_half_to_double_fpext_acceptance.summary` and
  `docs/evidence/distribution_all_after_inbox39_half_double.summary`.

- 2026-07-14 (this commit, INBOX-40 Part 1) Item 12 scalar FP comparison:
  exact half `fcmp uno/olt` now widens named operands through the proven
  `__extendhfsf2` helper and preserves two named operands through the existing
  pair-spill frame authority. Exact i16 signed-zero comparison and bitwise half
  select complete the captured min/max CFG. Permanent predicate, comparison,
  and select execution plus 26 precomputed native row calls are green.
  `compiler_rt.fmin.__fminh` and `compiler_rt.fmax.__fmaxh` are the two
  directed closures. `__fixunshfdi` and `__fixunshfsi` emit collaterally
  without semantic claims; no new failure appears. Report-all advances from
  443 / 239 / 204 to 443 / 243 / 200. Tier 2 and the single row-closure/shared
  selector Tier 3 are green. Continue with INBOX-40's pre-authorized half-add
  successor. Evidence `docs/evidence/std_debug_hello_half_fcmp_acceptance.summary`
  and `docs/evidence/distribution_all_after_inbox40_half_fcmp.summary`.

- 2026-07-14 (this commit, INBOX-40 pre-authorized successor) Item 12 scalar
  FP addition: exact half `fadd` now widens through `__extendhfsf2`, adds with
  `addss`, and truncates through `__truncsfhf2`. A finite-precision proof rules
  out double rounding: sums close enough to affect binary16 rounding fit
  exactly in binary32, while farther addends cannot reach a binary16 midpoint.
  The captured local half/pointer memory barrier, exact i16 immediate-left
  shift/sign predicates, and raw half literals complete the floor/ceil CFG.
  Permanent execution and 48 precomputed native row calls are green.
  `compiler_rt.floor_ceil.__floorh` and `__ceilh` are the two directed
  closures; `__fixhfsi` emits collaterally without a semantic claim. Report-all
  advances from 443 / 243 / 200 to 443 / 246 / 197. Tier 2 and the single
  row-closure/shared-frame Tier 3 are green. The INBOX-40 pipeline is exhausted;
  stop before the lanes-canonical vector-mask bridge, which requires its own
  directive. Evidence
  `docs/evidence/std_debug_hello_half_fadd_acceptance.summary` and
  `docs/evidence/distribution_all_after_inbox40_half_fadd.summary`.

- 2026-07-14 (this commit, INBOX-41) Item 12 canonical vector-mask bridge:
  the existing XMM vector location now records canonical two-lane masks with
  32/64-bit source widths, static definedness, and all-zero/all-one lanes.
  Packed fabs preserves every non-sign bit; FP-to-integer vector bitcasts
  retag without data movement; packed oeq and sign-biased unsigned i32 compare
  produce canonical masks; constant mask lanes extract through movmsk and the
  allocation-plan GPR authority. The existing pair-slot frame path owns mask
  spills. Permanent execution covers exact `__unordsf2`, fabs NaN payloads,
  both packed oeq widths, undefined-lane rejection, and standing fail-closed
  forms. The extracted relocation-free row passes eight precomputed native
  calls and is the only new emission, advancing report-all from 443 / 246 /
  197 to 443 / 247 / 196 with no collateral changes. Tier 2 and the single
  shared-shape Tier 3 are green. Stop for the aggregate-ABI architectural
  review; vector selects remain unauthorized. Evidence
  `docs/evidence/std_debug_hello_vector_mask_acceptance.summary` and
  `docs/evidence/distribution_all_after_inbox41_mask.summary`.

- 2026-07-14 (this commit, INBOX-42 slice 1) Item 12 exact SSE aggregate
  returns: the authoritative SysV classifier now admits only
  `{ <2 x float> }` in packed low XMM0 and `{ double, double }` in XMM0/XMM1.
  Typed terminal aggregate leaves reuse the existing value map, split returns
  use an alias-safe parallel copy, and classifier-derived verifier checks
  reject missing or partially defined return registers. A pinned-Zig
  `callconv(.c)` executable checks 24 raw fields spanning zeros, subnormals,
  finite values, infinities, and quiet/signaling NaN payloads. Report-all stays
  at 443 / 247 / 196 with the required zero closures: `__divdc3` advances to
  `llvm.maxnum.f64`, `__muldc3` to `<4 x double>` construction, and the f32
  complex rows to aggregate allocas. Tier 2 and the single shared-ABI/verifier
  Tier 3 are green. Continue with the pre-authorized aggregate stack-object
  successor, then stop; no third cycle is authorized. Evidence
  `docs/evidence/std_debug_hello_aggregate_sse_returns_acceptance.summary` and
  `docs/evidence/distribution_all_after_inbox42_aggregate_sse_returns.summary`.

- 2026-07-14 (this commit, INBOX-42 pre-authorized successor) Item 12 exact f32
  aggregate stack objects: a shared typed decoder admits only one 8-byte,
  4-aligned `{ float, float }` object through the existing frame authority.
  Typed base/current displacements, bounded constant byte GEPs, scalar f32
  stores, and an offset-zero packed load reuse the value map; pointer PHIs use
  ordinary 64-bit register/spill destinations. CFG liveness now preserves the
  existing pressure exemption for frame-owned PHI sources, and verifier XMM
  definedness covers the packed load forms. Permanent execution proves both
  object-selection branches bit-exactly, and five negative boundaries remain
  fail-closed. Report-all stays at 443 / 247 / 196 with zero closures and zero
  collateral emissions: `__divsc3` advances to `llvm.maxnum.f32` and
  `__mulsc3` to `<4 x float>` construction. Tier 2 and the shared-frame Tier 3
  are green. The INBOX-42 pipeline is exhausted; stop for review with no third
  cycle authorized. Evidence
  `docs/evidence/std_debug_hello_aggregate_object_acceptance.summary` and
  `docs/evidence/distribution_all_after_inbox42_aggregate_object.summary`.

- 2026-07-14 (this commit, INBOX-43 Part 1) Item 12 scalar FP intrinsic
  capability: exact `llvm.maxnum.f32/f64` now distinguishes either NaN before
  ordered comparison and merges equal operands bitwise for correct signed-zero
  ordering. The implementation reuses existing XMM comparisons, branches, and
  copies without adding a machine or allocation class. Permanent mmap execution
  covers 14 precomputed raw-bit cases; `minnum` remains fail-closed. Report-all
  stays at 443 / 247 / 196 with zero closures and collateral emissions:
  `__divdc3` advances to its vector-PHI destination and `__divsc3` to scalar
  `llvm.copysign.f32`. Tier 2 is green. Continue with INBOX-43's pre-authorized
  complete `<4 x float>` successor, which carries the single Tier 3 trigger.
  Evidence `docs/evidence/std_debug_hello_scalar_maxnum_acceptance.summary`.

- 2026-07-14 (this commit, INBOX-43 pre-authorized successor) Item 12 complete
  bounded f32x4 slice: four-bit static lane definedness, the exact captured
  construction and shuffle masks, packed arithmetic/fabs/oeq, lane-0/lane-2
  extraction, canonical mask-to-i4 lowering, and scalar `copysign.f32` now
  reuse the existing XMM and allocation authorities. Permanent execution found
  and prevented an upper-lane splat defect. The exact extracted row passes
  pinned-Zig finite, signed-zero, and infinite fallback calls; its pair spill
  uses the existing unaligned 16-byte frame path. Corrected physical
  XMM-destination definition tracking and packed aggregate return
  materialization close the verifier without weakening it.
  `compiler_rt.mulsc3.__mulsc3` is the sole emission, advancing report-all from
  443 / 247 / 196 to 443 / 248 / 195. Tier 2 and the single shared-shape Tier 3
  are green. The INBOX-43 pipeline is exhausted; stop for periodic review with
  no successor authorized. Evidence
  `docs/evidence/std_debug_hello_f32x4_mulsc3_acceptance.summary` and
  `docs/evidence/distribution_all_after_inbox43_f32x4.summary`.

- 2026-07-14 (this commit, INBOX-44) Item 12 read-only frontier ranking: the
  ten `icmp-form` rows separate into narrow i6/i7 unsigned-immediate,
  named-i16 predicate, and later `cttz.i64` capabilities; the seven switch-PHI
  rows separate into six EI entry-switch joins and the broader fma population.
  The complete `__divsc3` remainder supports an exact f32x2 canonical-mask
  select/copysign closing contract, while `__divdc3` retains a separate
  zero-closure vector-PHI planner boundary. I128 pair compare and byte swap are
  ranked as operation-specific leaves; `__muldc3` remains at the deferred
  256-bit checkpoint. No implementation or gate ran. The immediate next
  bounded work is the authorized Phase 0-1 distribution-all infrastructure
  interlude; two scalar capability pipelines follow under provisional
  Tier-2/native closure batching with one cumulative Tier 3 each. Evidence
  `docs/evidence/inbox44_frontier_ranking.md`.

- 2026-07-14 (this commit, self-declared P0 during INBOX-45) Item 12
  accumulator-alias correctness repair: focused native proof found that a
  destructive immediate binary operation preserved only one of multiple live
  EAX bindings created by a no-op truncation, silently changing another live
  value. Immediate scalar binary lowering now preserves every live accumulator
  binding using the existing liveness authority. The permanent regression
  fails on the accepted baseline (`expected 127007, found 126976`) and passes
  four exact cases after the repair. Tier 2 is green at 24/24 steps and 975/975
  tests; the mandatory P0 Tier 3 is green across all 17 subgates. No row closure
  is claimed. Resume and revalidate the preserved INBOX-45 comparison cycle
  against this repaired baseline. Evidence
  `docs/evidence/std_debug_hello_accumulator_alias_p0_repair.summary` and
  `docs/evidence/distribution_all_after_inbox45_accumulator_alias_p0.summary`.

- 2026-07-14 (this commit, fix-forward after `0717acf7`) Item 12 accepted-row
  audit: a structured IR/liveness scan conservatively found 15 functions that
  could contain multiple live sub-32-bit aliases across a destructive
  immediate operation. Eight were already failing and two were internal
  helpers without accepted per-function closure claims. The five intersecting
  accepted rows (`__floatsisf`, `__floatunsisf`, `__ashlsi3`, `__ashrsi3`,
  and `__lshrsi3`) each emit a nonempty, byte-identical object before and after
  the accumulator repair. Therefore no accepted closure hit the defect, no
  row is invalidated, and the row-exact re-proof rule does not activate. The
  preserved INBOX-45 comparison cycle may resume. Evidence
  `docs/evidence/inbox45_accumulator_alias_closure_audit.md`.

- 2026-07-14 (this commit, INBOX-45 Part 1) Item 12 normalized narrow unsigned
  comparisons: exact typed `samesign ult` and `samesign ugt` with i6/i7
  operands and in-range immediates now mask the source to its declared width
  before comparison; all other forms remain fail-closed. Exact native
  raw-half execution provisionally closes `__floatunsihf` and `__floatsihf`,
  moving the current report from 443 / 248 / 195 to 443 / 250 / 193. Tier 2 is
  green at 24/24 steps and 975/975 tests. The six predicted i64 conversion
  rows all advance to exact `llvm.cttz.i64`, authorizing INBOX-45 Part 2. No
  Tier 3 ran; the two closures remain provisional until the cumulative
  pipeline gate. Evidence
  `docs/evidence/std_debug_hello_inbox45_narrow_icmp.summary`.

- 2026-07-14 (this commit, INBOX-45 Part 2) Item 12 exact i64
  count-trailing-zeros: the composed selector now admits only
  `llvm.cttz.i64(i64, i1 immarg)` with literal flags 0/1, reusing the existing
  encoded and verified zero-defined machine operation. Exact extracted-row
  execution provisionally closes all six signed/unsigned i64-to-double,
  -float, and -half conversion rows with 75/75 precomputed bit-pattern calls.
  The current report moves from 443 / 250 / 193 to 443 / 256 / 187 with no
  collateral emissions. Tier 2 is green at 24/24 steps and 977/977 tests. No
  Tier 3 ran; all eight INBOX-45 closures remain provisional pending the one
  cumulative pipeline gate. Evidence
  `docs/evidence/std_debug_hello_inbox45_cttz_i64.summary`.

- 2026-07-14 (this commit, INBOX-45 cumulative acceptance) Item 12 pipeline A
  close: the single required Tier 3 passes all 17 subgates against committed
  tree `1d90ef75d73149eaa8aeb062e8640daee8330a3b`. It accepts all eight
  provisional conversion-row closures from Parts 1 and 2, making
  443 / 256 / 187 the accepted compiler_rt report state. Integrated objects
  remain 146/146 in all three pipelines, strict real rows remain 100/100/100,
  integrated executables remain 6/6, and release-source object/link/probe
  boundaries remain 100/100 each. Total reported duration is 2,268,761 ms,
  3.4% below the prior INBOX-43 run with no material runtime regression.
  Evidence
  `docs/evidence/distribution_all_after_inbox45_narrow_cmp_cttz_i64.summary`.

- 2026-07-14 (this commit, INBOX-46 Part 1) Item 12 exact named i16
  comparisons: non-`samesign` `slt`, `sgt`, and `ne` now sign-normalize both
  low-16-bit operands and reuse the existing i32 compare/setcc path; adjacent
  widths remain fail-closed. Exact extracted-row execution provisionally
  closes `__gehf2` and `__cmphf2` with 28/28 precomputed raw-half calls,
  moving report-all from 443 / 256 / 187 to 443 / 258 / 185 with no collateral
  emissions. Tier 2 is green at 24/24 steps and 980/980 tests. No Tier 3 ran;
  both closures remain provisional pending the single cumulative INBOX-46
  gate after the pre-authorized i128 pair-comparison successor. Evidence
  `docs/evidence/std_debug_hello_inbox46_named_i16.summary`.

- 2026-07-14 (this commit, INBOX-46 Part 2) Item 12 exact i128 pair
  comparisons: `llvm.ucmp.i32.i128` and `llvm.scmp.i32.i128` now compare the
  existing SysV argument pairs lexicographically, using signed high lanes and
  unsigned low lanes where required, and materialize -1/0/1 in EAX through
  existing machine forms. Exact extracted-row execution provisionally closes
  `__ucmpti2` and `__cmpti2` with 24/24 precomputed calls, moving report-all
  from 443 / 258 / 185 to 443 / 260 / 183 with no collateral emissions. Tier
  2 is green at 24/24 steps and 983/983 tests. No Tier 3 ran; all four
  INBOX-46 closures remain provisional pending the single cumulative pipeline
  gate. Evidence
  `docs/evidence/std_debug_hello_inbox46_i128_compare.summary`.

- 2026-07-14 (this commit, INBOX-46 cumulative acceptance) Item 12 pipeline B
  close: the single required Tier 3 passes all 17 subgates against committed
  tree `03c824c377765ac01cb1f53a47494f4ff602b12e`. It accepts all four
  provisional comparison-row closures from Parts 1 and 2, making
  443 / 260 / 183 the accepted compiler_rt report state. Integrated objects
  remain 146/146 in all three pipelines, strict real rows remain 100/100/100,
  integrated executables remain 6/6, and release-source object/link/probe
  boundaries remain 100/100 each. Total reported duration is 2,268,358 ms,
  effectively unchanged from INBOX-45. Evidence
  `docs/evidence/distribution_all_after_inbox46_named_i16_i128_compare.summary`.

- 2026-07-14 (this commit, INBOX-47 Part 1) Item 12 bounded f32x2 vector
  capability: exact canonical-mask select and `llvm.copysign.v2f32` now reuse
  the existing XMM shape and bitwise machine forms through lane-width helpers.
  Permanent execution also closes the captured row's previously missed exact
  packed unsigned `ult` comparison as the operand-swapped member of the
  existing `ugt` family. The exact extracted row passes five pinned-Zig
  finite, scaled, zero-denominator, infinite-numerator, and
  finite-over-infinite cases. `compiler_rt.divsc3.__divsc3` is the sole
  provisional emission, moving report-all from 443 / 260 / 183 to
  443 / 261 / 182 with no collateral emissions or new failures. Tier 2 is
  green at 24/24 steps and 986/986 tests. No Tier 3 ran; continue with the
  pre-authorized f64x2 parity successor, then accept the pipeline with its one
  cumulative gate. Evidence
  `docs/evidence/std_debug_hello_inbox47_f32x2_select_copysign.summary`.

- 2026-07-14 (this commit, INBOX-47 Part 2) Item 12 f64x2 parity capability:
  packed canonical-mask select, fabs, and copysign now share shape-driven
  implementations with f32x2; scalar `copysign.f32/f64` shares one
  width-parametric bitwise implementation. Exact f64x2 `[1,0]` and `[1,1]`
  masks extend the typed decoder and generalize the existing `shufpd` machine
  form without broadening selector admission. Permanent raw-bit execution
  covers both select lanes, zeros, subnormals, infinities, NaN payloads,
  shuffle definedness, and scalar/vector copysign. Report-all remains exactly
  443 / 261 / 182 with zero closures, collateral emissions, or new failures;
  `compiler_rt.divdc3.__divdc3` remains honestly blocked at its earlier
  `stage2-phi-dst` boundary. Tier 2 is green at 24/24 steps and 988/988 tests.
  No Tier 3 ran; commit this slice, then run the single cumulative INBOX-47
  gate and stop for the f64x2 PHI review. Evidence
  `docs/evidence/std_debug_hello_inbox47_f64x2_parity.summary`.

- 2026-07-14 (this commit, INBOX-47 cumulative acceptance) Item 12 vector
  pipeline close: the single required Tier 3 passes all 17 subgates against
  committed tree `6817bd3a46c4950e73945af7090c930f27bf768c`. It accepts the
  provisional `compiler_rt.divsc3.__divsc3` closure from Part 1; Part 2
  correctly contributes zero closures, making 443 / 261 / 182 the accepted
  compiler_rt report state. Integrated objects remain 146/146 in all three
  pipelines, strict real rows remain 100/100/100, integrated executables
  remain 6/6, and release-source object/link/probe boundaries remain 100/100
  each. Total reported duration is 2,274,150 ms, effectively unchanged from
  INBOX-46. Stop for the separately reviewed f64x2 PHI architecture; no
  implementation successor is authorized. Evidence
  `docs/evidence/distribution_all_after_inbox47_vector_pipeline.summary`.

- 2026-07-14 (this commit, INBOX-48) Item 12 bounded f64x2 PHI capability:
  stage2 now assigns fully defined `<2 x double>` PHI destinations to the
  existing XMM or pair-slot `.spill_vector` locations, and the existing
  parallel edge-copy authority preserves complete XMM shapes across crossed,
  duplicated, selected-edge, equal-location, and overlapping spill copies.
  Partial f64x2, other vector shapes, masks, constants, and scalar spill
  destinations remain fail-closed. Permanent raw-bit execution forces two
  crossed pair-spilled PHIs; Tier 2 is green at 24/24 steps and 991/991 tests.
  The fresh report stays 443 / 261 / 182 and differs only by advancing
  `compiler_rt.divdc3.__divdc3` from `stage2-phi-dst` to the later unreviewed
  `<2 x i64>` `composed-vector-extract-type` frontier. The expected closure
  and pinned-row proof therefore do not occur, and no closure is claimed.
  Run the required shared-CFG Tier 3 against this committed tree, then stop on
  the unexpected later frontier before the pre-authorized successor. Evidence
  `docs/evidence/std_debug_hello_inbox48_f64x2_phi.summary`.

- 2026-07-14 (this commit, INBOX-48 acceptance) Item 12 f64x2 PHI close:
  the single required Tier 3 passes all 17 subgates against committed tree
  `536f6a30e9c6f68ce2d1ea30174cf8fedf98db49`. Integrated objects remain
  146/146 in all three pipelines, strict real rows remain 100/100/100,
  integrated executables remain 6/6, and release-source object/link/probe
  boundaries remain 100/100 each. This accepts the reusable PHI capability
  with zero row closures; the compiler_rt report remains 443 / 261 / 182 and
  `__divdc3` remains unaccepted at its later `<2 x i64>` extraction frontier.
  Total reported duration is 2,283,788 ms, effectively unchanged from
  INBOX-47. Continue with the pre-authorized bit-permutation leaves pipeline.
  Evidence `docs/evidence/distribution_all_after_inbox48_f64x2_phi.summary`.

- 2026-07-14 (this commit, INBOX-48 successor) Item 12 exact bit-permutation
  leaves: exact typed `llvm.bswap.i128`, `llvm.bitreverse.i64`, and
  `llvm.bitreverse.i128` lowering reuses the existing pair spill/frame/value
  authorities and adds one encoded, assembled, and verified 64-bit RAX bit
  reversal operation. Wrong widths, unsupported call envelopes, other
  intrinsics, and `musttail` remain fail-closed. Permanent execution and a
  relocation-free extracted native object pass 14/14 precomputed cases. The
  fresh report moves exactly from 443 / 261 / 182 to 443 / 264 / 179, closing
  `__bswapti2`, `__bitreversedi2`, and `__bitreverseti2` provisionally with no
  collateral emission or new failure. Tier 2 passes 24/24 steps and 995/995
  tests. Commit the slice, then run one cumulative Tier 3 to accept the three
  closures. Evidence
  `docs/evidence/std_debug_hello_inbox48_bit_permutation.summary`.

- 2026-07-14 (this commit, INBOX-48 successor acceptance) Item 12
  bit-permutation pipeline close: the single cumulative Tier 3 passes all 17
  subgates against committed tree
  `23bf5cbdba0d9296c15f9baf7121527022c68a86`. This accepts the exact
  `__bswapti2`, `__bitreversedi2`, and `__bitreverseti2` closures, making
  443 / 264 / 179 the accepted compiler_rt report state. Integrated objects
  remain 146/146 in all three pipelines, strict real rows remain 100/100/100,
  integrated executables remain 6/6, and release-source object/link/probe
  boundaries remain 100/100 each. Total reported duration is 2,281,518 ms,
  effectively unchanged from the INBOX-48 PHI gate. Evidence
  `docs/evidence/distribution_all_after_inbox48_bit_permutation.summary`.

- 2026-07-14 (this commit, INBOX-49 Part 1) Item 12 exact i64x2 extraction:
  constant lanes 0 and 1 from fully defined `<2 x i64>` values now reuse the
  existing XMM/pair-spill shape, `unpckhpd`, and register-parametric `movq`
  paths. Permanent raw-bit execution covers both lanes and pair spills while
  partial, dynamic, wrong-width, and unrelated vector forms remain
  fail-closed. The fresh report moves exactly from 443 / 264 / 179 to
  443 / 265 / 178, provisionally closing `compiler_rt.divdc3.__divdc3` with
  no collateral change. Its extracted pinned-Zig native proof passes all five
  precomputed normal, scaled, zero-denominator, infinite-numerator, and
  finite-over-infinite cases through the five-edge return join. Tier 2 passes
  24/24 steps and 997/997 tests. No Tier 3 ran; continue with INBOX-49 Part 2
  and accept the complete pipeline with one cumulative gate. Evidence
  `docs/evidence/std_debug_hello_inbox49_i64x2_extract.summary`.

- 2026-07-14 (this commit, self-declared P0 during INBOX-49 Part 2) Item 12
  baseline-safe population count: the required audit confirmed that accepted
  `frontier_popcount_u32` and `compiler_rt.limb64.__popcount_limb64` objects
  emitted POPCNT despite captured `-popcnt` target attributes. The i32 machine
  operation and limb64 terminal routine now use software Kernighan loops; the
  latter retains all outer offsets by calling an appended helper through two
  same-width relative calls. Permanent execution, the existing mixed-numeric
  source harness, and an exact extracted limb64 object re-prove both accepted
  paths without POPCNT. Full unit passes 991/991 and Tier 2 passes 24/24 steps
  with 999/999 tests. The mandatory immediate wrong-code Tier 3 passes all 17
  subgates against staged tree `a938272b6c22a4cb07393de498cfc0d53223f498`.
  No closure or report movement is claimed. Commit the repair standalone,
  then resume the preserved INBOX-49 Part 2 capability. Evidence
  `docs/evidence/std_debug_hello_inbox49_popcount_baseline_p0.summary` and
  `docs/evidence/distribution_all_after_inbox49_popcount_p0.summary`.

- 2026-07-14 (this commit, INBOX-49 Part 2) Item 12 exact range-attributed
  population count: a shared typed decoder admits only `range(i64 0, 65)` for
  `llvm.ctpop.i64` and `range(i128 0, 129)` for `llvm.ctpop.i128`; malformed,
  unrelated, wrong-width, and unsupported call forms remain fail-closed. A
  baseline-safe 64-bit software operation is reused for both i128 limbs, with
  the existing pair-spill/frame authority and an exact sum. Permanent tests
  and the extracted relocation-free native object contain no POPCNT and pass
  12/12 precomputed width-boundary cases. The report moves exactly from
  443 / 265 / 178 to 443 / 267 / 176, provisionally closing `__popcountdi2`
  and `__popcountti2` with no collateral change. Tier 2 passes 24/24 steps and
  1004/1004 tests. Commit this slice, then run the cumulative INBOX-49 Tier 3
  to accept these rows together with Part 1's `__divdc3`. Evidence
  `docs/evidence/std_debug_hello_inbox49_popcount.summary`.

- 2026-07-14 (this commit, INBOX-49 cumulative acceptance) Item 12 pipeline
  close: the one cumulative Tier 3 passes all 17 subgates against committed
  tree `af36078479ed29e91040c24e9c6f4239a7143db7`. Integrated objects remain
  146/146 in all three pipelines, strict real rows remain 100/100/100, and
  source-owned native link, object inspection, and compatibility probes remain
  100/100 each. This accepts `__divdc3`, `__popcountdi2`, and `__popcountti2`,
  making 443 / 267 / 176 the accepted compiler_rt report state with no
  collateral emission or new failure. The standalone baseline-safe popcount
  P0 is also accepted independently at `76831275`. Stop for periodic review;
  no successor capability is authorized. Evidence
  `docs/evidence/distribution_all_after_inbox49_pipeline.summary`.

- 2026-07-14 (this commit, INBOX-50 Part 1) Item 12 preservation-frame
  false-rejection repair: stage-two planning now records selection-time
  preservation demand, and the shared frame authority reserves its existing
  spill area when live values cross a direct-call or exact absolute-value
  barrier. Single-block framed parameters receive stable homes only when the
  plan proves them live across such a barrier. Permanent execution covers
  quotient, remainder, and pointer-divmod shapes across 18 precomputed signed
  cases. The accepted-row audit found no prior accepted row could have
  traversed the exact defect because every no-frame dynamic spill propagates
  selection failure. The report moves from 443 / 267 / 176 to
  443 / 270 / 173, closing `__divmodsi4`, `__modsi3`, and `__divsi3`.
  `__divdi3` and `__divmoddi4` advance honestly to the separate unknown-pointer
  call boundary; no closure is claimed for them. Tier 2 passes 24/24 steps and
  1006/1006 tests. The immediate shared-frame Tier 3 passes all 17 subgates
  against staged implementation tree
  `0ec31119087ee5b2ca33e104582ae6e95742432e`, accepting the repair and three
  closures. Continue with the separately gated comparison-RHS pipeline.
  Evidence `docs/evidence/std_debug_hello_inbox50_frame_repair.summary` and
  `docs/evidence/distribution_all_after_inbox50_frame_repair.summary`.

- 2026-07-14 (this commit, INBOX-50 comparison cycle 1) Item 12 exact i16
  unsigned negative-literal comparison: LLVM constants in the signed-i16 to
  unsigned-i16 textual envelope now materialize as exact modulo-16-bit
  patterns for `ult`/`ugt`, with out-of-range constants and neighboring forms
  fail-closed. Permanent execution covers 22 threshold cases. Tier 2 passes
  24/24 steps and 1008/1008 tests. The report remains 443 / 270 / 173:
  `__mulhf3` advances to `composed-block-binary-width` and `__addhf3` advances
  to `composed-block-icmp-form`, so neither expected closure is claimed.
  Continue with the pre-authorized named i64 `ult` cycle and hold any closures
  for the comparison pipeline's cumulative Tier 3. Evidence
  `docs/evidence/std_debug_hello_inbox50_i16_negative_literal.summary`.

- 2026-07-14 (this commit, INBOX-50 comparison cycle 2) Item 12 exact named
  i64 unsigned less-than: plain named operands now reuse the existing two-
  scratch compare path with structurally fixed LHS/RHS order; samesign and
  neighboring forms remain fail-closed. Ten unsigned execution cases cover
  both asymmetric orders and the high-bit boundary. The report moves exactly
  from 443 / 270 / 173 to 443 / 272 / 171, provisionally closing
  `__truncdfsf2` and `__truncdfhf2`. A relocation-free extracted object passes
  46 frozen bit-exact float/half conversion calls across zeros, subnormals,
  rounding and overflow boundaries, infinities, and NaN payloads. Tier 2
  passes 24/24 steps and 1010/1010 tests. Commit, then run the comparison
  pipeline's one cumulative Tier 3; only these two closures are pending
  acceptance. Evidence
  `docs/evidence/std_debug_hello_inbox50_named_i64_ult.summary`.

- 2026-07-14 (this commit, INBOX-50 comparison acceptance) Item 12 pipeline
  close: the one cumulative Tier 3 passes all 17 subgates against committed
  tree `b55085f16351d6af65d686b262798374294525dc`. This accepts
  `__truncdfsf2` and `__truncdfhf2`, making 443 / 272 / 171 the accepted
  compiler_rt report state. The modulo-i16 cycle is accepted as a reusable
  capability with zero closures; `__mulhf3` and `__addhf3` remain at their
  later frontiers. Integrated objects remain 146/146 in all three pipelines,
  strict real rows remain 100/100/100, and release-source object/link/probe
  boundaries remain 100/100 each. Stop for review; no third pipeline is
  authorized. Evidence
  `docs/evidence/distribution_all_after_inbox50_comparison.summary`.

- 2026-07-14 (this commit, self-declared P0 during INBOX-51) Item 12 scalar
  fneg correctness: executable `__subdf3` evidence proved the composed
  selector lowered parser-normalized fneg as arithmetic `-0 - value`, losing
  exact NaN sign/payload semantics. Exact f32/f64 negative-zero forms now use
  the existing parameterized XMM XOR operation; ordinary subtraction remains
  unchanged. Permanent execution covers zeros, subnormals, normals,
  infinities, and both quiet/signaling NaN signs. The accepted-row audit found
  one prior hit, collateral `__subsf3`, and its extracted row is re-proven
  alongside the unaffected single-block negation controls in 34/34 pinned-Zig
  calls. The clean report remains 443 / 272 / 171; full unit passes 1005/1005
  and Tier 2 passes 24/24 steps with 1013/1013 tests. The mandatory immediate
  Tier 3 passes all 17 subgates against standalone staged tree
  `30c201aed2c45bf782e548205a948193408b9310`. Actual wall time is approximately
  1,682 seconds; summed concurrent child duration is 2,380.478 seconds. Commit
  the isolated repair, then resume the preserved INBOX-51 select cycle.
  Evidence `docs/evidence/std_debug_hello_inbox51_scalar_fneg_p0.summary` and
  `docs/evidence/distribution_all_after_inbox51_fneg_p0.summary`.

## Ratchet State

Latest recorded counters. Update in the same commit as the change; the
authoritative history with denominator metadata lives in the cited evidence
summaries.

| Counter | Value | Modes | Evidence | Denominator (candidate hash / selector / pin) |
| --- | ---: | --- | --- | --- |
| real_functions_lowered | 100 | ReleaseFast, ReleaseSafe, ReleaseSmall | `docs/evidence/real_rows_strict_limit100_after_intcast_safe.summary` | candidate=`83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d`; selector=`real-candidate-selector-v2`; pin=`bdee02bc0c7f227c0f11bc9a449df673fe803540` |
| real_objects_emitted | 100 | ReleaseFast, ReleaseSafe, ReleaseSmall | `docs/evidence/real_rows_strict_limit100_after_intcast_safe.summary` | candidate=`83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d`; selector=`real-candidate-selector-v2`; pin=`bdee02bc0c7f227c0f11bc9a449df673fe803540` |
| real_native_linked | 100 | ReleaseFast, ReleaseSafe, ReleaseSmall | `docs/evidence/real_rows_strict_limit100_after_intcast_safe.summary` | candidate=`83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d`; selector=`real-candidate-selector-v2`; pin=`bdee02bc0c7f227c0f11bc9a449df673fe803540` |
| real_executed | 0 | ReleaseFast, ReleaseSafe, ReleaseSmall | `docs/evidence/real_rows_strict_limit100_after_intcast_safe.summary` | candidate=`83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d`; selector=`real-candidate-selector-v2`; pin=`bdee02bc0c7f227c0f11bc9a449df673fe803540` |
| real_programs_ok | 1 | ReleaseFast, ReleaseSafe, ReleaseSmall | `docs/evidence/zig_integrated_exe_syscall_hello.summary` | enforcement=`distribution-zig-integrated-exe`; pin=`bdee02bc0c7f227c0f11bc9a449df673fe803540` |
| unsupported_functions (ReleaseFast, compiler-core-module) | 55479 | ReleaseFast | `docs/evidence/real_candidates_releasefast_v1.summary` | candidate=`eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204`; selector=`real-candidate-selector-v1`; pin=`141bfce0883017ff7ebe03e3af3db07fff0c5dc3` |

Fixture-frontier counters (`generic_cfg_functions=753`,
`executable_ok_rows=14`) remain tracked by the family checklist and gate
logs; they are debugging-corpus health, not convergence progress, and are
deliberately not ratcheted here.
