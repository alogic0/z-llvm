# Separate temporary work from maintained validation data

The previous follow-up implemented reclamation and shared inputs, but did not
separate the mixed validation directories. This pass implements that boundary.

1. Keep reports, commands, logs, generated test sources, captured inputs, profiles
   and unaudited traces in `local-state/validations/...`.
2. Allocate fresh owned workspaces in `local-state/tmp/validations/...` for
   private caches, generated assembly, objects, capture helpers and executables.
   Record the exact mapping in the maintained run's `*.storage-layout.json`.
3. Use the mapping in checked commands and the real-program, whole-compiler and
   execution-breadth producers. Preserve compatibility with existing mixed runs;
   do not move historical or currently pinned paths.
   Move the collector wrapper's own build scratch under `local-state/tmp` too,
   while keeping its installed helper and control records in `storage-cleanup`.
4. Collect a workspace only after a hash-bound successful terminal result.
   Active, interrupted and failed workspaces remain available for investigation.
   Holds on either tree, current manifests, active consumers, tree snapshots and
   the existing quarantine journal still guard deletion. Unknown temporary
   folders are not permission to delete.
5. Exercise producer-to-collector behavior, failure/hold/alias/race cases, and
   retained evidence. Qualify Debug and ReleaseFast, install the collector,
   retire this pass's build scratch and record results here.

Compiler installations prepared for later consumers are still live dependencies.
Their lifetime must be closed by the pipeline owner; completing a compiler build
alone does not release its installed executable. Existing explicit cache paths
and external cache environment overrides remain explicit caller decisions.

## Qualification

The implementation is in `validation/storage_workspace.zig`,
`validation/storage_paths.zig` and `storage_cleanup/workspaces.zig`, with producer
path changes and the ordinary collector's guarded directory mutation.

- Collector: 117 tests passed in Debug and ReleaseFast, including separate-tree
  collection, failed/interrupted retention, holds on either tree, changed
  diagnostics, alias refusal, raw-trace protection, current pins, active readers,
  capture inheritance and quarantine rollback after a new hold.
- Existing validation policy suite: 47 tests passed.
- Six workspace CLI cases and six existing lifecycle/input CLI cases passed.
- Real `hello_libc` ReleaseFast validation passed with one reference and one
  candidate execution. The first smoke exposed a stale marker-path issue: Zig
  can remove its intermediate file before validation. The check now resolves
  the surviving parent, preserving the prior containment behavior.
- Execution breadth passed seven ReleaseFast function/mode cases, 7,596
  observations and 18 negative controls using separate objects and executables.
- A whole-compiler backend smoke on a small captured IR module passed with raw
  events retained outside scratch. This checks the diagnostic path, not a new
  full compiler self-rebuild claim.

Evidence is under `local-state/storage-cleanup/separation-implementation/`.
The maintained smoke trees contain 279 files. Their before-cleanup checksum
manifest also includes the failed first smoke's diagnostics. During the first
real apply, another agent updated `holds.json`: the collector detected the
change and stopped with zero removals and no pending mutation. All 279
maintained checksums still passed. The fresh retry completed successfully.

## Completed collection and installation

The real apply report is
`local-state/retirements/automatic-storage-cleanup/1794597636317935673-117107/report.json`.
It removed exactly the three successful smoke workspaces: 416,444,416 allocated
file bytes (397.152 MiB). All 279 maintained file hashes and all five current
integrity manifests passed afterward. No pending mutation remains. The failed
first smoke stayed protected during automatic collection, as designed.

After reviewing the fixed replacement run, this pass's resolved first-smoke
scratch and private tool-build directory were retired separately: 48,369,664 and
544,776,192 allocated bytes including directory blocks. Their original logs,
results and the maintained checksum manifest remain. These are task-created
bytes, not a claim of reclaiming another GiB of preexisting project history.

The installed helper at `local-state/storage-cleanup/clean-storage` is Zig 0.17.0
ReleaseFast, SHA-256
`11b450935e8490ca2b0016f043f0595e4252df2caed2be8e6374878cc35ec944`.
The operational binary was installed under the build and cleanup locks, compared
with the qualified binary, and checked after retiring the private build tree.
All 23 collector CLI checks passed, including the wrapper's new build-cache
location; together with the lifecycle/input and workspace suites, 35 CLI checks
passed. The installed collector embeds hashes for all three new workspace
implementation modules in its audit reports.

Existing mixed directories still use the legacy release adapters. This pass
does not relabel all historical data as maintained or declare it necessary.
