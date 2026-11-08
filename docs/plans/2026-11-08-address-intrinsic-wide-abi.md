# Constant addresses, intrinsic facts and wide integer ABI carriers

Status: complete at `761ea199`. All 17 cumulative gates and 53 native
populations pass. Complete replay selects 6,752 of 8,928 compiler definitions,
adding 2,411 while preserving all prior successes. Runtime remains 274 of 455.
See the [implementation evidence](../evidence/address_intrinsic_wide_abi.md) and
[acceptance record](../evidence/address_intrinsic_wide_abi_acceptance_20261108.json).

Baseline implementation `baf7a767` and documentation
`c471c743` accept 4,341 of 8,928 compiler definitions and 274 of 455 runtime
definitions, with all 17 integration gates and 50 native populations passing.
These are selection counts; complete compiler emission and self-hosting remain
unproven. See the [preceding evidence](../evidence/census_integer_abi.md).

1. Extend the shared address and value-use contracts for constant-pointer memory
   operands. The census contains 1,771 constant GEP memcpy-source rejections and
   one stack allocation. Preserve global and alias properties, address spaces,
   checked offsets, copy widths, dependency accounting and transactional rollback.
   Add positive and negative contract tests plus executable differential cases.
2. Admit validated advisory integer facts through the intrinsic contract. Start
   with the 757 rejected `llvm.uadd.sat.i64` calls. Preserve the original IR and
   omit scalar facts from generated overflow aggregates or widened private views.
   Keep unsupported semantic attributes and envelopes rejected. Exercise overflow,
   boundary values, calls and live operands against an independent native oracle.
3. Extend the existing ABI carrier contract from 1–31-bit integers to 33–63-bit
   integers, covering the remaining i33/i37/i49/i63 call arguments. Preserve
   logical widths and explicit extension requirements. Test dirty incoming and
   returned padding, register and stack arguments, aliases, PHIs and live values.
4. Replay both complete original compiler and runtime inputs after each repair.
   Retain source/input/binary identities, every function result and newly exposed
   boundaries. Preserve all baseline successes; first-failure counts do not
   predict completed functions. Freeze the final implementation before production
   replay and cumulative acceptance.
5. Run Debug and ReleaseSafe units, structural and ABI checks, readiness, native
   regressions and all cumulative integration gates. Preserve the 12-function
   core execution cohort, bypass ratchet 130 and every prior execution population.
   Commit logical implementation slices, record acceptance and update the active
   handoff only when the evidence supports it.

Evidence root: `local-state/validations/address-intrinsic-wide-abi-20261108/`.
Use Zig for diagnostic tools. Preserve original inputs, accepted evidence,
baseline compilers, diagnostic worktrees and all scratch files. Create no archives.
Admission remains 32,949,672,960 bytes and the execution reserve remains
24,359,738,368 bytes.
