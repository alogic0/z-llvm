# INBOX-78 commit-6 call-result migration continuation

Commit 6 resumes the preserved hard-stop state at root `4cb867b5` through
migration scratch `697c3bd4` (tree
`3ae97547421b9be5bbab5874217820a02329253a`).  The pre-migration inventory was
committed first in `docs/evidence/inbox78_call_result_inventory.md`; its frozen
inventory commit/tree are `74a31b1a` / `610e220f68baf01f50c5d7028da3e022381a66bc`.
It classifies all 31 direct accumulator sites as 3 already migrated, 24
commit-6 scope, 4 exclusions, and zero unclassified.

## Two-stage call preparation repair

The hard stop was `compiler_rt.udiv.__udivei5` at the narrow
`zig.target.intByteSize` result: the accumulator transaction treated the dead
compare result still bound in EAX as a live alias and rejected with
`AccumulatorAliasConflict` before the accepted call could clobber it.

Call-result transactions now use this explicit order:

1. begin and validate the call EFLAGS clobber before mutation;
2. run the existing caller-clobber preservation in its accepted
   accumulator/GPR/XMM order;
3. stage every call argument in the existing order;
4. drop only expired EAX/RAX bindings without emitting instructions;
5. require the accumulator unbound, append the call/normalization, define the
   result, and commit.

The transaction's `preparing_call` phase separates the two preparation stages.
The post-staging drop uses the existing strict liveness/PHI rules; any live or
protected binding that survives preservation makes the accumulator-unbound
check fail closed.  Caller-clobber preservation remains the sole spill
authority, so no new scratch/spill movement is introduced.

Focused coverage proves the `__udivei5` dead compare result is discarded with
no spill; an accumulator-resident operand is staged before its expired binding
is dropped; live and protected-PHI values spill exactly once; mixed dead/live
aliases separate correctly; live-EFLAGS rejection precedes mutation; and
rollback after preservation, argument staging, expired drop, alignment, call
append, and result definition restores instructions, bindings, spill state,
counters, accumulator domain, and EFLAGS.

The extracted `__udivei5` before/after assembly streams are identical:

```text
cmpq ...
setb %al
movzbl %al, %eax
callq zig.target.intByteSize
andl $65535, %eax
```

Both streams have SHA-256
`5cf8be75c951c839ff4f95563d7b3bd9c993e7be74bd0065ed026f301d9bf895`.

## Residual direct-producer inventory

There are **zero deferrals**.  The only residuals are the inventory's explicit
commit-6 exclusions: XMM results, i128/pair/aggregate/sret results, indirect
calls, unsupported attributes/calling conventions, and argument-allocation
redesign.  Void and unused calls remain on their accepted non-result paths.

## Frozen validation

- Full unit suite: `7/7` steps, `1086/1086` tests; ABI differential
  `60/60` cases and `30/30` real functions.  Log
  `tmp/inbox78_continuation_unit.log`, SHA-256 `5b0018da45aa92876f3b846ea880260222f0bd8734b44c2b0db57a1b54a42b9f`.
- Standalone focused codegen canaries: 2 canaries, 35 execution cases, fma and
  `__multi3` object/stream/symbol/helper identities green, no host-libc fma
  substitution.  Log `tmp/inbox78_continuation_focused_canaries.log`, SHA-256
  `2bf6f68ae7cec068253218a52e4d89d17d0b193396c31e3bca2feb72744e40f8`.
- Full report: exactly `443 selected / 285 emitted / 158 failed`, first failure
  `compiler_rt.trunc.truncl` / `UnsupportedLongDoubleAbi`; SHA-256
  `49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`.
- Accepted-cohort object: SHA-256
  `061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be`.
- Selection-owner manifest: SHA-256
  `5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d`;
  live ledger `167 / 17 / 101` composed / legacy / fallback.
- Standard integrated executable gate: `7/7`; log
  `tmp/inbox78_continuation_integrated_exe.log`, SHA-256
  `c0b9678666690672de4f3ba705a6b128c295a9bbc715f2d9a5a3c7386ff2e42e`.
- Strengthened Tier 2: `28/28` steps, `1094/1094` tests; log
  `tmp/inbox78_continuation_tier2.log`, SHA-256
  `4da54f47b1a5ecde9fbf28f616c0873fd3953ddcffd81b54d6c11cf287fc93a1`.

Frozen identities are exact: `49a19f04` / `443-285-158-truncl` /
`061a64e4` / `5d91960e` / `167-17-101`.  No Tier 3 was run.  Stop for
Supervisor/Reviewer acceptance before commit 7.
