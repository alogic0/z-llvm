# Remaining local storage: purpose and retirement review

Status: investigation and verified cleanup in progress. This continues
[completed-run retention](2026-11-13-completed-run-retention.md). Ordinary old
build binaries and objects are disposable; reconstructing or archiving their
source/build configuration is not a prerequisite for retirement. Current uses,
queued holds, adopted baselines and exact-executable investigations remain
separate constraints.

The starting inventory was
`local-state/retirements/automatic-storage-cleanup/1794567509443891881-3494523/inventory.json`:
147.34 GiB allocated, including 23.26 GiB under explicit current contracts and
124.08 GiB unresolved. These are inode counts during concurrent development,
not a claim that the retained files are all necessary.

## Completed compiler builds

All 37 reviewed behavior compiler outputs from v800–v967 were removed:
4,031,119,360 allocated file bytes. Four newly closed compiler caches contributed
another 170,352,640 bytes. Total: **4,201,472,000 bytes (3.91 GiB)**.

Their purpose was to execute completed experiments. The build reports remain;
source/configuration reconstruction was not performed for this disposal.
Seventy exact references in completed historical retirement records were
transitioned. Current holds and integrity manifests were not retired.

The first apply stopped on a live state change after 24 removals. A fresh pass
completed the other 17. Both left no pending mutation, and the completed pass
verified all five current integrity manifests. Records:

- `1794569002644849105-3548554/report.json`
- `1794569724655554928-3605743/report.json`

## Private native-test caches

These directories contain Zig-generated test executables, objects, compiler
modules and cache indexes. Their role ends with the owning test job unless a
current consumer or hold requires them. Original test receipts and logs live
outside the cache, including failure and cancellation diagnostics.

The survey read 305 unit-related receipts. Eighty-six use copied-project
`evidence/` directories; 42 explicitly name private caches. One earlier receipt
reuses the same ReleaseSafe cache as a later completed receipt, so the reviewed
plan has 41 distinct owning jobs. Queued/current roots remain subject to holds.
The 35 default `.zig-cache` directories in these projects contain only 286,720
allocated bytes in total; they are not a substantial remaining opportunity.

Older receipts omit cwd. Their copied-project layout is produced by
`prepare_unit_project_v686.zig`: `.zigversion` is copied, while `src`, `tools`,
`test` and `docs` are linked. The cache plan explicitly records the ownership
review of that layout, relative source/cache arguments and sibling logs. It
does not pretend that cwd was recorded historically. New `run_checked` receipts
record the actual child cwd.

The collector now supports explicit private-cache requests and retains every
producer log. It checks terminal status, actual return code, timestamps, exact
cache arguments, owner scope, pins, consumers, links and a complete cache
snapshot. The first real preparation rejected all entries because the initial
marker check tried to traverse `src`. That was corrected to inspect the owned
source link itself without following or changing it. The rejected preparation
removed no payloads. The corrected preparation accepted all 41 requests.
Fresh review qualified 70 cache roots totaling 11,045,298,176 allocated file
bytes (10.29 GiB). Twelve other private-cache roots remain held under the
current tail-owner and legacy-tail test projects. No historical pin transition
was needed for the 70 admitted caches.

Implementation commits: `8584a487`, `cd595a6e`. Native qualification passes
74 tests in Debug and ReleaseFast. All 16 isolated CLI checks pass again after
the source-link correction; real-batch results are recorded below.
An independent smoke test verified that the recorded cwd equals `/bin/pwd`
when the invoking shell is in a different directory.

## Audited raw traces

Raw event streams explain compiler selection, failures, counters and timing.
They are different from executable build outputs. Complete semantic audits,
summaries, original outcomes and failure diagnostics already exist for many.

A specific blocker is now established for **24 isolated-prototype traces,
22,711,975,936 bytes (21.15 GiB)**. All 24 original compiler binaries are absent
after earlier retirement. A fresh check of all **15,384 source-hash entries**
from their build reports passed with zero mismatches. They are not being kept
because those source trees have been lost. The current trace adapter requires
the original executable as well as the audit and source/build evidence.

The next supported transition should authenticate the completed compiler
retirement record against the compiler identity in the audited run and build
receipt. Merely accepting a missing executable or an unverified JSON status is
insufficient. A rebuilt executable must not be claimed to exist. This review
does not weaken the trace contract or remove these streams.

There are also canonical build receipts and eight older traces with legacy
command/source bindings. The old audit's eight legacy entries total only
176,824,320 bytes. They should not distract from the much larger, precisely
identified missing-compiler case. Historical audit classifications are not
relabelled as fresh release qualification.

## Integrated comparison runs

Twenty-nine unresolved integrated-run roots in the starting inventory total
**25,981,669,376 bytes (24.20 GiB)**. This is a mixed category:

| Family | Allocated bytes | Purpose and next action |
| --- | ---: | --- |
| Executables | 5,058,748,416 | Capture helpers and local/reference programs used by completed comparisons; identify each producer and current baseline before retirement. |
| Objects/archives | 1,806,893,056 | Generated comparison/linking outputs; strong disposable candidates after matching terminal command records. |
| Recognized caches | 1,446,195,200 | Private Zig cache roots; current isolated-build adapter does not bind the integrated-run schema. |
| Compiler inputs | 8,367,509,504 | Captured preoptimization, optimized and object-input IR needed to explain/replay a comparison; review duplicate content independently. |
| Other | 5,384,519,680 | Includes large generated `linked-harness.s` assembly; the filename-family inventory does not assign all of it a semantic role. |
| Records/analyses | 2,594,672,640 | Commands, captured backend reports and local/reference observations; retain compact results while reviewing redundant detail. |
| Logs | 1,121,869,824 | Original command diagnostics; failed/incomplete outcomes require individual review. |
| Source and directories | 201,261,056 | Separate from generated executables and caches. |

For example, `integrated-behavior-followup-v781` occupies 2,252,787,712 bytes.
Its `input-program/report.json` records 138 local and 138 reference executions
with passed status. Other subtrees have their own commands and results; that
one passed report does not close the entire tree. The next adapter should read
those command/output bindings and release only generated outputs, preserving
IR, sources and result records. Blanket deletion of an integrated root would
mix these different roles.

## Duplicate large IR inputs

A fresh scan of `input.ll` files at least 400,000,000 bytes found 68 paths but
only **12 distinct inodes**, occupying 5,323,603,968 bytes. Existing hardlinks
already share many names. Hashing one representative of every inode found:

- Eleven distinct inodes with the identical 443,624,107-byte input and SHA-256
  `de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`.
- One different self-rebuild input with SHA-256
  `7217b032845c0bb8e653823eac80bfae571707eed60793047c2576e27b849976`.

The theoretical redundancy is about **4.13 GiB**, not 67 copies. These files
are recorded inputs, and some inode groups already have 35 aliases. They are
writable. Replacing independent copies with hardlinks without establishing
immutability would couple future writes. Use a reviewed immutable input-store
transition that preserves named consumers and verifies every alias; no input
paths were removed by this investigation.

## Pinned and discrepant selection compilers

The broader survey found 41 present canonical compiler install paths with
closed successful build commands. They occupy 36 distinct inodes and
3,776,917,504 allocated bytes; eight paths have multiple hardlink aliases.
This is not yet an eligible-byte count: current manifests, historical pins,
alias ownership and actual compiler identities still require review. The
receipt and inode lists are saved beside the cache investigation.

Two batch-30 v3 compilers belong to the current accepted-artifact manifest and
remain baselines. Other old selection outputs are referenced by batch-11,
batch-13, batch-14 or batch-30 v1 manifests. Those need explicit transitions
for their specific historical contracts; the collector does not treat every
accepted manifest as expired.

The batch-11 Debug v4 mismatch is explained by
`batch-11/binary-review-v5/inspection-incident.json`: GNU objcopy repacked the
install in place during an inspection. The current hash is
`db03461e04b0f42352180d8de448e025f4f944b028b6bc42105d589ef0b4f329`, matching the
recorded incident, while the build receipt expects `f69bac40…`. The original
receipt remains accurate for the original build. The incident explicitly kept
the repacked executable as discrepancy evidence and gave it no final acceptance
credit. Do not silently replace the expected hash to make cleanup pass.

## Other retained evidence

Native-suite roots outside the integrated-run group contain about 3.19 GiB
unresolved in the starting inventory. They include local/reference test
executables and objects, but also 1,398,972,416 bytes of stdout/stderr logs and
290,463,744 bytes of result records. Large allocations are spread across
thousands of per-case files, rather than one abandoned log. Their comparison
reports and per-command outcomes should drive selective compaction and output
retirement.

Research source copies and accepted source snapshots have a different role
from binaries. They can contain the sole remaining experiment edits or serve
active audit/replay consumers. The disposable-build policy removes the need to
create new source archives; it does not establish that every existing research
tree is redundant. Current shared caches, worktrees and artifact-store objects
also need their own consumer/store lifecycle, not the private-cache rule.

## Local evidence and next order

Small inventories, source-check results, input inode/hash lists, qualification
logs and the cache ownership plan are in
`local-state/storage-cleanup/remaining-investigation/`. They contain no copied
payload archive. The pin optimization was measured on 100,000 repeated absent
references: 0.59 s before and 0.50 s after in one isolated run. That narrow
measurement is not a claim that historical full-project cleanup is fast.

After the private-cache batch, prioritize authenticated retired-compiler
identity for the 21.15-GiB trace group, terminal command/output ownership for
integrated runs, and immutable input deduplication. Keep unresolved allocation
visible; neither age nor a zero-candidate cleanup report proves necessity.
