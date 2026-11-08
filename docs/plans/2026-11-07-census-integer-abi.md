# Census classification and shared integer ABI repair

Status: complete, accepted at `baf7a767`. The [evidence](../evidence/census_integer_abi.md)
records 4,341 compiler selections, including 817 additions with no lost successes,
unchanged runtime selection and all 17 cumulative gates passing.

Baseline implementation `5ad6c51c` is documented by the
[complete selection census](../evidence/selection_census_completion.md).
That baseline selected 3,524 of 8,928 compiler definitions and 274 of 455 runtime
definitions. These counts describe selection, not complete objects or execution.

1. Correct the active handoff in `docs/next_steps.md`. Keep one current baseline
   and next action; identify preceding allocation/parser work as historical.
2. Classify the largest first-failure groups at their actual rejection points,
   after normalization and optional legalization. Retain function and instruction
   identity, operand types, attributes, calling convention, intrinsic name, and
   resolved register/stack/pointer representation as relevant. Distinguish
   intermediate failed retries from the final diagnostic. Reproduce baseline
   selection identities and retain exact input/compiler/source identities.
3. Choose one shared repair from that classification. The initial candidate is
   narrow integer ABI handling across call arguments, returns and function
   parameters. Preserve signed/unsigned extension requirements, low-bit value
   semantics, calls, aliases, PHIs, spills, and transactional rollback. Extend
   the common contract, retaining explicit rejection of unsupported ABI forms.
   Classify intrinsic and memcpy groups without promising to repair every group.
4. Add focused negative and executable differential regressions for the selected
   contract, including boundary bit patterns, dirty upper bits, live values,
   mixed widths and register/stack arguments. Replay both complete original
   inputs with the final compiler; compare per-function identities, preserve all
   3,524 compiler and 274 runtime successes, and report newly exposed boundaries.
5. Run Debug/ReleaseSafe units, structural and ABI checks, readiness, native
   regressions and one cumulative integration acceptance on frozen sources.
   Preserve the 12-function core cohort, bypass ratchet 130, and every existing
   execution population. Commit the implementation and evidence, update accepted
   status only after those checks pass, and finish the active handoff.

Evidence root: `local-state/validations/census-integer-abi-20261107/`.
Use Zig for diagnostic tools. Preserve original compiler/runtime inputs, accepted
evidence, baseline compilers, diagnostic worktrees and all thirteen scratch files.
Create no archives. Admission remains 32,949,672,960 bytes and the execution
reserve remains 24,359,738,368 bytes. First-failure counts are investigation
priorities, not estimates of the number of functions a repair will complete.
