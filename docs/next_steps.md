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

Phase D architectural review is pending. The INBOX-22 read-only inventory was
committed in `d7d43ea7` and recommends the adopted `<2 x double>` candidate
slice with one revision: permit constant lane-0 or lane-1 insertion into a
poison or existing value while preserving static lane-definedness. The review
must approve, revise, or defer the vector value-location, allocation, spill,
packed-operation, and verifier model before implementation. Vector lowering
remains unauthorized. Evidence:
`docs/evidence/phase_d_vector_inventory.md`.

INBOX-23 closes type-driven scalar `fsub` and `fdiv` for float and double
through register-parametric SSE forms, non-commutative operand-order checks,
and 44 bit-exact executable cases. Twelve directed compiler_rt rows advance
from `fsub`/`fdiv` to `insertelement`; report-all remains 443 selected / 190
emitting / 253 failing with no collateral emission or regression. The
pre-authorized successor now also closes all 16 scalar float/double `fcmp`
predicates with 192 executable outcomes. Report-all advances to 192 emitting /
251 failing; `compiler_rt.round.__roundh` and `roundf` are collateral emissions
without separate semantic claims. The one-cycle pipeline is exhausted: do not
begin a third cycle until INBOX-23 review is accepted or a new directive
arrives. Vector forms remain unauthorized while the Phase D review is pending.
Evidence: `docs/evidence/std_debug_hello_scalar_fsub_fdiv_acceptance.summary`
and `docs/evidence/std_debug_hello_scalar_fcmp_acceptance.summary`.

INBOX-21 closes type-driven scalar `fpext float -> double`, `fptrunc
double -> float`, and `fmul` for float and double with register-parametric SSE
forms and bit-exact executable coverage. The internal `compiler_rt.tan.tanf`
body consumes the widening and multiplication forms and now stops at its first
vector frontier: `UnsupportedCodegenControlFlow / unsupported_instruction /
insertelement`. Vector lowering and tangent-polynomial recognition remain out
of scope. Debug compiler_rt report-all is now 443 selected / 190 emitting / 253
failing. `compiler_rt.fma.fmaf` is the one collateral emission and has no
separate semantic acceptance claim. Stop for architectural review at this
boundary. Evidence:
`docs/evidence/std_debug_hello_tanf_scalar_fp_acceptance.summary`.

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
