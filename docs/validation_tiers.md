# Validation Tiers

Adopted 2026-07-11 (user-approved). This supersedes the earlier rule that
`distribution-all` must be green before every commit.

Policy: focused commits must pass their change-impact gate (tier 1 or 2
per the routing table). Capability-closing, ratchet-moving, ABI-affecting,
and milestone commits must pass the full integration gate (tier 3).
During sensitive multi-commit work, intermediate commits may be marked
"not yet milestone-green" in the commit body; full green is required
before moving to another capability family, closing a tracker item, or
advancing any ratchet.

## Authority And Precedence

This file is the authoritative validation policy. `docs/working-cycle.md`
applies it to worker mechanics, and roadmap/checklist documents record goals
and historical evidence. If an older roadmap entry says that
`distribution-all` must run before every commit, that wording is historical
and does not override this file.

Before starting a tier-3 run, record in the worker log or cycle notes:

- the changed subsystem;
- the tier-3 trigger from this file;
- the exact command and intended evidence output;
- why an existing result cannot be reused.

Do not rerun a gate against unchanged relevant inputs when an existing log
already proves the required result. Reuse requires the same relevant source
state, Zig pin, target, mode, corpus, pipeline arguments, and expected-result
contract.

## Tier 1 — inner loop (seconds to a few minutes)

Run after each small implementation change:

- the relevant unit-test file or test filter;
- the focused selector/lowering test for the change;
- machine verification;
- assembly + encoding tests for newly introduced instruction forms;
- one executable semantic test exercising the changed behavior;
- the currently failing real row, usually in one mode.

## Tier 2 — capability close (several minutes)

Run when a coherent capability slice is ready to commit ("support icmp ne
against zero", "consume scalar spill locations" — not every edit inside
those slices):

- unit tests;
- structural smoke;
- the codegen/object-inspection gates relevant to the change;
- the executable canary suite (below);
- a limited real-row subset: the failing row, several rows from the same
  failure cluster, and the previously closed row most similar to the new
  feature;
- ReleaseFast plus the mode most sensitive to the change.

## Tier 3 — full integration (`distribution-all`)

Run:

- before closing a roadmap/tracker item;
- before advancing a strict ratchet (the full strict prefix runs here,
  not per inner-loop commit);
- after changes to shared ABI, frame layout, register allocation,
  relocation, AIR export, or linker boundaries;
- before claiming any evidence-backed milestone;
- periodically after a series of low-risk commits.

Tier 3 is not the default end of every worker cycle. After a tier-3 run,
inspect and record its result before starting another cycle or another full
run. A failed run is investigated with the narrowest reproducing subgate.

### Row-closure batching (amendment 2026-07-14, user-directed)

Individual compiler_rt row closures are recorded as provisional
(Tier-2/native-proven) on focused Tier 2 plus exact native row evidence.
One cumulative Tier 3 accepts the batch: at the end of a two-step
pipeline (not once per half, unless the first half must be independently
accepted before the second can safely begin), or at the
four-to-six-commit or family checkpoint for batches of low-risk
closures. Immediate Tier 3 is retained for confirmed wrong-code repairs
and for changes to ABI, shared frame layout, relocation/linker
ownership, AIR export, verifier invariants, or milestone claims. Do not
launch Tier 3 during a read-only periodic review or merely because the
worker stopped. A provisional closure is not a completed tracker claim
until the cumulative Tier 3 accepts it.

## Change-impact routing

Explicit and binding — do not decide ad hoc that a risky change is
"probably safe". Historical note: this project's selector-layer
regressions (loop-sum; call_chain) manifested in captured `.ll`
distribution rows, so selector/allocator/encoder changes always include
the captured-row object smoke, which the generic version of this table
would have missed.

| Changed area | Required gate (minimum) |
| --- | --- |
| Documentation, inventories | documentation validation only |
| IR parser/verifier | unit tests, readiness, parser corpus |
| Optimizer pass | pass fixtures, compare-opt, readiness |
| AIR model/lowering | AIR tests, focused real rows, relevant modes |
| Selector / register allocator | selector tests, executable canaries, captured-row object smoke, real-program boundary |
| Machine instructions / encoder | encoding, assembly, captured-row object inspection, executable probe |
| ABI / frame / calls | all modes, native link, executable gates (tier 3) |
| ELF / relocations | object inspection, linker boundary, full distribution (tier 3) |
| Gate/cache infrastructure | full distribution plus fresh/cache comparison (tier 3) |

## Executable canary suite

The permanent, deterministic runtime checks; every tier-2 run executes
them. Current members: the syscall hello (three modes), the compiler_rt
i128 arithmetic program, the setcc predicate program, and the mandatory
`abi-differential` gate over ten audited accepted compiler-rt functions in
all three modes. The ABI gate's paired-execution counters belong only to the
285-function compiler-rt population and do not describe the separate 100-row
compiler-core distribution population. Every
executable semantic case added under the INBOX-10 rule (each new
arithmetic/comparison/branch/call/spill capability lands with one) joins
this suite. Canaries are never removed, only extended; determinism is
required — no random sampling.

## Frontier, not prefix, during development

Inner-loop cycles validate the failing frontier row and nearby cluster
rows, not the whole strict prefix. The full strict prefix in all modes
runs at tier 3 when a ratchet moves or an item closes.

## Measurement before optimization

Gate-runner infrastructure work (subgate timing report first, then
tool/artifact reuse, mode parallelism, stage caching, build-graph
restructuring) proceeds in the order the measured numbers justify —
the timing report is the prerequisite for all the others. Implementation order,
acceptance criteria, and supervisor continuation rules are defined in
[`roadmap/distribution_all_optimization_plan.md`](roadmap/distribution_all_optimization_plan.md).

For gate/cache infrastructure measurement, the required comparison is exactly:

1. one fresh run for the current implementation state;
2. one cached run against that same state;
3. a comparison of summary lines, cache status, and subgate timings.

Do not repeat either full run unless the gate/cache implementation or another
relevant input changes after the measurement.
