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
