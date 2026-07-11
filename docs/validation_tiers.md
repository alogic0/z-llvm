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
i128 arithmetic program, and the setcc predicate program. Every
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
the timing report is the prerequisite for all the others.
