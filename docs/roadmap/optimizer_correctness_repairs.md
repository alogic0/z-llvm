# Optimizer correctness repair plan

Starting revision: `1efd9861`. Scope: the five bugs reproduced during the
project review; no acceptance counters or supported-codegen claims change.

1. [x] Add regression coverage for sibling-branch store forwarding, signed
   division after truncation, wrapping wide arithmetic, load sinking across
   exit stores, and loop-local uses of sunk values. Include nearby boundaries
   and keep positive optimization cases working.
2. [x] Give Early CSE independent store state per dominator subtree and invalidate
   inherited facts at control-flow joins/backedges where they are not proven.
3. [x] Normalize signed division/remainder operands to their IR width and avoid
   host overflow during constant addition, subtraction, and multiplication.
4. [x] Preserve memory ordering when sinking loads and retain computations with
   loop-local users (including users of a candidate GEP).
5. [x] Run focused regressions, native comparisons with LLVM 22, the full unit
   suite, optimizer fixtures, readiness, and documentation checks.
6. [x] Run the full distribution gate and record results and any limitations.

## Validation record

Build compiler: `/home/oleg/.zig/0.16.0/files/zig`.
Independent reference: `clang-22` / `opt-22`.

Tier-3 preflight: changed subsystems are Early CSE, integer constant folding,
and LICM. The trigger is confirmed wrong-code repair under
[validation tiers](../validation_tiers.md). Earlier results cannot validate the
changed optimizer semantics or new regression inputs.

Command (after focused checks pass):

```sh
/home/oleg/.zig/0.16.0/files/zig build distribution-all -- --serial \
  --serial-root=local-state/validations/optimizer-correctness-20260926/full \
  --real-rows-validation-root=local-state/validations/optimizer-correctness-20260926/project-improvement \
  --real-rows-cache-root=local-state/caches/project-improvement \
  --zig-emitter=/home/oleg/prog/ziglang/build/stage4/bin/zig
```

Intended evidence: `local-state/validations/optimizer-correctness-20260926/`
with separate logs for focused checks, LLVM execution comparisons, readiness,
and `distribution-all`. The existing immutable AIR-export cache is reusable:
the pinned emitter/source inputs have not changed. All optimization, object,
linking and execution checks run again for this source state. The runner must
verify cache identities and require hits; no earlier gate result is reused.
This replaces the initially planned fresh export, which is unnecessary for
optimizer-only changes. Allocate new validation/run directories and retain
any failed-run evidence.

Completed focused checks: 1,416 unit tests (including eight new regression
tests), eight structural tests, and documentation checks passed. The new
`optimizer-correctness` native runner passed 11 functions under both the
focused pipeline and `release-o3`, against LLVM 22 and explicit expected values.
It is part of readiness and can also be run independently with
`zig build optimizer-correctness`.

Readiness completed successfully (`readiness.log`): optimizer fixture comparisons,
the new native optimizer regressions, the mandatory ABI differential gate,
Zig corpus and handoff checks, generated scalar/behavioral checks, and the
release-pipeline policy report. The behavioral population passed all 24
program/mode pairs and 6,528 observations. All 243 optimizer fixtures passed.

Full integration completed successfully (`distribution-all.log`, exit 0): all
17 subgates passed with `local_fail=0`, in 2,186,625 ms (36m 27s). All three
AIR-export cache identities were verified hits. Each release mode lowered,
emitted and natively linked 100 compiler-core functions and passed all four
fixed-cohort executions. Integrated executables, release-object inspections,
native links/probes, and boundary checks passed. The release-source object
bundle identity remained
`a5dcce564ade761f3cf47c9767f69615cdadbe0d6c2cc88419efaaf52e9518fa`.

Relevant implementation and regression-input hashes are recorded in
`local-state/validations/optimizer-correctness-20260926/source.sha256`.
The existing accepted-status counters are unchanged; these results validate
the repairs and current development cohort, not a broader support claim.
