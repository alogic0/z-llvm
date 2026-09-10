# Project improvement implementation evidence

Started 2026-09-10 from HEAD `52e538c5` with an existing uncommitted store
replacement, parser/build edits, and migrated evidence. Those changes were
preserved and reviewed. The four-member cohort belongs to that development
commit; accepted counters remain the inherited three-member declaration.

Build compiler: `/home/oleg/.zig/0.16.0/files/zig` (0.16.0).
Emitter input pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`.
Acceptance routes: isolated store/unit tests, exact parser/runner tests, selector
runtime and object checks, then one fresh/cache Tier-3 pair for gate infrastructure.
Existing historical runs cannot validate these changed relevant source inputs.

## Storage and cleanup

Removed responsibilities: frozen worktree topology, workstation binary hashes,
permission topology identity, supplemental control Git, candidate/lineage/observer
and receipt protocols, and failure-directory fixtures. No live source imports
remain for the retired store modules. The replacement contains a CLI, compact
store, and test-owned fixtures. Migration manifests preserve original payload names,
hashes, byte counts, and retained diagnostics; preserved Git refs retain unique work.

The starting tree already held three local/trackable run manifests, a verified
legacy generation, and preserved worktree/ref inventories. Verification checked
all retained content directly (not gate-summary substrings). Publication and GC
use one OS lock; explicit `--pins` protects versioned manifests even when a local
manifest was accidentally deleted. Atomic staging occurs in incoming on filesystems
that need named temporary files. Input identities are ordinary named manifest fields.

Prior cleanup measurements are retained here as `zllvm-cleanup-*.txt/tsv`.
The filesystem free-space difference in those prior measurements is
34,026,696,704 bytes; it includes concurrent filesystem activity and is not an
exclusive allocation accounting claim. Starting observations were about 23 GiB
in tmp and 28 GiB in local-state. No additional cleanup from that earlier work is
claimed as newly performed in this continuation.

This continuation removed the six remaining schema-2 AIR cache pairs. The current
reader requires schema 3 and never consumes those keys; their metadata is retained
here. Three pairs duplicated content across exporter-state generations. Physical
allocation fell by 8,022,163,456 bytes (directory entry accounting may vary).
The exact before/after allocated-byte counts are in `continued-cleanup-*.tsv`.

Remaining keep-list: artifact objects and manifests (accepted evidence, original
inputs, unresolved logs); adopted O2-call performance input/baseline checkout
(current hard-coded consumer); udivmoddi4 null-pointer diagnostic objects; patched Zig
source/emitter. Full keep-list lives in `../tmp_retention_pins.tsv`. New validation
runs added during acceptance are listed separately with their results below.

## Validation and limitations

Store: 9 tests passed, covering publication/reuse, corruption, missing content,
strict manifests, lock exclusion, abandoned incoming files, versioned pins, and
leaf/intermediate symlink escapes. Initial real-store verification passed for 3 manifests; final verification passed for all 5 retained manifests.

Two copies under differently located `/tmp/zllvm-improvement-checkouts` roots
passed 63 verifier unit tests, 8 structural tests, and 9 storage tests each.
The first used PATH=/nonexistent. The second inherited Zig 0.17 on PATH while
explicitly invoking Zig 0.16 and also ran the artifact-store child successfully.
Neither checkout had sibling compiler/store/control repositories. An earlier full
unit and structural run passed; final semantic validation is recorded below.

Exact parser: 23 runner tests passed, including the five reported counter failures,
all supported modes, cache status, duplicates, malformed numeric encodings, hash
shape, and complete-key lookup. Expected development cohort membership is four;
this is not a migration of historical acceptance counters.

## Counter migration

`docs/accepted_status.json` carries forward the accepted declaration in
`docs/current_state.md` at `52e538c5`; it does not manufacture newer evidence.
The old convergence table mixed the compiler-core population, standalone syscall
program, and compiler-rt counters. Generated status blocks now label their separate
populations. Legacy `real_programs_ok=3` means three fixed paired cohort harnesses;
no historical result is reinterpreted as broad whole-program proof.

The new behavioral suite reports standalone IR programs separately: a case/mode
pair is a program success, function identities are counted independently, and
individual inputs are observations. LLVM compiles the same IR independently;
Zig compiles identical driver sources for both object sets. Legal inputs use
wrapping arithmetic, positive power-of-two divisors, bounded shifts and loop
counts, and initialized stack memory. Seeds and boundary inputs are fixed.

## Final acceptance runs

Focused validation passed. The external checkout blocker has been resolved and a fresh Tier-3 retry is running; fresh/cache acceptance remains pending. Accepted baseline counters are unchanged.

Tier-3 preflight: changed gate-output parsing, build compiler propagation, mandatory
behavioral canaries, and shared signed-immediate lowering. These trigger the
Gate/cache infrastructure and Selector validation routes. Command:
`/home/oleg/.zig/0.16.0/files/zig build distribution-all -- --serial --fresh-real-rows --serial-root=local-state/validations/project-improvement/fresh-final --real-rows-validation-root=local-state/validations/project-improvement --real-rows-cache-root=local-state/caches/project-improvement --zig-emitter=/home/oleg/prog/ziglang/build/stage4/bin/zig`.
Output: `tier3-fresh.log` in this evidence directory. After inspecting success,
run the same source state without `--fresh-real-rows` using `cached` as the serial
root and the same AIR cache; compare semantic records with the tracked log
comparison tool. These runs cannot reuse historical evidence because parser,
subprocess compiler selection, and selector semantics changed.

The first preflight omitted explicit root/emitter selections and correctly failed
before running any subgate (`tier3-preflight-missing-options.log`). Setup and tier
docs now show the required selections. The obsolete 1,696-line clean-tmp INBOX
classifier and its report-only fixture were removed after finding no callers
outside its build entry; the local object collector replaces its live retention role.

A second attempt used invalid absolute, differently named real-row roots. It was
stopped after six successful subgates before reaching that invalid selection;
`tier3-stopped-invalid-roots.log` preserves the partial evidence. Root validation
now runs before any subgate. The corrected run uses existing relative validation
and cache directories whose final component is `project-improvement`. The source
change to early preflight justifies a new full run; partial output is not acceptance.

Final focused checks: both isolated checkouts passed all 1,425 tests (1,408 unit,
8 structural, 9 store) with no sibling dependencies. Store tests also pass after
strict numeric JSON validation. The parallel runner passed 23 tests; the serial
runner passed 41. The documentation validator rejects a deliberately changed
accepted counter and a broken README link in an isolated copy.

The standalone behavioral suite passed all 24 case/mode pairs and 6,528 input
observations across 10 (case,function) identities. Every selected function used
composed_block or composed_cfg; none used a structural fallback. The new signed
i32 division lowering covers positive powers of two from 2 through 2^30 and
rounds negative values toward zero; focused tests include signed endpoints and a
live original source. The divide-by-two instruction stream is preserved.

Limitation: these new division cases prove shared lowering and composed standalone
behavior. They do not close a named real-function failure cluster in the pinned
compiler-core corpus. That distinct Phase-5 requirement remains open; no real-row
counter is advanced or fallback retired on this evidence alone.

The remaining udivmoddi4 cache was then minimized: the original 7,231,014-byte IR
(SHA-256 `7be46e0b88c96fce0ce527407672843c43d3416ce56257d53a286603bd533e06`,
MD5 matching the historical diagnostic) and both generated builtin configurations
were published and verified under `diagnostic-udivmoddi4-20260910`. There are no
live source/tool readers of the old path. The entire 50,262,016-byte cache tree,
including an empty object and failed archive, was removed. The retained object
adds about 7.3 MB to the store; historical source paths remain in the manifest.
Retrieve the IR with `zig build artifact-store -- get SHA256 output.ll`.

The prior worktree inventory contained 43 registrations. Two remain: this checkout
and the currently consumed O2 baseline. Thus 41 obsolete/stale registrations were
removed; 33 worktree heads were explicitly preserved (including dirty work) and
86 refs are inventoried. The six synthetic sibling stores, legacy sibling store,
and supplemental control repository no longer exist. Earlier source history is
kept as ordinary refs, not as duplicate working copies.

The mandatory ABI gate passed 60 paired cases (10 audited compiler-rt functions
across three harness modes, with normal/negative inputs), plus mismatch, callee-save,
write-boundary, timeout and termination negatives. Its raw provenance, input IR,
object inspections, owner maps and process records were published under
`project-improvement-abi-20260910` (383 files, 1,711,620 logical bytes, deduplicated).
After store verification, its 42-MiB scratch/cache tree was removed. The store now
has five retained manifests. The paired driver and source identities are in `abi.log`.

A Git-reachability audit matched 12,437 retained source-name entries to blobs
already reachable through the main repository's refs. Their original names,
SHA-256, Git blob identities and sizes are retained in
`../artifacts/git-backed-sources-20260910.tsv`. Two minimal manifests were pinned
atomically before the superseded manifests were removed under the store lock.
This makes 2,268 duplicate objects (47,280,128 allocated bytes before collection)
collectible without losing source content. `artifact-store pin` also provides a
normal recovery path for versioned manifests whose objects already exist.

The Git-backed object collection completed: 2,268 files, 41,094,302 logical bytes,
and exactly 47,280,128 allocated bytes reclaimed. Verification passed with five
remaining manifests. Abandoned output trees from the intentionally stopped
integration attempt and the empty legacy AIR cache directory were also removed.


## Final observed integration state

The corrected fresh run passed all nine subgates through
`integrated-object-release`. The three real-row children then exited with
`ExternalRepositoryDirty` before AIR export or cohort execution. Their raw stdout,
stderr and failure manifest are retained as `tier3-child-*` beside the complete
`tier3-fresh.log`. This is a failed acceptance attempt, not a passing Tier-3 run.
No cached acceptance run or fresh/cache equivalence is claimed.

The pinned checkout has exactly one reported untracked file:
`/home/oleg/prog/ziglang/doc/langref_to_markdown.py` (`external-status.txt`).
`src/distribution_execution_cohort_v1.zig:requireExternalRepositoryClean` checks
`git status --porcelain=v1 --untracked-files=all`. The unrelated file was left
untouched. This historical failure was resolved by the user-authorized deletion recorded below; the cleanliness requirement was not weakened. Resume with the documented
fresh command after that prerequisite is resolved, then run the cached command
and compare with `tools/compare_distribution_all_logs.zig` (28 tests passed).

An additional composed-only discovery used the currently retained compiler-rt
input `tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll`, SHA-256
`9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1`:
`zig-out/bin/z_llvm --target=x86_64-linux --emit=obj --generic-cfg-selector --report-all-codegen-failures --input-limit=50000000 INPUT`.
Its report (`real-family-discovery.log`) contains 443 selected, 264 emitted and
179 failed functions. This distinct retained workload/report configuration is
not comparable to the accepted 285-function population. The new division forms
do not close a family in this report. A concrete candidate is the four pointer
return failures (`__memset`, `memset`, `ssp.__memset_chk`, `ssp.__strncpy_chk`),
which also need composed memory intrinsic support; no admission-only change was
made or closure claimed. Phase 5's real-family requirement remains unfinished.

Final allocated sizes are recorded in `final-disk-usage.tsv`: tmp 45,821,952 bytes,
local-state 680,484,864 bytes, current Zig build cache 1,289,961,472 bytes and
current installed build 93,741,056 bytes. Failed real-row captures are small and
retained for the blocker; the selected AIR cache root is empty because export
was never reached. No validation processes remain active. The final current-doc
check passed for 14 documents, 50 internal file links and two generated status
blocks; `git diff --check` passed. Source file hashes accompany this report.


## Authorized unblock and fresh retry

The user explicitly requested removal of the unrelated untracked script.
`rm -- /home/oleg/prog/ziglang/doc/langref_to_markdown.py` completed, and
`git -C /home/oleg/prog/ziglang status --short` returned empty output.
The external checkout prerequisite is now resolved. The gate/cache and selector
changes still require Tier 3; the earlier attempt failed and cannot supply full
acceptance. Retrying the documented fresh command with serial root `fresh-clean`
and live output `tmp/project-improvement-tier3-fresh-clean.log`, retaining the same compiler, target, pins,
candidate contract and project source state.


## Implementation checkpoint commit

The user requested committing the current implementation. This is an intermediate
checkpoint, not yet milestone-green under `docs/validation_tiers.md`. The fresh
retry has passed the first six subgates and is running `integrated-object-preopt`
at this checkpoint. Its live log was moved to
`tmp/project-improvement-tier3-fresh-clean.log`; the open writer continues using
that same file. The mutable log is excluded from this commit. Retain the completed
log and same-input cached comparison in a subsequent evidence commit. The
real-function family requirement remains open and accepted counters do not move.

Source, tests, docs, completed focused logs and retention manifests are committed
together. No generated artifact objects, build cache or active validation tree
are included. The recorded source hashes still match the implemented files.
