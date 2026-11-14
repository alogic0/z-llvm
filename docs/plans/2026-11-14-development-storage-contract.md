# Declare storage ownership in every new development cycle

The user requested a clear distinction between temporary files and data that
must remain after future development cycles. Managed producer workspaces already
exist, but the primary development guides omit their use and the profiling
recipe creates mixed output. A bare reader lock records no artifact lifetime.

1. Extend the current-source launcher to run custom commands under the same
   managed workspace, terminal receipt and collection protocol as Zig tools.
   Export separate evidence/scratch roots, record caller-owned cache overrides,
   and allow explicit pipeline retention until downstream consumers finish.
   Convert upstream behavior, the proposed next milestone's producer, to the
   same layout, preserving inputs/traces and propagating the mapping to local
   capture children. Retain its products explicitly through independent audits.
2. Make storage planning and closure part of the authoritative development
   guides and proposed next milestone. Classify outputs before producing them;
   retained exceptions name a purpose, consumer and release condition. Update
   the profiling recipe so compilers, objects, caches and raw sampling work
   have an explicit lifetime. Keep provenance hashes separate from retention
   pins and preserve existing accepted/replay dependencies.
3. Exercise real producer-to-collector success, failure, pipeline release,
   inherited overrides, argument forwarding and external checkout behavior in
   isolated fixtures. Qualify Debug and ReleaseFast, update the installed
   tooling, remove task-owned scratch and commit the results.

This changes new-cycle workflow and tooling. Existing evidence is not moved or
reclassified, and this task does not start the proposed compiler milestone.

## This task's storage

- `local-state/storage-cleanup/development-contract-20261114/` keeps compact
  qualification logs, installed binary identity and final accounting for this
  tooling change. It contains no historical compiler payload.
- `local-state/tmp/development-contract-build/` is task-owned bootstrap scratch:
  private Zig caches and Debug/ReleaseFast checked/behavior-runner executables. Remove it
  after qualification and installation; no later consumer needs these copies.
- CLI fixtures use fresh `/tmp/zllvm-*-cli-*` directories, cleaned by the test
  harness after preserving its pass/failure log. They do not apply cleanup to
  the project's existing validation data.
- The installed `local-state/tmp/validation-tools/run-checked` belongs to the
  launcher's reusable bootstrap directory and is serialized by its build lock.

Validation is focused on storage orchestration. Compiler behavior, populations,
ABI and code generation are unchanged, so compiler-wide acceptance runs are not
part of this task.

## Implementation and qualification

Implemented the storage contract in `AGENTS.md`, the development/working-cycle
guides and the proposed ReleaseSafe milestone. The profiling recipe now separates
retained evidence from compiler builds, objects and sampling scratch. Plans and
run notes name retained exceptions, their consumers and release conditions;
cycle closure records collection and reasons for any remaining temporary data.

`tools/run-validation --command` runs custom commands with literal arguments,
separate `ZLLVM_RUN_ROOT`/`ZLLVM_TEMP_ROOT` paths, a terminal receipt and normal
collection. `--retain-products` gives the command a pipeline lifetime. Receipts
also identify caller-owned cache overrides. Nested tools keep independent
workspace lifetimes.

`run_upstream_behavior` now uses the same managed separation and propagates it
to local capture children. It retains inputs, raw event traces, reports and
diagnostics while moving caches, objects and test executables into temporary
storage. Its own `--retain-products` keeps products through later audits.
Completed errors record `status=failed`, permitting explicit release after
diagnosis without rewriting the original outcome.

Qualification passed in **Debug and ReleaseFast** with pinned Zig 0.17.0:

- 11 workspace CLI checks: evidence preservation, success/failure, holds,
  trace protection, overrides, pipeline retention and reviewed release.
- 11 external-checkout/launcher CLI checks, including literal custom arguments,
  ownership boundaries, unmanaged rejection and retained custom pipelines.
- 6 lifecycle/input CLI checks, including failure bookkeeping and repeated use.
- 8 behavior storage CLI checks, including captured-object mapping, reference
  outcomes, legacy compatibility, failed retention and reviewed failure release.
- All 4 targeted unit tests (module harness and 3 named-outcome parser tests).
- Build-graph loading, Zig formatting, shell syntax, profiling-guide shell
  examples and whitespace checks.

The behavior CLI uses isolated protocol fixtures; it does not claim a fresh
upstream behavior acceptance result. Concurrent fixture batches have unique
names because collector process checks also match relative run paths. An
initial incomplete fake capture and the earlier shared-name collision were
corrected before final qualification. The build-graph check succeeded with
private environment cache roots after the global cache's old helper reference
was unavailable.

The qualified ReleaseFast checked runner is installed in the reusable launcher
directory with SHA-256
`5ef8c4cf33d31dff333d67708821036378d645bb599c36a0956e5e9e182c414d`.
The launcher also rebuilds it from current sources on every invocation.
Qualification commands, logs and provenance identities are kept under this
task's evidence root.

Storage closure completed: the reviewed task-owned build directory was removed,
retiring 801 regular files and reclaiming **192,659,456 allocated file bytes**
(about 184 MiB). Exact identities, metadata checks and accounting are retained
in `scratch-retirement.json` and its companion records under the evidence root.
The installed runner remains owned by the reusable launcher bootstrap directory;
no task-specific temporary root or unresolved fixture remains.

All three plan steps are complete. Existing historical data, accepted artifacts
and other cycles' holds were not changed.
