# Symbolic integer call arguments and the next selection frontier

Status: implementing. Baseline implementation `111f2e0a`, documented at
`088ae654`, selects 7,116 of 8,928 compiler definitions and 284 of 455 runtime
definitions. All 17 integration gates and 60 native populations pass. See the
[baseline evidence](../evidence/syscall_selection_reduction.md).

Of 440 unknown-argument first failures, 326 calls contain the same unresolved
i64 `ptrtoint` of a constant byte GEP into
`Io.Threaded.global_single_threaded_instance`. The other candidates are undef
or poison and require a separate semantic decision. Group size does not predict
completed functions: every repaired first failure may expose another boundary.

1. Preserve input, baseline evidence and scratch identities. Finish any removal
   of inactive, rebuildable project caches before validation starts.
2. Extend the shared symbolic-address contract for default-space, integral
   64-bit pointers cast to i64. Expose accepted constant addresses as private
   SSA GEP/cast instructions, retaining symbol identity, checked signed addends,
   aliases, attributes and the existing global/TLS admission rules. Reuse normal
   call/syscall transfer planning and register effects. Keep unsupported widths,
   layouts, spaces and expressions closed; leave undef/poison semantics unchanged.
3. Add permanent negative contract checks and independent executable regressions
   for ordinary and indirect calls, stack arguments, syscalls, aliases, live
   GPR/SSE values, spills and PHIs. Verify private normalization is idempotent
   and preserves source IR and call contracts.
4. Retain actual rejected GEP and global representations before private IR
   expires. Classify the 225 baseline readonly-table global failures and their
   final transitions, then recommend the next shared repair from that evidence.
5. Replay both complete original inputs, comparing every function against the
   accepted baseline. Preserve all 7,116 compiler and 284 runtime successes;
   report newly selected functions and newly exposed failures separately.
6. Freeze implementation and run Debug/ReleaseSafe units, structural checks,
   readiness, focused Debug/ReleaseFast native execution, complete production
   replays with event audits and all 17 cumulative integration gates. Preserve
   all preceding native populations, the twelve-function core cohort and ratchet
   130. Review executable metadata separately from core object and observation
   identity. Publish acceptance and update the active handoff only after checks.

Evidence root: `local-state/validations/symbolic-call-20261108/`.
Use Zig tools; preserve original inputs, accepted evidence, baseline compilers,
diagnostic worktrees, AIR caches and user scratch. Create no archives. Admission
is 32,949,672,960 bytes; execution reserve is 24,359,738,368 bytes. Selection
counts establish neither complete object emission nor compiler self-hosting.
