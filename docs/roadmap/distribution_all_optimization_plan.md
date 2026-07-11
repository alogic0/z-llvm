# `distribution-all` Runtime Reduction Plan

This plan reduces the wall time and repeated work of
`zig build distribution-all` without weakening its integration contract. It
also defines the narrow refactoring direction needed to make distribution
validation maintainable. It is not authorization for a repository-wide
refactor.

The validation authority remains [`../validation_tiers.md`](../validation_tiers.md).
This document describes implementation order; it does not make Tier 3 the
default worker loop.

## Objective

Keep the existing full-gate semantics while making a fresh run and especially
a cached run materially faster. Optimize measured bottlenecks in this order:

1. repeated compilation and process startup;
2. duplicated stage work and avoidable cache misses;
3. sequential execution of independent gates;
4. opaque orchestration and duplicated gate definitions;
5. excessive artifact I/O and retention.

Initial performance targets, measured against the accepted baseline on the
same machine and source state:

- reduce cached wall time by at least 40%;
- reduce forced-fresh wall time by at least 20%;
- execute every logically shared prerequisite only once per run;
- preserve every existing summary, boundary, native-link, and executable
  assertion.

If measurements show that these percentages are unrealistic, record the
measured constraint and replace them with a source-backed target before
claiming completion.

## Non-Goals

- Do not remove coverage merely to make the number smaller.
- Do not replace `distribution-all` with sampling; focused validation already
  belongs to Tiers 1 and 2.
- Do not run all release modes concurrently before proving isolated output and
  cache ownership.
- Do not refactor unrelated parser, optimizer, AIR, selector, or codegen code.
- Do not introduce timestamp-only cache validity.
- Do not maintain a second list of gates that can drift from the authoritative
  distribution definition.

## Current Structural Problem

`build.zig` starts `tools/run_distribution_all_gates.zig`, which in turn starts
many `zig run` subprocesses. This makes the full suite mostly opaque to the Zig
build graph. The build system cannot reliably see shared prerequisites,
parallelize independent work, or explain why a subgate reran. Individual tools
also have opportunities to repeat AIR export, compilation, object emission,
inspection, and native-link work.

The current timing patch is the correct prerequisite: it records each
subgate's duration and cache status, ranks the slowest gates, and supports one
forced-fresh real-row run for comparison with one cached run.

## Phase 0 — Accept The Baseline

Finish the current measurement capability before changing orchestration.

Required evidence:

1. One `distribution-all -- --fresh-real-rows` run.
2. One normal cached `distribution-all` run on the identical implementation
   state.
3. Matching correctness and ratchet summary lines.
4. Per-subgate duration and cache-status lines.
5. Five slowest subgates for both runs.
6. Total wall time, summed child duration, and unexplained orchestration
   overhead.
7. A tracked summary under `docs/evidence/` containing the source commit,
   worktree state, Zig pin, target, commands, and log paths.

Do not repeat either full run unless the measurement implementation or another
relevant input changes. Do not start Phase 1 until the baseline identifies the
dominant costs.

## Phase 1 — Reuse Compiled Tools

Goal: stop treating every subgate as an independent `zig run` compilation.

Implementation direction:

1. Inventory the executable tools used by `distribution-all` and identify
   their shared modules.
2. Build each required tool once through the Zig build graph, or build one
   deliberately shared runner where that produces a cleaner ownership
   boundary.
3. Pass built executable paths to the orchestrator instead of launching
   nested `zig run` commands.
4. Build the main `z_llvm` artifact once per target/optimization configuration
   and reuse it across child gates.
5. Keep each subgate independently invocable for focused debugging.

Commit slices:

- add one reusable child executable without changing gate behavior;
- migrate one gate family and compare its output byte-for-byte or by canonical
  summary lines;
- migrate the remaining measured high-cost families;
- delete the superseded nested invocation path only after all callers move.

Acceptance:

- no changed gate summaries;
- direct focused commands still work;
- timing evidence shows reduced compilation/startup overhead;
- a failed child still reports its command, exit status, and captured output.

## Phase 2 — One Authoritative Gate Manifest

Goal: replace duplicated, order-dependent gate lists with one declarative
definition.

Define one `DistributionGate` record containing at least:

- stable gate id and description;
- executable/tool identity;
- fixed arguments;
- target and mode requirements;
- dependency ids;
- output-directory ownership;
- cacheability and cache-key inputs;
- whether the gate is a correctness, boundary, inspection, native-link, or
  executable proof;
- whether it may run concurrently.

Generate or consume both the `build.zig` steps and the full-suite order from
this definition. The manifest must not encode implementation-specific case
admission; it describes orchestration only.

Acceptance:

- one authoritative gate inventory;
- duplicate ids and missing dependencies fail during build configuration;
- `distribution-all` retains deterministic summary ordering even if execution
  becomes parallel later;
- focused build-step names remain stable.

## Phase 3 — Stage-Level Content Caching

Goal: reuse expensive outputs when their semantic inputs have not changed.

Candidate cached stages, in measured priority order:

- mode-specific AIR export;
- parsed/typed descriptor or lowered project IR;
- emitted object;
- object-inspection result;
- native-linked executable;
- deterministic executable result where reuse is explicitly allowed for
  diagnostics, never as the only milestone execution proof.

Every cache key must include the relevant subset of:

- Zig source pin and emitter/hook contract;
- content hash of relevant z_llvm sources;
- target, ABI, CPU/features, and optimization mode;
- corpus/candidate identity and slice;
- pipeline and tool arguments;
- toolchain versions;
- harness source and expected-result contract.

Cache design rules:

- a miss recomputes; it never falls back to stale data;
- metadata explains every hit and miss;
- outputs are written atomically;
- partial or corrupt entries are rejected and cleaned safely;
- documentation-only changes do not invalidate compiler artifacts;
- encoder changes invalidate objects but should not force AIR export;
- optimizer changes invalidate lowered/optimized IR and downstream artifacts,
  not the source AIR export when the exporter contract is unchanged.

Acceptance:

- a fresh/cached focused comparison produces identical semantic summaries;
- a deliberate change to every key category demonstrates the expected
  invalidation boundary;
- cache size and cleanup policy are documented;
- no cache is required for correctness.

## Phase 4 — Explicit DAG And Bounded Parallelism

Goal: execute independent work concurrently after dependencies and output
ownership are explicit.

Candidate parallel branches:

- independent release modes after their mode-specific inputs exist;
- object inspection, native-link probes, and unrelated executable cases that
  consume immutable objects;
- deterministic real-row shards with isolated output directories.

Implementation order:

1. Express dependencies without enabling concurrency.
2. Prove sequential DAG output matches the current runner.
3. Give every concurrent task a unique scratch/output directory.
4. Make shared cache metadata read-only during consumers, or protect atomic
   publication explicitly.
5. Enable bounded concurrency behind a flag.
6. Measure concurrency levels 1, 2, and a machine-appropriate upper bound.
7. Select the default from wall time, peak memory, and disk pressure rather
   than CPU count alone.

Preserve deterministic reporting by buffering child summaries and emitting
them in manifest order after completion.

Acceptance:

- concurrency 1 is a supported diagnostic mode;
- repeated parallel runs produce the same summaries and artifacts;
- no shared-path races or intermittent cache corruption;
- peak memory and temporary disk usage remain within documented bounds.

## Phase 5 — Remove Duplicated Work Inside Slow Gates

Use the baseline and post-Phase-4 timings to inspect only the remaining
dominant gates. For each slow gate, draw its stage sequence and compare it with
other gates. Consolidate shared work at the earliest semantically identical
artifact boundary.

Typical candidates:

- exporting the same whole-module AIR more than once per mode;
- reparsing the same descriptor for object, inspection, and link stages;
- re-emitting an object separately for readelf, objdump, and native link;
- rebuilding identical harnesses;
- scanning the same corpus repeatedly for different report views;
- writing and rereading very large intermediate text when an immutable
  in-process or binary artifact already exists.

Do not consolidate stages that merely look similar but have different
pipeline, target, mode, or expected-failure contracts.

## Phase 6 — Retire Transitional Orchestration

After the new graph is proven:

- remove duplicated gate arrays and nested `zig run` paths;
- keep thin compatibility build steps for documented focused commands;
- move shared process, timing, cache, and result types into responsibility-
  named modules;
- keep the runner small: argument parsing, graph execution, deterministic
  reporting, and final status;
- update `docs/build_steps.md`, `docs/validation_tiers.md`, and evidence
  tooling together.

This is the only broad refactoring phase, and it is limited to build/gate
orchestration. It begins only after behavior and timing evidence prove the new
path.

## Validation And Rollout Rules

Each implementation commit must:

1. name one optimization or ownership boundary;
2. use the smallest change-impact gate while developing;
3. compare old and new output for the migrated slice;
4. record timing only when the measured implementation state changed;
5. preserve fail-closed and expected-failure gates;
6. avoid mixing performance refactoring with compiler semantic changes.

Run full Tier 3 only when required by `docs/validation_tiers.md`: the baseline,
the fresh/cached comparison, a shared orchestration/cache boundary close, or
final milestone confirmation. Do not run it after every internal edit.

If a phase regresses correctness, stop the full run, reproduce with the
narrowest child gate, fix or revert that phase's slice, and do not stack the
next optimization on top.

## Progress Record

Maintain a compact table here or in a linked evidence summary:

| State | Fresh wall time | Cached wall time | Slowest gate | Cache result | Notes |
| --- | ---: | ---: | --- | --- | --- |
| Baseline | pending | pending | pending | pending | Phase 0 |

Record only materially changed states. Do not turn routine worker cycles into
repeated full-suite benchmarks.

## Supervisor And Worker Protocol

One monitoring agent may supervise the worker, following
[`../worker_agent_howto.md`](../worker_agent_howto.md). It is the single
supervisor and single writer for `docs/worker_inbox.md`.

The supervisor may nudge the worker to continue only when all are true:

- the worker turn is idle, not merely quiet during a background gate;
- the worktree is clean, or the worker has recorded an intentional stop state;
- the current phase's result has been inspected and recorded;
- the next checklist slice is explicit in this plan or the active tracker;
- no unresolved blocker requires user or architectural review.

The supervisor must not:

- nudge while a documented long-running gate is active;
- start a second worker or edit the same implementation files;
- invent a new phase because the worker is idle;
- repeatedly request `distribution-all` after an unchanged result;
- bypass an architectural stop or a failed validation;
- use the retired `scripts/inbox_watch.sh` alongside direct supervision.

Substantive direction is written as a numbered Active inbox entry first, then
delivered as the short tmux nudge documented in `worker_agent_howto.md`.
Routine continuation after a clean, successful cycle needs no new technical
directive: instruct the worker to resume the next documented slice.

## Completion Criteria

This plan is complete when:

- the accepted baseline and final fresh/cached measurements are tracked;
- the performance targets are met or replaced by an approved measured limit;
- gate semantics and deterministic summaries are unchanged;
- compiled tools and shared stages are reused at their correct ownership
  boundaries;
- independent gates use safe bounded parallelism where it helps;
- one manifest owns the distribution graph;
- obsolete nested orchestration is removed;
- focused gates remain independently usable;
- the worker documentation no longer encourages full-suite execution as an
  inner loop.
