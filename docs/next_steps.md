# Next Steps

This file is only for short-lived blocker and handoff notes.

The durable implementation queue is:

- `docs/roadmap/convergence_progress.md` (live tracker; the strategy
  reference is `docs/roadmap/end_to_end_convergence_plan.md`)

The family tactic list, used when a convergence goal directs family work:

- `docs/roadmap/x86_64_compiler_core_family_checklist.md`

The worker cycle rules are:

- `docs/working-cycle.md`

Do not use this file as a routine progress log. Normal implementation cycles
should check off completed items in `docs/roadmap/convergence_progress.md`,
update its Ratchet State table when counters changed, and check off family
items in the family checklist when the goal was a family item.

## Current Operating Rule

Pick the cycle goal in this order:

1. the first failing `distribution-real-rows` entry, when that gate exists;
2. the first failing real-program milestone gate, when it exists;
3. the first unchecked item in `docs/roadmap/convergence_progress.md`,
   top to bottom.

Stay on the selected goal until:

- the goal is complete;
- the next step needs hook-contract or architectural review;
- validation exposes an unexpected blocker.

## Active Blocker

INBOX-53 phase 2 is complete and accepted. Commit `4fc11d68` extends only the
existing stage-two scalar PHI source/copy authority; its Tier 3 passes all 17
subgates against committed tree
`2a5a2889f848521a7cb125ad1bc2390e696d68de`. The report remains 443 / 278 /
165 with zero closures and six FP-to-i128 advances. The crossed-i128 canary
found a latent sequential-copy defect, but the frozen-module audit found no
accepted-row hit. Stop and request review of the frozen Phase 3 exact six-row
EI entry-switch-edge contract before implementation. EI loop work, fma
widening, and preopt sharding remain unauthorized. Evidence:
`docs/evidence/std_debug_hello_inbox53_phase2_multiway_phi.summary` and
`docs/evidence/distribution_all_after_inbox53_phase2.summary`.

INBOX-50 Part 1 is complete and accepted. Preservation demand now participates
in the existing stage-two plan and shared frame reservation, with stable homes
only for single-block parameters proven live across a preservation barrier.
The report moves from 443 / 267 / 176 to 443 / 270 / 173, closing
`__divmodsi4`, `__modsi3`, and `__divsi3`; `__divdi3` and `__divmoddi4`
advance honestly to the separate unknown-pointer call boundary. The accepted-
row audit found no prior accepted hit. The immediate Tier 3 passes all 17
subgates against staged implementation tree
`0ec31119087ee5b2ca33e104582ae6e95742432e`. Evidence:
`docs/evidence/std_debug_hello_inbox50_frame_repair.summary` and
`docs/evidence/distribution_all_after_inbox50_frame_repair.summary`.

Continue with the pre-authorized INBOX-50 comparison-RHS pipeline: exact
modulo-i16 negative-literal unsigned comparisons first, refresh and commit,
then operand-order-safe named i64 `ult`. Hold the four expected closures
provisional until one cumulative Tier 3 at the end. No third pipeline is
authorized.

Comparison cycle 1 is complete with zero provisional closures. Exact modulo-
i16 negative literals advance `__mulhf3` to `composed-block-binary-width` and
`__addhf3` to `composed-block-icmp-form`; both remain failing and those later
forms stay out of scope. Continue at exact named i64 `ult`, targeting
`__truncdfsf2` and `__truncdfhf2`, then run the pipeline's cumulative Tier 3.
Evidence: `docs/evidence/std_debug_hello_inbox50_i16_negative_literal.summary`.

Comparison cycle 2 is complete provisionally. Exact plain named i64 `ult`
closes `__truncdfsf2` and `__truncdfhf2` through 46 frozen bit-exact native
calls, moving the report to 443 / 272 / 171 with no collateral change. Commit
the cycle and run the pipeline's one cumulative Tier 3; it accepts two total
closures because cycle 1 advanced rather than closed its half rows. Evidence:
`docs/evidence/std_debug_hello_inbox50_named_i64_ult.summary`.

INBOX-50 comparison acceptance is complete. The cumulative Tier 3 passes all
17 subgates against committed tree
`b55085f16351d6af65d686b262798374294525dc`, accepting `__truncdfsf2` and
`__truncdfhf2` and making 443 / 272 / 171 the accepted report state. The i16
cycle is accepted with zero closures and its two later half frontiers remain
open. Stop for review: no third pipeline is authorized. Evidence:
`docs/evidence/distribution_all_after_inbox50_comparison.summary`.

The self-declared INBOX-51 scalar-fneg P0 is accepted. Its native `__subdf3`
proof confirmed that composed scalar fneg used arithmetic subtraction and
failed to toggle RHS NaN signs exactly. The standalone XOR repair re-proves
accepted collateral `__subsf3`; its immediate Tier 3 passes all 17 subgates
against staged tree `30c201aed2c45bf782e548205a948193408b9310`. Actual wall
time is approximately 1,682 seconds versus 2,380.478 seconds of summed child
duration. Commit the repair alone, restore the INBOX-51 stash, and resume its
focused validation. Evidence:
`docs/evidence/std_debug_hello_inbox51_scalar_fneg_p0.summary` and
`docs/evidence/distribution_all_after_inbox51_fneg_p0.summary`.

INBOX-51 is complete and accepted after the P0 revalidation. Exact
select-owned i64 literal materialization closes `__floatsidf`, `__fixdfdi`,
`__fixsfdi`, `__fixhfdi`, `__adddf3`, and `__subdf3`, moving the report to
443 / 278 / 165. The extracted six-row object passes 75/75 frozen checks and
Tier 2 passes 24/24. The conditional named-bitcast-select successor is skipped
because the refreshed bodies already clear that form. The cumulative Tier 3
passes all 17 subgates against committed tree
`02b0100c022ded30fe2c2b90e9d4159b2e12a49e`; actual wall time is 1,657.823
seconds versus 2,363.022 seconds of summed child duration. Stop for periodic
review #13 and the switch-PHI/EI program design discussion. INBOX-52 remains
queued and has not started. Evidence:
`docs/evidence/std_debug_hello_inbox51_select_immediate.summary` and
`docs/evidence/distribution_all_after_inbox51_select_pipeline.summary`.

INBOX-52 is complete and accepted. Commit `6d5d3ad6` makes the integrated
release gate produce one atomic, manifest-verified 100-object bundle per
`distribution-all` run; object inspection, native-link, and linker probe reuse
that exact content while every native execution still runs. Focused gates
remain independently invocable. The same-state fresh/cached Tier-3 pair passes
all 17 subgates and schema 2 matches 1,262 canonical records. Cached actual
wall time falls from the accepted 1,678.60-second baseline to 1,337.819
seconds, saving 340.781 seconds (20.30%); summed child duration is
2,021.645 seconds and is not wall time. Stop after this bounded slice.
Preopt sharding or wider DAG/concurrency work requires a separate reviewed
directive. The switch-PHI/EI program is also pending the architectural
direction from periodic review #13. Evidence:
`docs/evidence/distribution_all_inbox52_artifact_reuse.summary`.

INBOX-48 is complete and accepted. Commit `1c5ff956` adds exact fully defined
f64x2 PHI destinations through the existing XMM/pair-spill value map and
parallel edge-copy authority. The single Tier 3 passed all 17 subgates against
tree `536f6a30e9c6f68ce2d1ea30174cf8fedf98db49`; strict real rows remain
100/100/100 and integrated executables remain 6/6. The accepted compiler_rt
report remains 443 selected / 261 emitting / 182 failing. Evidence:
`docs/evidence/distribution_all_after_inbox48_f64x2_phi.summary`.

INBOX-49 is complete and cumulatively accepted. Exact full-defined
`<2 x i64>` extraction closes `compiler_rt.divdc3.__divdc3`; exact range-
attributed `llvm.ctpop.i64/i128` software lowering closes `__popcountdi2` and
`__popcountti2`. The report moves from the prior accepted 443 / 264 / 179 to
443 / 267 / 176 with no collateral change. The pinned-Zig proofs pass 5/5
five-edge complex-division cases and 12/12 relocation-free popcount cases,
with no POPCNT. The cumulative Tier 3 passes all 17 subgates on committed
tree `af36078479ed29e91040c24e9c6f4239a7143db7`. Evidence:
`docs/evidence/std_debug_hello_inbox49_i64x2_extract.summary`,
`docs/evidence/std_debug_hello_inbox49_popcount.summary`, and
`docs/evidence/distribution_all_after_inbox49_pipeline.summary`.

Stop for the INBOX-49 periodic review. No successor is authorized;
`__muldc3` remains deferred at the 256-bit/AVX checkpoint, and the review must
rank the remaining switch-PHI/EI population against the roughly 15-20-row
reachable endgame.

The audit confirmed a P0 baseline-ISA violation in both accepted
`frontier_popcount_u32` and `compiler_rt.limb64.__popcount_limb64` paths.
The standalone software repair and row-exact re-proofs are accepted; its
mandatory immediate Tier 3 passed all 17 subgates. Evidence:
`docs/evidence/std_debug_hello_inbox49_popcount_baseline_p0.summary`. The new
range-attributed capability is kept out of that repair commit and is recorded
separately above. Full-gate evidence:
`docs/evidence/distribution_all_after_inbox49_popcount_p0.summary`.

The user-authorized Phase 0-1 infrastructure interlude is complete. Schema-2
comparison matched 1,258 semantic records across all 17 gates. The historical
14/17 `cache_status=none` population is now correctly classified as 14 gates
with unreported cache telemetry, not 14 proven cache misses. The same-state
fresh/cached pair took 37.81/27.98 minutes of actual wall time; the familiar
~39-minute cached number is summed child duration and double-counts the three
concurrent real-row gates. Phase 1 compiled-tool reuse remains a no-go because
compilation/startup is not isolated at the required 10% threshold. Do not
begin Phase 1, Phase 2, broader caching, or concurrency work from this result.
Evidence: `docs/evidence/distribution_all_phase0_1_observability.summary`.

`compiler_rt.mulo.__muloti4` is closed through exact object emission,
native link, executable signed-overflow checks, and its pressure diagnostic.
Debug compiler_rt report-all is now 443 selected / 137 emitting / 306 failing;
the global first failure crosses into the soft-float cluster at
`compiler_rt.trunc.__trunch`. Per the standing INBOX-9 sequence, continue the
separately ranked integer-helper bucket before crossing into soft-float
implementation work. `compiler_rt.mulo.__mulodi4` is now closed through exact
object emission, native link, executable signed-overflow checks, and pressure
acceptance. Continue in rank order at `compiler_rt.mulvsi3.__mulvsi3`; its
exact empty cold bundle on `llvm.assume` is admitted and the row now fails
closed through exact trap-block ownership, native link, executable SIGILL, and
pressure acceptance. The generic multi-use binary lifetime fix then closes
`__subvdi3`, `__subvsi3`, `__addvdi3`, and `__addvsi3`; continue in rank order
at `compiler_rt.negv.__negvsi2`. Its i32 minimum equality and immediate-left
subtraction are now closed through exact object emission, native link,
executable positive/negative checks, and pressure acceptance. Zero-left i128
subtraction and framed terminal traps then close
`compiler_rt.negv.__negvti2` and `compiler_rt.absvti2.__absvti2`, with
exact native and executable SIGILL evidence. Immediate-left i64 subtraction and
live-RAX preservation then close `compiler_rt.negv.__negvdi2` and
`compiler_rt.absvdi2.__absvdi2`; the exact native harness caught the stale
absolute-value binding before acceptance. Continue in rank order at
`compiler_rt.absvsi2.__absvsi2`. Width-correct i32 absolute value and live-EAX
preservation now close that row through exact native execution and pressure
acceptance. Excluding intervening tail-call ABI rows, continue at
`compiler_rt.mulXi3.__muldi3` at `composed-block-binary-op`. Named i32
multiplication and fail-closed EAX preservation now close that row through
exact decomposed native execution and pressure acceptance. Excluding
intervening tail-call ABI rows, continue at `compiler_rt.int.__udivmodsi4`.
Frame-backed phi destinations now extend its three-register phi pool through
the single spill authority, with executable four-phi loop coverage. The row
then advances through narrow scalar select lowering, with executable true and
false boolean outcomes. Zero-defined `llvm.ctlz.i32` lowering then advances
the row through i32 unsigned-greater immediate lowering to
named i32 equality and then `composed-block-call-form` at its first
`llvm.fshl.i32`. A general `shldl` machine form and intrinsic lowering advance
the row through funnel shifts. Concrete frame-index validation then removes
the false `stage2-phi-src-spill64` rejection caused by unrelated later spill
allocation; the row now fails closed at `composed-block-icmp-form`.
i32 inequality against zero then clears the body, while exact native execution
drives frame sizing, width-correct spill copies, stable framed parameter homes,
and parallel phi-edge alias preservation to correctness. `__udivmodsi4`,
`__udivsi3`, and `__umodsi3` now close through exact native execution and
pressure acceptance. Excluding intervening tail-call ABI rows, continue at
`compiler_rt.int.__udivmoddi4`. Its unsigned-subtract overflow tuples are now
pressure-exempt, advancing the row from `stage2-unsupported-value` to
`stage2-phi-restore-loc`. Conservative per-planned-value frame homes then
advance it through pointer equality with null and i64 stores through spilled
pointers. Named i32 unsigned comparisons, width-parametric division/remainder,
and unsigned overflow arithmetic then make the row emit. Exact native execution
drives CFG live-out intervals and stable frame-backed branch and phi state;
`__udivmoddi4` now closes through five executable quotient/remainder paths at
17 live values and 11 required spill slots. After the INBOX-16 test split,
`__ashlsi3`, `__lshrsi3`, `__lshrdi3`, and `__ashldi3` now close after
current-position accumulator preservation repairs parallel phi-edge copies.
`__ashrdi3` and `__ashrsi3` now close through immediate and variable i32 SAR
forms plus exact native signed execution. Frame-stabilized parallel phi sources
then close `__lshrti3`, `__ashrti3`, and `__ashlti3` through 18 exact native
boundary cases. The integer selector bucket is now closed: 43 composed rows
plus `__udivei4` and `__umodei5` account for all 45 non-tail rows. Stop at
soft-float `compiler_rt.trunc.__trunch` for user direction.
Current item-15
accounting is 43 composed rows, 17 terminal-template rows, zero stage-two
boundary rows, and 0 open integer-helper fallback candidates. The 21 remaining
integer-family `UnsupportedTailCallAbi` rows stay in the separate ABI family.

Current operating note recorded 2026-07-10:

- Active convergence-progress item: item 15 remains pulled forward as an
  architectural migration under item 12's std-hello real-program track. INBOX-4
  is acknowledged: the `__multi3` executable failure was a frame-layout
  collision, and the correction follows LLVM `RegAllocFast.cpp`
  `StackSlotForVirtReg` lines 481-500 / `MFI->CreateSpillStackObject(Size,
  Alignment)` line 497 by treating spill slots as ordinary frame objects rather
  than a parallel offset namespace. INBOX-5 is also acknowledged: the follow-up
  hardening fixed disp32 frame-slot encodings for offsets past 127, stale
  high-register instruction-size accounting that could misplace ELF
  relocations, integrated-exe expected-exit mismatch handling, and the missing
  `rcx` clobber before RHS spill64 reload. INBOX-6 is acknowledged: the fixed
  machine-layer frame-slot namespace cap is removed by making frame indexes
  data slots, while preserving the same single-frame authority invariant
  named by INBOX-4. INBOX-7 is acknowledged: scalar spill locations now
  materialize at operand use for 32-bit and 64-bit operands through the single
  value-location map, moving the parked `__udivei5` retry to the next
  fail-closed selector frontier. INBOX-8 is acknowledged: capability work now
  leads the cycle, and refactor interludes are limited to one touched file per
  completed capability slice. The real-row track remains closed through
  item 10 at strict `--limit=100`, but every stop report still states both
  tracks.
- Real-row track status: strict `distribution-real-rows --strict --limit=100`
  is green in ReleaseFast, ReleaseSafe, and ReleaseSmall, and
  `distribution-all` enforces that strict limit. Selector-v2 ReleaseFast
  report-mode `distribution-real-rows --mode=ReleaseFast --limit=200` remains
  green through typed lowering, x86_64 object emission, and native link with
  counters `real_functions_lowered=200`, `real_objects_emitted=200`,
  `real_native_linked=200`, `real_executed=0`, `real_programs_ok=0`.
- Real-program track status: item 11 syscall hello is closed by
  `docs/evidence/zig_integrated_exe_syscall_hello.summary`. Item 12 std hello
  remains open. Item 15 stage one closed 15 limb64 terminal selector routines,
  and the interrupted integer-helper work left `__udivei4` and `__umodei5` as
  validated terminal-template routines. The composed selector now also closes
  `compiler_rt.udivmod.__umodti3` as an i128 stack out-param direct-call
  wrapper, `compiler_rt.udivmod.__modti3` as a signed i128 stack out-param
  direct-call wrapper with bounded pair spills, and
  `compiler_rt.mulXi3.__mulsi3` as a composed i32 multiply loop. This cycle
  closes `compiler_rt.mulXi3.__multi3` as the first allocator acceptance row:
  the focused proof z_llvm-emits a `__multi3`/`__modti3` object, links it into a
  no-std executable-style harness, verifies both computed results at runtime,
  and now fails closed on wrong expected process exits. Current item-15
  accounting is composed-selection rows 12,
  terminal-template rows 17, recognizer fallback rows 32 in the open
  integer-helper bucket, stage-two-boundary rows 0, and no allocator acceptance
  row pending. Pressure diagnostics:
  `compiler_rt.mulXi3.__multi3` recorded `max_live_values=10`,
  `max_spill_slots_needed=4`, `max_spill_slots_over_envelope=0`,
  `first_exceed_block=-`, and no six-slot-envelope exceedance before closure;
  closed `compiler_rt.udivmodei4.__udivei5` now records
  `max_live_values=19`, `max_spill_slots_needed=13`,
  `max_spill_slots_over_envelope=0`, and no first exceedance under the
  32-slot frame;
  closed `compiler_rt.udivmodei4.__umodei4` now records
  `max_live_values=24`, `max_spill_slots_needed=18`,
  `max_spill_slots_over_envelope=0`, and no first exceedance under the
  32-slot frame. Both parked stage-two pressure rows are closed. The exact
  `__umodei4` body emits, native-links with `-fno-lld`, and the executable
  canary covers aliased accumulator operands. Debug compiler_rt report-all is
  now 443 selected / 132 emitting / 311 failing, with first failure
  `compiler_rt.divmodei4.__divei4` at `unsupported_type` / `call-ret`.
- First failing real row/stage beyond the enforced prefix: none known after
  the strict `--limit=100` close.
- Strict ratchet `real_*` counters:
  `real_functions_lowered=100`, `real_objects_emitted=100`,
  `real_native_linked=100`, `real_executed=0`, `real_programs_ok=1`.
- Current candidate denominator:
  `docs/evidence/real_candidates_release_v2.tsv`,
  hash
  `83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d`,
  selector `real-candidate-selector-v2`, Zig pin
  `bdee02bc0c7f227c0f11bc9a449df673fe803540`.
- Enforcement state: `distribution-all` runs
  `src/distribution_real_rows_gate.zig --strict --limit=100` for ReleaseFast,
  ReleaseSafe, and ReleaseSmall.
- Saved log paths: `tmp/std_debug_hello_udivei5_pressure.log`,
  `tmp/std_debug_hello_umodei4_pressure.log`,
  `tmp/std_debug_hello_debug_umodti3_composed.log`,
  `tmp/std_debug_hello_debug_modti3_composed.log`, and
  `tmp/std_debug_hello_debug_mulsi3_composed.log`. Current closure logs are
  `tmp/zig_integrated_exe_i128_arithmetic.log` and
  `tmp/distribution_all_after_multi3_single_frame.log`. Current INBOX-5
  hardening logs are `tmp/zig_integrated_exe_i128_arithmetic_inbox5.log` and
  `tmp/distribution_all_after_inbox5.log`. Current INBOX-7 validation logs are
  `tmp/zig_integrated_exe_i128_arithmetic_inbox7.log` and
  `tmp/distribution_all_after_inbox7.log`. The current parked-boundary retry
  acceptance logs are `tmp/umodei4_accumulator_alias_retry.log`,
  `tmp/umodei4_acceptance_pressure.log`, `tmp/umodei4_native_link.log`, and
  `tmp/distribution_all_after_umodei4_acceptance.log`.
- Tracked evidence: `docs/evidence/std_debug_hello_udivei5_pressure.tsv` and
  `docs/evidence/std_debug_hello_umodei4_pressure.tsv`;
  `docs/evidence/std_debug_hello_umodti3_composed.summary`;
  `docs/evidence/std_debug_hello_modti3_composed.summary`;
  `docs/evidence/std_debug_hello_mulsi3_composed.summary`;
  `docs/evidence/std_debug_hello_multi3_pressure.tsv`;
  `docs/evidence/zig_integrated_exe_i128_arithmetic.summary`; and
  `docs/evidence/distribution_all_after_multi3_single_frame.summary`. Current
  INBOX-5 hardening evidence is
  `docs/evidence/zig_integrated_exe_i128_arithmetic_inbox5.summary` and
  `docs/evidence/distribution_all_after_inbox5.summary`. Current
  parked-boundary retry evidence is
  `docs/evidence/std_debug_hello_udivei5_frame32_pointer_phi.summary`.
  Current INBOX-7 gate evidence is
  `docs/evidence/zig_integrated_exe_i128_arithmetic_inbox7.summary` and
  `docs/evidence/distribution_all_after_inbox7.summary`. Current boundary
  acceptance evidence is `docs/evidence/std_debug_hello_umodei4_acceptance.summary`,
  `docs/evidence/std_debug_hello_umodei4_acceptance_pressure.tsv`,
  `docs/evidence/zig_integrated_exe_umodei4_acceptance.summary`, and
  `docs/evidence/distribution_all_after_umodei4_acceptance.summary`.
- Recommended next action: resume remaining integer-helper rows in rank order,
  beginning with `compiler_rt.divmodei4.__divei4` at `unsupported_type` /
  `call-ret`; keep the intervening
  `compiler_rt.udivmod.__udivmodti4`, `__divti3`, and `__udivti3`
  `UnsupportedTailCallAbi` rows in the separate ABI family. Keep terminal
  routines frozen and keep the 44 `UnsupportedTailCallAbi` rows as a separate
  ABI family.

When the worker stops, record only:

- active convergence-progress item (and active family, when the goal was a
  family item);
- blocked checklist item;
- exact failure or missing hook fact;
- the first failing real row and current staged `real_*` counter values,
  once the real-row gate exists;
- saved log path or tracked evidence summary path;
- recommended next action.

## Documentation Rule

Do not update this file after every successful cycle.

Update this file only when:

- the active goal is blocked;
- the next item needs a hook-contract or architectural decision;
- the worker changes active goal track (real rows / real program / family);
- the worker stops with a blocker.
