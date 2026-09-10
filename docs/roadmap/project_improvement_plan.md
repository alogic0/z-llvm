# Project Improvement Plan

Date: 2026-09-10
Status: implementation in progress; focused work complete, final integration and real-family closure tracked below.
Revision: artifact-store simplification first, maximum justified cleanup second.
Review baseline: `48ae01be97c6ade57aeaea5fdf21d738914b497c`, plus the four
working-tree changes listed below.

## Objective

Replace the historical artifact-authority system with a small local storage
component, then remove as much obsolete code and generated state as possible.
Retain the minimum data needed for current work, accepted evidence, and
irreplaceable inputs. Follow with exact validation, reproducible builds, and
broader executable coverage through shared compiler lowering.

This revision sets the user's requested priority order. The user authorized implementation on 2026-09-10. Changes, cleanup measurements,
source identities, and exact validation results are recorded in the
[implementation evidence](../evidence/project_improvement/implementation.md).
Use [Validation Tiers](../validation_tiers.md) for acceptance; source changes
and focused results do not automatically advance counters. Historical frozen-path rules are requirements to retire,
not permanent constraints to reproduce in the replacement design.

## Review baseline and evidence

The review included uncommitted changes in:

- `src/distribution_execution_cohort_v1.zig`
- `src/distribution_real_rows_gate.zig`
- `tools/run_distribution_real_rows_parallel.zig`
- `tools/run_distribution_real_rows_parallel/cohort_output.zig`

Those changes extend the execution cohort from three members to four. Preserve
their ownership and distinguish proposed behavior from accepted evidence when
implementing this plan.

Observed findings:

| Finding | Evidence | Implication |
| --- | --- | --- |
| Summary validation uses substring matching | `tools/run_distribution_real_rows_parallel/cohort_output.zig`, `validate` and `fieldValue` | Invalid counters and ambiguous records can pass validation. |
| Artifact tests require historical local state | `tools/zllvm_artifact_store/registration.zig`, `store_test_support.zig`, and `artifact_composition.zig` | Another checkout cannot reproduce these tests independently; cleanup can break them. |
| Storage implements a large historical authority protocol | Approximately 10,086 lines including tests; frozen worktree inventories, system-binary hashes, supplemental control Git repository, candidate/lineage/receipt machinery | The replacement should remove obsolete responsibilities rather than only split them into smaller files. |
| Child tools select Zig through PATH | `build.zig`, `addToolStep*` helpers | Selecting the top-level compiler does not consistently select the compiler used by subprocesses. |
| Unit-test entrypoint includes an external ABI gate | `build.zig`, `test_step` | The advertised unit-test command requires additional tooling and sibling state. |
| Executed cohort members return constants | `src/distribution_execution_cohort_v1.zig`, `Program` | Cohort success provides little coverage of interactions between compiler features. |
| Generated differential coverage is narrow | `tools/run_generated_scalar_diff.zig`, `generated_cases` | Six arithmetic identities do not exercise broad optimization or codegen composition. |
| Current documentation has drifted | `docs/current_state.md`, `docs/next_steps.md`, and the convergence ratchet table | Completed housekeeping and different counter populations are difficult to distinguish from current work. |
| Generated state occupies substantial space | Review observation: approximately 23 GiB in `tmp/`, 28 GiB in `local-state/` | Artifact ownership and retention need a usable lifecycle. These sizes are not reclaimable-byte estimates. |

The storage-focused follow-up found approximately 25 GiB of validations and
3.2 GiB of caches inside `local-state/`, while its copied artifact payload is
only about 9.7 MiB. The external authoritative store is also about 9.7 MiB.
Prioritize large generated run trees as well as visible sibling-folder clutter;
do not count the nested sizes twice.

Review validation: 8 structural smoke tests, 8 execution-cohort tests, 1 cohort
output test, and 63 verifier-filtered tests passed using Zig 0.16.0. The stage4
pin check passed. An additional temporary regression probe demonstrated five
malformed summaries accepted by the output validator. Full distribution
integration was not run; these results are not milestone acceptance.

## Sequence and dependencies

| Priority | Phase | Dependency | Completion outcome |
| --- | --- | --- | --- |
| 1 | Simplify the artifact store | Record current consumers and essential retained data | Small local store; historical security and test-state dependencies removed. |
| 2 | Remove obsolete code and maximize cleanup | Phase 1 replacement and migration verified | Maximum justified reclamation, with an explicit reason for everything retained. |
| 3 | Exact gate-output validation | Starting-state review; independent of storage redesign | Malformed or ambiguous acceptance summaries are rejected. |
| 4 | Consistent toolchain and independent unit tests | No dependency for focused storage tests in phase 1 | One selected build compiler and a useful fresh-checkout test command. |
| 5 | Behavioral coverage and shared lowering | Reliable gates from phase 3 | New shared capabilities compile and execute meaningful combinations of features. |
| 6 | Current documentation and discoverable setup | Update storage/retention docs in phases 1–2; finish broader setup/status here | One understandable current status with reproducible setup instructions. |

At the start of each implementation phase, record the relevant source state,
compiler identity, input pins, affected files, and acceptance command. Reuse
existing evidence only when the relevant inputs match. Phases 1 and 2 take
precedence over further artifact-framework decomposition or new compiler
capability work. Use the installed Zig 0.16 compiler explicitly for focused
storage tests; the broader build-system work in phase 4 is not a prerequisite.

## Implementation progress (2026-09-10)

Checkboxes below describe implemented deliverables, not automatic milestone
acceptance. Exact commands and limitations are in the
[completion evidence](../evidence/project_improvement/implementation.md).

| Phase | Current result |
| --- | --- |
| 1 | Compact store and migration verified; isolated storage tests pass in two locations. |
| 2 | Historical roots/worktrees and obsolete code removed; source duplicates moved to ordinary Git lookup; exact current keep-list recorded. |
| 3 | Exact parser and runner tests pass; external checkout blocker resolved; fresh Tier-3 retry running, fresh/cache acceptance pending. |
| 4 | Zig 0.16 pin, selected children, filtered independent unit tests; two full isolated test runs pass. |
| 5 | Eight composed behavioral programs, 24 paired runs, 6,528 observations; signed power-of-two lowering and rejection fixtures. Named real-function failure-family closure remains open. |
| 6 | Structured accepted status, generated current tables, setup README and documentation checks implemented; accepted counters unchanged. |

## Phase 1: Replace the historical artifact-authority system

Primary owners: `tools/zllvm_artifact_store.zig`, its component directory,
current consumers, and artifact/retention operating documents.

### Operating assumptions

The user and local tools are trusted. Handle crashes, partial writes, corrupt
data, stale inputs, concurrent writers, and accidental deletion. Do not build a
defense against a malicious process running as the same user. Reproducibility
requires relevant compiler and input identities, not authentication of the
entire workstation and its history.

### Target design

Use one configurable artifact root, a content-addressed object directory, one
manifest per retained run, an incoming directory, and one lock coordinating
publication and garbage collection. A suitable final layout is:

```text
local-state/artifacts/
  objects/<sha256>
  manifests/<run-id>.json
  incoming/
  store.lock
```

Manifests contain the command, relevant source/compiler/input identities,
result, and named artifact hashes and sizes. Keep accepted manifests versioned
in the main repository. Local run manifests may live in the store; both use the
same schema. Keep disposable caches separate from durable evidence. Make
compressed snapshots optional exports, rather than mandatory storage objects
with a separate authority protocol.

Reuse the current object format and payload location during the first migration
step where practical. The directory example is a target, not a reason to copy
all large caches or implement a second permanent store.

### Remove or replace

- [x] Remove the exact 43-worktree requirement and frozen topology hashes.
- [x] Remove repeated global Git scans from ordinary object operations; confine
      operations to an opened, explicitly selected store root.
- [x] Remove hard-coded local paths and exact hashes of installed Git, tar,
      zstd, sha256sum, and install executables from normal storage checks.
      Record tool versions/encoding metadata only where relevant to reproduction.
- [x] Replace exact ancestor permission-bit requirements with practical access
      checks. Read-only objects may prevent accidental edits without making
      every directory mode part of artifact identity.
- [x] Replace the supplemental control Git repository and dormant candidate,
      authority, lineage, observer, and acceptance-receipt protocols with the
      run-manifest model. Audit callers before retiring their modules and tests.
- [x] Replace tests that require failed INBOX directories with temporary
      test-owned fixtures. Routine store tests must not inspect real stores,
      historical worktree registrations, or retained failure directories.
- [x] Consolidate overlapping manifest/ledger data. Preserve meaningful source,
      result, and content identities; remove historical ceremony fields that
      have no current consumer.
- [x] Update storage and retention contracts as these requirements are retired;
      do not leave documents directing future work to recreate them.

### Retain these integrity guarantees

- [x] Verify object hashes and sizes, reject corrupt existing objects, and never
      silently overwrite different content under the same identity.
- [x] Publish objects and manifests atomically. Synchronize durable evidence at
      publication boundaries; disposable caches may use cheaper durability.
- [x] Parse manifests strictly and reject ambiguous keys, invalid references,
      malformed hashes, and unsafe relative paths.
- [x] Prevent symlink/path escapes during writes, extraction, and deletion.
- [x] Serialize publication and garbage collection with one store lock; publish
      a manifest only after all its referenced objects are complete.
- [x] Keep pins for currently required inputs and accepted evidence. An extra
      unreferenced object is a cleanup candidate, not an invalid store.

### Migration and acceptance

- [x] Identify active readers/writers and map retained inputs/evidence to the
      new manifests. Explicitly record any data with no remaining consumer.
- [x] Switch consumers to the simplified interface and verify the retained
      payloads before retiring the old source location. Keep a bounded rollback
      path during verification, then remove migration-only duplicates in phase 2.
- [x] Test publication/reuse, malformed manifests, corruption, interrupted
      publication, unsafe paths, and publisher/collector coordination.
- [x] Run the isolated suite from two differently located checkouts without
      historical sibling stores or the supplemental control repository.

Acceptance: current consumers can retrieve their required artifacts through the
small store, integrity tests pass, ordinary Git/worktree changes do not affect
it, and successful test runs leave no permanent sibling folders. Retired
protocols and their test scaffolding have no live callers. Do not substitute a
new generic authority framework for the old one.

Validate retained content directly by manifest/hash/size and exact process
results. Until phase 3 lands, the known substring-based summary validator is
not sufficient evidence for migration or cleanup correctness.

## Phase 2: Remove obsolete machinery and maximize cleanup

Primary owners: retired store modules and harnesses, retention tooling,
`tmp/`, `local-state/`, and project-created sibling folders/worktrees.

The goal is maximum justified removal. A historical INBOX name, old document
reference, previous failed run, or obsolete pin is not by itself a reason to
keep a directory forever. Keep the minimum sufficient accepted evidence and
currently required inputs; treat regenerable outputs as disposable once their
consumers and regeneration requirements are understood.

Deliverables:

- [x] Delete unused authority/migration code, obsolete test helpers, build
      entries, scripts, schemas, and redundant operating documentation after
      checking their callers and references. Use Git history for retired source;
      do not create another archive directory of dead code.
- [x] Inventory generated roots by physical size, live use, unique data,
      regeneration cost, and current consumer. Consolidate historical pins into
      a small current keep-list and retire pins whose purpose has ended.
- [x] Preserve the minimal evidence needed to support accepted results and
      reproduce unresolved failures before deleting their bulky run trees.
      Keep full logs or original inputs when summaries cannot replace them.
- [x] Remove superseded validation runs, old build/install trees, duplicate AIR
      exports, abandoned migration copies, unused snapshots, and failed-test
      directories whose required diagnostics have been retained.
- [x] Remove obsolete worktrees through Git after preserving unique commits on
      a named ref and checking uncommitted/untracked work. Remove stale worktree
      metadata once no remaining consumer relies on it.
- [x] Remove the supplemental control repository and legacy sibling store after
      consumer migration and unique-content checks. Avoid indefinite duplicate
      stores or quarantine copies that merely relocate the clutter.
- [x] Add a small dry-run/apply collector. Live manifests and explicit pins mark
      retained objects; unreferenced objects and abandoned incoming files become
      deletion candidates under the store lock. Exclude active runs.
- [x] For regenerable caches, retain only generations justified by active work
      and near-term rebuild cost. Remove the rest; do not preserve every older
      known-good generation by default.
- [x] Execute the classified cleanup, check remaining consumers, and record
      physical space reclaimed and the exact remaining keep-list.

Initial cleanup scope, subject to fresh inspection:

| Area | Review observation | Intended disposition |
| --- | --- | --- |
| `tmp/` | About 23 GiB | Remove obsolete runs, build trees, duplicates, and unused caches; retain only identified live work and essential evidence. |
| `local-state/validations/` | About 25 GiB | Extract essential retained evidence; remove superseded and migration-only run trees. |
| `local-state/caches/` | About 3.2 GiB | Remove inactive/redundant generations once active consumers are known. |
| `local-state/worktrees/` | About 111 MiB | Preserve unique work, remove obsolete checkouts and registrations. |
| `../zllvm-inbox45-p0` | About 3.9 GiB, including 3.8 GiB of duplicate AIR cache | Preserve detached commit `b93e2d57`; remove obsolete worktree after consumer checks. |
| Six `../z_llvm-inbox*-artifact-store-synthetic` directories | About 17 MiB combined | Remove after phase 1 removes test dependencies and any necessary diagnostics are retained. |
| `local-state/control/` and duplicate authority payloads | Small compared with validation trees | Remove after migration; leave one live store and ordinary manifests. |
| Obsolete tracked storage protocol code/docs | Approximately 10,086 lines including tests in the reviewed subsystem | Delete unused responsibilities and scaffolding; retain the compact store, its tests, and required evidence. |

These are inspected sizes, not promised savings. Measure actual filesystem
reclamation; do not double-count hard links, shared objects, or parent/child
trees. Project source, unique uncommitted work, the required patched compiler,
and unrelated sibling projects are outside blanket cleanup scope. Record a
concrete reason and next decision for any unresolved candidate, without blocking
removal of independently verified disposable data.

Acceptance: all identified disposable data has been removed, current consumers
and focused tests still work, every retained generated root has a current
reason, and no live manifest references missing content. Report bytes reclaimed,
directories/worktrees removed, retired code, remaining disk usage, and specific
unresolved candidates. No long-lived duplicate archive is created as a substitute
for cleanup.

## Phase 3: Make acceptance summaries exact

Primary owner: `tools/run_distribution_real_rows_parallel/cohort_output.zig`.

Deliverables:

- [x] Parse complete space-delimited key/value fields, matching keys exactly.
- [x] Reject duplicate keys, missing required fields, invalid numeric values,
      trailing junk, and schema-incompatible fields according to an explicit
      record contract.
- [x] Parse counters into bounded integer types and compare exact expected
      values. Define canonical numeric encoding, including leading-zero rules.
- [x] Apply the parser consistently to headers, cache records, cohort rows,
      and summaries; preserve mode, denominator, multiplicity, and cohort checks.
- [x] Add focused negative coverage for the demonstrated failures and for
      substring keys in `fieldValue`.

Required regression cases include:

| Malformed summary field | Required result |
| --- | --- |
| `real_functions_lowered=1000` when 100 is expected | Reject |
| `real_executed=40 real_programs_ok=40` when 4 is expected | Reject |
| `local_fail=01` | Reject |
| `not_local_fail=0` without `local_fail` | Reject |
| `local_fail=0 local_fail=1` | Reject |

Acceptance: valid output from each supported mode passes; each malformed case
fails with a meaningful diagnostic. Test the cohort count belonging to the
accepted implementation state rather than silently accepting the pending
four-member expansion as part of this fix.

Validation: focused parser and parallel-runner tests first. Before accepting
this gate-infrastructure change, run the integration and fresh/cache comparison
required by `docs/validation_tiers.md`. Reuse that evidence for the same source
state rather than repeating full gates for every intermediate edit.

## Phase 4: Make builds and unit tests reproducible

Primary owners: `build.zig`, shared tool invocation helpers, and setup docs.

Deliverables:

- [x] Record the supported build compiler version in a small tracked source of
      configuration and fail early with an actionable mismatch diagnostic.
- [x] Replace literal `zig` subprocess selection in build helpers with
      `b.graph.zig_exe` or compiled build artifacts.
- [x] Audit nested tool invocations so they preserve the selected compiler.
      Keep the patched stage4 emitter identity separate from the compiler used
      to build this project.
- [x] Add `zig build test-unit` with a supported focused-test filter.
- [x] Keep the mandatory ABI and integration gates available and required at
      their existing acceptance boundaries; adding an inner-loop command must
      not weaken acceptance.

Acceptance: in an isolated checkout, explicitly invoking Zig 0.16 while PATH
contains another Zig still uses 0.16 for project build-tool children.
`test-unit` and structural smoke run without a patched sibling compiler,
LLVM utilities, historical artifact stores, or production artifact access.

Validation: exercise the mismatched-PATH case, the supported compiler case,
and the missing-external-tools case. Verify that integration steps still select
and check their explicitly pinned external compiler.

## Phase 5: Expand behavioral proof through shared lowering

Primary owners: execution cohorts, `tools/run_generated_scalar_diff.zig`,
`src/codegen/x86_64/generic_cfg_selector.zig`, and composed-selector modules.

Deliverables:

- [x] Separate executed-function counts from whole-program success counts.
      Publish denominator, mode, source pin, and harness scope for each metric.
- [x] Preserve existing smoke cases and add a first bounded program suite
      covering arguments and branches, loops and memory, nested calls, and
      register-pressure/spill interactions.
- [x] Compare observable results with an independently compiled reference over
      deterministic input sets. Define legal input domains to avoid undefined
      behavior producing misleading differential failures.
- [x] Extend generated tests beyond arithmetic identities to interacting
      operations, signedness, widths, control flow, and memory where supported.
      Record seeds and minimize failures into stable regression fixtures.
- [ ] Select one recurring real-function failure family and extend shared
      composed lowering to cover several members, with representative executable
      cases and nearby rejection cases.
- [x] Record which rows use composed lowering and which use structural
      fallbacks. Retire a fallback only after equivalent semantic coverage exists.

Acceptance: each selected program executes through z_llvm and agrees with its
reference in the applicable modes. Each new lowering capability has a runtime
regression that detects the wrong result. Coverage improvement must come from
new behavior or shared lowering, not counter renaming or case-specific admission.

Counter-schema or denominator changes require an explicit migration record;
do not reinterpret historical `real_programs_ok` evidence in place. Use the
selector, ABI, frame, and gate validation routes specified by the existing tier
policy. Keep mechanical file splits separate from semantic changes.

## Phase 6: Establish one usable current project status

Primary owners: `docs/current_state.md`, `docs/next_steps.md`,
`docs/roadmap/convergence_progress.md`, and a root setup entrypoint.

Deliverables:

- [x] Reconcile completed watcher/tooling work and replace stale active tasks.
- [x] Distinguish accepted baseline, current source revision, pending work, and
      historical milestones.
- [x] Store current accepted counters and evidence references in one small
      structured record; generate or validate repeated status tables from it.
      Keep next-action selection explicit rather than inferring it from Git HEAD.
- [x] Label every reported counter with its population and evidence scope.
- [x] Add a concise root README covering purpose, supported scope, compiler
      setup, unit tests, integration prerequisites, and the current-state link.
- [x] Add documentation checks for broken internal links and disagreement with
      the accepted status record.

Acceptance: a reader can identify what is proven, what is pending, and how to
run the relevant tests without reading historical INBOX transcripts. A new
implementation commit alone never advances accepted counters.

## Completion record

Close each phase with its exact change scope, commands and results, relevant
source/compiler/input identities, remaining limitations, and accepted evidence
reference. For the first two phases, lead with obsolete responsibilities removed,
historical dependencies eliminated, physical space reclaimed, and the remaining
keep-list. Also track fresh-checkout test success, malformed-summary rejection,
executed behavioral coverage, and fallback usage.
Use these outcomes to choose the next capability slice; file counts and
checklist length are not measures of compiler progress.
