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
  source/function-name admission, `distribution-all` green before every
  commit, no weakening captured rows or golden files without behavioral
  verification, recognizer three-strikes escalation per the item 15 note
  (count stands at 1), and `real_executed=0` remains correct until a
  selector version lifts determinism marks via a ratchet-migration note.
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
  soft-float/libm/conversion selector bucket. `distribution-all` must stay
  green before every commit; if captured rows regress, use the loop-sum bisect
  discipline before proceeding.

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
| Debug compiler_rt | std-hello | 443 selected | 130 emitting | 313 failures | `docs/evidence/std_debug_hello_udivei5_frame32_pointer_phi.summary` |

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
| `real-program object-emission compiler_rt soft-float/libm/conversion selector candidates` | 236 | Open | 0 | Report-all object emission on the current Debug std-hello compiler_rt module found the largest remaining selector/codegen bucket in soft-float, libm-style, complex-float, comparison, and float/int conversion helpers after separating 23 tail-call ABI rows. Representative first selector failure is `compiler_rt.trunc.__trunch`; non-tail diagnostics are `UnsupportedCodegenControlFlow` 225 and `UnsupportedCodegenInstruction` 11. Mechanical family/diagnostic buckets before tail-call separation were 180 across 157 namespace families, which triggered the item-15 architectural review before implementing this cluster. Evidence `docs/evidence/std_debug_hello_compiler_rt_report_all.summary`; full log `tmp/std_debug_hello_debug_report_all.log` |
| `real-program object-emission compiler_rt integer helper selector candidates` | 32 | Open | 10 | Report-all object emission found the integer helper selector/codegen bucket after separating 21 tail-call ABI rows from the historical 66-row integer helper cluster. Composed-selection proofs now emit all three parity rows, `compiler_rt.parity.__paritysi2`, `compiler_rt.parity.__paritydi2`, `compiler_rt.parity.__parityti2`, `compiler_rt.mulo.__mulosi4`, `compiler_rt.int.__umoddi3`, `compiler_rt.int.__moddi3`, `compiler_rt.udivmod.__umodti3`, `compiler_rt.udivmod.__modti3`, `compiler_rt.mulXi3.__mulsi3`, and `compiler_rt.mulXi3.__multi3` through block-local per-instruction selection with explicit operand and register assignment. Stage-two pressure diagnostics record `compiler_rt.udivmodei4.__udivei5` and `compiler_rt.udivmodei4.__umodei4` as boundary rows, not next fix targets. The latest composed row, `__multi3`, is the first allocator acceptance row: INBOX-4 identified the executable failure as a frame-layout collision, and the composed selector now assigns non-overlapping 8-byte spill slots under one frame authority so the z_llvm-emitted `__multi3`/`__modti3` object computes correct results in the integrated executable proof. INBOX-5 then hardened the same proof by adding disp32 frame-slot encodings for offsets past 127, correcting high-register instruction-size accounting so ELF relocations target the actual call immediate, making integrated-exe exit-code mismatches fail closed, and clobbering `rcx` before RHS spill64 reloads from the single value-location map. INBOX-6 is acknowledged by generalizing machine frame indexes from a fixed enum namespace into data slots while keeping spill objects inside the same frame authority as LLVM RegAllocFast `StackSlotForVirtReg` / `MFI->CreateSpillStackObject`. INBOX-7 is acknowledged by materializing scalar spill locations at operand use for 32-bit and 64-bit operands through that same single value-location map. The proof prebuilds the no-std `_start` harness as a normal patched-Zig object and links it with selector-emitted compiler_rt objects, keeping the row closure on the composed compiler_rt bodies rather than a wrapper CFG dependency. The parked `__udivei5` retry now uses the corrected 32-slot frame envelope, pointer-phi support, `llvm.assume` no-op lowering, exact `tail fastcc i16 @zig.target.intByteSize(i16 ...)` helper-call lowering, data-backed frame indexes, allocation-plan-sized spill reservation, scalar spill-location consumption, narrow-to-i64 zext lowering through a 32-bit accumulator write, dynamic byte-pointer GEP lowering, i64 immediate AND lowering through RCX and RAX, nonzero i64 equality-immediate lowering, and named i64 equality lowering; Debug compiler_rt report-all remains 130 emitting / 313 failing, and the first failure remains `__udivei5` but now at `no_emitter` / `composed-block-icmp-form`. Resume the integer-helper bucket at that comparison-predicate frontier, then continue remaining rows in rank order while keeping intervening tail-call rows in the separate ABI family and recording each row's envelope fit or live-value count. Current item-15 accounting is composed-selection rows 10, terminal-template rows 17 (15 limb64 plus `__udivei4` and `__umodei5`), stage-two-boundary rows 2, allocator-acceptance rows 0 pending, and open integer-helper fallback candidates 32. Evidence `docs/evidence/std_debug_hello_udivei5_pressure.tsv`; `docs/evidence/std_debug_hello_umodei4_pressure.tsv`; `docs/evidence/std_debug_hello_udivei5_frame32_pointer_phi.summary`; `docs/evidence/std_debug_hello_umodti3_composed.summary`; `docs/evidence/std_debug_hello_modti3_composed.summary`; `docs/evidence/std_debug_hello_mulsi3_composed.summary`; `docs/evidence/std_debug_hello_multi3_pressure.tsv`; `docs/evidence/std_debug_hello_multi3_gap_inventory.tsv`; `docs/evidence/zig_integrated_exe_i128_arithmetic.summary`; `docs/evidence/distribution_all_after_multi3_single_frame.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_inbox5.summary`; `docs/evidence/distribution_all_after_inbox5.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_inbox7.summary`; `docs/evidence/distribution_all_after_inbox7.summary`; `docs/evidence/std_debug_hello_udivei5_zext_width.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_zext_width.summary`; `docs/evidence/distribution_all_after_zext_width.summary`; `docs/evidence/std_debug_hello_udivei5_gep_source.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_gep_source.summary`; `docs/evidence/distribution_all_after_gep_source.summary`; `docs/evidence/std_debug_hello_udivei5_and64_imm.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_and64_imm.summary`; `docs/evidence/distribution_all_after_and64_imm.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_eq_imm.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_eq_imm.summary`; `docs/evidence/distribution_all_after_icmp_eq_imm.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_eq_values.summary`; `docs/evidence/zig_integrated_exe_i128_arithmetic_icmp_eq_values.summary`; `docs/evidence/distribution_all_after_icmp_eq_values.summary` |
| `real-program object-emission compiler_rt stage-two pressure boundary rows` | 2 | Boundary | 0 | `compiler_rt.udivmodei4.__udivei5` and `compiler_rt.udivmodei4.__umodei4` were the parked six-slot pressure-boundary rows. The corrected frame authority makes the stage-two spill envelope allocation-plan-sized while preserving the historical 32-slot floor for existing stack-array rows. The `__udivei5` retry now passes the old pressure gate, pointer phi binding, well-formed `llvm.assume` calls, the exact `tail fastcc i16 @zig.target.intByteSize(i16 ...)` helper call, the old fixed frame-slot namespace cap, scalar spill-location consumption, narrow-to-i64 zext lowering, dynamic byte-pointer GEP lowering, i64 immediate AND lowering, nonzero i64 equality-immediate lowering, and named i64 equality lowering, then fails closed at `no_emitter` / `composed-block-icmp-form`; that is the next narrow frontier for this row. Saved old pressure data remains useful as the historical six-slot boundary: `__udivei5` max live values `16`, old spill slots needed `10`, first six-slot-envelope exceedance `Then8.prol` / `live_out` at live values `13`; `__umodei4` max live values `21`, old spill slots needed `15`, first six-slot-envelope exceedance `Then9.prol` / `live_out` at live values `13`. Evidence `docs/evidence/std_debug_hello_udivei5_pressure.tsv`; `docs/evidence/std_debug_hello_umodei4_pressure.tsv`; `docs/evidence/std_debug_hello_udivei5_frame32_pointer_phi.summary`; `docs/evidence/std_debug_hello_udivei5_zext_width.summary`; `docs/evidence/std_debug_hello_udivei5_gep_source.summary`; `docs/evidence/std_debug_hello_udivei5_and64_imm.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_eq_imm.summary`; `docs/evidence/std_debug_hello_udivei5_icmp_eq_values.summary` |
| `real-program object-emission compiler_rt tail-call ABI family` | 44 | Open | 0 | Report-all object emission found 44 `UnsupportedTailCallAbi` rows across compiler_rt: 23 in soft-float/libm/conversion helpers and 21 in integer helper families. This is tracked as a separate ordinary ABI family, not an item-15 selector concern. Evidence `docs/evidence/std_debug_hello_compiler_rt_report_all.summary`; full log `tmp/std_debug_hello_debug_report_all.log` |
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
