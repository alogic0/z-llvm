# Alloca And Convenience-Spill Collision Repair

schema_version: 1
directive: `INBOX-27` Part 1
contract_class: correctness repair
target: `x86_64-linux-gnu`
validation_tier: 3
result: pass

The composed selector previously let an alloca-only function start its frame
payload at displacement zero while the convenience spill allocator also
started at frame slot zero. A local store could therefore overwrite a live
value spill. Stack-frame preparation now reserves the complete convenience-
spill range before laying out any scalar, 128-bit, or array alloca. Instruction
lowering only validates and consumes those preplanned frame locations; it no
longer contains a second ad hoc alloca allocator.

The defect regression reproduces the observed shape: a live f32 parameter is
spilled, an alloca-backed double store executes, and the f32 value is reloaded
and stored through an output pointer. Before the repair, both operations used
the same frame index and the structural assertion failed (902 passed / 1
failed). After the repair, the indexes are disjoint and five executable bit
patterns pass exactly: positive and negative zero, minimum subnormal,
infinity, and a NaN payload. Existing scalar out-parameter tests now assert a
256-byte separation between convenience slots and the alloca payload.

Audit of the accepted 199-emission report found 30 emitted functions containing
allocas. Twenty-six had an existing PHI, array, scalar-SSE-call, or wide-value
reservation trigger; the two i128 remainder wrappers had planned pair spills.
`compiler_rt.int.__umoddi3` had no reservation trigger but did not create a
live convenience spill. `compiler_rt.int.__moddi3` did hit the defect: its
captured single-block body has max pressure 3/6, spills the sign mask at slot
zero, passes the alloca at displacement zero to `__udivmoddi4`, then reloads
the sign after the callee writes the remainder. Its earlier closure was
structural/object-emission evidence and did not prove correct execution for
that path. The repaired test stream places the out-parameter at displacement
256 while sign/magnitude spills remain in slots 0, 2, and 4.

Validation:

```text
zig build test: 903/903 passed
zig build structural-smoke: pass
zig build distribution-x86_64-selected-zllvm: executable_ok=146/146
zig build distribution-all: 17/17 subgates, local_fail=0
strict real rows: ReleaseFast=100/100 ReleaseSafe=100/100 ReleaseSmall=100/100
integrated executable canaries: 5/5
release-source-owned object inspection: 100/100
release-source-owned native link: 100/100
```

Tier-2 log: `tmp/inbox27_part1_tier2.log`, sha256
`cad1137bef95e42b3c4b56a09d60275fabd76cf8e324fa02fccd95ad72d7ae04`.
Tier-3 evidence is recorded in
`docs/evidence/distribution_all_after_inbox27_alloca_spill_collision.md`.

`INBOX-27` is acknowledged by id. Part 2 is pre-authorized after this repair
commits cleanly.
