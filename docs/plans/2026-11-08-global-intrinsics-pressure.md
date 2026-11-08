# Global properties, scalar intrinsics and register pressure

Status: complete. Baseline implementation `761ea199`, documented at
`bdd92055`, selects 6,752 of 8,928 compiler definitions and 274 of 455 runtime
definitions. All 17 cumulative gates and 53 native populations pass. See the
[preceding evidence](../evidence/address_intrinsic_wide_abi.md).

Implementation is accepted at `4b8eac2a`. Production replays select 7,040 compiler
and 284 runtime functions, with all baseline successes preserved. Debug and
ReleaseSafe each pass 1,962 units and 21 structural checks. Readiness, all 17
cumulative integration gates and 58 native populations pass. See the
[implementation and evidence](../evidence/global_intrinsics_pressure.md) and
[acceptance record](../evidence/global_intrinsics_pressure_acceptance_20261108.json).

1. Classify the 372 `composed-block-gep-global-properties` first failures using
   the final private function and actual resolved global properties. Repair the
   shared address contract with explicit linkage, layout, address-space and
   relocation rules. Preserve alias identity and dependency accounting. Add
   positive, negative and native differential coverage.
2. Replay both complete original inputs and preserve every baseline success.
   Reclassify the 217 main intrinsic failures (plus the separately diagnosed
   intrinsic rejection). Extend shared scalar intrinsic lowering, starting with
   `ctpop` and `fshl`, across the concrete widths, attributes and operand forms.
   Cover boundary counts, dirty padding, live aliases, PHIs and calls with an
   independent executable oracle. Reject unsupported semantic envelopes.
3. Replay both inputs again, then classify and repair the 184 register-pressure
   first failures through the shared allocation, transfer and register-effect
   contracts. Preserve width semantics, live values and transactional rollback;
   avoid function-name special cases. Exercise pressure around calls and PHIs.
4. Replay both unchanged inputs after the pressure slice. Retain configuration,
   source/input/compiler identities, every function result and newly exposed
   rejection groups. First-failure counts do not predict completed functions.
   Commit logical slices and freeze implementation before final acceptance.
5. Run Debug and ReleaseSafe units, structural and ABI checks, readiness,
   focused native regressions and all 17 cumulative integration gates. Preserve
   the twelve-function core cohort, bypass ratchet 130 and every existing
   execution population. Update status, evidence and the active handoff to match
   measured results; do not infer whole-object or self-hosting success.

Evidence root: `local-state/validations/global-intrinsics-pressure-20261108/`.
Use Zig for diagnostic tools. Preserve original inputs, accepted evidence,
baseline compilers, diagnostic worktrees and user scratch files. Create no
archives. Admission remains 32,949,672,960 bytes; the execution reserve remains
24,359,738,368 bytes. Complete any cache cleanup before builds and validation.
