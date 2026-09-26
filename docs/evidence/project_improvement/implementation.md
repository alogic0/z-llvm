# Project improvement implementation evidence

Current result: the cache retry fix passed focused validation and the full fresh/
cached Tier-3 pair, with 17/17 subgates passing in each and 1,315 matching canonical
records. The original plan's named real-function failure-family closure remains
open. Accepted baseline counters are unchanged.

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

## Initial validation and failed integration attempts

The following records describe validation before checkpoint `44a87146`. The
completed fresh retry and its cached comparison are recorded in the cache retry
section below. Accepted baseline counters are unchanged.

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
compiler-core corpus. That distinct Phase-5 requirement remained open at this checkpoint; no real-row
counter was advanced or fallback retired on the division evidence alone. The
[later memset slice](../composed_memset_family.md) records the separate real-family work.

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


## Historical integration failure before checkpoint

The corrected fresh run passed all nine subgates through
`integrated-object-release`. The three real-row children then exited with
`ExternalRepositoryDirty` before AIR export or cohort execution. Their raw stdout,
stderr and failure manifest are retained as `tier3-child-*` beside the complete
`tier3-fresh.log`. This was a failed acceptance attempt, not a passing Tier-3 run.
It provided no cached acceptance or fresh/cache equivalence evidence.

The pinned checkout has exactly one reported untracked file:
`/home/oleg/prog/ziglang/doc/langref_to_markdown.py` (`external-status.txt`).
`src/distribution_execution_cohort_v1.zig:requireExternalRepositoryClean` checks
`git status --porcelain=v1 --untracked-files=all`. The unrelated file was left
untouched at that point. The user-authorized deletion recorded below resolved
this historical failure; the cleanliness requirement was preserved. The next
required checks were the fresh/cached pair and log comparison (the comparator
then passed 28 tests).

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
made or closure claimed in that discovery. The later
[bounded memset slice](../composed_memset_family.md) implements three of these
functions; string-copy semantics remain outside that slice.

Checkpoint allocated sizes are recorded in `final-disk-usage.tsv`: tmp 45,821,952 bytes,
local-state 680,484,864 bytes, current Zig build cache 1,289,961,472 bytes and
current installed build 93,741,056 bytes. Failed real-row captures are small and
retained for the blocker; the selected AIR cache root was empty because export
was never reached. No validation processes were active at that checkpoint. The current-doc
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
retry had passed the first six subgates and was running `integrated-object-preopt`
at this checkpoint. Its live log was moved to
`tmp/project-improvement-tier3-fresh-clean.log`; the open writer continues using
that same file. The mutable log is excluded from this commit. Retain the completed
log and same-input cached comparison in a subsequent evidence commit. The
real-function family requirement remains open and accepted counters do not move.

Source, tests, docs, completed focused logs and retention manifests are committed
together. No generated artifact objects, build cache or active validation tree
are included. The recorded source hashes still match the implemented files.


## Cache retry correction

After checkpoint `44a87146`, the fresh retry passed nine subgates and failed
with `PathAlreadyExists` when creating its first mode-cache root. Its completed
log is `tier3-fresh-clean-failed.log`. The previous child failure had left three
empty `MODE/export` directory pairs. Inspection found no files or symlinks;
`rmdir` removed only those six empty directories and would have failed on content.

The shared cache-selection preflight now rejects any existing mode entry before
creating run state. The full runner calls it before the first subgate and reports
`RealRowsFreshCacheAlreadyExists` with a cache-selection remedy. Files and dangling
symlinks also reject without being modified. This preserves the unused-generation
contract; it does not silently overwrite a retained or active cache. The standalone
parallel runner now exposes `--fresh-export` for reproducing the same production
fresh path directly, with required-hit reuse as its default.

Tests: 25 parallel-runner and 43 serial-runner tests passed. A full-runner negative
using the actual leftover directories rejected before any `gate-start` or scratch
allocation (`retry-preflight.log`). A direct fresh/cached pair uses isolated roots
ending in `project-improvement-probe` before the full retry. Gate/cache changes
require a new fresh/cache Tier-3 pair; the earlier failing runs cannot prove it.
The full pair used unchanged source, target, emitter, candidate pin and
expected counters, roots ending in `project-improvement`, and serial run roots
`retry-fresh`/`retry-cached`. Its completed results are recorded below.

The direct fresh group passed (exit 0) in 1,359,404 ms. Each mode reported
100 lowered, 100 objects, 100 native links, 4 cohort functions and 4 paired
harnesses, with zero failures. Fresh cache export took 587,837 ms (Fast),
608,037 ms (Safe) and 474,448 ms (Small). `retry-real-rows-fresh.log` retains the
complete strict records and parent cache verification evidence. The required-hit
run against those same caches subsequently passed, as recorded below. The final
comparator plus imported runner tests passed (31 tests).


### Comparison schema 4

The direct cached run exposed a pre-existing comparison limitation: Fast harness
executables embed the unique run directory in debug information, so their whole
file hashes change across identical executions. Extracted `.text` hashes of both
the reference and linked Fast binaries are equal across fresh/cache runs. Both
sampled Small binaries are byte-identical. Hashes and sizes are recorded in
`retry-wrapper-binary-check.tsv`; `strings` confirms the unique work path in the
Fast reference executable. All twelve completed cohort rows match in every field
except `reference_sha256` and `linked_sha256`.

The comparator schema is now 4. It validates complete raw real-row records in all
three modes using the production strict parser before dropping those two wrapper
hash fields from comparison. Raw logs retain their per-run hashes. Descriptor and
selected-object hashes, byte counts, results, witnesses, stdout hashes, exit
statuses and counters remain exact comparisons. Malformed hashes and incomplete
mode sets reject before normalization. A `--real-rows` comparison entrypoint uses
this same logic for standalone focused logs without claiming a 17-subgate run.
This utility-only change does not alter the running native gates or their inputs.

The direct required-hit group passed (exit 0), wall_ms=766130.
All three cache statuses were hit; every mode again reported 100/100/100 and
4/4 with zero failures. The schema-4 comparator reports 21 canonical records
matching across all three modes (`retry-real-rows-equivalence.log`).

Starting the authoritative full fresh run:
`/home/oleg/.zig/0.16.0/files/zig build distribution-all -- --serial --fresh-real-rows --serial-root=local-state/validations/project-improvement/retry-fresh --real-rows-validation-root=local-state/validations/project-improvement --real-rows-cache-root=local-state/caches/project-improvement --zig-emitter=/home/oleg/prog/ziglang/build/stage4/bin/zig`.
Live output: `tmp/project-improvement-tier3-retry-fresh.log`. The source snapshot
`retry-source-files.sha256` now includes the comparator schema-4 change. The
external checkout is clean and the selected fresh cache generation is empty.


The full fresh Tier-3 run passed all 17 subgates (exit 0), wall_ms=2726375.
Each real-row mode passed 100 lowered/emitted/linked rows and 4/4 cohort execution;
the seven original integrated-executable cases and all 24 behavioral program
pairs (6,528 observations, 10 composed functions, zero fallbacks) passed. The
release bundle was produced once and reused by three consumers with identity
`a5dcce564ade761f3cf47c9767f69615cdadbe0d6c2cc88419efaaf52e9518fa`.
The completed log is `tier3-retry-fresh.log`. The strict comparator parses its
17 complete gate lifecycles and 1,315 canonical records successfully.

The full cached run used the same command, omitting `--fresh-real-rows`, setting
serial root to `retry-cached`, and retaining the same validation/cache roots and
emitter. Both completed logs are retained in this directory; their temporary
copies were removed after comparison.


## Completed cache retry acceptance

Both full runs exited 0 with all 17 subgates passing. Fresh wall time was
2,726,375 ms (45m 26s); cached wall time was 2,036,697 ms (33m 57s).
`tier3-retry-timings.tsv` records each subgate's elapsed time and cache status;
the three real-row modes execute in parallel, so their times must not be added
to estimate wall time. All three fresh cache statuses were miss, all three cached
statuses were hit, and each mode retained the same cache key and descriptor size.

The final comparison command was:

```sh
/home/oleg/.zig/0.16.0/files/zig run tools/compare_distribution_all_logs.zig -- \
  docs/evidence/project_improvement/tier3-retry-fresh.log \
  docs/evidence/project_improvement/tier3-retry-cached.log
```

`tier3-retry-equivalence.log` reports schema 4, 17 gates, 1,315 canonical records,
`semantic_match=true` and `local_fail=0`. Raw cohort records validate before the
two documented wrapper hashes are normalized. Each mode again passed 100 lowered,
100 emitted and 100 linked rows, four executed cohort functions and four paired
harnesses. The integrated executable gate passed all seven original cases and
24 behavioral program/mode pairs, 6,528 observations across 10 composed function
identities, with no structural fallback. Both runs produced the same release
bundle identity once and reused it in three consumers.

Relevant source hashes matched `retry-source-files.sha256` before and after the
pair; the patched emitter checkout remained clean at the recorded pin. The live
child compiler observation in `retry-child-compiler.txt` confirms Zig 0.16.0 even
with the other Zig version on the original PATH. Focused checks passed 25 parallel
runner tests, 43 serial runner tests and 31 comparator/imported tests. The actual
leftover-cache negative rejected before the first subgate (`retry-preflight.log`).

The separate focused fresh/cached pair also passed all three modes and matched
21 canonical records. Its duplicate cache and scratch trees were removed after
preserving complete logs and wrapper binary/text hashes. Full-run scratch trees
were removed by their runners. Historical failure copies were checked against
versioned evidence before deletion, and the old empty mode/work directories were
removed using `rmdir`. `retry-cleanup.txt` records those removals;
`retry-final-disk-usage.tsv` records remaining allocated sizes. One AIR generation
(4,011,089,920 allocated bytes) remains for near-term required-hit reuse. The
validation root is empty and no validation process remains running.

This completes cache/gate infrastructure acceptance for this implementation state.
It does not close the original plan's named recurring real-function family or
migrate the inherited three-member accepted baseline to the four-member development
cohort. That family remains the next implementation task.


The 2026-09-26 [composed memset family](../composed_memset_family.md) closes the
remaining Phase-5 named-family deliverable. Three byte-identical retained
definitions execute through shared lowering, with six additional compositions,
8,652 native observations and 12 checked traps across two routes and three modes.
The final corrected source passes 17/17 integration subgates. The 443-function
discovery report improves from 264 to 267 emitted functions with no new failures;
accepted population counters and denominators are unchanged.
