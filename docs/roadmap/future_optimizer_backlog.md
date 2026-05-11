# Future Optimizer Backlog

This file holds optional follow-up work after the completed finish burn-down.
It is not an active roadmap. Promote one item only after selecting a concrete
source-backed fixture, opt-22 delta, or readiness-gate failure.

The current finish state has no active source-backed blocker:

```text
manifest rows=40
optimizer_input=33
unsupported=0
future=4
debug-info-only=0
```

The four future rows are explicit boundaries, not unowned blockers:

```text
tiny_scalar_debug: future
tiny_scalar_release_safe: future
tiny_scalar_release_small: future
vector_future_release_fast: parse,verify,future
```

## Activation Rule

- [ ] Start new work only from a measured source-backed blocker, a concrete
      opt-22 mismatch, or a failing readiness check.
- [ ] Add or identify the fixture before creating a new cycle.
- [ ] Record the LLVM upstream source mapping before marking the cycle
      complete.
- [ ] Keep local conservative behavior documented when LLVM is broader.
- [ ] Run `bash scripts/run_readiness_checks.sh` before closing the cycle.

## Corpus Discovery Candidates

- [ ] Refresh selected Zig-emitted IR rows from the current `../ziglang`
      stage4 compiler and compare them with the checked manifest rows.
- [ ] Add one small Zig source fixture only when it exposes a construct not
      already covered by accepted rows.
- [ ] Reduce broad Debug IR only when it contains a concrete uncovered Debug
      construct.
- [ ] Reduce broad ReleaseSafe IR only when it contains a concrete uncovered
      safety or runtime-call construct.
- [ ] Promote the vector future row only when vector FP semantics,
      vector-condition legality, scalable-vector policy, target-cost modeling,
      or native vector lowering becomes a measured requirement.

## Optimizer Quality Candidates

These are quality improvements, not finish blockers. Pick one only when a
fixture shows the current local behavior is too conservative for a Zig-backed
case.

- [ ] SROA: extend DataLayout-backed aggregate slicing beyond the current simple
      pointer-field case.
- [ ] GVN: add one measured PRE or load-availability slice beyond the current
      MemorySSA-backed fixtures.
- [ ] ADCE: improve one measured control-dependence case beyond the current
      acyclic dead-region fixtures.
- [ ] DSE: extend MemorySSA-backed byte-range reasoning only for a concrete
      source-backed store pattern.
- [ ] EarlyCSE: replace linear expression scans with scoped hash buckets only
      after expression keys include all needed alias-sensitive memory facts.

## Floating-Point Candidates

The parser/verifier and conservative optimizer boundary already cover the
current accepted FP corpus. Further FP work needs new source-backed pressure or
explicit opt-22 parity work.

- [ ] Expand the APFloat-shaped semantic model only for a fixture involving
      NaN, infinity, signed zero, subnormals, or target-dependent literals.
- [ ] Teach InstSimplify/InstCombine strict FP identities only after legal
      NaN/signed-zero/exception fixtures exist.
- [ ] Use fast-math flags as optimization facts only after matching the required
      LLVM `FastMathFlags` legality for the chosen transform.
- [ ] Extend SCCP with an FP constant lattice only after APFloat comparison
      fixtures exist.
- [ ] Enable FP value numbering/CSE only after strict and fast-math equality
      rules are represented.

## Debug Candidates

Current debug-location-only behavior is fixture-backed. Full variable-location
salvage remains outside the finish scope.

- [ ] Add a debug salvage slice only when a source-backed transform removes or
      replaces an instruction carrying `!dbg` in a way not covered by existing
      fixtures.
- [ ] Keep `llvm.dbg.value` and `llvm.dbg.declare` transform pipelines disabled
      until variable-location salvage is represented.
- [ ] Reduce new Debug-mode rows only when they contain an uncovered DI node,
      intrinsic, or verifier requirement.

## Backend And Handoff Candidates

The local backend remains validation-only and bounded to documented x86_64
smoke coverage.

- [ ] Add one handoff proof only when an accepted optimized IR shape cannot be
      validated by the existing scalar, memory, loop, global, call, stack, and
      stack-memory-to-call cases.
- [ ] Keep broad register allocation, scheduling, unwind/debug object
      generation, target-complete ABI lowering, and multi-object-format parity
      out of scope.

## Explicitly Completed Or Superseded Items

The following earlier backlog ideas are no longer active backlog items because
they were completed, superseded, or converted into conservative boundaries:

- [x] Inline asm representation and barrier preservation.
- [x] `atomicrmw`, `cmpxchg`, and `fence` representation with fail-closed
      verifier rules.
- [x] Vector parser/verifier bootstrap and narrow lane-operation transforms.
- [x] AArch64 target-independent optimizer-input policy.
- [x] Reduced Debug metadata rows for the accepted Debug boundary.
- [x] Path-aware MemorySSA foundation and follow-up vector-lane clobber fix.
- [x] Stale ReleaseSmall unsupported-row closure.
