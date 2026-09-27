# Correctness checkpoint before the next memory family

Baseline: `230a30ef`, 2026-09-26. The user requested fixes for the four
reproduced review findings and a correctness checkpoint before further memory
family work. Status: complete; focused validation, readiness and all 17
integration subgates passed. Accepted counters remain unchanged.

## Repairs

- InstCombine resolves alias chains through the shared typed operand traversal
  over the complete live function after folding. Earlier PHIs, terminators and
  non-topologically ordered blocks receive replacements before use counting and
  verification. This repairs dangling loop-backedge definitions.
- ConstMerge uses shared module reference discovery before merging. Opaque
  expressions, initializers, metadata, assembly and unparsed attributes prevent
  merging; structured operands use the shared traversal. A final reference
  check prevents deletion if any use remains. Positive structured merges and
  alias rewrites still work. This deliberately sacrifices optimization when
  complete reference coverage is unavailable.
- Vector lane selection interprets each constant in its own unsigned integer
  width. InstCombine, VectorCombine and the verifier share that rule. Same-lane
  folding, different-lane bypass and shuffle extraction use normalized indices;
  widening an index preserves its effective lane. The existing out-of-bounds
  verifier rejection remains in force; this does not add general vector codegen.
- Constant shift folding normalizes the count before comparing it with the
  operand width. Wrapped zero counts remain defined, while genuinely excessive
  counts remain poison. Unsupported shift widths keep their existing policy.
- The native optimizer runner uses one output writer across its fixtures so a
  redirected regular-file log retains every result instead of overwriting
  previous fixture records.

## Required checkpoint

Do not start `ssp.__memcpy_chk` or close another memory-family capability until
all items below pass for the same relevant source state. Preserve this ordering
when additional correctness failures are discovered during validation.

- [x] Reproduce the review failures before changing implementation.
- [x] Add permanent regressions for backedges and forward alias chains, opaque
  and structured global references, typed vector indices and shift boundaries.
- [x] Pass focused Debug and ReleaseFast tests and independent native LLVM
  comparisons under individual passes and `release-o3`.
- [x] Pass final unit/structural/storage tests, optimizer fixtures and readiness.
- [x] Pass all 17 integration subgates and record source/input identities.
- [x] Inspect the completed evidence and update current guidance before resuming
  the next bounded memory family. Do not migrate accepted counters implicitly.

The permanent native fixture has 11 functions and 1,640 defined observations
per pipeline, including 256 seeded values, six scalar boundaries, and 64 finite
loop lengths. Its C harness asserts explicit expected results as well as matching
an independently compiled original. Transformed IR is verified by LLVM 22 and
compiled at `-O0`. Pipelines: `instcombine`, `constmerge`, `vector-combine`, and
`release-o3`. These checks validate optimizer semantics independently of local
object emission; existing behavioral/memset canaries retain their own populations.

## Validation and evidence

Evidence root: `local-state/validations/correctness-checkpoint-20260926/`.
Project compiler: `/home/oleg/.zig/0.16.0/files/zig` (0.16.0).
Oracle: LLVM 22. Emitter source pin:
`bdee02bc0c7f227c0f11bc9a449df673fe803540`.

`review-baseline/` retains the review probes. `unit-before.log` reproduces six
failing regression groups, including two adjacent vector-index failures.
Focused tests pass (`unit-focused.log`, `releasefast.log`); `native-final.log`
records all four new pipeline comparisons and every existing native fixture.
`compare-opt.log` records all 243 existing optimizer fixtures passing unchanged.
`unit-final.log` records 1,503 passing tests (1,486 unit, eight structural, nine
storage), plus documentation validation. `readiness.log` exits successfully after
ABI, corpus, native optimizer, handoff, generated scalar and 24 behavioral
program/mode checks. The focused ReleaseFast invocation passes 14 tests, including
the seven checkpoint tests and imported test roots.

Tier-3 preflight: changed optimizer replacement/reference/integer semantics and
vector-index verification. Confirmed wrong-code and verifier repairs require
Tier 3 under [validation tiers](../validation_tiers.md). Prior logs cannot prove
this source state. Reuse only the unchanged emitter's verified AIR export cache;
all native and integration validation executes again. No gate/cache contract,
selector default, ABI, accepted population or expected counter changes.

```sh
/home/oleg/.zig/0.16.0/files/zig build test-unit structural-smoke artifact-store-test --summary all
/home/oleg/.zig/0.16.0/files/zig build test-unit -Doptimize=ReleaseFast -Dtest-filter='correctness checkpoint' --summary all
/home/oleg/.zig/0.16.0/files/zig build optimizer-correctness
/home/oleg/.zig/0.16.0/files/zig build readiness
/home/oleg/.zig/0.16.0/files/zig build distribution-all -- --serial \
  --serial-root=local-state/validations/correctness-checkpoint-20260926/full \
  --real-rows-validation-root=local-state/validations/correctness-checkpoint-20260926/project-improvement \
  --real-rows-cache-root=local-state/caches/project-improvement \
  --zig-emitter=/home/oleg/prog/ziglang/build/stage4/bin/zig
```

## Completed acceptance

`distribution-all.log` and `distribution-result.json` record exit 0 and all
17 successful subgates. Runner wall time: 2,404,726 ms (40m 05s).
`subgate-timings.tsv` records each subgate's duration and cache status; the three
real-row modes run concurrently, so their durations must not be summed as wall
time. Each mode reports 100 lowered/emitted/linked compiler-core functions, four
cohort executions, four paired harness successes, and zero failures. All three
export-cache identities were verified hits.

Both preopt and postopt object routes passed 146 executable cases. The integrated
canary gate passed all 24 behavioral program/mode pairs (6,528 observations) and
the memset comparisons (8,652 observations and 12 checked traps). Release object,
native link/probe and boundary checks passed. The release bundle identity remains
`a5dcce564ade761f3cf47c9767f69615cdadbe0d6c2cc88419efaaf52e9518fa`.

`source-before-tier3.sha256` and `source-verification.txt` establish that all
1,377 compiler, tool, test and build files were unchanged across the final run.
`external-before.txt` and `external-after.txt` establish the same pinned, clean
emitter checkout. LLVM tools report 22.1.8. Documentation and formatting checks
pass. The evidence root is listed in the current retention keep-list.

The correctness prerequisite is complete. The reconciled
[architecture plan](architecture_refactor_plan.md) schedules its remaining
fixed-program performance baseline before the next memory-family investigation.
ConstMerge's conservative opaque-reference boundary, the limited local
vector backend and unsupported wide shift folding remain explicit limitations.
This is correctness acceptance for this source state, not an accepted-counter
migration, new memory capability, or general optimizer/backend parity claim.
