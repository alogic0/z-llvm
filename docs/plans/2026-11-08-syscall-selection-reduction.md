# Syscall contracts and measured selection reduction

Status: in progress. Baseline implementation `4b8eac2a`, documented at
`d4292871`, selects 7,040 of 8,928 compiler definitions and 284 of 455 runtime
definitions. All 17 integration gates and 58 native populations pass. See the
[preceding evidence](../evidence/global_intrinsics_pressure.md).

The observational replay preserves all 8,928 compiler and 455 runtime outcomes.
All 328 assembly rejections are `syscall`, in four concrete forms; 325 share
three syscall arguments with a typed range on the last argument. The shared
syscall matcher now reuses validated call facts and optional tail hints. Its
eight-function native population passes 6,912 local and 3,456 reference
observations. The subsequent comparison repair admits named `samesign ult i64`
operands through the existing full-width transfer action. Six native functions
pass 21,504 local and 10,752 reference observations, including clobbering calls,
PHIs and memory canaries. The census now retains actual rejected allocation-plan
definitions and inspected allocation types. Final replays and cumulative
acceptance remain outstanding.

1. Retain the baseline, immutable original inputs and scratch hashes. Extend
   diagnostic observations with the exact inline assembly and call attributes.
   Classify all 327 main inline-assembly result failures and the separate
   varargs rejection; prove that observation does not change selection outcomes.
2. Extend the existing closed syscall contract for the concrete supported
   templates, constraints, typed facts and tail markers. Reuse register effects,
   simultaneous argument transfers and live-value preservation. Keep arbitrary
   assembly, unsupported ABI promises and mandatory tail calls rejected.
3. Add negative contract checks and independent native differential regressions
   for syscall arities, meaningful arguments, errors, memory effects, aliases,
   live GPR/SSE values, spills and PHIs. Preserve all previous fixtures.
4. Replay both complete original inputs. Record identities, newly selected
   functions, lost successes and every newly exposed rejection. Use the updated
   census to classify comparison operands, general unsupported values and alloca
   types; implement the next shared repair supported by concrete representations
   and executable evidence. Measure each slice separately.
5. Freeze and commit implementation, then perform both production replays with
   complete event audits. Run Debug and ReleaseSafe units, structural checks,
   readiness, focused native populations and all 17 cumulative integration gates.
   Preserve all 7,040 compiler and 284 runtime selections, the twelve-function
   core cohort, ratchet 130 and every existing execution population.
6. Publish measured before/after selection counts, unchanged-input hashes,
   per-function transitions and remaining groups. Update the accepted record and
   active handoff only after cumulative acceptance. Selection counts do not
   establish complete objects, compiler startup or self-rebuilding capability.

Evidence root: `local-state/validations/syscall-selection-20261108/`.
Use Zig for diagnostic tools. Preserve original inputs, accepted evidence,
baseline compilers, diagnostic worktrees, AIR caches and user scratch files.
Create no archives. Admission remains 32,949,672,960 bytes and the execution
reserve remains 24,359,738,368 bytes. Do any cache cleanup before validation.
